import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'help/live_chat/live_chat.dart';
import 'help/live_chat/methods.dart';

class AllSupportScreen extends StatelessWidget {
  final bool isAdmin;

  const AllSupportScreen({super.key, required this.isAdmin});

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri phoneUri = Uri.parse('tel:+233557112580');

    try {
      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer.')),
        );
      }
    }
  }

  Future<void> _sendSupportEmail(BuildContext context) async {
    final Uri emailUri = Uri.parse(
      'mailto:omeeogh@gmail.com?subject=Support%20Request',
    );

    try {
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        await Clipboard.setData(const ClipboardData(text: 'omeeogh@gmail.com'));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No email app found. Email address copied: omeeogh@gmail.com',
            ),
          ),
        );
      }
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: 'omeeogh@gmail.com'));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open email app. Email address copied: omeeogh@gmail.com',
            ),
          ),
        );
      }
    }
  }

  void _openLiveChat(BuildContext context) {
    customRoute(context, LiveChat(isAdmin: isAdmin));
  }

  Future<void> _handleSupportTap(BuildContext context, ChatItem chat) async {
    switch (chat.type) {
      case SupportActionType.liveChat:
        _openLiveChat(context);
        break;
      case SupportActionType.phone:
        await _makePhoneCall(context);
        break;
      case SupportActionType.email:
        await _sendSupportEmail(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chats = [
      ChatItem(
        title: 'Live Chat',
        subtitle: 'Chat with our support team.',
        iconData: Icons.headset_mic,
        type: SupportActionType.liveChat,
      ),
      ChatItem(
        title: 'Phone Support',
        subtitle: 'Call us for immediate help',
        iconData: Icons.phone,
        type: SupportActionType.phone,
      ),
      ChatItem(
        title: 'Email Support',
        subtitle: 'Send us an email',
        iconData: Icons.email_outlined,
        type: SupportActionType.email,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallPhone = constraints.maxWidth < 360;
            final horizontalPadding = isSmallPhone ? 12.0 : 16.0;

            return Column(
              children: [
                const SizedBox(height: 6),
                const _SupportTopBar(title: 'All chats'),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 4,
                        ),
                        itemCount: chats.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE3E3E3),
                        ),
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          return ChatTile(
                            chat: chat,
                            onTap: () => _handleSupportTap(context, chat),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SupportTopBar extends StatelessWidget {
  final String title;

  const _SupportTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 28,
                ),
              ),
            ),
            Center(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatTile extends StatelessWidget {
  final ChatItem chat;
  final VoidCallback? onTap;

  const ChatTile({super.key, required this.chat, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;

    final avatarSize = isSmallPhone ? 52.0 : 56.0;
    final iconSize = isSmallPhone ? 24.0 : 28.0;
    final titleSize = isSmallPhone ? 17.0 : 19.0;
    final subtitleSize = isSmallPhone ? 14.0 : 16.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isSmallPhone ? 12 : 14,
          horizontal: 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5F5F5),
                border: Border.all(color: const Color(0xFFE6E6E6), width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: Icon(
                chat.iconData,
                color: const Color(0xFF000000),
                size: iconSize,
              ),
            ),
            SizedBox(width: isSmallPhone ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A8A8A),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: isSmallPhone ? 22 : 24,
              color: const Color(0xFF8A8A8A),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatItem {
  final String title;
  final String subtitle;
  final IconData iconData;
  final SupportActionType type;

  ChatItem({
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.type,
  });
}

enum SupportActionType { liveChat, phone, email }
