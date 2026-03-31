// import 'dart:async';
// import 'dart:io';

// import 'package:cached_network_image/cached_network_image.dart'
//     show CachedNetworkImageProvider, CachedNetworkImage;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' hide Category;
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:omeeowash/models/message.dart';
// import 'package:omeeowash/services/chat_sync_service.dart';
// import 'package:omeeowash/services/local_chat_storage.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:provider/provider.dart';
// import 'package:video_player/video_player.dart';

// import 'live_chat.dart';
// import 'methods.dart';

// class Chat extends StatefulWidget {
//   final String? clientId;
//   final String? clientName;
//   final bool isAdmin;

//   const Chat({
//     super.key,
//     required this.clientId,
//     this.clientName,
//     this.isAdmin = false,
//   });

//   const Chat.admin({
//     super.key,
//     required this.clientId,
//     required this.clientName,
//     this.isAdmin = false,
//   });

//   @override
//   State<Chat> createState() => _ChatState();
// }

// class _ChatState extends State<Chat> {
//   static const double _maxImageSizeMb = 10;
//   static const double _maxVideoSizeMb = 50;

//   final _newestKey = GlobalKey();
//   final TextEditingController messageController = TextEditingController();
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final FocusNode _messageFocusNode = FocusNode();
//   final GlobalKey<EmojiPickerState> _emojiPickerKey =
//       GlobalKey<EmojiPickerState>();
//   bool _showEmojiPicker = false;

//   bool get isAdmin => widget.isAdmin;

//   String get userId =>
//       isAdmin ? widget.clientId! : FirebaseAuth.instance.currentUser!.uid;

//   final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

//   String get chatId => '${userId.substring(2, 14)}cc-4372-a';
//   String get sender => isAdmin ? 'ommeo' : 'user';

//   String username = "";
//   late final ChatSyncService sync;
//   late final LocalChatStore store;

//   final SelectionController selection = SelectionController();

//   bool isCurrentlyTyping = false;
//   Timer? _typingTimer;

//   String? pickedImageFile;
//   String? pickedVideoFile;

//   bool isSending = false;
//   final Set<String> _processedDeletions = {};

//   String get supportDisplayName => 'lundri support';
//   String get chatHeaderTitle =>
//       isAdmin ? (widget.clientName ?? 'Client') : supportDisplayName;

//   void _showToast(String message) {
//     Fluttertoast.cancel();
//     Fluttertoast.showToast(
//       msg: message,
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.BOTTOM,
//       backgroundColor: Colors.black87,
//       textColor: Colors.white,
//       fontSize: 14,
//     );
//   }

//   Future<void> pickImage() async {
//     setState(() {
//       pickedImageFile = null;
//       pickedVideoFile = null;
//     });

//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.image,
//       withData: false,
//     );

//     if (result == null || !mounted) return;

//     final filePath = result.files.single.path;
//     if (filePath == null) return;

//     final file = File(filePath);
//     final sizeInMb = file.lengthSync() / (1024 * 1024);

//     if (sizeInMb > _maxImageSizeMb) {
//       _showToast(
//         'Image is too large. Maximum allowed size is ${_maxImageSizeMb.toInt()} MB.',
//       );
//       return;
//     }

//     setState(() {
//       pickedImageFile = filePath;
//     });

//     debugPrint(
//       '🖼️ Picked image: $filePath (${sizeInMb.toStringAsFixed(2)} MB)',
//     );
//   }

//   Future<void> pickVideo() async {
//     setState(() {
//       pickedVideoFile = null;
//       pickedImageFile = null;
//     });

//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.video,
//       withData: false,
//     );

//     if (result == null || !mounted) return;

//     final filePath = result.files.single.path;
//     if (filePath == null) return;

//     final file = File(filePath);
//     final sizeInMb = file.lengthSync() / (1024 * 1024);

//     if (sizeInMb > _maxVideoSizeMb) {
//       _showToast(
//         'Video is too large. Maximum allowed size is ${_maxVideoSizeMb.toInt()} MB.',
//       );
//       return;
//     }

//     setState(() {
//       pickedVideoFile = filePath;
//     });

//     debugPrint(
//       '🎬 Picked video: $filePath (${sizeInMb.toStringAsFixed(2)} MB)',
//     );
//   }

//   void listenForDeletedMessages() {
//     firestore
//         .collection('users')
//         .doc(userId)
//         .collection('help_messages')
//         .orderBy('createdAt', descending: true)
//         .limit(50)
//         .snapshots()
//         .listen((snapshot) async {
//           final deletedIds = <String>[];

//           for (final change in snapshot.docChanges) {
//             final data = change.doc.data();
//             if (data == null) continue;

//             final docId = change.doc.id;

//             if (data['deleted'] == true &&
//                 !_processedDeletions.contains(docId)) {
//               _processedDeletions.add(docId);
//               deletedIds.add(docId);
//             }
//           }

//           if (deletedIds.isNotEmpty) {
//             await sync.listenAndDeleteMany(docIds: deletedIds);
//           }
//         });
//   }

//   @override
//   void initState() {
//     super.initState();
//     getUserInfo();

//     store = context.read<LocalChatStore>();
//     sync = context.read<ChatSyncService>();
//     sync.start(chatId, userId);

//     listenForDeletedMessages();

//     _messageFocusNode.addListener(() {
//       if (_messageFocusNode.hasFocus && _showEmojiPicker && mounted) {
//         setState(() {
//           _showEmojiPicker = false;
//         });
//       }
//     });

//     messageController.addListener(() {
//       if (mounted) {
//         setState(() {});
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _typingTimer?.cancel();
//     sync.stop();
//     _messageFocusNode.dispose();
//     messageController.dispose();
//     super.dispose();
//   }

//   void getUserInfo() async {
//     final userSnapshot = await firestore.collection("users").doc(userId).get();
//     final userData = userSnapshot.data();
//     if (!mounted) return;

//     setState(() {
//       username = userData?["name"] ?? "User";
//     });
//   }

//   Future<void> sendHelpMessage() async {
//     final message = messageController.text.trim();

//     if (message.isEmpty && pickedImageFile == null && pickedVideoFile == null) {
//       return;
//     }

//     messageController.clear();
//     final rawMediaUrl = pickedImageFile ?? pickedVideoFile;

//     setState(() {
//       isSending = true;
//     });

//     String? mediaUrl;
//     MessageType type = MessageType.text;

//     try {
//       if (pickedImageFile != null) {
//         type = MessageType.image;
//         final ref = FirebaseStorage.instance
//             .ref()
//             .child('chat_media')
//             .child(
//               '$currentUserId/${DateTime.now().millisecondsSinceEpoch}_${pickedImageFile!.split('/').last}',
//             );

//         await ref.putFile(File(pickedImageFile!));
//         mediaUrl = await ref.getDownloadURL();

//         setState(() {
//           pickedImageFile = null;
//         });
//       }

//       if (pickedVideoFile != null) {
//         type = MessageType.video;
//         final ref = FirebaseStorage.instance
//             .ref()
//             .child('chat_media')
//             .child(
//               '$currentUserId/${DateTime.now().millisecondsSinceEpoch}_${pickedVideoFile!.split('/').last}',
//             );

//         await ref.putFile(File(pickedVideoFile!));
//         mediaUrl = await ref.getDownloadURL();

//         setState(() {
//           pickedVideoFile = null;
//         });
//       }

//       await sync.sendMessage(
//         chatId: chatId,
//         senderId: userId,
//         sender: sender,
//         text: message.isNotEmpty ? message : null,
//         mediaUrl: mediaUrl,
//         type: type,
//         rawMediaUrl: rawMediaUrl,
//       );

//       if (!mounted) return;

//       setState(() {
//         isSending = false;
//       });

//       final adminChatRef = firestore
//           .collection('admin')
//           .doc("idforadminv1")
//           .collection('help_chats')
//           .doc(userId);

//       final batch = firestore.batch();
//       final lastMessage = message.isEmpty ? type.name : message;

//       if (isAdmin) {
//         batch.update(adminChatRef, {"last_message": lastMessage});
//       } else {
//         batch.set(adminChatRef, {
//           "userId": widget.clientId,
//           "username": username,
//           "last_message": lastMessage,
//         });
//       }

//       await batch.commit();
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         isSending = false;
//       });
//       debugPrint('❌ Failed to send help message: $e');
//       _showToast('Failed to send message. Please try again.');
//     }
//   }

//   void hideEmojiPicker() {
//     FocusScope.of(context).unfocus();
//     setState(() {
//       _showEmojiPicker = false;
//     });
//   }

//   void toggleEmojiPicker() {
//     if (_showEmojiPicker) {
//       setState(() {
//         _showEmojiPicker = false;
//       });
//       _messageFocusNode.requestFocus();
//       return;
//     }

//     FocusScope.of(context).unfocus();

//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (!mounted) return;
//       setState(() {
//         _showEmojiPicker = true;
//       });
//     });
//   }

//   void _handleEmojiSelected(Category category, Emoji emoji) {
//     final currentText = messageController.text;
//     final selection = messageController.selection;
//     final start = selection.start >= 0 ? selection.start : currentText.length;
//     final end = selection.end >= 0 ? selection.end : currentText.length;

