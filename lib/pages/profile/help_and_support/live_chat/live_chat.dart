import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:omeeowash/models/message.dart';
import 'package:omeeowash/services/local_chat_storage.dart';

import 'chat.dart';
import 'help_list.dart';

class LiveChat extends StatefulWidget {
  final bool isAdmin;
  const LiveChat({super.key, required this.isAdmin});

  @override
  State<LiveChat> createState() => _LiveChatState();
}

class _LiveChatState extends State<LiveChat> {
  final String clientId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return widget.isAdmin
        ? HelpList()
        : Chat.admin(
            clientId: clientId,
            clientName: '',
            isAdmin: widget.isAdmin,
          );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool isFirstSequence;
  final String timestamp;
  final bool isSelected;
  final bool showSenderLabel;
  final String senderLabel;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final LocalChatStore store;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.isFirstSequence,
    required this.timestamp,
    required this.showSenderLabel,
    required this.senderLabel,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? const Color(0xFFDDF4FB)
        : const Color(0xFFE2E5EA);

    final selectionColor = const Color(0xFFD8DDE4);

    final textColor = const Color(0xFF202020);
    final timeColor = isMine
        ? const Color(0xFF2AAFC9)
        : const Color(0xFF9E9E9E);

    final margin = EdgeInsets.only(
      top: isFirstSequence ? 6 : 2,
      bottom: 2,
      left: isMine ? 72 : 12,
      right: isMine ? 12 : 72,
    );

    Widget buildContent() {
      switch (message.type) {
        case MessageType.image:
          return GestureDetector(
            onTap: () {
              final imagePath = message.mediaUrl;
              if (imagePath == null) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(imagePath: imagePath),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: message.mediaUrl == null
                  ? const SizedBox.shrink()
                  : message.mediaUrl!.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: message.mediaUrl!,
                      fit: BoxFit.cover,
                      width: 220,
                      height: 220,
                    )
                  : Image.file(
                      File(message.mediaUrl!),
                      fit: BoxFit.cover,
                      width: 220,
                      height: 220,
                    ),
            ),
          );

        case MessageType.video:
          return SizedBox(
            width: 240,
            child: VideoPreview(
              filePath: message.mediaUrl ?? '',
              onRemove: () {},
              forBubble: true,
              downloadVideo: () async {
                await store.downloadAndReplaceVideo(message);
              },
            ),
          );

        case MessageType.text:
          return Text(
            message.text ?? '',
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
              height: 1.28,
            ),
          );
      }
    }

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Container(
              margin: margin,
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (showSenderLabel)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 10,
                            backgroundColor: Color(0xFFFF6A3D),
                            child: Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            senderLabel,
                            style: const TextStyle(
                              color: Color(0xFF8B8B8B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.76,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        message.type == MessageType.text ? 16 : 8,
                        message.type == MessageType.text ? 12 : 8,
                        message.type == MessageType.text ? 16 : 8,
                        10,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isMine ? 20 : 6),
                          bottomRight: Radius.circular(isMine ? 6 : 20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Align(
                            alignment: isMine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: buildContent(),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timestamp,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: timeColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isMine) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.done_all_rounded,
                                  size: 17,
                                  color: Color(0xFF2AAFC9),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: selectionColor.withOpacity(0.45)),
              ),
            ),
        ],
      ),
    );
  }
}

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
