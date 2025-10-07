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
  /// chatId: your local partition key (can be same as senderId)
  /// senderId: whose help_messages we read/write
  Future<void> start(
    String chatId,
    String senderId, {
    int initialPage = 50,
  }) async {
    // 1) Backfill once if local empty
    final latestLocal = await local.latestCreatedAt(chatId);
    if (latestLocal == null) {
      final firstPage = await _msgs(
        senderId,
      ).orderBy('createdAt', descending: true).limit(initialPage).get();

      final firstMsgs = firstPage.docs.map(_toMessage).toList();
      if (firstMsgs.isNotEmpty) {
        // defensive dedupe
        await local.deleteAllByDocIds(firstMsgs.map((m) => m.docId).toList());
        await local.upsertMany(firstMsgs);
      }
    }

    // 2) Delta: strictly newer than latest local
    final since = await local.latestCreatedAt(chatId);
    if (since != null) {
      final deltaSnap = await _msgs(senderId)
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

    Query<Map<String, dynamic>> q = _msgs(senderId).orderBy('createdAt');
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
        ? _msgs(senderId).orderBy('createdAt', descending: true).limit(pageSize)
        : _msgs(senderId)
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

  /// Send without duplication (pre-generate Firestore id and use it locally)
  Future<void> sendMessage({
    required String chatId, // local partition
    required String senderId,
    required String text,
    required String sender,
  }) async {
    final ref = _msgs(senderId).doc(); // generate id locally
    final docId = ref.id;
    final now = DateTime.now();

    // 1) Optimistic local write with SAME docId
    final optimistic = Message()
      ..docId = docId
      ..chatId = chatId
      ..senderId = senderId
      ..sender = sender
      ..text = text
      ..createdAt = now
      ..updatedAt = now;

    // defensive dedupe, then upsert
    await local.deleteByDocId(docId);
    await local.upsertMany([optimistic]);

    // 2) Remote write with that id
    await ref.set({
      'chatId': chatId,
      'senderId': senderId,
      'sender': sender,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'deleted': false,
    });
  }

  /// Accept DocumentSnapshot so it works for both query pages and change docs
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
      ..text = (data['text'] as String?) ?? ''
      ..createdAt = createdAt
      ..updatedAt = updatedAt
      ..deleted = (data['deleted'] as bool?) ?? false;
  }
}

// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:omeeowash/models/message.dart';

// import 'local_chat_storage.dart';

// class ChatSyncService {
//   final FirebaseFirestore firestore;
//   final LocalChatStore local;
//   StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tailSub;
//   final String userId = FirebaseAuth.instance.currentUser!.uid;

//   ChatSyncService(this.firestore, this.local);

//   CollectionReference<Map<String, dynamic>> _msgs(senderId) =>
//       firestore.collection('users').doc(senderId).collection('help_messages');
//   //firestore.collection('chats').doc(chatId).collection('messages');

//   // Call on screen open (or app start) to reconcile + start realtime tail
//   Future<void> start(
//     String chatId,
//     String senderId, {
//     int initialPage = 50,
//   }) async {
//     // 1) If local is empty, backfill latest page once for instant UX next time.
//     final latestLocal = await local.latestCreatedAt(chatId);
//     if (latestLocal == null) {
//       final firstPage = await _msgs(
//         senderId,
//       ).orderBy('createdAt', descending: true).limit(initialPage).get();
//       await local.upsertMany(firstPage.docs.map(_toMessage).toList());
//     }

//     // 2) Delta sync: fetch anything newer than latest local, merge into local
//     final since = await local.latestCreatedAt(chatId);
//     if (since != null) {
//       final delta = await _msgs(senderId)
//           .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
//           .orderBy('createdAt') // ascending to apply in order
//           .get();
//       await local.upsertMany(delta.docs.map(_toMessage).toList());
//     }

//     // 3) Start realtime tail: listen for new/updated docs (strictly newer than latest local)
//     _tailSub?.cancel();
//     final startAfter = await local.latestCreatedAt(userId);
//     Query<Map<String, dynamic>> q = _msgs(
//       senderId,
//     ).orderBy('createdAt', descending: false);
//     if (startAfter != null) {
//       q = q.startAfter([Timestamp.fromDate(startAfter)]);
//     }
//     _tailSub = q.snapshots().listen((snap) async {
//       final msgs = snap.docs.map(_toMessage).toList();
//       if (msgs.isNotEmpty) {
//         await local.upsertMany(msgs); // write-through: local first
//       }
//     });
//   }

//   void stop() => _tailSub?.cancel();

//   // Pagination for older history (user scrolls up)
//   Future<void> loadOlder(
//     String senderId,
//     String chatId, {
//     int pageSize = 50,
//   }) async {
//     final oldest = await local.oldestCreatedAt(chatId);
//     final q = oldest == null
//         ? _msgs(senderId).orderBy('createdAt', descending: true).limit(pageSize)
//         : _msgs(senderId)
//               .orderBy('createdAt', descending: true)
//               .startAfter([Timestamp.fromDate(oldest)])
//               .limit(pageSize);

//     final older = await q.get();
//     await local.upsertMany(older.docs.map(_toMessage).toList());
//   }

//   // Optimistic send: save locally immediately, then to Firestore
//   Future<void> sendMessage({
//     required String chatId,
//     required String senderId,
//     required String text,
//     required String sender,
//   }) async {
//     final now = DateTime.now();

//     // Optimistic local insert (temporary docId; Firestore docId will reconcile via listener)
//     final temp = Message()
//       ..docId = 'temp_${now.microsecondsSinceEpoch}'
//       ..chatId = chatId
//       ..senderId = senderId
//       ..text = text
//       ..sender = sender
//       ..createdAt = DateTime.now()
//       ..updatedAt = DateTime.now();

//     await local.upsertMany([temp]);

//     // Firestore write (server timestamps)
//     final ref = await _msgs(senderId).add({
//       'chatId': chatId,
//       'senderId': senderId,
//       'text': text,
//       "sender": sender,
//       'createdAt': FieldValue.serverTimestamp(),
//       'updatedAt': FieldValue.serverTimestamp(),
//       'deleted': false,
//     });

//     // When the server doc appears on the snapshot, it will be upserted and your UI
//     // will naturally include it (you can also reconcile temp by matching text+time if desired).
//   }

//   Message _toMessage(QueryDocumentSnapshot<Map<String, dynamic>> d) {
//     final data = d.data();
//     final createdAt =
//         (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
//     final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();

//     final m = Message()
//       ..docId = d.id
//       ..chatId = data['chatId'] as String
//       ..senderId = data['senderId'] as String
//       ..text = data['text'] as String? ?? ''
//       ..sender = data['sender'] as String? ?? ''
//       ..createdAt = createdAt
//       ..updatedAt = updatedAt
//       ..deleted = (data['deleted'] as bool?) ?? false;
//     return m;
//   }
// }