//     final newText = currentText.replaceRange(start, end, emoji.emoji);
//     messageController.value = TextEditingValue(
//       text: newText,
//       selection: TextSelection.collapsed(offset: start + emoji.emoji.length),
//     );

//     onTyping(messageController.text);
//   }

//   Widget _buildEmojiPanel() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 220),
//       curve: Curves.easeOut,
//       height: _showEmojiPicker ? 250 : 0,
//       child: ClipRRect(
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         child: Material(
//           color: Colors.white,
//           child: _showEmojiPicker
//               ? EmojiPicker(
//                   key: _emojiPickerKey,
//                   //                   onEmojiSelected: (_) {
//                   // // _handleEmojiSelected()
//                   //                   },
//                   onBackspacePressed: () {
//                     final value = messageController.value;
//                     final text = value.text;
//                     final selection = value.selection;

//                     if (text.isEmpty) return;

//                     if (selection.start != selection.end) {
//                       final start = selection.start.clamp(0, text.length);
//                       final end = selection.end.clamp(0, text.length);
//                       final newText = text.replaceRange(start, end, '');
//                       messageController.value = TextEditingValue(
//                         text: newText,
//                         selection: TextSelection.collapsed(offset: start),
//                       );
//                     } else if (selection.start > 0) {
//                       final start = selection.start.clamp(0, text.length);
//                       final newStart = start - 1;
//                       final newText = text.replaceRange(newStart, start, '');
//                       messageController.value = TextEditingValue(
//                         text: newText,
//                         selection: TextSelection.collapsed(offset: newStart),
//                       );
//                     }

//                     onTyping(messageController.text);
//                   },
//                   textEditingController: messageController,
//                   config: Config(
//                     height: 320,
//                     checkPlatformCompatibility: true,

//                     // bgColor: Colors.white,
//                     emojiViewConfig: const EmojiViewConfig(
//                       emojiSizeMax: 28,
//                       columns: 8,
//                     ),
//                     viewOrderConfig: const ViewOrderConfig(
//                       top: EmojiPickerItem.categoryBar,
//                       middle: EmojiPickerItem.emojiView,
//                       bottom: EmojiPickerItem.searchBar,
//                     ),
//                     skinToneConfig: const SkinToneConfig(),
//                     categoryViewConfig: const CategoryViewConfig(),
//                     bottomActionBarConfig: const BottomActionBarConfig(),
//                     searchViewConfig: const SearchViewConfig(),
//                   ),
//                 )
//               : const SizedBox.shrink(),
//         ),
//       ),
//     );
//   }

//   void onTyping(String text) {
//     if (!isAdmin && !isCurrentlyTyping) {
//       isCurrentlyTyping = true;
//       firestore.collection('users').doc(userId).update({'isTyping': true});
//     }

//     _typingTimer?.cancel();
//     _typingTimer = Timer(const Duration(seconds: 2), () {
//       firestore.collection('users').doc(userId).update({'isTyping': false});
//       isCurrentlyTyping = false;
//     });
//   }

//   String formatTimestamp(DateTime dt) {
//     return DateFormat('HH:mm').format(dt);
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return PreferredSize(
//       preferredSize: const Size.fromHeight(72),
//       child: Container(
//         color: const Color(0xFFF5F5F5),
//         child: SafeArea(
//           bottom: false,
//           child: AppBar(
//             backgroundColor: const Color(0xFFF5F5F5),
//             elevation: 0,
//             scrolledUnderElevation: 0,
//             leadingWidth: 44,
//             leading: GestureDetector(
//               onTap: () => Navigator.of(context).pop(),
//               child: const Padding(
//                 padding: EdgeInsets.only(left: 10),
//                 child: Icon(
//                   FontAwesomeIcons.arrowLeft,
//                   size: 24,
//                   color: Colors.black87,
//                 ),
//               ),
//             ),
//             titleSpacing: 0,
//             title: ValueListenableBuilder<int>(
//               valueListenable: selection.count,
//               builder: (context, addUp, _) {
//                 if (addUp > 0) {
//                   return Text(
//                     '$addUp selected',
//                     style: const TextStyle(
//                       color: Colors.black87,
//                       fontWeight: FontWeight.w700,
//                       fontSize: 18,
//                     ),
//                   );
//                 }

//                 return Row(
//                   children: [
//                     Container(
//                       width: 46,
//                       height: 46,
//                       decoration: const BoxDecoration(shape: BoxShape.circle),
//                       child: ClipOval(
//                         child: Image.asset(
//                           'assets/images/support_avatar.png',
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) {
//                             return Container(
//                               color: const Color(0xFFFF6A3D),
//                               child: const Icon(
//                                 Icons.local_shipping_rounded,
//                                 color: Colors.white,
//                                 size: 22,
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           chatHeaderTitle,
//                           style: const TextStyle(
//                             color: Colors.black87,
//                             fontWeight: FontWeight.w700,
//                             fontSize: 17,
//                           ),
//                         ),
//                         isAdmin
//                             ? StreamBuilder<DocumentSnapshot>(
//                                 stream: firestore
//                                     .collection('users')
//                                     .doc(widget.clientId)
//                                     .snapshots(),
//                                 builder: (context, snapshot) {
//                                   if (!snapshot.hasData) {
//                                     return const SizedBox.shrink();
//                                   }

//                                   final data =
//                                       snapshot.data!.data()
//                                           as Map<String, dynamic>?;

//                                   final isOnline = data?['isOnline'] ?? false;

//                                   return Text(
//                                     isOnline ? 'Online' : 'Offline',
//                                     style: TextStyle(
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w500,
//                                       color: isOnline
//                                           ? const Color(0xFF2DBE60)
//                                           : Colors.grey,
//                                     ),
//                                   );
//                                 },
//                               )
//                             : const Text(
//                                 'Online',
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w500,
//                                   color: Color(0xFF2DBE60),
//                                 ),
//                               ),
//                       ],
//                     ),
//                   ],
//                 );
//               },
//             ),
//             actions: [
//               ValueListenableBuilder<int>(
//                 valueListenable: selection.count,
//                 builder: (context, addUp, _) {
//                   if (addUp == 0) return const SizedBox.shrink();

//                   return Row(
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.delete, color: Colors.black87),
//                         onPressed: () {
//                           Methods().showDeleteConfirmationDialog(context, () {
//                             if (selection.selectedIds().length > 1) {
//                               sync.deleteMany(
//                                 senderId: userId,
//                                 docIds: selection.selectedIds(),
//                               );
//                             } else {
//                               sync.deleteMessage(
//                                 senderId: userId,
//                                 docId: selection.selectedIds()[0],
//                               );
//                             }
//                             selection.clear();
//                             Navigator.of(context).pop(true);
//                           });
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.clear, color: Colors.black87),
//                         onPressed: selection.clear,
//                       ),
//                     ],
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         if (_showEmojiPicker) {
//           setState(() {
//             _showEmojiPicker = false;
//           });
//           return false;
//         }
//         return true;
//       },
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF2F2F2),
//         resizeToAvoidBottomInset: true,
//         appBar: _buildAppBar(),
//         body: Column(
//           children: [
//             Expanded(
//               child: MessageListView(
//                 chatId: chatId,
//                 newestKey: _newestKey,
//                 sender: sender,
//                 selection: selection,
//                 formatTimestamp: formatTimestamp,
//                 isSending: isSending,
//                 pickedImageFile: pickedImageFile,
//                 pickedVideoFile: pickedVideoFile,
//                 store: store,
//                 senderNameForRemoteSide: isAdmin
//                     ? (widget.clientName ?? 'Client')
//                     : supportDisplayName,
//                 onLoadOlderMessages: () async {
//                   await sync.loadOlder(userId, chatId);
//                 },
//               ),
//             ),
//             StreamBuilder<DocumentSnapshot>(
//               stream: firestore
//                   .collection('users')
//                   .doc(widget.clientId)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return const SizedBox.shrink();
//                 if (!isAdmin) return const SizedBox.shrink();

//                 final data = snapshot.data!.data() as Map<String, dynamic>?;
//                 final isTyping = data?['isTyping'] ?? false;

//                 if (!isTyping) return const SizedBox.shrink();

//                 return Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.only(
//                     left: 18,
//                     right: 18,
//                     bottom: 6,
//                   ),
//                   alignment: Alignment.centerLeft,
//                   child: const Text(
//                     'typing...',
//                     style: TextStyle(
//                       color: Colors.black54,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 );
//               },
//             ),
//             MessageInput(
//               controller: messageController,
//               focusNode: _messageFocusNode,
//               onPickImage: pickImage,
//               onPickVideo: pickVideo,
//               onRemoveImage: () {
//                 setState(() {
//                   pickedImageFile = null;
//                 });
//               },
//               onRemoveVideo: () {
//                 setState(() {
//                   pickedVideoFile = null;
//                 });
//               },
//               onSend: sendHelpMessage,
//               onToggleEmojis: toggleEmojiPicker,
//               hideEmojiPicker: hideEmojiPicker,
//               onTyping: onTyping,
//               pickedImageFile: pickedImageFile,
//               pickedVideoFile: pickedVideoFile,
//               isSending: isSending,
//               isEmojiPickerVisible: _showEmojiPicker,
//             ),
//             _buildEmojiPanel(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class MessageListView extends StatefulWidget {
//   final String chatId;
//   final GlobalKey newestKey;
//   final String sender;
//   final SelectionController selection;
//   final String Function(DateTime) formatTimestamp;
//   final bool isSending;
//   final String? pickedImageFile;
//   final String? pickedVideoFile;
//   final LocalChatStore store;
//   final bool alwaysSnapToBottomOnNewMessage;
//   final Future<void> Function()? onLoadOlderMessages;
//   final String senderNameForRemoteSide;

