import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImageProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:omeeowash/models/message.dart';
import 'package:omeeowash/services/chat_sync_service.dart';
import 'package:omeeowash/services/local_chat_storage.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'live_chat.dart';
import 'methods.dart';

class Chat extends StatefulWidget {
  final String? clientId;
  final String? clientName;
  final bool isAdmin;
  const Chat({
    super.key,
    required this.clientId,
    this.clientName,
    this.isAdmin = false,
  });
  const Chat.admin({
    super.key,
    required this.clientId,
    required this.clientName,
    this.isAdmin = false,
  });

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final _newestKey = GlobalKey();

  final TextEditingController messageController = TextEditingController();
  final firestore = FirebaseFirestore.instance;
  bool get isAdmin => widget.isAdmin;
  String get userId =>
      isAdmin ? widget.clientId! : FirebaseAuth.instance.currentUser!.uid;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // keep your original chatId logic (watch out for substring assumptions)
  String get chatId => '${userId.substring(2, 14)}cc-4372-a';
  String get sender => isAdmin ? "ommeo" : 'user';

  String username = "";
  late final ChatSyncService sync;
  late final LocalChatStore store;

  // Selection controller
  final SelectionController selection = SelectionController();

  bool isCurrentlyTyping = false;
  Timer? _typingTimer;

  // store file paths as in your original code
  String? pickedImageFile;
  String? pickedVideoFile;

  bool isSending = false;

  Future<void> pickImage() async {
    // Reset previous selections first
    setState(() {
      pickedImageFile = null;
      pickedVideoFile = null;
    });

    // Pick an image file safely
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false, // prevents loading the whole image into memory
    );

