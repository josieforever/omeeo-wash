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

  const MessageBubble({
    super.key,
    required this.message,
    required this.isPreviouseMessageMine,
    required this.isFirstSequence,
    required this.timestamp,
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

    return Container(
      margin: EdgeInsets.only(
        right: isMe && isFirstSequence ? 8 : 16,
        left: !isMe && isFirstSequence ? 8 : 16,
        top: isFirstSequence ? 10 : 3,
      ),

      //   margin: EdgeInsets.only(
      //     top: isFirstSequence ? 10 : 4,
      //     right: isMe ? 8 : 40,
      //     left: isMe ? 40 : 8,
      //   ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isFirstSequence
                ? MediaQuery.of(context).size.width * 0.85 + 15
                : MediaQuery.of(context).size.width * 0.85, // Max 75% width
          ),
          child: Bubble(
            padding: BubbleEdges.only(bottom: 3),
            // margin: const BubbleEdges.symmetric(horizontal: 16, vertical: 4),
            nip: nip,
            color: isMe ? const Color(0xFF6D66F6) : AppColors.periwinklePurple,
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
    );
  }
}

// class MessageBubble extends StatelessWidget {
//   final bool isPreviouseMessageMine;
//   final bool isFirstSequence;
//   final String message;
//   final String timestamp;
//   final String? fileUrl; // image/pdf URL
//   final String? fileType; // "image" | "pdf" | null

//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.isPreviouseMessageMine,
//     required this.isFirstSequence,
//     required this.timestamp,
//     this.fileUrl,
//     this.fileType,
//   });

//   // Future<void> _openExternalUrl(BuildContext context, String url) async {
//   //   final uri = Uri.parse(url);
//   //   if (await canLaunchUrl(uri)) {
//   //     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   //   } else {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text('Could not open link')),
//   //     );
//   //   }
//   // }

//   Future<void> _previewImage(BuildContext context, String url) async {
//     await showDialog(
//       context: context,
//       builder: (_) => Dialog(
//         backgroundColor: Colors.black,
//         insetPadding: const EdgeInsets.all(12),
//         child: GestureDetector(
//           onTap: () => Navigator.of(context).pop(),
//           child: InteractiveViewer(
//             child: Image.network(url, fit: BoxFit.contain),
//           ),
//         ),
//       ),
//     );
//   }

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

//     Widget content;
//     if (fileUrl != null && fileType == "image") {
//       content = GestureDetector(
//         onTap: () => _previewImage(context, fileUrl!),
//         // onLongPress: () => _openExternalUrl(context, fileUrl!),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: Image.network(
//             fileUrl!,
//             width: 220,
//             height: 220,
//             fit: BoxFit.cover,
//           ),
//         ),
//       );
//     } else if (fileUrl != null && fileType == "pdf") {
//       content = InkWell(
//         // onTap: () => _openExternalUrl(context, fileUrl!),
//         child: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: (isMe ? Colors.white : Colors.black).withOpacity(0.08),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.picture_as_pdf, color: Colors.red),
//               const SizedBox(width: 8),
//               Text(
//                 'Open PDF',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w600,
//                   color: isMe ? Colors.white : Colors.black,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     } else {
//       content = Text(
//         message,
//         style: TextStyle(
//           fontSize: 15,
//           color: isMe ? Colors.white : Colors.black,
//         ),
//       );
//     }

//     return Container(
//       margin: EdgeInsets.only(
//         right: isMe && isFirstSequence ? 8 : 16,
//         left: !isMe && isFirstSequence ? 8 : 16,
//         top: isFirstSequence ? 10 : 3,
//       ),
//       child: Align(
//         alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.85,
//           ),
//           child: Bubble(
//             padding: const BubbleEdges.all(8),
//             nip: nip,
//             color: isMe ? const Color(0xFF6D66F6) : AppColors.periwinklePurple,
//             child: Column(
//               crossAxisAlignment: isMe
//                   ? CrossAxisAlignment.end
//                   : CrossAxisAlignment.start,
//               children: [
//                 content,
//                 const SizedBox(height: 4),
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
