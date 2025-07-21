import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
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
            children: [NotificationsTopBar(), NotificationSettingsPage()],
          ),
        ],
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
  // Notification Methods
  bool pushNotification = true;
  bool emailNotification = true;

  // Booking Updates
  bool bookingConfirmed = true;
  bool washStarted = true;
  bool washCompleted = true;

  // Payment Notifications
  bool paymentConfirmation = true;
  bool paymentIssues = true;

  // Promotions and Rewards
  bool promotionsAndOffers = true;
  bool loyaltyPoints = true;

  // App and System
  bool appUpdates = true;

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    Color iconColor = AppColors.secondary,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.white,
        activeTrackColor: AppColors.black,
        // trackColor: AppColors.white,
        // trackColor: Colors.red,
      ),
    );
  }

  Widget _buildCard(String title, String subtitle, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Text(subtitle, style: const TextStyle(color: Colors.grey)),
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
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.82,
      child: ListView(
        children: [
          _buildCard("Notification Methods", "", [
            _buildSwitchTile(
              icon: Icons.phone_android,
              title: "Push Notifications",
              subtitle: "Instant alerts on your device",
              value: pushNotification,
              onChanged: (val) => setState(() => pushNotification = val),
            ),
            _buildSwitchTile(
              icon: Icons.email_outlined,
              title: "Email",
              subtitle: "Updates sent to your inbox",
              value: emailNotification,
              onChanged: (val) => setState(() => emailNotification = val),
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
                value: bookingConfirmed,
                onChanged: (val) => setState(() => bookingConfirmed = val),
              ),
              _buildSwitchTile(
                icon: Icons.local_car_wash,
                title: "Wash Started",
                subtitle: "Know when your car wash begins",
                value: washStarted,
                onChanged: (val) => setState(() => washStarted = val),
              ),
              _buildSwitchTile(
                icon: Icons.check_circle_outline,
                title: "Wash Completed",
                subtitle: "Get notified when your wash is done",
                value: washCompleted,
                onChanged: (val) => setState(() => washCompleted = val),
              ),
            ],
          ),

          _buildCard("App & System", "Technical updates and announcements", [
            _buildSwitchTile(
              icon: FontAwesomeIcons.phone,
              title: "App Updates",
              subtitle: "New features and improvements",
              value: appUpdates,
              onChanged: (val) => setState(() => appUpdates = val),
            ),
          ]),
        ],
      ),
    );
  }
}

class NotificationsTopBar extends StatelessWidget {
  const NotificationsTopBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
        ),
      ),
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
                        textColor: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.color,
                        textSize: TextSizes.heading2,
                        textWeight: FontWeight.w900,
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                      Icon(FontAwesomeIcons.bell, color: Colors.white),
                    ],
                  ),
                  CustomText(
                    text: 'Manage how you recieve updates',
                    textColor: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.color,
                    textSize: TextSizes.subtitle2,
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
