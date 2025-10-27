import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:omeeowash/providers/user_provider.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSettingsTopBar(),
              SizedBox(height: 10),
              AppSettingsPage(),
            ],
          ),
        ),
      ),
    );
  }
}

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  Widget _buildTile({
    required String label,
    required String title,
    required String subtitle,
    required BuildContext context,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: TextSizes.bodyText1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: TextSizes.bodyText1,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
        child: CustomText(
          text: label,
          textColor: Theme.of(context).colorScheme.primary,
          textSize: TextSizes.bodyText2,
          textWeight: FontWeight.bold,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required BuildContext context,
  }) {
    return ListTile(
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
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.inversePrimary,
          activeTrackColor: CupertinoColors.systemGreen,
          inactiveTrackColor: const Color.fromARGB(255, 78, 78, 81),
          inactiveThumbColor: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
    );
  }

  Widget _buildCard(
    IconData icon,
    String title,
    String subtitle,
    List<Widget> children,
    BuildContext context,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: TextSizes.subtitle2,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final settings = user.settings;

    return Column(
      children: [
        _buildCard(Icons.language, "Language & Region", "", [
          _buildTile(
            label: "English",
            title: "Language",
            subtitle: "App display language",
            context: context,
          ),
          _buildTile(
            label: "United States",
            title: "Region",
            subtitle: "Format for dates, currency, etc.",
            context: context,
          ),
        ], context),
        _buildCard(Icons.security, "Security & Privacy", "", [
          _buildSwitchTile(
            title: "Auto Lock",
            subtitle: "Lock app after 5 minutes of inactivity",
            value: settings['autoLock'] ?? false,
            onChanged: (val) => userProvider.updateSetting('autoLock', val),
            context: context,
          ),
          _buildSwitchTile(
            title: "Biometric Authentication",
            subtitle: "Use fingerprint or face ID to unlock",
            value: settings['biometricAuth'] ?? false,
            onChanged: (val) =>
                userProvider.updateSetting('biometricAuth', val),
            context: context,
          ),
        ], context),
        _buildCard(Icons.palette, "Appearance", "", [
          _buildSwitchTile(
            title: "Dark Mode",
            subtitle: "Use dark theme throughout the app",
            value: settings['darkMode'] ?? false,
            onChanged: (val) => userProvider.updateSetting('darkMode', val),
            context: context,
          ),
        ], context),
        const SizedBox(height: 20),
      ],
    );
  }
}

class AppSettingsTopBar extends StatelessWidget {
  const AppSettingsTopBar({super.key});
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
                  CustomText(
                    text: 'App Settings',
                    textColor: Theme.of(context).colorScheme.primary,
                    textSize: TextSizes.heading2,
                    textWeight: FontWeight.w900,
                  ),
                  CustomText(
                    text: 'Manage your settings',
                    textColor: Theme.of(context).colorScheme.surface,
                    textSize: TextSizes.subtitle2,
                  ),
                ],
              ),
              GoBack(onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
