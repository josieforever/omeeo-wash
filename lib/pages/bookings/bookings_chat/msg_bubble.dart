import 'dart:io';

import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:omeeowash/models/message.dart';
import 'package:omeeowash/services/local_chat_storage.dart';

// class LiveChat extends StatefulWidget {
//   final bool isAdmin;
//   const LiveChat({super.key, required this.isAdmin});

//   @override
//   State<LiveChat> createState() => _LiveChatState();
// }

// class _LiveChatState extends State<LiveChat> {
//   final String clientId = FirebaseAuth.instance.currentUser!.uid;

//   @override
//   Widget build(BuildContext context) {
//     return widget.isAdmin
//         ? HelpList()
//         : Chat.admin(clientId: clientId, clientName: '');
//   }
// }

class MsgBubble extends StatelessWidget {
  final Message message; // full message
  final bool isPreviouseMessageMine;
  final bool isFirstSequence;
  final String timestamp;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const MsgBubble({
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

    final BubbleNip nip = isFirstSequence
        ? (isMe ? BubbleNip.rightTop : BubbleNip.leftTop)
        : BubbleNip.no;

    final outerPadding = EdgeInsets.only(
      right: isMe && isFirstSequence ? 8 : 16,
      left: !isMe && isFirstSequence ? 8 : 16,
      top: isFirstSequence ? 10 : 3,
    );

    // Text-only content (no file/media loading)
    final String text = (message.text ?? '').trim();

    return Stack(
      children: [
        GestureDetector(
          onLongPress: onLongPress,
          onTap: onTap,
          child: Container(
            color: isSelected
                ? const Color.fromARGB(255, 218, 215, 255)
                : Theme.of(context).colorScheme.inversePrimary,
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
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.isEmpty
                              ? ' '
                              : text, // keep layout even if empty
                          style: TextStyle(
                            fontSize: 16,
                            color: isMe
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          timestamp,
                          style: TextStyle(
                            color: isMe
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.scrim,
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
