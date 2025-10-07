import 'package:bubble/bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final bool isPreviouseMessageMine;
  final bool isFirstSequence;
  final String message;
  final String timestamp;

  // NEW:
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

    // Selection styling
    final borderColor = isSelected ? const Color(0xFFF97316) : null; // orange
    final outerPadding = EdgeInsets.only(
      right: isMe && isFirstSequence ? 8 : 16,
      left: !isMe && isFirstSequence ? 8 : 16,
      top: isFirstSequence ? 10 : 3,
    );

    return Padding(
      padding: outerPadding,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
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
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 15,
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      timestamp,
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.grey[600],
                        fontSize: 11,
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
    );
  }
}


// class MessageBubble extends StatelessWidget {
//   final bool isPreviouseMessageMine;
//   final bool isFirstSequence;
//   final String message;
//   final String timestamp;

//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.isPreviouseMessageMine,
//     required this.isFirstSequence,
//     required this.timestamp,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isMe = isPreviouseMessageMine;

//     BubbleNip nip;
//     if (isFirstSequence && isMe) {
//       nip = BubbleNip.rightTop;
//     } else if (isFirstSequence && !isMe) {
//       nip = BubbleNip.leftTop;
//     } else {
//       nip = BubbleNip.no;
//     }

//     return Container(
//       margin: EdgeInsets.only(
//         right: isMe && isFirstSequence ? 8 : 16,
//         left: !isMe && isFirstSequence ? 8 : 16,
//         top: isFirstSequence ? 10 : 3,
//       ),

//       //   margin: EdgeInsets.only(
//       //     top: isFirstSequence ? 10 : 4,
//       //     right: isMe ? 8 : 40,
//       //     left: isMe ? 40 : 8,
//       //   ),
//       child: Align(
//         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             maxWidth: isFirstSequence
//                 ? MediaQuery.of(context).size.width * 0.85 + 15
//                 : MediaQuery.of(context).size.width * 0.85, // Max 75% width
//           ),
//           child: Bubble(
//             padding: BubbleEdges.only(bottom: 3),
//             // margin: const BubbleEdges.symmetric(horizontal: 16, vertical: 4),
//             nip: nip,
//             color: isMe ? const Color(0xFF6D66F6) : AppColors.periwinklePurple,
//             child: Column(
//               crossAxisAlignment: isMe
//                   ? CrossAxisAlignment.end
//                   : CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   message,
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: isMe ? Colors.white : Colors.black,
//                   ),
//                 ),
//                 Text(
//                   timestamp,
//                   style: TextStyle(
//                     color: isMe ? Colors.white70 : Colors.grey[600],
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

