import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';

class MsgBubble extends StatelessWidget {
  final String text; // full message
  final bool isPreviouseMessageMine;
  final bool isFirstSequence;
  final String timestamp;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const MsgBubble({
    super.key,
    required this.text,
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
