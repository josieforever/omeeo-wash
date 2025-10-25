import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingsChat extends StatefulWidget {
  final String bookingId; // e.g. 'abc123'
  final String
  username; // title to show in AppBar (e.g. "Support Centre" or client's name)

  const BookingsChat({
    super.key,
    required this.bookingId,
    required this.username,
  });

  @override
  State<BookingsChat> createState() => _BookingsChatState();
}

class _BookingsChatState extends State<BookingsChat> {
  final _firestore = FirebaseFirestore.instance;
  final _me = FirebaseAuth.instance.currentUser!;
  final TextEditingController _messageController = TextEditingController();

  CollectionReference<Map<String, dynamic>> get _msgsRef => _firestore
      .collection('bookings')
      .doc(widget.bookingId)
      .collection('booking_chat');

  String _fmt(DateTime? dt) =>
      dt == null ? '' : DateFormat('h:mm a').format(dt);

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    // Use current user's displayName if available (falls back to email local-part or "You")
    final myName =
        _me.displayName ??
        (_me.email != null ? _me.email!.split('@').first : 'You');

    await _msgsRef.add({
      'text': text,
      'senderId': _me.uid,
      'senderName': myName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.username, // just the name you pass in
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
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

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data();
                    final msgText = (m['text'] as String? ?? '').trim();
                    final ts = (m['createdAt'] as Timestamp?)?.toDate();
                    final isMe = m['senderId'] == _me.uid;

                    return _TextBubble(
                      text: msgText.isEmpty ? ' ' : msgText,
                      timestamp: _fmt(ts),
                      isMe: isMe,
                      theme: Theme.of(context),
                    );
                  },
                );
              },
            ),
          ),

          // Input row (text-only)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: Theme.of(context).colorScheme.inversePrimary,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
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

class _TextBubble extends StatelessWidget {
  final String text;
  final String timestamp;
  final bool isMe;
  final ThemeData theme;

  const _TextBubble({
    required this.text,
    required this.timestamp,
    required this.isMe,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe
        ? theme.colorScheme.secondary
        : theme.colorScheme.primary;
    final textColor = isMe
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              timestamp,
              style: TextStyle(
                color: isMe
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.scrim,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
