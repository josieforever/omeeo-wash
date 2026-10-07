import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/notifications/notification_service.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/providers/user_provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: const [
            SettingsTopBar(),
            Expanded(child: SingleChildScrollView(child: SettingsPage())),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _buildTile({
    required String label,
    required String title,
    required String subtitle,
    required BuildContext context,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallPhone = constraints.maxWidth < 340;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isSmallPhone ? 14 : TextSizes.bodyText1,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isSmallPhone ? 12 : TextSizes.bodyText1,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          trailing: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isSmallPhone ? 100 : 130),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 6,
                horizontal: isSmallPhone ? 8 : 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: isSmallPhone ? 11 : TextSizes.bodyText2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required BuildContext context,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallPhone = constraints.maxWidth < 340;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 2,
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isSmallPhone ? 14 : TextSizes.bodyText2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isSmallPhone ? 12 : TextSizes.bodyText2,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          trailing: Transform.scale(
            scale: isSmallPhone ? 0.68 : 0.75,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.inversePrimary,
              activeTrackColor: CupertinoColors.systemGreen,
              inactiveTrackColor: const Color.fromARGB(255, 78, 78, 81),
              inactiveThumbColor: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
    required BuildContext context,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallPhone ? 12 : 16,
        vertical: 8,
      ),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF7F7F7),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isSmallPhone ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallPhone ? 6 : 7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: isSmallPhone ? 18 : 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isSmallPhone ? 16 : TextSizes.subtitle2,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, thickness: 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final settings = user.settings;
    final notificationSettings = user.notificationSettings;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            _buildCard(
              icon: Icons.language,
              title: "Language & Region",
              context: context,
              children: [
                _buildTile(
                  label: "English",
                  title: "Language",
                  subtitle: "App display language",
                  context: context,
                ),
                _buildSectionDivider(),
                _buildTile(
                  label: "Ghana",
                  title: "Region",
                  subtitle: "Format for dates, currency, and location",
                  context: context,
                ),
              ],
            ),
            _buildCard(
              icon: Icons.notifications_active_rounded,
              title: "Notifications",
              context: context,
              children: [
                _buildSwitchTile(
                  title: "Push Notifications",
                  subtitle: "Receive alerts directly on your device",
                  value: notificationSettings['push'] ?? false,
                  onChanged: (val) =>
                      userProvider.updateNotificationSetting('push', val),
                  context: context,
                ),
                _buildSectionDivider(),
                _buildSwitchTile(
                  title: "Booking Updates",
                  subtitle: "Get updates about pickup, washing, and delivery",
                  value: notificationSettings['bookingUpdates'] ?? false,
                  onChanged: (val) => userProvider.updateNotificationSetting(
                    'bookingUpdates',
                    val,
                  ),
                  context: context,
                ),
                _buildSectionDivider(),
                _buildSwitchTile(
                  title: "Promotions & Offers",
                  subtitle: "Receive discounts, promos, and special offers",
                  value: notificationSettings['promotions'] ?? false,
                  onChanged: (val) =>
                      userProvider.updateNotificationSetting('promotions', val),
                  context: context,
                ),
                _buildSectionDivider(),
                _buildSwitchTile(
                  title: "Email Notifications",
                  subtitle: "Receive receipts and important updates by email",
                  value: notificationSettings['email'] ?? false,
                  onChanged: (val) =>
                      userProvider.updateNotificationSetting('email', val),
                  context: context,
                ),
              ],
            ),
            _buildCard(
              icon: Icons.security,
              title: "Security & Privacy",
              context: context,
              children: [
                _buildSwitchTile(
                  title: "Auto Lock",
                  subtitle: "Lock app after 5 minutes of inactivity",
                  value: settings['autoLock'] ?? false,
                  onChanged: (val) =>
                      userProvider.updateSetting('autoLock', val),
                  context: context,
                ),
                _buildSectionDivider(),
                _buildSwitchTile(
                  title: "Biometric Authentication",
                  subtitle: "Use fingerprint or Face ID to unlock",
                  value: settings['biometricAuth'] ?? false,
                  onChanged: (val) =>
                      userProvider.updateSetting('biometricAuth', val),
                  context: context,
                ),
              ],
            ),
            _buildCard(
              icon: Icons.palette,
              title: "Appearance",
              context: context,
              children: [
                _buildSwitchTile(
                  title: "Dark Mode",
                  subtitle: "Use dark theme throughout the app",
                  value: settings['darkMode'] ?? false,
                  onChanged: (val) =>
                      userProvider.updateSetting('darkMode', val),
                  context: context,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: SignOut(
                textWidget1: 'Sign Out',
                textWidget2: 'Sign out of your account',
                icon: Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.error,
                ),
                scale: 1,
                onPressed: () async {
                  await NotificationService().removeToken();
                  if (!context.mounted) return;
                  await FirebaseService().signOut(context);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class SettingsTopBar extends StatelessWidget {
  const SettingsTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Padding(
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
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.primary,
                    size: 26,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Settings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
