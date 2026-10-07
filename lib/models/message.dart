import 'package:isar/isar.dart';

part 'message.g.dart';

enum MessageType { text, image, video }

@collection
class Message {
  Id id = Isar.autoIncrement; // local id

  @Index(unique: true, replace: true)
  late String docId; // Firestore document id

  @Index()
  late String chatId;

  late String senderId;
  late String sender;

  String? text; // optional caption or plain text
  String? mediaUrl; // image/video URL or local path

  @enumerated
  MessageType type = MessageType.text; // text, image, video

  // Timestamps
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