//   const MessageListView({
//     super.key,
//     required this.chatId,
//     required this.newestKey,
//     required this.sender,
//     required this.selection,
//     required this.formatTimestamp,
//     required this.isSending,
//     required this.pickedImageFile,
//     required this.pickedVideoFile,
//     required this.store,
//     required this.senderNameForRemoteSide,
//     this.alwaysSnapToBottomOnNewMessage = true,
//     this.onLoadOlderMessages,
//   });

//   @override
//   State<MessageListView> createState() => _MessageListViewState();
// }

// class _MessageListViewState extends State<MessageListView> {
//   final ScrollController _scrollController = ScrollController();
//   final GlobalKey _bottomSentinelKey = GlobalKey();

//   int _prevCount = 0;
//   String? _lastBottomMsgId;

//   bool _autoScrollLocked = false;
//   static const double _kAutoScrollThresholdPx = 120.0;
//   static const double _kTopTriggerThresholdPx = 80.0;
//   bool _isLoadingOlder = false;

//   @override
//   void initState() {
//     super.initState();

//     _scrollController.addListener(() {
//       if (!widget.alwaysSnapToBottomOnNewMessage &&
//           _scrollController.hasClients) {
//         final distanceFromBottom =
//             _scrollController.position.maxScrollExtent -
//             _scrollController.position.pixels;
//         _autoScrollLocked = distanceFromBottom > _kAutoScrollThresholdPx;
//       }

//       if (_scrollController.hasClients &&
//           _scrollController.position.pixels <= _kTopTriggerThresholdPx &&
//           !_isLoadingOlder &&
//           widget.onLoadOlderMessages != null) {
//         _triggerLoadOlder();
//       }
//     });

//     WidgetsBinding.instance.addPostFrameCallback((_) => _ensureBottomVisible());
//   }

//   Future<void> _triggerLoadOlder() async {
//     if (widget.onLoadOlderMessages == null) return;
//     setState(() => _isLoadingOlder = true);
//     try {
//       await widget.onLoadOlderMessages!.call();
//     } finally {
//       if (mounted) {
//         setState(() => _isLoadingOlder = false);
//       }
//     }
//   }

//   @override
//   void didUpdateWidget(covariant MessageListView oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.isSending && !oldWidget.isSending) {
//       WidgetsBinding.instance.addPostFrameCallback(
//         (_) => _ensureBottomVisible(),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   Future<void> _ensureBottomVisible() async {
//     if (!mounted) return;
//     if (!widget.alwaysSnapToBottomOnNewMessage && _autoScrollLocked) return;

//     await Future<void>.delayed(const Duration(milliseconds: 16));

//     final ctx = _bottomSentinelKey.currentContext;
//     if (ctx != null) {
//       try {
//         await Scrollable.ensureVisible(
//           ctx,
//           duration: const Duration(milliseconds: 250),
//           curve: Curves.easeOut,
//           alignment: 1.0,
//         );
//         return;
//       } catch (_) {}
//     }

//     if (_scrollController.hasClients) {
//       await _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 250),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   bool _isSameDay(DateTime a, DateTime b) {
//     return a.year == b.year && a.month == b.month && a.day == b.day;
//   }

//   bool _isYesterday(DateTime date) {
//     final now = DateTime.now();
//     final yesterday = DateTime(
//       now.year,
//       now.month,
//       now.day,
//     ).subtract(const Duration(days: 1));
//     final d = DateTime(date.year, date.month, date.day);
//     return d == yesterday;
//   }

//   bool _isToday(DateTime date) {
//     final now = DateTime.now();
//     return _isSameDay(date, now);
//   }

//   DateTime _startOfWeek(DateTime date) {
//     final normalized = DateTime(date.year, date.month, date.day);
//     return normalized.subtract(Duration(days: normalized.weekday - 1));
//   }

//   bool _isInCurrentWeek(DateTime date) {
//     final now = DateTime.now();
//     final start = _startOfWeek(now);
//     final end = start.add(const Duration(days: 7));
//     final normalized = DateTime(date.year, date.month, date.day);
//     return !normalized.isBefore(start) && normalized.isBefore(end);
//   }

//   String _formatDaySeparator(DateTime date) {
//     if (_isToday(date)) return 'Today';
//     if (_isYesterday(date)) return 'Yesterday';
//     if (_isInCurrentWeek(date)) return DateFormat('EEEE').format(date);
//     return DateFormat('MMMM d, y').format(date);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         StreamBuilder<List<Message>>(
//           stream: widget.store.watchLatest(widget.chatId, limit: 50),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting &&
//                 !snapshot.hasData) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             final msgs = snapshot.data ?? const <Message>[];
//             if (msgs.isEmpty) {
//               return const SizedBox.shrink();
//             }

//             final currentBottomId = msgs.last.docId;
//             final countChanged = msgs.length != _prevCount;
//             final bottomChanged = currentBottomId != _lastBottomMsgId;

//             if (countChanged || bottomChanged) {
//               _prevCount = msgs.length;
//               _lastBottomMsgId = currentBottomId;
//               WidgetsBinding.instance.addPostFrameCallback(
//                 (_) => _ensureBottomVisible(),
//               );
//             }

//             return ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.fromLTRB(10, 14, 10, 20),
//               itemCount: msgs.length + 1,
//               itemBuilder: (context, index) {
//                 if (index == msgs.length) {
//                   return SizedBox(
//                     key: _bottomSentinelKey,
//                     height: 1,
//                     width: MediaQuery.of(context).size.width,
//                   );
//                 }

//                 final message = msgs[index];
//                 final msgId = message.docId;
//                 final ts = message.createdAt;
//                 final isMine = message.sender == widget.sender;
//                 final isLast = index == msgs.length - 1;

//                 final previous = index > 0 ? msgs[index - 1] : null;

//                 final showDaySeparator =
//                     previous == null || !_isSameDay(previous.createdAt, ts);

//                 final isSameSenderAsPrevious =
//                     previous != null &&
//                     previous.sender == message.sender &&
//                     _isSameDay(previous.createdAt, ts);

//                 final showSenderLabelForThisBubble =
//                     !isMine &&
//                     (previous == null || !_isSameDay(previous.createdAt, ts));

