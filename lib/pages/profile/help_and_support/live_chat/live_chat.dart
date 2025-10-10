import 'dart:io';

import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:omeeowash/models/message.dart';
import 'package:omeeowash/widgets.dart/colors.dart';

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
        : Chat.admin(clientId: clientId, clientName: '');
  }
}

class MessageBubble extends StatelessWidget {
  final Message message; // Updated to accept full Message object
  final bool isPreviouseMessageMine;
  final bool isFirstSequence;
  final String timestamp;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isPreviouseMessageMine,
    required this.isFirstSequence,
    required this.timestamp,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = isPreviouseMessageMine;

    BubbleNip nip;
    if (isFirstSequence && isMe) {
      nip = BubbleNip.rightTop;
    } else if (isFirstSequence && !isMe) {
      nip = BubbleNip.leftTop;
    } else {
      nip = BubbleNip.no;
    }

    final outerPadding = EdgeInsets.only(
      right: isMe && isFirstSequence ? 8 : 16,
      left: !isMe && isFirstSequence ? 8 : 16,
      top: isFirstSequence ? 10 : 3,
    );

    Widget buildContent() {
      switch (message.type) {
        case MessageType.text:
          return Text(
            message.text ?? '',
            style: TextStyle(
              fontSize: 16,
              color: isMe ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          );

        case MessageType.image:
          return GestureDetector(
            onTap: () {
              final imagePath = message.mediaUrl;
              if (imagePath != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(imagePath: imagePath),
                  ),
                );
              } else {
                if (onTap != null) onTap!();
              }
            },
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (message.mediaUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: Hero(
                        tag: message
                            .mediaUrl!, // use docId instead of mediaUrl to avoid null
                        child: (message.mediaUrl!.startsWith('http'))
                            ? CachedNetworkImage(
                                imageUrl: message.mediaUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              )
                            : Image.file(
                                File(message.mediaUrl!),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                if ((message.text ?? '').isNotEmpty)
                  Text(
                    message.text ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: isMe ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          );

        case MessageType.video:
          return Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (message.mediaUrl != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            FullScreenVideoPlayer(filePath: message.mediaUrl!),
                      ),
                    );
                  }
                },
                child: VideoPreview(
                  filePath: message.mediaUrl!,
                  onRemove: () {},
                ),
              ),
              if ((message.text ?? '').isNotEmpty)
                Text(
                  message.text ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: isMe ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          );
      }
    }

    return Stack(
      children: [
        GestureDetector(
          onLongPress: onLongPress,
          onTap: onTap,
          child: Container(
            color: isSelected
                ? const Color.fromARGB(255, 218, 215, 255)
                : Colors.transparent,
            child: Padding(
              padding: outerPadding,
              child: Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isFirstSequence
                        ? MediaQuery.of(context).size.width * 0.85 + 15
                        : MediaQuery.of(context).size.width * 0.85,
                  ),
                  child: Bubble(
                    padding: const BubbleEdges.only(bottom: 3),
                    nip: nip,
                    color: isMe
                        ? const Color(0xFF6D66F6)
                        : AppColors.periwinklePurple,
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        buildContent(),
                        const SizedBox(height: 3),
                        Text(
                          timestamp,
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
