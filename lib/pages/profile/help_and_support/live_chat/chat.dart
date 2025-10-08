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
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

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

  String? pickedImageFile;
  String? pickedVideoFile;

  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    setState(() {
      pickedImageFile = result?.files.single.path;
      pickedVideoFile = null;
    });
    if (result != null) {
      print("Picked image: ${result.files.single.path}");
    }
  }

  Future<void> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && mounted) {
      final filePath = result.files.single.path;
      if (filePath == null) return;

      setState(() {
        pickedVideoFile = filePath;
        pickedImageFile = null;
      });
    }
  }

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
                          // message: message.text,
                          message: "jhkj",
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
                      child: Column(
                        children: [
                          if (pickedImageFile != null)
                            ImagePreview(
                              filePath: pickedImageFile!,
                              onRemove: () {
                                setState(() {
                                  pickedImageFile = null;
                                });
                              },
                            ),
                          if (pickedVideoFile != null)
                            SizedBox(
                              // height: 200,
                              child: VideoPreview(
                                filePath: pickedVideoFile!,
                                onRemove: () {
                                  setState(() {
                                    pickedVideoFile = null;
                                  });
                                },
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
                        ],
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
                        Methods().showMediaPickerDialog(
                          context,
                          () => pickImage(),
                          () => pickVideo(),
                        );
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
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FullScreenImageViewer(imagePath: widget.filePath),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.filePath),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
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

class VideoPreview extends StatefulWidget {
  final String filePath;
  final VoidCallback onRemove;

  const VideoPreview({
    super.key,
    required this.filePath,
    required this.onRemove,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {}); // Refresh UI after initialization
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: VideoPlayer(_controller),
                  )
                : const Center(child: CircularProgressIndicator()),
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
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Navigate to full-screen player

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FullScreenVideoPlayer(filePath: widget.filePath),
                    ),
                  );
                },
                child: Icon(Icons.play_circle, color: Colors.white70, size: 50),
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
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isDragging = false;
  Duration _dragPosition = Duration.zero;

  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _startHideTimer();
      });

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

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenImageViewer({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoView(
            imageProvider: imagePath.startsWith('http')
                ? NetworkImage(imagePath)
                : FileImage(File(imagePath)) as ImageProvider,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3.0,
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
    );
  }
}

// // adb connect 192.168.43.1