//                 return ValueListenableBuilder<bool>(
//                   valueListenable: widget.selection.listen(msgId),
//                   builder: (context, isSelected, _) {
//                     return Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         if (showDaySeparator)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 18, bottom: 14),
//                             child: Center(
//                               child: Text(
//                                 _formatDaySeparator(ts),
//                                 style: const TextStyle(
//                                   color: Color(0xFF9E9E9E),
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         MessageBubble(
//                           key: isLast ? widget.newestKey : ValueKey(msgId),
//                           message: message,
//                           timestamp: widget.formatTimestamp(ts),
//                           isMine: isMine,
//                           isFirstSequence: !isSameSenderAsPrevious,
//                           isSelected: isSelected,
//                           showSenderLabel: showSenderLabelForThisBubble,
//                           senderLabel: widget.senderNameForRemoteSide,
//                           onLongPress: () => widget.selection.toggle(msgId),
//                           onTap: () {
//                             if (widget.selection.count.value > 0) {
//                               widget.selection.toggle(msgId);
//                             }
//                           },
//                           store: widget.store,
//                         ),
//                         if (isLast &&
//                             widget.isSending &&
//                             (widget.pickedImageFile != null ||
//                                 widget.pickedVideoFile != null))
//                           Align(
//                             alignment: Alignment.centerRight,
//                             child: Container(
//                               margin: const EdgeInsets.only(right: 12, top: 8),
//                               height: 92,
//                               width: 92,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(14),
//                               ),
//                               child: const Stack(
//                                 children: [
//                                   Center(
//                                     child: Icon(
//                                       Icons.file_copy_rounded,
//                                       color: Colors.grey,
//                                       size: 42,
//                                     ),
//                                   ),
//                                   Center(
//                                     child: SizedBox(
//                                       width: 24,
//                                       height: 24,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                       ],
//                     );
//                   },
//                 );
//               },
//             );
//           },
//         ),
//         if (_isLoadingOlder)
//           const Align(
//             alignment: Alignment.topCenter,
//             child: Padding(
//               padding: EdgeInsets.only(top: 8),
//               child: SizedBox(
//                 height: 22,
//                 width: 22,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }

// typedef SendCallback = Future<void> Function();

// class MessageInput extends StatelessWidget {
//   final TextEditingController controller;
//   final VoidCallback onPickImage;
//   final VoidCallback onPickVideo;
//   final VoidCallback onRemoveImage;
//   final VoidCallback onRemoveVideo;
//   final SendCallback onSend;
//   final VoidCallback onToggleEmojis;
//   final VoidCallback hideEmojiPicker;
//   final FocusNode focusNode;
//   final bool isEmojiPickerVisible;
//   final void Function(String) onTyping;
//   final String? pickedImageFile;
//   final String? pickedVideoFile;
//   final bool isSending;

//   const MessageInput({
//     super.key,
//     required this.controller,
//     required this.onPickImage,
//     required this.onPickVideo,
//     required this.onRemoveImage,
//     required this.onRemoveVideo,
//     required this.onSend,
//     required this.onTyping,
//     required this.pickedImageFile,
//     required this.pickedVideoFile,
//     required this.isSending,
//     required this.onToggleEmojis,
//     required this.focusNode,
//     required this.isEmojiPickerVisible,
//     required this.hideEmojiPicker,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final sendEnabled =
//         !isSending &&
//         (controller.text.trim().isNotEmpty ||
//             pickedImageFile != null ||
//             pickedVideoFile != null);

//     return Container(
//       color: const Color(0xFFF2F2F2),
//       padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
//       child: SafeArea(
//         top: false,
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(28),
//                   border: Border.all(color: const Color(0xFFE5E5E5)),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (pickedImageFile != null && !isSending)
//                       ImagePreview(
//                         filePath: pickedImageFile!,
//                         onRemove: onRemoveImage,
//                       ),
//                     if (pickedVideoFile != null && !isSending)
//                       VideoPreview(
//                         filePath: pickedVideoFile!,
//                         onRemove: onRemoveVideo,
//                       ),
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         IconButton(
//                           onPressed: () {
//                             Methods().showMediaPickerDialog(
//                               context,
//                               onPickImage,
//                               onPickVideo,
//                             );
//                           },
//                           icon: const Icon(
//                             Icons.attach_file_rounded,
//                             color: Color(0xFF8F8F8F),
//                             size: 28,
//                           ),
//                         ),
//                         Expanded(
//                           child: ConstrainedBox(
//                             constraints: const BoxConstraints(maxHeight: 120),
//                             child: TextField(
//                               controller: controller,
//                               focusNode: focusNode,
//                               onTap: hideEmojiPicker,
//                               onChanged: onTyping,
//                               minLines: 1,
//                               maxLines: null,
//                               keyboardType: TextInputType.multiline,
//                               style: const TextStyle(
//                                 color: Colors.black87,
//                                 fontSize: 17,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               decoration: const InputDecoration(
//                                 hintText: 'Message',
//                                 hintStyle: TextStyle(
//                                   color: Color(0xFF9B9B9B),
//                                   fontSize: 17,
//                                   fontWeight: FontWeight.w400,
//                                 ),
//                                 border: InputBorder.none,
//                                 contentPadding: EdgeInsets.only(
//                                   top: 14,
//                                   bottom: 14,
//                                   right: 8,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         IconButton(
//                           onPressed: onToggleEmojis,
//                           icon: Icon(
//                             isEmojiPickerVisible
//                                 ? Icons.keyboard_rounded
//                                 : Icons.sentiment_satisfied_alt_rounded,
//                             color: const Color(0xFF8F8F8F),
//                             size: 28,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             GestureDetector(
//               onTap: sendEnabled ? onSend : null,
//               child: Container(
//                 width: 52,
//                 height: 52,
//                 decoration: BoxDecoration(
//                   color: sendEnabled
//                       ? const Color(0xFFE8F7FC)
//                       : const Color(0xFFE6E6E6),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Center(
//                   child: isSending
//                       ? const SizedBox(
//                           width: 22,
//                           height: 22,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : Icon(
//                           Icons.send_rounded,
//                           size: 26,
//                           color: sendEnabled
//                               ? const Color(0xFF2AAFC9)
//                               : const Color(0xFFB8B8B8),
//                         ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ImagePreview extends StatefulWidget {
//   final String filePath;
//   final VoidCallback onRemove;

//   const ImagePreview({
//     super.key,
//     required this.filePath,
//     required this.onRemove,
//   });

//   @override
//   State<ImagePreview> createState() => _ImagePreviewState();
// }

// class _ImagePreviewState extends State<ImagePreview> {
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (_) => FullScreenImageViewer(imagePath: widget.filePath),
//           ),
//         );
//       },
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
//         child: Stack(
//           children: [
//             Hero(
//               tag: widget.filePath,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(14),
//                 child: Image.file(
//                   File(widget.filePath),
//                   height: 150,
//                   width: double.infinity,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 8,
//               right: 8,
//               child: GestureDetector(
//                 onTap: widget.onRemove,
//                 child: const CircleAvatar(
//                   radius: 14,
//                   backgroundColor: Colors.black54,
//                   child: Icon(Icons.close, color: Colors.white, size: 16),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class VideoPreview extends StatefulWidget {
//   final String filePath;
//   final VoidCallback onRemove;
//   final VoidCallback? downloadVideo;
//   final bool isSending;
//   final bool forBubble;

//   const VideoPreview({
//     super.key,
//     required this.filePath,
//     required this.onRemove,
//     this.isSending = false,
//     this.forBubble = false,
//     this.downloadVideo,
//   });

//   @override
//   State<VideoPreview> createState() => _VideoPreviewState();
// }

// class _VideoPreviewState extends State<VideoPreview> {
//   VideoPlayerController? _controller;
//   bool _isInitialized = false;
//   bool isDownloading = false;

//   @override
//   void initState() {
//     super.initState();
//     if (!widget.filePath.startsWith('http') && widget.filePath.isNotEmpty) {
//       _initController(widget.filePath);
//     }
//   }

//   @override
//   void didUpdateWidget(VideoPreview oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.filePath != widget.filePath) {
//       _disposeController();
//       if (!widget.filePath.startsWith('http') && widget.filePath.isNotEmpty) {
//         _initController(widget.filePath);
//       }
//     }
//   }

//   Future<void> _initController(String path) async {
//     try {
//       final isLocal = !path.startsWith('http');
//       final controller = isLocal
//           ? VideoPlayerController.file(File(path))
//           : VideoPlayerController.networkUrl(Uri.parse(path));

//       await controller.initialize();
//       if (!mounted) return;

//       setState(() {
//         _controller = controller;
//         _isInitialized = true;
//       });
//     } catch (e) {
//       debugPrint('🎥 Video init error: $e');
//     }
//   }

//   void _disposeController() {
//     _controller?.dispose();
//     _controller = null;
//     _isInitialized = false;
//   }

//   @override
//   void dispose() {
//     _disposeController();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isUrl = widget.filePath.startsWith("http");

//     return Padding(
//       padding: widget.forBubble
//           ? EdgeInsets.zero
//           : const EdgeInsets.fromLTRB(14, 12, 14, 0),
//       child: Stack(
//         children: [
//           if (isUrl)
//             ClipRRect(
//               borderRadius: BorderRadius.circular(14),
//               child: Container(
//                 height: 180,
//                 color: Colors.black12,
//                 alignment: Alignment.center,
//                 child: const Icon(
//                   Icons.videocam,
//                   size: 48,
//                   color: Colors.white70,
//                 ),
//               ),
//             )
//           else if (_isInitialized && _controller != null)
//             ClipRRect(
//               borderRadius: BorderRadius.circular(14),
//               child: AspectRatio(
//                 aspectRatio: _controller!.value.aspectRatio,
//                 child: VideoPlayer(_controller!),
//               ),
//             )
//           else
//             Container(
//               height: 180,
//               alignment: Alignment.center,
//               decoration: BoxDecoration(
//                 color: Colors.black12,
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: const CircularProgressIndicator(),
//             ),
//           if (!widget.forBubble)
//             Positioned(
//               top: 8,
//               right: 8,
//               child: GestureDetector(
//                 onTap: widget.onRemove,
//                 child: const CircleAvatar(
//                   radius: 14,
//                   backgroundColor: Colors.black54,
//                   child: Icon(Icons.close, color: Colors.white, size: 16),
//                 ),
//               ),
//             ),
//           Positioned.fill(
//             child: Center(
//               child: GestureDetector(
//                 onTap: () {
//                   if (isUrl) {
//                     Fluttertoast.showToast(msg: 'Video not downloaded');
//                     return;
//                   }

//                   if (!widget.isSending) {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) =>
//                             FullScreenVideoPlayer(filePath: widget.filePath),
//                       ),
//                     );
//                   } else {
//                     Fluttertoast.showToast(msg: 'Video still uploading...');
//                   }
//                 },
//                 child: widget.isSending
//                     ? const CircularProgressIndicator()
//                     : const Icon(
//                         Icons.play_circle,
//                         color: Colors.white70,
//                         size: 52,
//                       ),
//               ),
//             ),
//           ),
//           if (isUrl)
//             Positioned(
//               bottom: 8,
//               right: 10,
//               child: GestureDetector(
//                 onTap: () async {
//                   widget.downloadVideo?.call();
//                   setState(() => isDownloading = true);
//                 },
//                 child: CircleAvatar(
//                   radius: 16,
//                   backgroundColor: Colors.black54,
//                   child: isDownloading
//                       ? const SizedBox(
//                           width: 18,
//                           height: 18,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Icon(
//                           Icons.download,
//                           color: Colors.white,
//                           size: 18,
//                         ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class FullScreenVideoPlayer extends StatefulWidget {
//   final String filePath;

//   const FullScreenVideoPlayer({super.key, required this.filePath});

//   @override
//   State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
// }

// class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
//   late VideoPlayerController _controller;
//   bool _isDragging = false;
//   Duration _dragPosition = Duration.zero;
//   bool _showControls = true;
//   Timer? _hideTimer;

//   @override
//   void initState() {
//     super.initState();

//     if (widget.filePath.startsWith("http")) {
//       _controller = VideoPlayerController.networkUrl(Uri.parse(widget.filePath))
//         ..initialize().then((_) {
//           if (!mounted) return;
//           setState(() {});
//           _controller.play();
//           _startHideTimer();
//         });
//     } else {
//       _controller = VideoPlayerController.file(File(widget.filePath))
//         ..initialize().then((_) {
//           if (!mounted) return;
//           setState(() {});
//           _controller.play();
//           _startHideTimer();
//         });
//     }

//     _controller.addListener(() {
//       if (!_isDragging && mounted) setState(() {});
//     });
//   }

//   void _startHideTimer() {
//     _hideTimer?.cancel();
//     _hideTimer = Timer(const Duration(seconds: 5), () {
//       if (mounted) {
//         setState(() {
//           _showControls = false;
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _hideTimer?.cancel();
//     super.dispose();
//   }

//   String _formatDuration(Duration d) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final h = d.inHours;
//     final m = d.inMinutes.remainder(60);
//     final s = d.inSeconds.remainder(60);

//     if (h > 0) {
//       return '${twoDigits(h)}:${twoDigits(m)}:${twoDigits(s)}';
//     }
//     return '${twoDigits(m)}:${twoDigits(s)}';
//   }

//   void _forward() async {
//     final pos = await _controller.position ?? Duration.zero;
//     final target = pos + const Duration(seconds: 10);
//     await _controller.seekTo(target);
//   }

//   void _backward() async {
//     final pos = await _controller.position ?? Duration.zero;
//     final target = pos - const Duration(seconds: 10);
//     await _controller.seekTo(target < Duration.zero ? Duration.zero : target);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: _controller.value.isInitialized
//           ? GestureDetector(
//               onTap: () {
//                 setState(() {
//                   _showControls = !_showControls;
//                 });
//                 if (_showControls) _startHideTimer();
//               },
//               child: Stack(
//                 children: [
//                   Center(
//                     child: AspectRatio(
//                       aspectRatio: _controller.value.aspectRatio,
//                       child: VideoPlayer(_controller),
//                     ),
//                   ),
//                   if (_showControls)
//                     Positioned.fill(
//                       child: Container(
//                         color: Colors.black26,
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             Slider(
//                               value: _isDragging
//                                   ? _dragPosition.inMilliseconds.toDouble()
//                                   : _controller.value.position.inMilliseconds
//                                         .toDouble(),
//                               min: 0,
//                               max: _controller.value.duration.inMilliseconds
//                                   .toDouble()
//                                   .clamp(1, double.infinity),
//                               onChangeStart: (_) {
//                                 setState(() => _isDragging = true);
//                               },
//                               onChanged: (value) {
//                                 setState(() {
//                                   _dragPosition = Duration(
//                                     milliseconds: value.toInt(),
//                                   );
//                                 });
//                               },
//                               onChangeEnd: (value) async {
//                                 final newPos = Duration(
//                                   milliseconds: value.toInt(),
//                                 );
//                                 await _controller.seekTo(newPos);
//                                 setState(() => _isDragging = false);
//                                 _startHideTimer();
//                               },
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 20,
//                               ),
//                               child: Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     _formatDuration(_controller.value.position),
//                                     style: const TextStyle(color: Colors.white),
//                                   ),
//                                   Text(
//                                     _formatDuration(_controller.value.duration),
//                                     style: const TextStyle(color: Colors.white),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 10),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 IconButton(
//                                   icon: const Icon(
//                                     Icons.replay_10,
//                                     color: Colors.white,
//                                     size: 30,
//                                   ),
//                                   onPressed: _backward,
//                                 ),
//                                 IconButton(
//                                   icon: Icon(
//                                     _controller.value.isPlaying
//                                         ? Icons.pause
//                                         : Icons.play_arrow,
//                                     color: Colors.white,
//                                     size: 40,
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       _controller.value.isPlaying
//                                           ? _controller.pause()
//                                           : _controller.play();
//                                     });
//                                     _startHideTimer();
//                                   },
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(
//                                     Icons.forward_10,
//                                     color: Colors.white,
//                                     size: 30,
//                                   ),
//                                   onPressed: _forward,
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 24),
//                           ],
//                         ),
//                       ),
//                     ),
//                   if (_showControls)
//                     Positioned(
//                       top: 40,
//                       left: 20,
//                       child: IconButton(
//                         icon: const Icon(
//                           Icons.close,
//                           color: Colors.white,
//                           size: 30,
//                         ),
//                         onPressed: () => Navigator.of(context).pop(),
//                       ),
//                     ),
//                 ],
//               ),
//             )
//           : const Center(child: CircularProgressIndicator()),
//     );
//   }
// }

// class FullScreenImageViewer extends StatefulWidget {
//   final String imagePath;

//   const FullScreenImageViewer({super.key, required this.imagePath});

//   @override
//   State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
// }

// class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
//   double _dragOffset = 0.0;
//   static const double _closeThreshold = 50.0;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: GestureDetector(
//         onVerticalDragUpdate: (details) {
//           setState(() {
//             _dragOffset += details.delta.dy;
//           });
//         },
//         onVerticalDragEnd: (details) {
//           if (_dragOffset > _closeThreshold) {
//             Navigator.pop(context);
//           } else {
//             setState(() => _dragOffset = 0.0);
//           }
//         },
//         child: Stack(
//           children: [
//             Hero(
//               tag: widget.imagePath,
//               child: PhotoView(
//                 imageProvider: widget.imagePath.startsWith('http')
//                     ? CachedNetworkImageProvider(widget.imagePath)
//                     : FileImage(File(widget.imagePath)) as ImageProvider,
//                 minScale: PhotoViewComputedScale.contained,
//                 maxScale: PhotoViewComputedScale.covered * 3.0,
//                 backgroundDecoration: const BoxDecoration(color: Colors.black),
//               ),
//             ),
//             Positioned(
//               top: 40,
//               left: 20,
//               child: IconButton(
//                 icon: const Icon(Icons.close, color: Colors.white, size: 30),
//                 onPressed: () => Navigator.of(context).pop(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart'
    show CachedNetworkImageProvider, CachedNetworkImage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' hide Category;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:omeeowash/models/message.dart';
import 'package:omeeowash/services/chat_sync_service.dart';
import 'package:omeeowash/services/local_chat_storage.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'live_chat.dart';
import 'methods.dart';

class Chat extends StatefulWidget {
  final String? clientId;
  final String? clientName;
  final bool isAdmin;

  const Chat({
    super.key,
    required this.clientId,
    this.clientName,
    this.isAdmin = false,
  });

  const Chat.admin({
    super.key,
    required this.clientId,
    required this.clientName,
    this.isAdmin = false,
  });

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  static const double _maxImageSizeMb = 10;
  static const double _maxVideoSizeMb = 50;

  final _newestKey = GlobalKey();
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FocusNode _messageFocusNode = FocusNode();
  final GlobalKey<EmojiPickerState> _emojiPickerKey =
      GlobalKey<EmojiPickerState>();
  bool _showEmojiPicker = false;
  bool _isEmojiSearchVisible = false;

  bool get isAdmin => widget.isAdmin;

  String get userId =>
      isAdmin ? widget.clientId! : FirebaseAuth.instance.currentUser!.uid;

  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String get chatId => '${userId.substring(2, 14)}cc-4372-a';
  String get sender => isAdmin ? 'ommeo' : 'user';

  String username = "";
  late final ChatSyncService sync;
  late final LocalChatStore store;

  final SelectionController selection = SelectionController();

  bool isCurrentlyTyping = false;
  Timer? _typingTimer;

  String? pickedImageFile;
  String? pickedVideoFile;

  bool isSending = false;
  final Set<String> _processedDeletions = {};

  String get supportDisplayName => 'lundri support';
  String get chatHeaderTitle =>
      isAdmin ? (widget.clientName ?? 'Client') : supportDisplayName;

  bool get _hasPickedMedia =>
      pickedImageFile != null || pickedVideoFile != null;

  void _showToast(String message) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14,
    );
  }

  Future<void> pickImage() async {
    setState(() {
      pickedImageFile = null;
      pickedVideoFile = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: false,
    );

    if (result == null || !mounted) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    final file = File(filePath);
    final sizeInMb = file.lengthSync() / (1024 * 1024);

    if (sizeInMb > _maxImageSizeMb) {
      _showToast(
        'Image is too large. Maximum allowed size is ${_maxImageSizeMb.toInt()} MB.',
      );
      return;
    }

    setState(() {
      pickedImageFile = filePath;
    });

    debugPrint(
      '🖼️ Picked image: $filePath (${sizeInMb.toStringAsFixed(2)} MB)',
    );
  }

  Future<void> pickVideo() async {
    setState(() {
      pickedVideoFile = null;
      pickedImageFile = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: false,
    );

    if (result == null || !mounted) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    final file = File(filePath);
    final sizeInMb = file.lengthSync() / (1024 * 1024);

    if (sizeInMb > _maxVideoSizeMb) {
      _showToast(
        'Video is too large. Maximum allowed size is ${_maxVideoSizeMb.toInt()} MB.',
      );
      return;
    }

    setState(() {
      pickedVideoFile = filePath;
    });

    debugPrint(
      '🎬 Picked video: $filePath (${sizeInMb.toStringAsFixed(2)} MB)',
    );
  }

  void listenForDeletedMessages() {
    firestore
        .collection('users')
        .doc(userId)
        .collection('help_messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) async {
          final deletedIds = <String>[];

          for (final change in snapshot.docChanges) {
            final data = change.doc.data();
            if (data == null) continue;

            final docId = change.doc.id;

            if (data['deleted'] == true &&
                !_processedDeletions.contains(docId)) {
              _processedDeletions.add(docId);
              deletedIds.add(docId);
            }
          }

          if (deletedIds.isNotEmpty) {
            await sync.listenAndDeleteMany(docIds: deletedIds);
          }
        });
  }

  @override
  void initState() {
    super.initState();
    getUserInfo();

    store = context.read<LocalChatStore>();
    sync = context.read<ChatSyncService>();
    sync.start(chatId, userId);

    listenForDeletedMessages();

    // _messageFocusNode.addListener(() {
    //   if (_messageFocusNode.hasFocus && _showEmojiPicker && mounted) {
    //     setState(() {
    //       _showEmojiPicker = false;
    //     });
    //   }
    // });

    messageController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    sync.stop();
    _messageFocusNode.dispose();
    messageController.dispose();
    super.dispose();
  }

  void getUserInfo() async {
    final userSnapshot = await firestore.collection("users").doc(userId).get();
    final userData = userSnapshot.data();
    if (!mounted) return;

    setState(() {
      username = userData?["name"] ?? "User";
    });
  }

  Future<void> sendHelpMessage() async {
    final message = messageController.text.trim();

    if (message.isEmpty && pickedImageFile == null && pickedVideoFile == null) {
      return;
    }

    messageController.clear();
    final rawMediaUrl = pickedImageFile ?? pickedVideoFile;

    setState(() {
      isSending = true;
    });

    String? mediaUrl;
    MessageType type = MessageType.text;

    try {
      if (pickedImageFile != null) {
        type = MessageType.image;
        final ref = FirebaseStorage.instance
            .ref()
            .child('chat_media')
            .child(
              '$currentUserId/${DateTime.now().millisecondsSinceEpoch}_${pickedImageFile!.split('/').last}',
            );

        await ref.putFile(File(pickedImageFile!));
        mediaUrl = await ref.getDownloadURL();

        setState(() {
          pickedImageFile = null;
        });
      }

      if (pickedVideoFile != null) {
        type = MessageType.video;
        final ref = FirebaseStorage.instance
            .ref()
            .child('chat_media')
            .child(
              '$currentUserId/${DateTime.now().millisecondsSinceEpoch}_${pickedVideoFile!.split('/').last}',
            );

        await ref.putFile(File(pickedVideoFile!));
        mediaUrl = await ref.getDownloadURL();

        setState(() {
          pickedVideoFile = null;
        });
      }

      await sync.sendMessage(
        chatId: chatId,
        senderId: userId,
        sender: sender,
        text: message.isNotEmpty ? message : null,
        mediaUrl: mediaUrl,
        type: type,
        rawMediaUrl: rawMediaUrl,
      );

      if (!mounted) return;

      setState(() {
        isSending = false;
      });

      final adminChatRef = firestore
          .collection('admin')
          .doc("idforadminv1")
          .collection('help_chats')
          .doc(userId);

      final batch = firestore.batch();
      final lastMessage = message.isEmpty ? type.name : message;

      if (isAdmin) {
        batch.update(adminChatRef, {"last_message": lastMessage});
      } else {
        batch.set(adminChatRef, {
          "userId": widget.clientId,
          "username": username,
          "last_message": lastMessage,
        });
      }

      await batch.commit();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSending = false;
      });
      debugPrint('❌ Failed to send help message: $e');
      _showToast('Failed to send message. Please try again.');
    }
  }

  void hideEmojiPicker() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showEmojiPicker = false;
    });
  }

  void toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
      _messageFocusNode.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      setState(() {
        _showEmojiPicker = true;
      });
    });
  }

  void _handleEmojiSelected(Category category, Emoji emoji) {
    final currentText = messageController.text;
    final selection = messageController.selection;
    final start = selection.start >= 0 ? selection.start : currentText.length;
    final end = selection.end >= 0 ? selection.end : currentText.length;

    final newText = currentText.replaceRange(start, end, emoji.emoji);
    messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.emoji.length),
    );

    onTyping(messageController.text);
  }

  Widget _buildEmojiPanel() {
    final pickerHeight = _isEmojiSearchVisible ? 120.0 : 320.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: _showEmojiPicker ? pickerHeight : 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          color: Colors.white,
          child: _showEmojiPicker
              ? EmojiPicker(
                  key: _emojiPickerKey,
                  onBackspacePressed: () {
                    final value = messageController.value;
                    final text = value.text;
                    final selection = value.selection;

                    if (text.isEmpty) return;

                    if (selection.start != selection.end) {
                      final start = selection.start.clamp(0, text.length);
                      final end = selection.end.clamp(0, text.length);
                      final newText = text.replaceRange(start, end, '');
                      messageController.value = TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(offset: start),
                      );
                    } else if (selection.start > 0) {
                      final start = selection.start.clamp(0, text.length);
                      final newStart = start - 1;
                      final newText = text.replaceRange(newStart, start, '');
                      messageController.value = TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(offset: newStart),
                      );
                    }

                    onTyping(messageController.text);
                  },
                  textEditingController: messageController,
                  config: Config(
                    height: pickerHeight,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: const EmojiViewConfig(
                      emojiSizeMax: 28,
                      columns: 8,
                    ),
                    viewOrderConfig: const ViewOrderConfig(
                      top: EmojiPickerItem.categoryBar,
                      middle: EmojiPickerItem.emojiView,
                      bottom: EmojiPickerItem.searchBar,
                    ),
                    skinToneConfig: const SkinToneConfig(),
                    categoryViewConfig: const CategoryViewConfig(),
                    bottomActionBarConfig: const BottomActionBarConfig(
                      enabled: false,
                    ),
                    searchViewConfig: SearchViewConfig(
                      customSearchView: (config, state, showEmojiView) {
                        return _EmojiSearchModeListener(
                          config: config,
                          state: state,
                          showEmojiView: () {
                            if (mounted) {
                              setState(() => _isEmojiSearchVisible = false);
                            }
                            showEmojiView();
                          },
                          onSearchOpened: () {
                            if (mounted) {
                              setState(() => _isEmojiSearchVisible = true);
                            }
                          },
                          onSearchClosed: () {
                            if (mounted) {
                              setState(() => _isEmojiSearchVisible = false);
                            }
                          },
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  void onTyping(String text) {
    if (!isAdmin && !isCurrentlyTyping) {
      isCurrentlyTyping = true;
      firestore.collection('users').doc(userId).update({'isTyping': true});
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      firestore.collection('users').doc(userId).update({'isTyping': false});
      isCurrentlyTyping = false;
    });
  }

  String formatTimestamp(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        color: const Color(0xFFF5F5F5),
        child: SafeArea(
          bottom: false,
          child: AppBar(
            backgroundColor: const Color(0xFFF5F5F5),
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 44,
            leading: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(
                  FontAwesomeIcons.arrowLeft,
                  size: 24,
                  color: Colors.black87,
                ),
              ),
            ),
            titleSpacing: 0,
            title: ValueListenableBuilder<int>(
              valueListenable: selection.count,
              builder: (context, addUp, _) {
                if (addUp > 0) {
                  return Text(
                    '$addUp selected',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  );
                }

                return Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/support_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: const Color(0xFFFF6A3D),
                              child: const Icon(
                                Icons.local_shipping_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chatHeaderTitle,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        isAdmin
                            ? StreamBuilder<DocumentSnapshot>(
                                stream: firestore
                                    .collection('users')
                                    .doc(widget.clientId)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }

                                  final data =
                                      snapshot.data!.data()
                                          as Map<String, dynamic>?;

                                  final isOnline = data?['isOnline'] ?? false;

                                  return Text(
                                    isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isOnline
                                          ? const Color(0xFF2DBE60)
                                          : Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : const Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2DBE60),
                                ),
                              ),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              ValueListenableBuilder<int>(
                valueListenable: selection.count,
                builder: (context, addUp, _) {
                  if (addUp == 0) return const SizedBox.shrink();

                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black87),
                        onPressed: () {
                          Methods().showDeleteConfirmationDialog(context, () {
                            if (selection.selectedIds().length > 1) {
                              sync.deleteMany(
                                senderId: userId,
                                docIds: selection.selectedIds(),
                              );
                            } else {
                              sync.deleteMessage(
                                senderId: userId,
                                docId: selection.selectedIds()[0],
                              );
                            }
                            selection.clear();
                            Navigator.of(context).pop(true);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black87),
                        onPressed: selection.clear,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('users').doc(widget.clientId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        if (!isAdmin) return const SizedBox.shrink();

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final isTyping = data?['isTyping'] ?? false;

        if (!isTyping) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 18, right: 18, bottom: 6),
          alignment: Alignment.centerLeft,
          child: const Text(
            'typing...',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showEmojiPicker) {
          setState(() {
            _showEmojiPicker = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2),
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            Positioned.fill(
              child: _hasPickedMedia
                  ? ComposerMediaPreview(
                      pickedImageFile: pickedImageFile,
                      pickedVideoFile: pickedVideoFile,
                      onRemoveImage: () {
                        setState(() {
                          pickedImageFile = null;
                        });
                      },
                      onRemoveVideo: () {
                        setState(() {
                          pickedVideoFile = null;
                        });
                      },
                    )
                  : MessageListView(
                      chatId: chatId,
                      newestKey: _newestKey,
                      sender: sender,
                      selection: selection,
                      formatTimestamp: formatTimestamp,
                      isSending: isSending,
                      pickedImageFile: pickedImageFile,
                      pickedVideoFile: pickedVideoFile,
                      store: store,
                      bottomInset: _showEmojiPicker
                          ? (_isEmojiSearchVisible ? 220 : 420)
                          : 110,
                      senderNameForRemoteSide: isAdmin
                          ? (widget.clientName ?? 'Client')
                          : supportDisplayName,
                      onLoadOlderMessages: () async {
                        await sync.loadOlder(userId, chatId);
                      },
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypingIndicator(),
                  MessageInput(
                    controller: messageController,
                    focusNode: _messageFocusNode,
                    onPickImage: pickImage,
                    onPickVideo: pickVideo,
                    onRemoveImage: () {
                      setState(() {
                        pickedImageFile = null;
                      });
                    },
                    onRemoveVideo: () {
                      setState(() {
                        pickedVideoFile = null;
                      });
                    },
                    onSend: sendHelpMessage,
                    onToggleEmojis: toggleEmojiPicker,
                    hideEmojiPicker: hideEmojiPicker,
                    onTyping: onTyping,
                    pickedImageFile: pickedImageFile,
                    pickedVideoFile: pickedVideoFile,
                    isSending: isSending,
                    isEmojiPickerVisible: _showEmojiPicker,
                    isOverlayMode: _hasPickedMedia,
                  ),
                  _buildEmojiPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageListView extends StatefulWidget {
  final String chatId;
  final GlobalKey newestKey;
  final String sender;
  final SelectionController selection;
  final String Function(DateTime) formatTimestamp;
  final bool isSending;
  final String? pickedImageFile;
  final String? pickedVideoFile;
  final LocalChatStore store;
  final double bottomInset;
  final bool alwaysSnapToBottomOnNewMessage;
  final Future<void> Function()? onLoadOlderMessages;
  final String senderNameForRemoteSide;

  const MessageListView({
    super.key,
    required this.chatId,
    required this.newestKey,
    required this.sender,
    required this.selection,
    required this.formatTimestamp,
    required this.isSending,
    required this.pickedImageFile,
    required this.pickedVideoFile,
    required this.store,
    required this.bottomInset,
    required this.senderNameForRemoteSide,
    this.alwaysSnapToBottomOnNewMessage = true,
    this.onLoadOlderMessages,
  });

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _bottomSentinelKey = GlobalKey();

  int _prevCount = 0;
  String? _lastBottomMsgId;

  bool _autoScrollLocked = false;
  static const double _kAutoScrollThresholdPx = 120.0;
  static const double _kTopTriggerThresholdPx = 80.0;
  bool _isLoadingOlder = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!widget.alwaysSnapToBottomOnNewMessage &&
          _scrollController.hasClients) {
        final distanceFromBottom =
            _scrollController.position.maxScrollExtent -
            _scrollController.position.pixels;
        _autoScrollLocked = distanceFromBottom > _kAutoScrollThresholdPx;
      }

      if (_scrollController.hasClients &&
          _scrollController.position.pixels <= _kTopTriggerThresholdPx &&
          !_isLoadingOlder &&
          widget.onLoadOlderMessages != null) {
        _triggerLoadOlder();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureBottomVisible());
  }

  Future<void> _triggerLoadOlder() async {
    if (widget.onLoadOlderMessages == null) return;
    setState(() => _isLoadingOlder = true);
    try {
      await widget.onLoadOlderMessages!.call();
    } finally {
      if (mounted) {
        setState(() => _isLoadingOlder = false);
      }
    }
  }

  @override
  void didUpdateWidget(covariant MessageListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSending && !oldWidget.isSending) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureBottomVisible(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureBottomVisible() async {
    if (!mounted) return;
    if (!widget.alwaysSnapToBottomOnNewMessage && _autoScrollLocked) return;

    await Future<void>.delayed(const Duration(milliseconds: 16));

    final ctx = _bottomSentinelKey.currentContext;
    if (ctx != null) {
      try {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 1.0,
        );
        return;
      } catch (_) {}
    }

    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isYesterday(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    return d == yesterday;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  bool _isInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final start = _startOfWeek(now);
    final end = start.add(const Duration(days: 7));
    final normalized = DateTime(date.year, date.month, date.day);
    return !normalized.isBefore(start) && normalized.isBefore(end);
  }

  String _formatDaySeparator(DateTime date) {
    if (_isToday(date)) return 'Today';
    if (_isYesterday(date)) return 'Yesterday';
    if (_isInCurrentWeek(date)) return DateFormat('EEEE').format(date);
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<List<Message>>(
          stream: widget.store.watchLatest(widget.chatId, limit: 50),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final msgs = snapshot.data ?? const <Message>[];
            if (msgs.isEmpty) {
              return const SizedBox.shrink();
            }

            final currentBottomId = msgs.last.docId;
            final countChanged = msgs.length != _prevCount;
            final bottomChanged = currentBottomId != _lastBottomMsgId;

            if (countChanged || bottomChanged) {
              _prevCount = msgs.length;
              _lastBottomMsgId = currentBottomId;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _ensureBottomVisible(),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(10, 14, 10, widget.bottomInset),
              itemCount: msgs.length + 1,
              itemBuilder: (context, index) {
                if (index == msgs.length) {
                  return SizedBox(
                    key: _bottomSentinelKey,
                    height: 1,
                    width: MediaQuery.of(context).size.width,
                  );
                }

                final message = msgs[index];
                final msgId = message.docId;
                final ts = message.createdAt;
                final isMine = message.sender == widget.sender;
                final isLast = index == msgs.length - 1;

                final previous = index > 0 ? msgs[index - 1] : null;

                final showDaySeparator =
                    previous == null || !_isSameDay(previous.createdAt, ts);

                final isSameSenderAsPrevious =
                    previous != null &&
                    previous.sender == message.sender &&
                    _isSameDay(previous.createdAt, ts);

                final showSenderLabelForThisBubble =
                    !isMine &&
                    (previous == null || !_isSameDay(previous.createdAt, ts));

                return ValueListenableBuilder<bool>(
                  valueListenable: widget.selection.listen(msgId),
                  builder: (context, isSelected, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDaySeparator)
                          Padding(
                            padding: const EdgeInsets.only(top: 18, bottom: 14),
                            child: Center(
                              child: Text(
                                _formatDaySeparator(ts),
                                style: const TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        MessageBubble(
                          key: isLast ? widget.newestKey : ValueKey(msgId),
                          message: message,
                          timestamp: widget.formatTimestamp(ts),
                          isMine: isMine,
                          isFirstSequence: !isSameSenderAsPrevious,
                          isSelected: isSelected,
                          showSenderLabel: showSenderLabelForThisBubble,
                          senderLabel: widget.senderNameForRemoteSide,
                          onLongPress: () => widget.selection.toggle(msgId),
                          onTap: () {
                            if (widget.selection.count.value > 0) {
                              widget.selection.toggle(msgId);
                            }
                          },
                          store: widget.store,
                        ),
                        if (isLast &&
                            widget.isSending &&
                            (widget.pickedImageFile != null ||
                                widget.pickedVideoFile != null))
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(right: 12, top: 8),
                              height: 92,
                              width: 92,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Stack(
                                children: [
                                  Center(
                                    child: Icon(
                                      Icons.file_copy_rounded,
                                      color: Colors.grey,
                                      size: 42,
                                    ),
                                  ),
                                  Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
        if (_isLoadingOlder)
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}

typedef SendCallback = Future<void> Function();

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onRemoveImage;
  final VoidCallback onRemoveVideo;
  final SendCallback onSend;
  final VoidCallback onToggleEmojis;
  final VoidCallback hideEmojiPicker;
  final FocusNode focusNode;
  final bool isEmojiPickerVisible;
  final void Function(String) onTyping;
  final String? pickedImageFile;
  final String? pickedVideoFile;
  final bool isSending;
  final bool isOverlayMode;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onRemoveImage,
    required this.onRemoveVideo,
    required this.onSend,
    required this.onTyping,
    required this.pickedImageFile,
    required this.pickedVideoFile,
    required this.isSending,
    this.isOverlayMode = false,
    required this.onToggleEmojis,
    required this.focusNode,
    required this.isEmojiPickerVisible,
    required this.hideEmojiPicker,
  });

  @override
  Widget build(BuildContext context) {
    final sendEnabled =
        !isSending &&
        (controller.text.trim().isNotEmpty ||
            pickedImageFile != null ||
            pickedVideoFile != null);

    return Container(
      color: isOverlayMode ? Colors.transparent : const Color(0xFFF2F2F2),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  boxShadow: isOverlayMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        Methods().showMediaPickerDialog(
                          context,
                          onPickImage,
                          onPickVideo,
                        );
                      },
                      icon: const Icon(
                        Icons.attach_file_rounded,
                        color: Color(0xFF8F8F8F),
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onTap: hideEmojiPicker,
                          onChanged: onTyping,
                          minLines: 1,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            hintStyle: TextStyle(
                              color: Color(0xFF9B9B9B),
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(
                              top: 14,
                              bottom: 14,
                              right: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: onToggleEmojis,
                      icon: Icon(
                        isEmojiPickerVisible
                            ? Icons.keyboard_rounded
                            : Icons.sentiment_satisfied_alt_rounded,
                        color: const Color(0xFF8F8F8F),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: sendEnabled ? onSend : null,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: sendEnabled
                      ? const Color(0xFFE8F7FC)
                      : const Color(0xFFE6E6E6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.send_rounded,
                          size: 26,
                          color: sendEnabled
                              ? const Color(0xFF2AAFC9)
                              : const Color(0xFFB8B8B8),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComposerMediaPreview extends StatelessWidget {
  final String? pickedImageFile;
  final String? pickedVideoFile;
  final VoidCallback onRemoveImage;
  final VoidCallback onRemoveVideo;

  const ComposerMediaPreview({
    super.key,
    required this.pickedImageFile,
    required this.pickedVideoFile,
    required this.onRemoveImage,
    required this.onRemoveVideo,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        children: [
          Positioned.fill(
            child: pickedImageFile != null
                ? GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imagePath: pickedImageFile!,
                          ),
                        ),
                      );
                    },
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Image.file(
                          File(pickedImageFile!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                : pickedVideoFile != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 110),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: VideoPreview(
                          filePath: pickedVideoFile!,
                          onRemove: onRemoveVideo,
                          forBubble: true,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: GestureDetector(
              onTap: pickedImageFile != null ? onRemoveImage : onRemoveVideo,
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
                child: SizedBox(height: 130),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiSearchModeListener extends StatefulWidget {
  final Config config;
  final EmojiViewState state;
  final VoidCallback showEmojiView;
  final VoidCallback onSearchOpened;
  final VoidCallback onSearchClosed;

  const _EmojiSearchModeListener({
    required this.config,
    required this.state,
    required this.showEmojiView,
    required this.onSearchOpened,
    required this.onSearchClosed,
  });

  @override
  State<_EmojiSearchModeListener> createState() =>
      _EmojiSearchModeListenerState();
}

class _EmojiSearchModeListenerState extends State<_EmojiSearchModeListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSearchOpened();
      }
    });
  }

  @override
  void dispose() {
    widget.onSearchClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultSearchView(widget.config, widget.state, widget.showEmojiView);
  }
}

class ImagePreview extends StatefulWidget {
  final String filePath;
  final VoidCallback onRemove;

  const ImagePreview({
    super.key,
    required this.filePath,
    required this.onRemove,
  });

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(imagePath: widget.filePath),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Stack(
          children: [
            Hero(
              tag: widget.filePath,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(widget.filePath),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPreview extends StatefulWidget {
  final String filePath;
  final VoidCallback onRemove;
  final VoidCallback? downloadVideo;
  final bool isSending;
  final bool forBubble;

  const VideoPreview({
    super.key,
    required this.filePath,
    required this.onRemove,
    this.isSending = false,
    this.forBubble = false,
    this.downloadVideo,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.filePath.startsWith('http') && widget.filePath.isNotEmpty) {
      _initController(widget.filePath);
    }
  }

  @override
  void didUpdateWidget(VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _disposeController();
      if (!widget.filePath.startsWith('http') && widget.filePath.isNotEmpty) {
        _initController(widget.filePath);
      }
    }
  }

  Future<void> _initController(String path) async {
    try {
      final isLocal = !path.startsWith('http');
      final controller = isLocal
          ? VideoPlayerController.file(File(path))
          : VideoPlayerController.networkUrl(Uri.parse(path));

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('🎥 Video init error: $e');
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrl = widget.filePath.startsWith("http");

    return Padding(
      padding: widget.forBubble
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Stack(
        children: [
          if (isUrl)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 180,
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.videocam,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
            )
          else if (_isInitialized && _controller != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const CircularProgressIndicator(),
            ),
          if (!widget.forBubble)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (isUrl) {
                    Fluttertoast.showToast(msg: 'Video not downloaded');
                    return;
                  }

                  if (!widget.isSending) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FullScreenVideoPlayer(filePath: widget.filePath),
                      ),
                    );
                  } else {
                    Fluttertoast.showToast(msg: 'Video still uploading...');
                  }
                },
                child: widget.isSending
                    ? const CircularProgressIndicator()
                    : const Icon(
                        Icons.play_circle,
                        color: Colors.white70,
                        size: 52,
                      ),
              ),
            ),
          ),
          if (isUrl)
            Positioned(
              bottom: 8,
              right: 10,
              child: GestureDetector(
                onTap: () async {
                  widget.downloadVideo?.call();
                  setState(() => isDownloading = true);
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.download,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final String filePath;

  const FullScreenVideoPlayer({super.key, required this.filePath});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isDragging = false;
  Duration _dragPosition = Duration.zero;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    if (widget.filePath.startsWith("http")) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.filePath))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _controller.play();
          _startHideTimer();
        });
    } else {
      _controller = VideoPlayerController.file(File(widget.filePath))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _controller.play();
          _startHideTimer();
        });
    }

    _controller.addListener(() {
      if (!_isDragging && mounted) setState(() {});
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);

    if (h > 0) {
      return '${twoDigits(h)}:${twoDigits(m)}:${twoDigits(s)}';
    }
    return '${twoDigits(m)}:${twoDigits(s)}';
  }

  void _forward() async {
    final pos = await _controller.position ?? Duration.zero;
    final target = pos + const Duration(seconds: 10);
    await _controller.seekTo(target);
  }

  void _backward() async {
    final pos = await _controller.position ?? Duration.zero;
    final target = pos - const Duration(seconds: 10);
    await _controller.seekTo(target < Duration.zero ? Duration.zero : target);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
                if (_showControls) _startHideTimer();
              },
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  if (_showControls)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Slider(
                              value: _isDragging
                                  ? _dragPosition.inMilliseconds.toDouble()
                                  : _controller.value.position.inMilliseconds
                                        .toDouble(),
                              min: 0,
                              max: _controller.value.duration.inMilliseconds
                                  .toDouble()
                                  .clamp(1, double.infinity),
                              onChangeStart: (_) {
                                setState(() => _isDragging = true);
                              },
                              onChanged: (value) {
                                setState(() {
                                  _dragPosition = Duration(
                                    milliseconds: value.toInt(),
                                  );
                                });
                              },
                              onChangeEnd: (value) async {
                                final newPos = Duration(
                                  milliseconds: value.toInt(),
                                );
                                await _controller.seekTo(newPos);
                                setState(() => _isDragging = false);
                                _startHideTimer();
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_controller.value.position),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    _formatDuration(_controller.value.duration),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.replay_10,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: _backward,
                                ),
                                IconButton(
                                  icon: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _controller.value.isPlaying
                                          ? _controller.pause()
                                          : _controller.play();
                                    });
                                    _startHideTimer();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.forward_10,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  onPressed: _forward,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  if (_showControls)
                    Positioned(
                      top: 40,
                      left: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final String imagePath;

  const FullScreenImageViewer({super.key, required this.imagePath});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  double _dragOffset = 0.0;
  static const double _closeThreshold = 50.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dy;
          });
        },
        onVerticalDragEnd: (details) {
          if (_dragOffset > _closeThreshold) {
            Navigator.pop(context);
          } else {
            setState(() => _dragOffset = 0.0);
          }
        },
        child: Stack(
          children: [
            Hero(
              tag: widget.imagePath,
              child: PhotoView(
                imageProvider: widget.imagePath.startsWith('http')
                    ? CachedNetworkImageProvider(widget.imagePath)
                    : FileImage(File(widget.imagePath)) as ImageProvider,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3.0,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
