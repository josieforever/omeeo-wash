import 'dart:async';

import 'package:bubble/bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:uuid/uuid.dart';

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
    return widget.isAdmin ? Clients() : Chat(clientId: clientId);
  }
}

class Clients extends StatelessWidget {
  const Clients({super.key});

  Future<List<Map<String, dynamic>>> fetchClients() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('admin')
        .doc('idforadminv1')
        .collection('help_chats')
        .get();

    // Extract fields from documents
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'userId': data['userId'],
        'username': data['username'],
        'photoUrl': data['photoUrl'],
        'last_message': data['last_message'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 248, 255),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              color: const Color.fromARGB(213, 255, 255, 255),
            ),
          ),
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/background_animation_light.json',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              color: const Color.fromARGB(100, 255, 255, 255),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            CustomText(
                              text: 'Clients',
                              textColor: Theme.of(
                                context,
                              ).textTheme.headlineLarge?.color,
                              textSize: TextSizes.heading2,
                              textWeight: FontWeight.w900,
                            ),
                          ],
                        ),
                        GoBack(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchClients(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final clients = snapshot.data ?? [];

                  if (clients.isEmpty) {
                    return const Center(child: Text('No clients found.'));
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    Chat(clientId: client['userId']),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  radius: 25,

                                  // backgroundImage: client['photoUrl'] != null
                                  //     ? NetworkImage(client['photoUrl'])
                                  //     : null,
                                  child: const Icon(Icons.person),
                                  // child: client['photoUrl'] == null
                                  //     ? const Icon(Icons.person)
                                  //     : null,
                                ),
                                title: Text(
                                  client['username'] ?? 'No Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  client['last_message'] ?? "none",
                                ),
                                trailing: Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Chat extends StatefulWidget {
  final String clientId;
  const Chat({super.key, required this.clientId});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final ScrollController _scrollController = ScrollController();
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
        .doc(widget.clientId)
        .collection('help_messages')
        .doc(messageId);

    final adminChatRef = firestore
        .collection('admin')
        .doc("idforadminv1")
        .collection('help_chats')
        .doc(userId);

    final batch = firestore.batch();
    batch.set(userChatRef, messageData);
    if (isAdmin) {
      batch.update(adminChatRef, {"last_message": message});
    }
    if (!isAdmin) {
      batch.set(adminChatRef, {
        "userId": widget.clientId,
        "username": username,
        "photoUrl": "",
        "last_message": message,
      });
    }
    messageController.clear();

    try {
      await batch.commit();
      debugPrint('✅ Help message sent to both user and admin chat paths.');
    } catch (e) {
      debugPrint('❌ Failed to send help message: $e');
    }
  }

  bool isCurrentlyTyping = false;
  Timer? _typingTimer;

  void onTyping(String text) {
    if (!isCurrentlyTyping) {
      isCurrentlyTyping = true;
      firestore.collection('users').doc(userId).update({'isTyping': true});
    }

    // Debounce typing (wait before setting to false)
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      firestore.collection('users').doc(userId).update({'isTyping': false});
      isCurrentlyTyping = false;
    });
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
  void initState() {
    super.initState();
    getUserInfo();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
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
                      .doc(widget.clientId)
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

                    // Schedule scroll to bottom after build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.easeOut,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
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
                          child: Text(
                            'typing...',
                            style: TextStyle(
                              color: black,
                              fontSize: TextSizes.bodyText1,
                            ),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 2),
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
                      child: SafeArea(
                        child: TextField(
                          onChanged: onTyping,
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            border: InputBorder.none,
                          ),
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
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    // return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
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
