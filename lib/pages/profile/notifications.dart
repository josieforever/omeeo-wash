import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NotificationsTopBar(),
              const SizedBox(height: 10),
              NotificationSettingsPage(),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late UserProvider userProvider;
  late UserModel user;

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    user = userProvider.user!;
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    final updatedUser = user.copyWith(
      notificationSettings: {...user.notificationSettings, key: value},
    );

    await userProvider.setUser(updatedUser);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(updatedUser.uid)
        .update({'notificationSettings': updatedUser.notificationSettings});

    setState(() => user = updatedUser);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String keyName,
  }) {
    final Color iconColor = Theme.of(context).colorScheme.primary;
    final value = user.notificationSettings[keyName] ?? true;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: TextSizes.bodyText2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: TextSizes.bodyText2,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
      trailing: Transform.scale(
        scale: 0.75,
        child: Switch(
          value: value,
          onChanged: (val) => _updateNotificationSetting(keyName, val),
          activeColor: Theme.of(context).colorScheme.inversePrimary,
          activeTrackColor: CupertinoColors.systemGreen,
          inactiveTrackColor: const Color.fromARGB(255, 78, 78, 81),
          inactiveThumbColor: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
    );
  }

  Widget _buildCard(String title, String subtitle, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: TextSizes.subtitle1,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCard("Notification Methods", "", [
          _buildSwitchTile(
            icon: Icons.phone_android,
            title: "Push Notifications",
            subtitle: "Instant alerts on your device",
            keyName: 'pushNotification',
          ),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: "Email",
            subtitle: "Updates sent to your inbox",
            keyName: 'emailNotification',
          ),
        ]),
        _buildCard(
          "Booking Updates",
          "Stay informed about your wash appointments",
          [
            _buildSwitchTile(
              icon: Icons.calendar_today,
              title: "Booking Confirmations",
              subtitle: "Get notified when your wash is confirmed",
              keyName: 'bookingConfirmed',
            ),
            _buildSwitchTile(
              icon: Icons.local_car_wash,
              title: "Wash Started",
              subtitle: "Know when your car wash begins",
              keyName: 'washStarted',
            ),
            _buildSwitchTile(
              icon: Icons.check_circle_outline,
              title: "Wash Completed",
              subtitle: "Get notified when your wash is done",
              keyName: 'washCompleted',
            ),
          ],
        ),
        _buildCard("App & System", "Technical updates and announcements", [
          _buildSwitchTile(
            icon: FontAwesomeIcons.phone,
            title: "App Updates",
            subtitle: "New features and improvements",
            keyName: 'appUpdates',
          ),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }
}

class NotificationsTopBar extends StatelessWidget {
  const NotificationsTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      CustomText(
                        text: 'Notifications',
                        textColor: Theme.of(context).colorScheme.primary,
                        textSize: TextSizes.heading2,
                        textWeight: FontWeight.w900,
                      ),
                    ],
                  ),
                  CustomText(
                    text: 'Manage how you recieve updates',
                    textColor: Theme.of(context).colorScheme.surface,
                    textSize: TextSizes.bodyText1,
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
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