    if (result != null && mounted) {
      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      final sizeInMB = file.lengthSync() / (1024 * 1024);

      // ✅ Limit image size (e.g., 10 MB)
      if (sizeInMB > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image too large. Maximum allowed size is 10 MB.'),
          ),
        );
        return;
      }

      // ✅ Save the selected file path
      setState(() {
        pickedImageFile = filePath;
      });

      debugPrint(
        '🖼️ Picked image: $filePath (${sizeInMB.toStringAsFixed(2)} MB)',
      );
    }
  }

  Future<void> pickVideo() async {
    // Reset previous selections
    setState(() {
      pickedVideoFile = null;
      pickedImageFile = null;
    });

    // Pick a video file safely
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: false, // ensures file is not loaded into memory
    );

    if (result != null && mounted) {
      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      final sizeInMB = file.lengthSync() / (1024 * 1024);

      // Limit video size (e.g. 50 MB)
      if (sizeInMB > 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video too large. Maximum allowed size is 50 MB.'),
          ),
        );
        return;
      }

      // Save the path temporarily for upload
      setState(() {
        pickedVideoFile = filePath;
      });

      debugPrint(
        '🎬 Picked video: $filePath (${sizeInMB.toStringAsFixed(2)} MB)',
      );
    }
  }

  final Set<String> _processedDeletions = {};

  void listenForDeletedMessages() {
    firestore
        .collection('users')
        .doc(userId)
        .collection('help_messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) async {
          final List<String> deletedIds = [];

          for (var change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;

            final docId = change.doc.id;

            if (data['deleted'] == true &&
                !_processedDeletions.contains(docId)) {
              _processedDeletions.add(docId);
              deletedIds.add(docId);
            }
          }

          if (deletedIds.isNotEmpty) {
            await sync.listenAndDeleteMany(docIds: deletedIds);
          }
        });
  }

  @override
  void initState() {
    super.initState();
    getUserInfo();

    store = context.read<LocalChatStore>();
    sync = context.read<ChatSyncService>();
    sync.start(chatId, userId);

    listenForDeletedMessages();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    sync.stop();
    super.dispose();
  }

  void getUserInfo() async {
    final userSnapshot = await firestore.collection("users").doc(userId).get();
    final userData = userSnapshot.data();
    setState(() {
      username = userData?["name"] ?? "User";
    });
  }

  Future<void> sendHelpMessage() async {
    final String message = messageController.text.trim();

    if (message.isEmpty && pickedImageFile == null && pickedVideoFile == null) {
      return;
    }

    messageController.clear();

    final String? rawMediaUrl = pickedImageFile ?? pickedVideoFile;

    setState(() {
      isSending = true;
    });

    String? mediaUrl;
    MessageType type = MessageType.text;

    try {
      if (pickedImageFile != null) {
        type = MessageType.image;
        final ref = FirebaseStorage.instance
            .ref()
            .child('chat_media')
            .child(
              '$currentUserId/${DateTime.now().millisecondsSinceEpoch}_${pickedImageFile!.split('/').last}',
            );
        await ref.putFile(File(pickedImageFile!));
        mediaUrl = await ref.getDownloadURL();
        setState(() {
          pickedImageFile = null;
        });
      }

      if (pickedVideoFile != null) {
        type = MessageType.video;
        final ref = FirebaseStorage.instance
            .ref()
            .child('chat_media')
            .child(
              '$currentUserId/${DateTime.now().millisecondsSinceEpoch}_${pickedVideoFile!.split('/').last}',
            );
        await ref.putFile(File(pickedVideoFile!));
        mediaUrl = await ref.getDownloadURL();
        setState(() {
          pickedVideoFile = null;
        });
      }

      await sync.sendMessage(
        chatId: chatId,
        senderId: userId,
        sender: sender,
        text: message.isNotEmpty ? message : null,
        mediaUrl: mediaUrl,
        type: type,
        rawMediaUrl: rawMediaUrl,
      );

      setState(() {
        isSending = false;
      });

      final adminChatRef = firestore
          .collection('admin')
          .doc("idforadminv1")
          .collection('help_chats')
          .doc(userId);

      final batch = firestore.batch();
      final lastMessage = message.isEmpty ? type.name : message;

      if (isAdmin) {
        batch.update(adminChatRef, {"last_message": lastMessage});
      } else {
        batch.set(adminChatRef, {
          "userId": widget.clientId,
          "username": username,
          "last_message": lastMessage,
        });
      }

      await batch.commit();
    } catch (e) {
      setState(() {
        isSending = false;
      });
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

  String formatTimestamp(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Container(
          color: Theme.of(context).colorScheme.secondary,

          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 1,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                FontAwesomeIcons.arrowLeft,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: ValueListenableBuilder<int>(
              valueListenable: selection.count,
              builder: (context, addUp, _) {
                if (addUp > 0) {
                  return CustomText(
                    text: "$addUp selected",
                    textWeight: FontWeight.w600,
                    textColor: Theme.of(context).colorScheme.primary,
                  );
                }
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin ? widget.clientName ?? "" : "Support Centre",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
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
                      children: [
                        Icon(
                          Icons.call,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 15),
                        Icon(
                          Icons.videocam,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 10),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.primary,
                        ),
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
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context).colorScheme.primary,
                        ),
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
            child: MessageListView(
              chatId: chatId,
              newestKey: _newestKey,
              sender: sender,
              selection: selection,
              formatTimestamp: formatTimestamp,
              isSending: isSending,
              pickedImageFile: pickedImageFile,
              pickedVideoFile: pickedVideoFile,
              store: store,
              onLoadOlderMessages: () {
                return sync.loadOlder(userId, chatId);
              },
            ),
          ),
          // typing indicator (unchanged)
          StreamBuilder<DocumentSnapshot>(
            stream: firestore
                .collection('users')
                .doc(widget.clientId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final isTyping = data['isTyping'] ?? false;
              return isTyping
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
          MessageInput(
            controller: messageController,
            onPickImage: pickImage,
            onPickVideo: pickVideo,
            onRemoveImage: () {
              setState(() {
                pickedImageFile = null;
              });
            },
            onRemoveVideo: () {
              setState(() {
                pickedVideoFile = null;
              });
            },
            onSend: sendHelpMessage,
            onTyping: onTyping,
            pickedImageFile: pickedImageFile,
            pickedVideoFile: pickedVideoFile,
            isSending: isSending,
          ),
        ],
      ),
    );
  }
}

// keep your existing imports/types: Message, MessageBubble, SelectionController, LocalChatStore

class MessageListView extends StatefulWidget {
  final String chatId;
  final GlobalKey newestKey;
  final String sender;
  final SelectionController selection;
  final String Function(DateTime) formatTimestamp;
  final bool isSending;
  final String? pickedImageFile; // file path (String)
  final String? pickedVideoFile; // file path (String)
  final LocalChatStore store;
  final bool alwaysSnapToBottomOnNewMessage;

