import 'package:isar/isar.dart';

part 'message.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement; // local id
  @Index(unique: true, replace: true)
  late String docId; // Firestore document id

  @Index()
  late String chatId;

  late String senderId;
  late String text;
  late String sender;

  // Use millisecondsSinceEpoch for easy range queries
  @Index()
  late int createdAtMs;

  @Index()
  int? updatedAtMs;

  bool deleted = false;

  // Helpers
  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(createdAtMs);
  set createdAt(DateTime v) => createdAtMs = v.millisecondsSinceEpoch;
  DateTime? get updatedAt => updatedAtMs == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(updatedAtMs!);
  set updatedAt(DateTime? v) => updatedAtMs = v?.millisecondsSinceEpoch;
}
