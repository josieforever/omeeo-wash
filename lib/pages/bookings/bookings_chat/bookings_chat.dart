import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omeeowash/pages/bookings/bookings_chat/msg_bubble.dart';
import 'package:omeeowash/pages/profile/help/live_chat/app.config.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';

class BookingsChat extends StatefulWidget {
  final String bookingRecieverId;
  final String bookingId;
  final String bookingSenderId;

  const BookingsChat({
    super.key,
    required this.bookingId,
    required this.bookingSenderId,
    required this.bookingRecieverId,
  });

  @override
  State<BookingsChat> createState() => _BookingsChatState();
}

class _BookingsChatState extends State<BookingsChat> {
  final _firestore = FirebaseFirestore.instance;
  final _me = FirebaseAuth.instance.currentUser!;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Multi-select for delete
  final Set<String> _selectedIds = <String>{};
  bool get _selectionMode => _selectedIds.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _msgsRef => _firestore
      .collection('bookings')
      .doc(widget.bookingId)
      .collection('booking_chat');

  String _fmt(DateTime? dt) =>
      dt == null ? '' : DateFormat('h:mm a').format(dt);

  bool _isFirstSequence(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    int i,
  ) {
    if (i == 0) return true;
    final prev = docs[i - 1].data();
    final curr = docs[i].data();

    final prevSender = prev['senderId'];
    final currSender = curr['senderId'];

    final prevTs = (prev['createdAt'] as Timestamp?)?.toDate();
    final currTs = (curr['createdAt'] as Timestamp?)?.toDate();

    final differentSender = prevSender != currSender;
    final timeBreak = (prevTs != null && currTs != null)
        ? currTs.difference(prevTs).inMinutes > 4
        : false;

    return differentSender || timeBreak;
  }

  bool _canDelete(Map<String, dynamic> m) {
    return (m['senderId'] as String?) == _me.uid;
  }

