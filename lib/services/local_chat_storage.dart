import 'package:isar/isar.dart';
import 'package:omeeowash/models/message.dart';

class LocalChatStore {
  final Isar isar;
  LocalChatStore(this.isar);

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

  // Does a message exist by its Firestore docId?
  Future<bool> existsByDocId(String docId) async {
    final m = await isar.messages.getByDocId(docId);
    return m != null;
  }

  // Fetch message by docId (convenience)
  Future<Message?> getByDocId(String docId) => isar.messages.getByDocId(docId);

  // Bulk: which of these docIds already exist? (uses the index in one go)
  Future<Set<String>> existingDocIds(Iterable<String> docIds) async {
    if (docIds.isEmpty) return <String>{};
    final found = await isar.messages.getAllByDocId(docIds.toList());
    return found.whereType<Message>().map((m) => m.docId).toSet();
  }

  // Upsert only the ones that are missing locally
  Future<void> upsertManyIfMissing(List<Message> msgs) async {
    if (msgs.isEmpty) return;
    final ids = msgs.map((m) => m.docId);
    final have = await existingDocIds(ids);
    final newOnes = msgs.where((m) => !have.contains(m.docId)).toList();
    if (newOnes.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.messages.putAll(newOnes);
    });
  }
}