  /// Callback that triggers when the user scrolls to the top (for loading older messages)
  final Future<void> Function()? onLoadOlderMessages;

  const MessageListView({
    super.key,
    required this.chatId,
    required this.newestKey,
    required this.sender,
    required this.selection,
    required this.formatTimestamp,
    required this.isSending,
    required this.pickedImageFile,
    required this.pickedVideoFile,
    required this.store,
    this.alwaysSnapToBottomOnNewMessage = true,
    this.onLoadOlderMessages,
  });

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _bottomSentinelKey = GlobalKey();

  int _prevCount = 0;
  String? _lastBottomMsgId;

  bool _autoScrollLocked = false;
  static const double _kAutoScrollThresholdPx = 120.0;
  static const double _kTopTriggerThresholdPx = 80.0;

  bool _isLoadingOlder = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      // Detect user scrolling near bottom
      if (!widget.alwaysSnapToBottomOnNewMessage &&
          _scrollController.hasClients) {
        final distanceFromBottom =
            _scrollController.position.maxScrollExtent -
            _scrollController.position.pixels;
        _autoScrollLocked = distanceFromBottom > _kAutoScrollThresholdPx;
      }

      // Detect user scrolling near the top to load older messages
      if (_scrollController.hasClients &&
          _scrollController.position.pixels <= _kTopTriggerThresholdPx &&
          !_isLoadingOlder &&
          widget.onLoadOlderMessages != null) {
        _triggerLoadOlder();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureBottomVisible());
  }

  Future<void> _triggerLoadOlder() async {
    if (widget.onLoadOlderMessages == null) return;
    setState(() => _isLoadingOlder = true);
    try {
      await widget.onLoadOlderMessages!();
    } finally {
      if (mounted) {
        setState(() => _isLoadingOlder = false);
      }
    }
  }

  @override
  void didUpdateWidget(covariant MessageListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSending && !oldWidget.isSending) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureBottomVisible(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureBottomVisible() async {
    if (!mounted) return;
    if (!widget.alwaysSnapToBottomOnNewMessage && _autoScrollLocked) return;

    await Future<void>.delayed(const Duration(milliseconds: 16));

    final ctx = _bottomSentinelKey.currentContext;
    if (ctx != null) {
      try {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 1.0,
        );
        return;
      } catch (_) {
        // fallback
      }
    }

    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<List<Message>>(
          stream: widget.store.watchLatest(widget.chatId, limit: 50),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final msgs = snapshot.data ?? const <Message>[];
            if (msgs.isEmpty) {
              return const Center(child: Text('No messages yet.'));
            }

            final currentBottomId = msgs.last.docId;
            final countChanged = msgs.length != _prevCount;
            final bottomChanged = currentBottomId != _lastBottomMsgId;

            if (countChanged || bottomChanged) {
              _prevCount = msgs.length;
              _lastBottomMsgId = currentBottomId;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _ensureBottomVisible(),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: msgs.length + 1,
              padding: const EdgeInsets.only(bottom: 24),
              itemBuilder: (context, index) {
                if (index == msgs.length) {
                  return SizedBox(
                    key: _bottomSentinelKey,
                    height: 1,
                    width: MediaQuery.of(context).size.width,
                  );
                }

                final message = msgs[index];
                final msgId = message.docId;
                final isMine = message.sender == widget.sender;
                final ts = message.createdAt;

                bool isSameSenderAsPrevious = false;
                if (index > 0) {
                  final prevMessage = msgs[index - 1];
                  isSameSenderAsPrevious = prevMessage.sender == message.sender;
                }

                final isLast = index == msgs.length - 1;

                return ValueListenableBuilder<bool>(
                  valueListenable: widget.selection.listen(msgId),
                  builder: (context, isSelected, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MessageBubble(
                          key: isLast ? widget.newestKey : ValueKey(msgId),
                          message: message,
                          timestamp: widget.formatTimestamp(ts),
                          isPreviouseMessageMine: isMine,
                          isFirstSequence: !isSameSenderAsPrevious,
                          isSelected: isSelected,
                          onLongPress: () => widget.selection.toggle(msgId),
                          onTap: () {
                            if (widget.selection.count.value > 0) {
                              widget.selection.toggle(msgId);
                            }
                          },
                          store: widget.store,
                        ),
                        if (isLast &&
                            widget.isSending &&
                            (widget.pickedImageFile != null ||
                                widget.pickedVideoFile != null))
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin: const EdgeInsets.only(right: 18, top: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.white,
                              ),
                              height: 100,
                              width: 100,
                              child: const Stack(
                                children: [
                                  Center(
                                    child: Icon(
                                      Icons.file_copy_sharp,
                                      color: Colors.grey,
                                      size: 70,
                                    ),
                                  ),
                                  Center(child: CircularProgressIndicator()),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),

        // Small indicator on top while loading older messages
        if (_isLoadingOlder)
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

typedef SendCallback = Future<void> Function();

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onRemoveImage;
  final VoidCallback onRemoveVideo;
  final SendCallback onSend;
  final void Function(String) onTyping;
  final String? pickedImageFile; // path
  final String? pickedVideoFile; // path
  final bool isSending;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onRemoveImage,
    required this.onRemoveVideo,
    required this.onSend,
    required this.onTyping,
    required this.pickedImageFile,
    required this.pickedVideoFile,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Column(
                  children: [
                    if (pickedImageFile != null && !isSending)
                      ImagePreview(
                        filePath: pickedImageFile!,
                        onRemove: onRemoveImage,
                      ),
                    if (pickedVideoFile != null && !isSending)
                      SizedBox(
                        child: VideoPreview(
                          filePath: pickedVideoFile!,
                          onRemove: onRemoveVideo,
                        ),
                      ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: onTyping,
                        controller: controller,
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Methods().showMediaPickerDialog(
                    context,
                    onPickImage,
                    onPickVideo,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.attach_file,
                    color: Theme.of(context).colorScheme.inversePrimary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              isSending
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () async {
                        await onSend();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.inversePrimary,
                          size: 20,
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Keeps selection state per-message without forcing a pr screen rebuild.
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

class ImagePreview extends StatefulWidget {
  final String filePath;
  final VoidCallback onRemove;

  const ImagePreview({
    super.key,
    required this.filePath,
    required this.onRemove,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(imagePath: widget.filePath),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Stack(
          children: [
            Hero(
              tag: widget.filePath,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(widget.filePath),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//VIDEO PREVIEW

class VideoPreview extends StatefulWidget {
  final String filePath;
  final VoidCallback onRemove;
  final VoidCallback? downloadVideo;
  final bool isSending;
  final bool forBubble;

  const VideoPreview({
    super.key,
    required this.filePath,
    required this.onRemove,
    this.isSending = false,
    this.forBubble = false,
    this.downloadVideo,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    // ❗️Skip initializing for HTTP URLs
    if (!widget.filePath.startsWith('http')) {
      _initController(widget.filePath);
    }
  }

  @override
  void didUpdateWidget(VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize if the filePath changes (e.g. after upload)

    if (oldWidget.filePath != widget.filePath) {
      _disposeController();
      // ❗️Skip initializing for HTTP URLs
      if (!widget.filePath.startsWith('http')) {
        _initController(widget.filePath);
      }
    }
  }

  Future<void> _initController(String path) async {
    try {
      final isLocal = !path.startsWith('http');
      final controller = isLocal
          ? VideoPlayerController.file(File(path))
          : VideoPlayerController.networkUrl(Uri.parse(path));

      await controller.initialize();
      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('🎥 Video init error: $e');
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isUrl = widget.filePath.startsWith("http");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Stack(
        children: [
          // 👇 For HTTP URLs, show a static "thumbnail" placeholder (no controller)
          if (isUrl)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 180,
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.videocam,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
            )
          // Local file: show initialized player
          else if (_isInitialized && _controller != null)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: widget.forBubble
                    ? 500
                    : MediaQuery.of(context).size.height * 0.30,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          // Local file but not initialized yet
          else
            Container(
              height: 180,
              color: Colors.black12,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),

          // ❌ Remove button (top-right)
          if (!widget.forBubble)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),

          // ▶️ Play button (center) — unchanged; still blocked for HTTP URLs
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (isUrl) {
                    Fluttertoast.showToast(msg: 'Video not downloaded');
                    return;
                  }
                  if (!widget.isSending) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FullScreenVideoPlayer(filePath: widget.filePath),
                      ),
                    );
                  } else {
                    Fluttertoast.showToast(msg: 'Video still uploading...');
                  }
                },
                child: widget.isSending
                    ? const CircularProgressIndicator()
                    : const Icon(
                        Icons.play_circle,
                        color: Colors.white70,
                        size: 50,
                      ),
              ),
            ),
          ),

          // ⬇️ Download button for Firebase URL videos (overlay stays the same)
          if (isUrl)
            Positioned(
              bottom: 8,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  widget.downloadVideo?.call();
                  setState(() => isDownloading = true);
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: isDownloading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        )
                      : const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String filePath;

  const FullScreenVideoPlayer({super.key, required this.filePath});

  @override
  FullScreenVideoPlayerState createState() => FullScreenVideoPlayerState();
}

class FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isDragging = false;
  Duration _dragPosition = Duration.zero;

  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    if (widget.filePath.startsWith("http")) {
      _controller = VideoPlayerController.networkUrl(widget.filePath as Uri)
        ..initialize().then((_) {
          setState(() {});
          _controller.play();
          _startHideTimer();
        });
    } else {
      _controller = VideoPlayerController.file(File(widget.filePath))
        ..initialize().then((_) {
          setState(() {});
          _controller.play();
          _startHideTimer();
        });
    }

    _controller.addListener(() {
      if (!_isDragging && mounted) setState(() {}); // keep slider in sync
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) _startHideTimer();
  }

  void _forward() {
    final newPos = _controller.value.position + const Duration(seconds: 10);
    _controller.seekTo(
      newPos < _controller.value.duration ? newPos : _controller.value.duration,
    );
    _startHideTimer();
  }

  void _backward() {
    final newPos = _controller.value.position - const Duration(seconds: 10);
    _controller.seekTo(newPos > Duration.zero ? newPos : Duration.zero);
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  // Controls overlay
                  if (_showControls)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Slider
                            Row(
                              children: [
                                const SizedBox(width: 10),
                                Text(
                                  _formatDuration(
                                    _isDragging
                                        ? _dragPosition
                                        : _controller.value.position,
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Expanded(
                                  child: Slider(
                                    activeColor: Colors.red,
                                    inactiveColor: Colors.white54,
                                    min: 0,
                                    max: _controller
                                        .value
                                        .duration
                                        .inMilliseconds
                                        .toDouble(),
                                    value: _isDragging
                                        ? _dragPosition.inMilliseconds
                                              .toDouble()
                                        : _controller
                                              .value
                                              .position
                                              .inMilliseconds
                                              .toDouble(),
                                    onChanged: (value) {
                                      setState(() {
                                        _isDragging = true;
                                        _dragPosition = Duration(
                                          milliseconds: value.toInt(),
                                        );
                                      });
                                    },
                                    onChangeEnd: (value) {
                                      final newPos = Duration(
                                        milliseconds: value.toInt(),
                                      );
                                      _controller.seekTo(newPos);
                                      setState(() {
                                        _isDragging = false;
                                      });
                                      _startHideTimer();
                                    },
                                  ),
                                ),
                                Text(
                                  _formatDuration(_controller.value.duration),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                            // Play/pause & skip buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.replay_10,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: _backward,
                                ),
                                IconButton(
                                  icon: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _controller.value.isPlaying
                                          ? _controller.pause()
                                          : _controller.play();
                                    });
                                    _startHideTimer();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.forward_10,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: _forward,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  // Close button
                  if (_showControls)
                    Positioned(
                      top: 40,
                      left: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final String imagePath;

  const FullScreenImageViewer({super.key, required this.imagePath});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  double _dragOffset = 0.0;
  static const double _closeThreshold = 50.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dy;
          });
        },
        onVerticalDragEnd: (details) {
          //  If dragged down beyond threshold, close the viewer
          if (_dragOffset > _closeThreshold) {
            Navigator.pop(context);
          } else {
            // Reset position if not dragged enough
            setState(() => _dragOffset = 0.0);
          }
        },
        child: Stack(
          children: [
            Hero(
              tag: widget.imagePath,
              child: PhotoView(
                imageProvider: widget.imagePath.startsWith('http')
                    ? CachedNetworkImageProvider(widget.imagePath)
                    : FileImage(File(widget.imagePath)),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3.0,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// // adb connect 192.168.43.1
// // adb connect 192.168.100.40







