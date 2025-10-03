import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:uuid/uuid.dart';

import 'live_chat.dart';

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
  final TextEditingController messageController = TextEditingController();
  final firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  String username = "";
  bool isAdmin = false;
  final white = AppColors.white;
  final black = AppColors.black;
  List<DocumentSnapshot> _messages = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoadingMore = false;
  static const int pageSize = 20;

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

  Future<void> sendMessage({
    required String text,
    String? fileUrl,
    String? fileType,
  }) async {
    final message = {
      "text": text,
      // "senderId": user.uid,
      "clientId": widget.clientId,
      "isAdmin": isAdmin,
      "timestamp": FieldValue.serverTimestamp(),
      "fileUrl": fileUrl,
      "fileType": fileType, // "image", "pdf" or null
    };

    // await FirebaseFirestore.instance
    //     .collection("users")
    //     .doc(widget.clientId)
    //     .collection("chat")
    //     .add(message);
  }

  Future<void> pickFileAndSend() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final ext = fileName.split('.').last.toLowerCase();

      // final ref = FirebaseStorage.instance.ref().child(
      //   "chat_files/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext",
      // );

      // await ref.putFile(file);
      // final downloadUrl = await ref.getDownloadURL();

      // await sendMessage(
      //   text: "",
      //   fileUrl: downloadUrl,
      //   fileType: ext == "pdf" ? "pdf" : "image",
      // );
    }
  }

  @override
  void initState() {
    super.initState();
    getUserInfo();
    _loadInitialMessages();

    // Auto-load more when user scrolls near top
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.minScrollExtent &&
          !_isLoadingMore) {
        _loadMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    final snapshot = await firestore
        .collection('users')
        .doc(widget.clientId)
        .collection('help_messages')
        .orderBy('timestamp', descending: true)
        .limit(pageSize)
        .get();

    setState(() {
      _messages = snapshot.docs;
      if (_messages.isNotEmpty) _lastDoc = _messages.last;
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_lastDoc == null) return;

    setState(() => _isLoadingMore = true);

    final snapshot = await firestore
        .collection('users')
        .doc(widget.clientId)
        .collection('help_messages')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(_lastDoc!)
        .limit(pageSize)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _messages.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.last;
      });
    }

    setState(() => _isLoadingMore = false);
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
                      isAdmin ? widget.clientName ?? "" : "Support Centre",
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
                      .orderBy('timestamp', descending: true)
                      .limit(pageSize)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No messages yet.'));
                    }

                    final liveMessages = snapshot.data?.docs ?? [];
                    final allMessages = [
                      ...liveMessages,
                      ..._messages.skip(liveMessages.length),
                    ];

                    // final messages = snapshot.data!.docs;
                    final messages = allMessages;

                    // // Schedule scroll to bottom after build
                    // WidgetsBinding.instance.addPostFrameCallback((_) {
                    //   if (_scrollController.hasClients) {
                    //     _scrollController.animateTo(
                    //       _scrollController.position.maxScrollExtent,
                    //       duration: const Duration(milliseconds: 100),
                    //       curve: Curves.easeOut,
                    //     );
                    //   }
                    // });

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: allMessages.length + (_isLoadingMore ? 1 : 0),
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

                        if (_isLoadingMore && index == allMessages.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
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

                  return isTyping && isAdmin
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
                decoration: BoxDecoration(color: Colors.transparent),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: SafeArea(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 2,
                              color: AppColors.deeperPeriwinkle,
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 120, //
                            ),
                            child: TextField(
                              onChanged: onTyping,
                              controller: messageController,
                              maxLines: null, //
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
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: pickFileAndSend,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.deeperPeriwinkle,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.attach_file,
                              color: AppColors.white,
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
                              color: AppColors.white,
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

// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:omeeowash/widgets.dart/colors.dart';
// import 'live_chat.dart';

// class Chat extends StatefulWidget {
//   final String clientId;
//   final String? clientName;
//   final bool isAdmin;

//   const Chat({
//     super.key,
//     required this.clientId,
//     this.isAdmin = false,
//     this.clientName,
//   });
//   const Chat.admin({
//     super.key,
//     required this.clientId,
//     this.isAdmin = false,
//     this.clientName,
//   });

//   @override
//   State<Chat> createState() => _ChatState();
// }

// class _ChatState extends State<Chat> {
//   final TextEditingController messageController = TextEditingController();
//   final user = FirebaseAuth.instance.currentUser!;

//   Future<void> sendMessage({
//     required String text,
//     String? fileUrl,
//     String? fileType,
//   }) async {
//     final message = {
//       "text": text,
//       "senderId": user.uid,
//       "clientId": widget.clientId,
//       "isAdmin": widget.isAdmin,
//       "timestamp": FieldValue.serverTimestamp(),
//       "fileUrl": fileUrl,
//       "fileType": fileType, // "image", "pdf" or null
//     };

//     await FirebaseFirestore.instance
//         .collection("users")
//         .doc(widget.clientId)
//         .collection("chat")
//         .add(message);
//   }

//   Future<void> pickFileAndSend() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['jpg', 'png', 'pdf'],
//     );

//     if (result != null) {
//       final file = File(result.files.single.path!);
//       final fileName = result.files.single.name;
//       final ext = fileName.split('.').last.toLowerCase();

//       final ref = FirebaseStorage.instance.ref().child(
//         "chat_files/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.$ext",
//       );

//       await ref.putFile(file);
//       final downloadUrl = await ref.getDownloadURL();

//       await sendMessage(
//         text: "",
//         fileUrl: downloadUrl,
//         fileType: ext == "pdf" ? "pdf" : "image",
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.isAdmin ? "Client Chat" : "Help Chat"),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
//               begin: Alignment.centerRight,
//               end: Alignment.centerLeft,
//             ),
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection("users")
//                   .doc(widget.clientId)
//                   .collection("chat")
//                   .orderBy("timestamp", descending: true)
//                   .snapshots(),
//               builder: (ctx, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 final messages = snapshot.data!.docs;

//                 return ListView.builder(
//                   reverse: true,
//                   itemCount: messages.length,
//                   itemBuilder: (ctx, i) {
//                     final msg = messages[i].data() as Map<String, dynamic>;

//                     final text = msg["text"] ?? "";
//                     final fileUrl = msg["fileUrl"];
//                     final fileType = msg["fileType"];
//                     final senderId = msg["senderId"];
//                     final isMe = senderId == user.uid;

//                     String time = "";
//                     if (msg["timestamp"] != null) {
//                       final ts = msg["timestamp"] as Timestamp;
//                       final date = ts.toDate();
//                       time =
//                           "${date.hour.toString().padLeft(2, "0")}:${date.minute.toString().padLeft(2, "0")}";
//                     }

//                     return MessageBubble(
//                       message: fileType == "image"
//                           ? "[Image Attached]"
//                           : fileType == "pdf"
//                           ? "[PDF Attached]"
//                           : text,
//                       isPreviouseMessageMine: isMe,
//                       isFirstSequence: true,
//                       timestamp: time,
//                       fileUrl: fileUrl, // extend MessageBubble to preview
//                       fileType: fileType,
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ConstrainedBox(
//                     constraints: const BoxConstraints(maxHeight: 120),
//                     child: TextField(
//                       controller: messageController,
//                       maxLines: null,
//                       decoration: const InputDecoration(
//                         hintText: "Message",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(
//                     Icons.attach_file,
//                     color: AppColors.deeperPeriwinkle,
//                   ),
//                   onPressed: pickFileAndSend,
//                 ),
//                 GestureDetector(
//                   onTap: () {
//                     if (messageController.text.isNotEmpty) {
//                       sendMessage(text: messageController.text);
//                       messageController.clear();
//                     }
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: const BoxDecoration(
//                       color: AppColors.deeperPeriwinkle,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.send,
//                       color: Colors.white,
//                       size: 20,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
