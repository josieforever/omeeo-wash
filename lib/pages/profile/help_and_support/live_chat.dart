import 'package:bubble/bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:uuid/uuid.dart';

class LiveChat extends StatefulWidget {
  const LiveChat({super.key});

  @override
  State<LiveChat> createState() => _LiveChatState();
}

class _LiveChatState extends State<LiveChat> {
  final TextEditingController messageController = TextEditingController();
  final firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  String username = "";
  bool isAdmin = false;

  final white = AppColors.white;
  final black = AppColors.black;

  Future<void> sendHelpMessage() async {
    final messageId = const Uuid().v4();
    final timestamp = FieldValue.serverTimestamp();
    final String message = messageController.text.trim();

    if (message.isEmpty) return;

    final messageData = {
      'id': userId,
      'sender': isAdmin ? "ommeo" : 'user',
      'message': message,
      'timestamp': timestamp,
      'username': isAdmin ? "ommeo" : username,
    };

    final userChatRef = firestore
        .collection('users')
        .doc('XPV2pjk6QDTFs0OdQIsdU4l1RJo2')
        .collection('help_messages')
        .doc(messageId);

    final adminChatRef = firestore
        .collection('admin')
        .doc("idforadminv1")
        .collection('help_chats')
        .doc(userId);

    final batch = firestore.batch();
    batch.set(userChatRef, messageData);
    if (!isAdmin) {
      batch.set(adminChatRef, {"userId": userId, "username": username});
    }
    messageController.clear();

    try {
      await batch.commit();
      debugPrint('✅ Help message sent to both user and admin chat paths.');
    } catch (e) {
      debugPrint('❌ Failed to send help message: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  void getUserInfo() async {
    final userSnapshot = await firestore.collection("users").doc(userId).get();
    final userData = userSnapshot.data();
    setState(() {
      isAdmin = userData?["isAdmin"] ?? false;
      username = userData?["name"] ?? "User";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: Icon(FontAwesomeIcons.arrowLeft, color: white),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emma Wilson',
                      style: TextStyle(
                        color: white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: TextSizes.bodyText1,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: const [
              Icon(Icons.call, color: Colors.white),
              SizedBox(width: 15),
              Icon(Icons.videocam, color: Colors.white),
              SizedBox(width: 10),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: const Color.fromARGB(213, 255, 255, 255)),
          ),
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/background_animation_light.json',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: const Color.fromARGB(100, 255, 255, 255)),
          ),
          Column(
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Chat started at 01:25 PM',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('users')
                      .doc('XPV2pjk6QDTFs0OdQIsdU4l1RJo2')
                      .collection('help_messages')
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No messages yet.'));
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data =
                            messages[index].data() as Map<String, dynamic>;
                        final String msgSenderId = data['id'] ?? '';
                        final Timestamp? ts = data['timestamp'];
                        final isMine = msgSenderId == userId;

                        bool isSameSenderAsPrevious = false;
                        if (index > 0) {
                          final prevSender = messages[index - 1]['id'];
                          isSameSenderAsPrevious = prevSender == msgSenderId;
                        }

                        return MessageBubble(
                          message: data['message'] ?? '',
                          timestamp: ts != null
                              ? formatTimestamp(ts)
                              : 'Sending...',
                          isPreviouseMessageMine: isMine,
                          isFirstSequence: !isSameSenderAsPrevious,
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 5, backgroundColor: Colors.grey),
                    const SizedBox(width: 4),
                    const CircleAvatar(radius: 5, backgroundColor: Colors.grey),
                    const SizedBox(width: 4),
                    const CircleAvatar(radius: 5, backgroundColor: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Emma is typing...',
                      style: TextStyle(
                        color: black,
                        fontSize: TextSizes.bodyText1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Icon(Icons.attach_file, color: Colors.grey),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        if (messageController.text.isNotEmpty) {
                          sendHelpMessage();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.grey,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
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
        right: isMe && isFirstSequence ? 0 : 8,
        left: !isMe && isFirstSequence ? 0 : 8,
        top: isPreviouseMessageMine ? 0 : 10,
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
            margin: const BubbleEdges.symmetric(horizontal: 16, vertical: 4),
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
                const SizedBox(height: 5),
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
