import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omeeowash/models/message.dart';
import 'local_chat_storage.dart';

class ChatSyncService {
  final FirebaseFirestore firestore;
  final LocalChatStore local;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tailSub;

  ChatSyncService(this.firestore, this.local);

  // users/{senderId}/help_messages
  CollectionReference<Map<String, dynamic>> _msgs(String senderId) =>
      firestore.collection('users').doc(senderId).collection('help_messages');

  /// Start sync for a chat
  Future<void> start(
    String chatId,
    String senderId, {
    int initialPage = 50,
  }) async {
    // 1) Backfill once if local empty
    final latestLocal = await local.latestCreatedAt(chatId);
    if (latestLocal == null) {
      final firstPage = await _msgs(senderId)
          .where('deleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(initialPage)
          .get();

      final firstMsgs = firstPage.docs.map(_toMessage).toList();
      if (firstMsgs.isNotEmpty) {
        await local.deleteAllByDocIds(firstMsgs.map((m) => m.docId).toList());
        await local.upsertMany(firstMsgs);
      }
    }

    // 2) Delta: strictly newer than latest local
    final since = await local.latestCreatedAt(chatId);
    if (since != null) {
      final deltaSnap = await _msgs(senderId)
          .where('deleted', isEqualTo: false)
          .orderBy('createdAt') // asc
          .startAfter([Timestamp.fromDate(since)]) // strictly newer
          .get();

      final deltaMsgs = deltaSnap.docs.map(_toMessage).toList();
      if (deltaMsgs.isNotEmpty) {
        await local.deleteAllByDocIds(deltaMsgs.map((m) => m.docId).toList());
        await local.upsertMany(deltaMsgs);
      }
    }

    // 3) Realtime tail (start after latest local)
    _tailSub?.cancel();
    final tailSince = await local.latestCreatedAt(chatId);

    Query<Map<String, dynamic>> q = _msgs(
      senderId,
    ).where('deleted', isEqualTo: false).orderBy('createdAt');

    if (tailSince != null) {
      q = q.startAfter([Timestamp.fromDate(tailSince)]);
    }

    _tailSub = q.snapshots().listen((snap) async {
      final toUpsert = <Message>[];
      final toDelete = <String>[];

      for (final ch in snap.docChanges) {
        switch (ch.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            toUpsert.add(_toMessage(ch.doc));
            break;
          case DocumentChangeType.removed:
            toDelete.add(ch.doc.id);
            break;
        }
      }

      if (toUpsert.isNotEmpty) {
        await local.deleteAllByDocIds(toUpsert.map((m) => m.docId).toList());
        await local.upsertMany(toUpsert);
      }
      if (toDelete.isNotEmpty) {
        await local.deleteAllByDocIds(toDelete);
      }
    });
  }

  void stop() => _tailSub?.cancel();

  /// Older-page pagination
  Future<int> loadOlder(
    String senderId,
    String chatId, {
    int pageSize = 50,
  }) async {
    final oldest = await local.oldestCreatedAt(chatId);
    final q = oldest == null
        ? _msgs(senderId)
              .where('deleted', isEqualTo: false)
              .orderBy('createdAt', descending: true)
              .limit(pageSize)
        : _msgs(senderId)
              .where('deleted', isEqualTo: false)
              .orderBy('createdAt', descending: true)
              .startAfter([Timestamp.fromDate(oldest)])
              .limit(pageSize);

    final older = await q.get();
    final olderMsgs = older.docs.map(_toMessage).toList();
    if (olderMsgs.isNotEmpty) {
      await local.deleteAllByDocIds(olderMsgs.map((m) => m.docId).toList());
      await local.upsertMany(olderMsgs);
    }
    return older.docs.length;
  }

  /// Send message (text, image, or video)
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String sender,
    String? text,
    String? mediaUrl, // for image/video
    MessageType type = MessageType.text,
  }) async {
    final ref = _msgs(senderId).doc(); // generate id locally
    final docId = ref.id;
    final now = DateTime.now();

    final optimistic = Message()
      ..docId = docId
      ..chatId = chatId
      ..senderId = senderId
      ..sender = sender
      ..text = text
      ..mediaUrl = mediaUrl
      ..type = type
      ..createdAt = now
      ..updatedAt = now
      ..deleted = false;

    await local.deleteByDocId(docId);
    await local.upsertMany([optimistic]);

    await ref.set({
      'chatId': chatId,
      'senderId': senderId,
      'sender': sender,
      'text': text,
      'mediaUrl': mediaUrl,
      'type': type.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': false,
    });
  }

  /// Convert Firestore -> Message
  Message _toMessage(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? const <String, dynamic>{};
    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

    return Message()
      ..docId = d.id
      ..chatId = (data['chatId'] as String?) ?? ''
      ..senderId = (data['senderId'] as String?) ?? ''
      ..sender = (data['sender'] as String?) ?? ''
      ..text = data['text'] as String?
      ..mediaUrl = data['mediaUrl'] as String?
      ..type = _parseMessageType(data['type'] as String?)
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..deleted = (data['deleted'] as bool?) ?? false;
  }

  MessageType _parseMessageType(String? raw) {
    switch (raw) {
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      default:
        return MessageType.text;
    }
  }

  /// Delete many by marking as deleted
  Future<int> deleteMany({
    required String senderId,
    required List<String> docIds,
  }) async {
    if (docIds.isEmpty) return 0;

    await local.deleteAllByDocIds(docIds);

    const int kLimit = 500;
    int total = 0;

    for (int i = 0; i < docIds.length; i += kLimit) {
      final end = (i + kLimit < docIds.length) ? i + kLimit : docIds.length;
      final chunk = docIds.sublist(i, end);

      final batch = firestore.batch();
      for (final id in chunk) {
        batch.update(_msgs(senderId).doc(id), {
          'deleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      total += chunk.length;
    }

    return total;
  }

  /// Single delete convenience
  Future<void> deleteMessage({
    required String senderId,
    required String docId,
  }) async {
    await local.deleteByDocId(docId);

    await _msgs(senderId).doc(docId).update({
      'deleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }
}

// class ChatSyncService {
//   final FirebaseFirestore firestore;
//   final LocalChatStore local;
//   StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tailSub;

//   ChatSyncService(this.firestore, this.local);

//   // users/{senderId}/help_messages
//   CollectionReference<Map<String, dynamic>> _msgs(String senderId) =>
//       firestore.collection('users').doc(senderId).collection('help_messages');

//   /// Start sync for a chat
//   Future<void> start(
//     String chatId,
//     String senderId, {
//     int initialPage = 50,
//   }) async {
//     // 1) Backfill once if local empty
//     final latestLocal = await local.latestCreatedAt(chatId);
//     if (latestLocal == null) {
//       final firstPage = await _msgs(senderId)
//           .where('deleted', isEqualTo: false)
//           .orderBy('createdAt', descending: true)
//           .limit(initialPage)
//           .get();

//       final firstMsgs = firstPage.docs.map(_toMessage).toList();
//       if (firstMsgs.isNotEmpty) {
//         await local.deleteAllByDocIds(firstMsgs.map((m) => m.docId).toList());
//         await local.upsertMany(firstMsgs);
//       }
//     }

//     // 2) Delta: strictly newer than latest local
//     final since = await local.latestCreatedAt(chatId);
//     if (since != null) {
//       final deltaSnap = await _msgs(senderId)
//           .where('deleted', isEqualTo: false)
//           .orderBy('createdAt') // asc
//           .startAfter([Timestamp.fromDate(since)]) // strictly newer
//           .get();

//       final deltaMsgs = deltaSnap.docs.map(_toMessage).toList();
//       if (deltaMsgs.isNotEmpty) {
//         await local.deleteAllByDocIds(deltaMsgs.map((m) => m.docId).toList());
//         await local.upsertMany(deltaMsgs);
//       }
//     }

//     // 3) Realtime tail (start after latest local)
//     _tailSub?.cancel();
//     final tailSince = await local.latestCreatedAt(chatId);

//     Query<Map<String, dynamic>> q = _msgs(
//       senderId,
//     ).where('deleted', isEqualTo: false).orderBy('createdAt');

//     if (tailSince != null) {
//       q = q.startAfter([Timestamp.fromDate(tailSince)]);
//     }

//     _tailSub = q.snapshots().listen((snap) async {
//       final toUpsert = <Message>[];
//       final toDelete = <String>[];

//       for (final ch in snap.docChanges) {
//         switch (ch.type) {
//           case DocumentChangeType.added:
//           case DocumentChangeType.modified:
//             toUpsert.add(_toMessage(ch.doc));
//             break;
//           case DocumentChangeType.removed:
//             toDelete.add(ch.doc.id);
//             break;
//         }
//       }

//       if (toUpsert.isNotEmpty) {
//         await local.deleteAllByDocIds(toUpsert.map((m) => m.docId).toList());
//         await local.upsertMany(toUpsert);
//       }
//       if (toDelete.isNotEmpty) {
//         await local.deleteAllByDocIds(toDelete);
//       }
//     });
//   }

//   void stop() => _tailSub?.cancel();

//   /// Older-page pagination
//   Future<int> loadOlder(
//     String senderId,
//     String chatId, {
//     int pageSize = 50,
//   }) async {
//     final oldest = await local.oldestCreatedAt(chatId);
//     final q = oldest == null
//         ? _msgs(senderId)
//               .where('deleted', isEqualTo: false)
//               .orderBy('createdAt', descending: true)
//               .limit(pageSize)
//         : _msgs(senderId)
//               .where('deleted', isEqualTo: false)
//               .orderBy('createdAt', descending: true)
//               .startAfter([Timestamp.fromDate(oldest)])
//               .limit(pageSize);

//     final older = await q.get();
//     final olderMsgs = older.docs.map(_toMessage).toList();
//     if (olderMsgs.isNotEmpty) {
//       await local.deleteAllByDocIds(olderMsgs.map((m) => m.docId).toList());
//       await local.upsertMany(olderMsgs);
//     }
//     return older.docs.length;
//   }

//   /// Send without duplication (pre-generate Firestore id and use it locally)
//   Future<void> sendMessage({
//     required String chatId, // local partition
//     required String senderId,
//     required String text,
//     required String sender,
//   }) async {
//     final ref = _msgs(senderId).doc(); // generate id locally
//     final docId = ref.id;
//     final now = DateTime.now();

//     final optimistic = Message()
//       ..docId = docId
//       ..chatId = chatId
//       ..senderId = senderId
//       ..sender = sender
//       ..text = text
//       ..createdAt = now
//       ..updatedAt = now;

//     await local.deleteByDocId(docId);
//     await local.upsertMany([optimistic]);

//     await ref.set({
//       'chatId': chatId,
//       'senderId': senderId,
//       'sender': sender,
//       'text': text,
//       'createdAt': FieldValue.serverTimestamp(),
//       'updatedAt': FieldValue.serverTimestamp(),
//       'deleted': false,
//     });
//   }

//   /// Accept DocumentSnapshot so it works for both query pages and change docs
//   Message _toMessage(DocumentSnapshot<Map<String, dynamic>> d) {
//     final data = d.data() ?? const <String, dynamic>{};
//     final createdAt =
//         (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
//     final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

//     return Message()
//       ..docId = d.id
//       ..chatId = (data['chatId'] as String?) ?? ''
//       ..senderId = (data['senderId'] as String?) ?? ''
//       ..sender = (data['sender'] as String?) ?? ''
//       ..text = (data['text'] as String?) ?? ''
//       ..createdAt = createdAt
//       ..updatedAt = updatedAt
//       ..deleted = (data['deleted'] as bool?) ?? false;
//   }

//   /// Delete many by docIds: local first (optimistic), then Firestore (batched).
//   Future<int> deleteMany({
//     required String senderId,
//     required List<String> docIds,
//   }) async {
//     if (docIds.isEmpty) return 0;

//     await local.deleteAllByDocIds(docIds);

//     const int kLimit = 500;
//     int total = 0;

//     for (int i = 0; i < docIds.length; i += kLimit) {
//       final end = (i + kLimit < docIds.length) ? i + kLimit : docIds.length;
//       final chunk = docIds.sublist(i, end);

//       final batch = firestore.batch();
//       for (final id in chunk) {
//         batch.update(_msgs(senderId).doc(id), {
//           'deleted': true,
//           'deletedAt': FieldValue.serverTimestamp(), // optional: track when
//         });
//       }
//       await batch.commit();
//       total += chunk.length;
//     }

//     return total;
//   }

//   /// Single delete convenience
//   Future<void> deleteMessage({
//     required String senderId,
//     required String docId,
//   }) async {
//     await local.deleteByDocId(docId);

//     await _msgs(senderId).doc(docId).update({
//       'deleted': true,
//       'deletedAt': FieldValue.serverTimestamp(), // optional
//     });
//   }
// }
