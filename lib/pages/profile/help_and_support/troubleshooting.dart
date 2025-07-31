import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/pages/home/booking%20flow/services_screen.dart';
import 'package:omeeowash/pages/home_screen_with_nav.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

class Troubleshooting extends StatefulWidget {
  const Troubleshooting({super.key});

  @override
  State<Troubleshooting> createState() => _TroubleshootingState();
}

class _TroubleshootingState extends State<Troubleshooting> {
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
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [TroubleshootingTopBar(), TroubleshootingPage()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TroubleshootingPage extends StatefulWidget {
  const TroubleshootingPage({super.key});

  @override
  State<TroubleshootingPage> createState() => _TroubleshootingPageState();
}

class _TroubleshootingPageState extends State<TroubleshootingPage> {
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

  Widget _buildHowToBook({
    required IconData icon,
    required String title,
    required String subtitle,
    required String number,
    required VoidCallback onPressed,
    Color iconColor = AppColors.secondary,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // So text can wrap down
        children: [
          CircleAvatar(
            backgroundColor: iconColor,
            radius: 15,
            child: CustomText(
              text: number,
              textColor: Theme.of(context).textTheme.headlineLarge?.color,
              textWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(32, 137, 43, 226),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            // Ensures Column can wrap inside remaining space
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  softWrap: true,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: TextSizes.bodyText1,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: TextSizes.bodyText1,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget BookNow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    Color iconColor = AppColors.secondary,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      width: double.infinity,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => const ServicesScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: const [
                    Color(0xFF6D66F6), // Right (periwinkle blue-purple)
                    Color(0xFFA558F2), // Left (light pink-purple)
                  ],
                ),
              ),
              child: CustomText(
                text: title,
                textColor: Theme.of(context).textTheme.headlineLarge?.color,
                textSize: TextSizes.bodyText1,
                textWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = AppColors.secondary,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: TextSizes.bodyText1,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: TextSizes.bodyText1,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: Icon(FontAwesomeIcons.chevronRight, size: IconSizes.small),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: TextSizes.subtitle2,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
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

  Widget BookNowNoGradient({
    required String title,
    required VoidCallback onPressed,
    required EdgeInsets margin,
    required Color backgroundColor,
    Color iconColor = AppColors.secondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      margin: margin,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: backgroundColor,
      ),
      child: CustomText(
        text: title,
        textColor: Theme.of(context).textTheme.headlineLarge?.color,
        textSize: TextSizes.bodyText3,
        textWeight: FontWeight.bold,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildIconCard(
    String title,
    IconData icon,
    String subtitle,
    List<Widget> children,
  ) {
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: IconSizes.midSmall,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: TextSizes.subtitle2,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
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
    final List<String> howPricingWorks = [
      'Restart the app',
      'Check your internet connection',
      'Update the app to the latest version',
      'Clear app cache (Android only)',
      'Restart your device',
    ];
    return Column(
      children: [
        _buildIconCard("Try these quick fixes first:", Icons.warning, "", [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var point in howPricingWorks)
                  Row(
                    children: [
                      Icon(Icons.do_not_disturb_on_sharp, size: 8),
                      const SizedBox(width: 5),
                      CustomText(
                        text: point,
                        textColor: Theme.of(context).textTheme.bodyLarge?.color,
                        textSize: TextSizes.bodyText1,
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ]),
        _buildIconCard("App Issues", Icons.phone_android, "", [
          FaqScreen(
            faqs: [
              FaqItem(
                question: "App is crashing or freezing",
                answer:
                    "Try force-closing the app and reopening it. If the issue persists, restart your phone or reinstall the app.",
              ),
              FaqItem(
                question: "Can't login to my account",
                answer:
                    "Check your email and password. Use 'Forgot Password' if needed. Ensure you're using the correct email address.",
              ),
              FaqItem(
                question: "App is runnign slowly",
                answer:
                    "Close other apps running in the background. Check your phone's storage space and ensure you have a stable internet connection.",
              ),
            ],
          ),
        ]),
        _buildIconCard("Connection Issues", Icons.wifi, "", [
          FaqScreen(
            faqs: [
              FaqItem(
                question: "Can't connect to the internet",
                answer:
                    "Check your WiFi or mobile data connection. Try switching between WiFi and mobile data to see if one works better.",
              ),
              FaqItem(
                question: "Location services not working",
                answer:
                    "Enable location permissions for the app in your phone's settings. Make sure GPS is turned on.",
              ),
              FaqItem(
                question: "Unable to load booking information",
                answer:
                    "Check your internet connection and try refreshing the app. If the issue persists, contact support.",
              ),
            ],
          ),
        ]),
        _buildIconCard("Payment Issues", Icons.payment, "", [
          FaqScreen(
            faqs: [
              FaqItem(
                question: "Payment failed or declined",
                answer:
                    "Check that your card details are correct and that you have sufficient funds. Try a different payment method or contact your bank.",
              ),
              FaqItem(
                question: "Charged but booking not confirmed",
                answer:
                    "Check your email for confirmation. If you don't receive one within 15 minutes, contact support with your payment reference.",
              ),
              FaqItem(
                question: "Can't add a payment method",
                answer:
                    "Ensure your card details are correct. Check that your card supports online payments and try again.",
              ),
            ],
          ),
        ]),
        _buildIconCard("Booking Issues", Icons.calendar_month, "", [
          FaqScreen(
            faqs: [
              FaqItem(
                question: "Can't find available time slots",
                answer:
                    "Try selecting a different date or location. Popular times fill up quickly, so book in advance when possible.",
              ),
              FaqItem(
                question: "Booking confirmation not received",
                answer:
                    "Check your email (including spam folder). You can also view your bookings in the app under 'My Bookings'.",
              ),
              FaqItem(
                question: "Need to cancel last-minute",
                answer:
                    "You can cancel up to 2 hours before your appointment. For emergency cancellations, call our support line.",
              ),
            ],
          ),
        ]),

        _buildCard("Still Need Help?", "", [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: CustomText(
              text:
                  "If you couldn't find a solution above, our support team is here to help",
              textColor: Theme.of(context).textTheme.bodyLarge?.color,
              textSize: TextSizes.bodyText1,
            ),
          ),
          const SizedBox(height: 10),
          BookNow(
            icon: Icons.phone_in_talk_outlined,
            title: "Start Live Chat",
            subtitle: "View My Bookings",
            onPressed: () {},
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: BookNowNoGradient(
                  backgroundColor: // Right (periwinkle blue-purple)
                  Color.fromARGB(
                    251,
                    165,
                    88,
                    242,
                  ),
                  margin: EdgeInsets.only(left: 10, right: 5, bottom: 10),
                  title: "Call Support",
                  onPressed: () {},
                ),
              ),
              Expanded(
                child: BookNowNoGradient(
                  backgroundColor: Color(0xFF6D66F6),
                  margin: EdgeInsets.only(left: 5, right: 10, bottom: 10),
                  title: "Email Us",
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }
}

class TroubleshootingTopBar extends StatelessWidget {
  const TroubleshootingTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        text: 'Troubleshooting',
                        textColor: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.color,
                        textSize: TextSizes.heading2,
                        textWeight: FontWeight.w900,
                      ),
                    ],
                  ),
                  CustomText(
                    text: 'Common issues and solutions',
                    textColor: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.color,
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

class FaqScreen extends StatefulWidget {
  final List<FaqItem> faqs;
  const FaqScreen({super.key, required this.faqs});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: ExpansionPanelList.radio(
        elevation: 0,
        dividerColor: Theme.of(context).textTheme.bodyMedium?.color,
        children: widget.faqs.map<ExpansionPanelRadio>((faq) {
          return ExpansionPanelRadio(
            value: faq.question,
            headerBuilder: (context, isExpanded) {
              return ListTile(
                title: Text(
                  faq.question,
                  style: TextStyle(
                    fontSize: TextSizes.bodyText1,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              );
            },
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Text(
                faq.answer,
                style: TextStyle(
                  fontSize: TextSizes.bodyText1,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FaqItem {
  final String question;
  final String answer;

  FaqItem({required this.question, required this.answer});
}
