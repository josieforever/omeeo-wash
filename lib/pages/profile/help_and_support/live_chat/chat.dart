import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/models/message.dart';
import 'package:omeeowash/services/chat_sync_service.dart';
import 'package:omeeowash/services/local_chat_storage.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';

import 'live_chat.dart';
import 'methods.dart';

class Chat extends StatefulWidget {
  final String? clientId;
  final String? clientName;
  const Chat({super.key, required this.clientId, this.clientName});
  const Chat.admin({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final ScrollController _scrollController = ScrollController();
  final _newestKey = GlobalKey();
  final TextEditingController messageController = TextEditingController();
  final firestore = FirebaseFirestore.instance;
  bool isAdmin = false;

  String get userId =>
      isAdmin ? widget.clientId! : FirebaseAuth.instance.currentUser!.uid;

  String get chatId => '${userId.substring(2, 14)}cc-4372-a';
  String get sender => isAdmin ? "ommeo" : 'user';

  String username = "";
  final bool _isLoadingMore = false; // remove final if needed
  late final ChatSyncService sync;
  late final LocalChatStore store;

  // Selection controller
  final SelectionController selection = SelectionController();

  bool isCurrentlyTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    getUserInfo();

    store = context.read<LocalChatStore>();
    sync = context.read<ChatSyncService>();
    sync.start(chatId, userId);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    sync.stop();
    super.dispose();
  }

  void _ensureNewestVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _newestKey.currentContext;
      if (ctx != null && _isNearBottom()) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.0,
        );
      }
    });
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    const pad = 200.0;
    return (pos.pixels - pos.minScrollExtent).abs() <= pad;
  }

  void getUserInfo() async {
    final userSnapshot = await firestore.collection("users").doc(userId).get();
    final userData = userSnapshot.data();
    setState(() {
      isAdmin = userData?["isAdmin"] ?? false;
      username = userData?["name"] ?? "User";
    });
  }

  Future<void> sendHelpMessage() async {
    final String message = messageController.text.trim();
    if (message.isEmpty) return;

    sync.sendMessage(
      chatId: chatId,
      senderId: userId,
      text: message,
      sender: sender,
    );

    final adminChatRef = firestore
        .collection('admin')
        .doc("idforadminv1")
        .collection('help_chats')
        .doc(userId);

    final batch = firestore.batch();
    if (isAdmin) {
      batch.update(adminChatRef, {"last_message": message});
    } else {
      batch.set(adminChatRef, {
        "userId": widget.clientId,
        "username": username,
        "last_message": message,
      });
    }

    messageController.clear();
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('❌ Failed to send help message: $e');
    }
  }

  void onTyping(String text) {
    if (!isCurrentlyTyping) {
      isCurrentlyTyping = true;
      firestore.collection('users').doc(userId).update({'isTyping': true});
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      firestore.collection('users').doc(userId).update({'isTyping': false});
      isCurrentlyTyping = false;
    });
  }

  Future<void> pickFileAndSend() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final ext = fileName.split('.').last.toLowerCase();
      // Upload logic here...
    }
  }

  String formatTimestamp(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 1,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                FontAwesomeIcons.arrowLeft,
                color: Colors.white,
              ),
            ),
            title: ValueListenableBuilder<int>(
              valueListenable: selection.count,
              builder: (context, addUp, _) {
                if (addUp > 0) {
                  return CustomText(text: "$addUp selected");
                }
                return Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? widget.clientName ?? "" : "Support Centre",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              ValueListenableBuilder<int>(
                valueListenable: selection.count,
                builder: (context, addUp, _) {
                  if (addUp == 0) {
                    return Row(
                      children: const [
                        Icon(Icons.call, color: Colors.white),
                        SizedBox(width: 15),
                        Icon(Icons.videocam, color: Colors.white),
                        SizedBox(width: 10),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () {
                          Methods().showDeleteConfirmationDialog(context, () {
                            if (selection.selectedIds().length > 1) {
                              sync.deleteMany(
                                senderId: userId,
                                docIds: selection.selectedIds(),
                              );
                            } else {
                              sync.deleteMessage(
                                senderId: userId,
                                docId: selection.selectedIds()[0],
                              );
                            }
                            selection.clear();
                            Navigator.of(context).pop(true);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: selection.clear,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Chat started at 01:25 PM',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: store.watchLatest(chatId, limit: 50),
              builder: (context, snapshot) {
                final msgs = snapshot.data ?? const <Message>[];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (msgs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                _ensureNewestVisible();

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: msgs.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoadingMore && index == msgs.length) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final message = msgs[index];
                    final msgId = message.docId;
                    final isMine = message.sender == sender;
                    final ts = message.createdAt;

                    bool isSameSenderAsPrevious = false;
                    if (index > 0) {
                      final prevSender = msgs[index - 1];
                      isSameSenderAsPrevious =
                          prevSender.sender == message.sender;
                    }
                    final isNewest = index == 0;

                    return ValueListenableBuilder<bool>(
                      valueListenable: selection.listen(msgId),
                      builder: (context, isSelected, _) {
                        return MessageBubble(
                          key: isNewest ? _newestKey : ValueKey(msgId),
                          message: message.text,
                          timestamp: formatTimestamp(ts),
                          isPreviouseMessageMine: isMine,
                          isFirstSequence: !isSameSenderAsPrevious,
                          isSelected: isSelected,
                          onLongPress: () => selection.toggle(msgId),
                          onTap: () {
                            if (selection.count.value > 0) {
                              selection.toggle(msgId);
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // typing indicator
          StreamBuilder<DocumentSnapshot>(
            stream: firestore
                .collection('users')
                .doc(widget.clientId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final isTyping = data['isTyping'] ?? false;
              return isTyping && isAdmin
                  ? Container(
                      padding: const EdgeInsets.only(left: 20),
                      alignment: Alignment.bottomLeft,
                      child: const Text(
                        'typing...',
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          // input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          width: 2,
                          color: AppColors.deeperPeriwinkle,
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: onTyping,
                          controller: messageController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    GestureDetector(
                      // onTap: pickFileAndSend,
                      onTap: () {
                        Methods().showMediaPickerDialog(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.deeperPeriwinkle,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.attach_file,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        if (messageController.text.isNotEmpty) {
                          sendHelpMessage();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.deeperPeriwinkle,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps selection state per-message without forcing a full screen rebuild.
class SelectionController {
  final Map<String, ValueNotifier<bool>> _byId = {};
  final ValueNotifier<int> count = ValueNotifier<int>(0);

  ValueListenable<bool> listen(String docId) {
    return _byId.putIfAbsent(docId, () => ValueNotifier<bool>(false));
  }

  bool isSelected(String docId) => (_byId[docId]?.value ?? false);

  void toggle(String docId) {
    final vn = _byId.putIfAbsent(docId, () => ValueNotifier<bool>(false));
    final newVal = !vn.value;
    vn.value = newVal;
    count.value += newVal ? 1 : -1;
  }

  void clear() {
    for (final vn in _byId.values) {
      if (vn.value) vn.value = false;
    }
    count.value = 0;
  }

  List<String> selectedIds() =>
      _byId.entries.where((e) => e.value.value).map((e) => e.key).toList();
}

// // adb connect 192.168.43.1
