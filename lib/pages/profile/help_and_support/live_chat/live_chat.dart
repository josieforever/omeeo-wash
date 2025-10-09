import 'package:bubble/bubble.dart';
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
              if (message.mediaUrl != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        FullScreenImageViewer(imagePath: message.mediaUrl!),
                  ),
                );
              } else {
                onTap!();
              }
            },
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),

                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 300),
                    child: Hero(
                      tag: message.mediaUrl!,
                      child: Image.network(message.mediaUrl!),
                    ),
                  ),
                ),
                if ((message.text ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      message.text!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : Colors.black,
                      ),
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
                        builder: (_) => FullScreenVideoPlayer(
                          filePath: message.mediaUrl!,
                          isBubble: true,
                        ),
                      ),
                    );
                  }
                },
                child: VideoPreview(
                  isBubble: true,
                  filePath: message.mediaUrl!,
                  onRemove: () {},
                ),
              ),
              if ((message.text ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    message.text!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : Colors.black,
                    ),
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
