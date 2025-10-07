import 'package:isar/isar.dart';
import 'package:omeeowash/models/message.dart';

class LocalChatStore {
  final Isar isar;
  LocalChatStore(this.isar);

  // Stream messages for UI (latest first)
  // Stream<List<Message>> watchLatest(String chatId, {int limit = 50}) {
  //   return isar.messages
  //       .filter()
  //       .chatIdEqualTo(chatId)
  //       .and()
  //       .deletedEqualTo(false)
  //       .limit(limit)
  //       .watch(fireImmediately: true);
  // }
  Stream<List<Message>> watchLatest(String chatId, {int limit = 50}) {
    return isar.messages
        .filter()
        .chatIdEqualTo(chatId)
        .deletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((msgs) {
          // copy + sort ascending (oldest -> newest)
          final sorted = List<Message>.from(msgs)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          // take the newest `limit` messages (still ascending)
          if (sorted.length <= limit) return sorted;
          return sorted.sublist(sorted.length - limit);
        });
  }

  // Upsert many (transactional)
  Future<void> upsertMany(List<Message> msgs) async {
    if (msgs.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.messages.putAll(
        msgs,
      ); // because docId is unique index + replace
    });
  }

  // Get most recent createdAt in local
  Future<DateTime?> latestCreatedAt(String chatId) async {
    final q = await isar.messages
        .filter()
        .chatIdEqualTo(chatId)
        .sortByCreatedAtMsDesc()
        .limit(1)
        .findAll();
    return q.isEmpty ? null : q.first.createdAt;
  }

  // Get oldest (for pagination)
  Future<DateTime?> oldestCreatedAt(String chatId) async {
    final q = await isar.messages
        .filter()
        .chatIdEqualTo(chatId)
        .sortByCreatedAtMs()
        .limit(1)
        .findAll();
    return q.isEmpty ? null : q.first.createdAt;
  }

  // Delete ONE by Firestore docId (unique index)
  Future<bool> deleteByDocId(String docId) async {
    return isar.writeTxn(() => isar.messages.deleteByDocId(docId));
  }

  // Delete MANY by docIds
  Future<int> deleteAllByDocIds(List<String> docIds) async {
    return isar.writeTxn(() => isar.messages.deleteAllByDocId(docIds));
  }

  // Optional: soft-delete (keep row but hide it)
  Future<void> softDelete(String docId) async {
    await isar.writeTxn(() async {
      final m = await isar.messages.getByDocId(docId);
      if (m != null) {
        m.deleted = true;
        await isar.messages.putByDocId(m);
      }
    });
  }
}