  void _toggleSelect(String docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
      } else {
        _selectedIds.add(docId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _confirmAndDeleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete selected messages?'),
        content: Text(
          'This will permanently delete ${_selectedIds.length} message(s).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final batch = _firestore.batch();
      for (final id in _selectedIds) {
        batch.delete(_msgsRef.doc(id));
      }
      await batch.commit();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    } finally {
      _clearSelection();
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final myName =
        _me.displayName ??
        (_me.email != null ? _me.email!.split('@').first : 'You');

    await _msgsRef.add({
      'text': text,
      "bookingRecieverId": widget.bookingRecieverId,
      'senderId': _me.uid,
      'senderName': myName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  String username = "";
  String profilePhoto = "Unknown";
  Future<void> _getUsername() async {
    final isAdmin = AppConfig().isAdmin;
    final userId = !isAdmin ? widget.bookingRecieverId : widget.bookingSenderId;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final fetchedUsername = doc.data()?['name'];
        final fetchedProfilePhoto = doc.data()?['photoUrl'];
        setState(() {
          username = fetchedUsername ?? 'Unknown';
          profilePhoto = fetchedProfilePhoto ?? 'Unknown';
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching username: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getUsername();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarRadius = context.rw(18, min: 14, max: 18);
    final avatarDiameter = avatarRadius * 2;
    final avatarLoader = context.rw(16, min: 12, max: 16);
    final usernameLoader = context.rw(25, min: 18, max: 25);
    final messageInputMaxHeight = context.rh(120, min: 88, max: 140);
    final composerPaddingH = context.rw(12, min: 10, max: 16);
    final composerPaddingV = context.rh(8, min: 6, max: 10);
    final sendIconSize = context.rw(20, min: 16, max: 22);
    final sendPadding = context.rw(12, min: 10, max: 14);
    final sendRadius = context.rw(12, min: 10, max: 14);
    final avatarGap = context.rw(10, min: 6, max: 10);

    return Scaffold(
      backgroundColor: theme.colorScheme.inversePrimary,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.secondary,
        elevation: 1,
        leading: IconButton(
          icon: Icon(
            _selectionMode ? Icons.close : Icons.arrow_back,
            color: theme.colorScheme.primary,
          ),
          onPressed: () {
            if (_selectionMode) {
              _clearSelection();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: _selectionMode
            ? Text(
                '${_selectedIds.length} selected',
                style: TextStyle(color: theme.colorScheme.primary),
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: theme.colorScheme.secondary,
                    child: profilePhoto != "Unknown"
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(avatarRadius),
                            child: CachedNetworkImage(
                              imageUrl: profilePhoto,
                              width: avatarDiameter,
                              height: avatarDiameter,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => SizedBox(
                                width: avatarDiameter,
                                height: avatarDiameter,
                                child: Center(
                                  child: SizedBox(
                                    width: avatarLoader,
                                    height: avatarLoader,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => SizedBox(
                                width: avatarDiameter,
                                height: avatarDiameter,
                                child: const Icon(Icons.error),
                              ),
                            ),
                          )
                        : Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                  SizedBox(width: avatarGap),
                  username == ""
                      ? SizedBox(
                          width: usernameLoader,
                          height: usernameLoader,
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          username,
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ],
              ),
        actions: [
          if (_selectionMode)
            IconButton(
              tooltip: 'Delete selected',
              icon: Icon(Icons.delete, color: theme.colorScheme.primary),
              onPressed: _confirmAndDeleteSelected,
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: context.rh(8, min: 6, max: 10)),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _msgsRef
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snap.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: composerPaddingH,
                    vertical: composerPaddingV,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final m = doc.data();
                    final msgText = (m['text'] as String? ?? '').trim();
                    final ts = (m['createdAt'] as Timestamp?)?.toDate();
                    final isMe = (m['senderId'] as String?) == _me.uid;
                    final isFirst = _isFirstSequence(docs, i);
                    final isSelected = _selectedIds.contains(doc.id);

                    void handleLongPress() {
                      if (!_canDelete(m)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "You can only select your own messages to delete.",
                            ),
                          ),
                        );
                        return;
                      }
                      _toggleSelect(doc.id);
                    }

                    void handleTap() {
                      if (_selectionMode) {
                        if (_canDelete(m)) {
                          _toggleSelect(doc.id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "You can only select your own messages to delete.",
                              ),
                            ),
                          );
                        }
                      }
                    }

                    return MsgBubble(
                      // ✨ updated: `MsgBubble` now expects a plain string
                      text:
                          msgText, // <— if you kept the name `message` as String, rename to `message: msgText`
                      isPreviouseMessageMine: isMe,
                      isFirstSequence: isFirst,
                      timestamp: _fmt(ts),
                      isSelected: isSelected,
                      onLongPress: handleLongPress,
                      onTap: handleTap,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                composerPaddingH,
                composerPaddingV,
                composerPaddingH,
                context.rh(12, min: 10, max: 14),
              ),
              // keep composer comfortable on compact devices
              color: theme.colorScheme.inversePrimary,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          width: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: messageInputMaxHeight,
                        ),
                        child: TextField(
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          // onChanged: onTyping,
                          controller: _messageController,
                          maxLines: null,
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
                    // TextField(
                    //   controller: _messageController,
                    //   textInputAction: TextInputAction.send,
                    //   onSubmitted: (_) => _send(),
                    //   maxLines: 4,
                    //   minLines: 1,
                    //   decoration: InputDecoration(
                    //     hintText: 'Type a message…',
                    //     filled: true,
                    //     fillColor: theme.colorScheme.surface,
                    //     contentPadding: const EdgeInsets.symmetric(
                    //       horizontal: 12,
                    //       vertical: 10,
                    //     ),
                    //     border: OutlineInputBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //       borderSide: BorderSide.none,
                    //     ),
                    //   ),
                    // ),
                  ),
                  SizedBox(width: context.rw(8, min: 6, max: 10)),
                  InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(sendRadius),
                    child: Container(
                      padding: EdgeInsets.all(sendPadding),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(sendRadius),
                      ),
                      child: Icon(
                        Icons.send,
                        color: theme.colorScheme.onPrimary,
                        size: sendIconSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
