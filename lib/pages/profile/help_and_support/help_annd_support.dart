import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/pages/profile/help_and_support/booking_and_scheduling.dart';
import 'package:omeeowash/pages/profile/help_and_support/live_chat.dart';
import 'package:omeeowash/pages/profile/help_and_support/services_and_pricing.dart';
import 'package:omeeowash/pages/profile/help_and_support/troubleshooting.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

class HelpAndSupport extends StatefulWidget {
  const HelpAndSupport({super.key});

  @override
  State<HelpAndSupport> createState() => _HelpAndSupportState();
}

class _HelpAndSupportState extends State<HelpAndSupport> {
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
                children: [HelpAndSupportTopBar(), HelpAndSupportPage()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpAndSupportPage extends StatefulWidget {
  const HelpAndSupportPage({super.key});

  @override
  State<HelpAndSupportPage> createState() => _HelpAndSupportPageState();
}

class _HelpAndSupportPageState extends State<HelpAndSupportPage> {
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

  Widget _buildActionTab({
    required IconData icon,
    required String title,
    required String subtitle,
    required String infomation,
    required String buttonText,
    required VoidCallback onPressed,
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
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: iconColor),
              borderRadius: BorderRadius.circular(5),
              color: const Color.fromARGB(32, 137, 43, 226),
            ),
            child: GestureDetector(
              onTap: () => onPressed(),
              child: CustomText(
                text: buttonText,
                textColor: Theme.of(context).colorScheme.primary,
                textSize: TextSizes.bodyText1,
                textWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 2),
          CustomText(
            text: infomation,
            textColor: Theme.of(context).textTheme.bodyMedium?.color,
            textSize: TextSizes.bodyText2,
          ),
        ],
      ),
    );
  }

  Widget _emergencySupport({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    Color iconColor = AppColors.secondary,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.error),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: TextSizes.bodyText2,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: TextSizes.bodyText2,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).colorScheme.error,
        ),
        child: CustomText(
          text: buttonText,
          textColor: Theme.of(context).textTheme.headlineLarge?.color,
          textSize: TextSizes.bodyText1,
          textWeight: FontWeight.bold,
          textAlign: TextAlign.center,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCard("Contact Support", "", [
          _buildActionTab(
            icon: Icons.chat,
            title: "Live Chat",
            subtitle: "Chat with our support team",
            buttonText: 'Start Chat',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const LiveChat(),
                ),
              );
              print("Working....");
            },
            infomation: '24 Hours',
          ),
          Divider(indent: 15, endIndent: 15, thickness: 0.5),
          _buildActionTab(
            icon: Icons.phone_in_talk_outlined,
            title: "Phone Support",
            subtitle: "Call us for immediate help",
            buttonText: 'Call Now',
            onPressed: () {},
            infomation: 'Mon-Sun 6AM-10PM',
          ),
          Divider(indent: 15, endIndent: 15, thickness: 0.5),
          _buildActionTab(
            icon: Icons.email_outlined,
            title: "Email Support",
            subtitle: "Send us your questions",
            buttonText: 'Send Email',
            onPressed: () {},
            infomation: 'Response within 24h',
          ),
        ]),
        _buildCard("Frequently Asked Questions", "", [FaqScreen()]),
        _buildCard("Help Topics", "", [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookingAndScheduling()),
              );
            },
            child: _buildFAQ(
              icon: Icons.library_books_rounded,
              title: "Booking & Scheduling",
              subtitle: "Learn how to book and manage appointments",
            ),
          ),
          Divider(indent: 15, endIndent: 15, thickness: 0.5),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ServicesAndPricing()),
              );
            },
            child: _buildFAQ(
              icon: Icons.wb_incandescent_sharp,
              title: "Services & Pricing",
              subtitle: "Information about our wash packages",
            ),
          ),
          Divider(indent: 15, endIndent: 15, thickness: 0.5),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Troubleshooting()),
              );
            },
            child: _buildFAQ(
              icon: Icons.help,
              title: "Troubleshooting",
              subtitle: "Common issues and solutions",
            ),
          ),
        ]),
        _buildCard("Emergency", "", [
          _emergencySupport(
            icon: Icons.phone_in_talk_outlined,
            title: "Emergency Support",
            subtitle: "For urgent issues during service",
            buttonText: 'Call Emergency',
            onPressed: () {},
          ),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }
}

class HelpAndSupportTopBar extends StatelessWidget {
  const HelpAndSupportTopBar({super.key});

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
                        text: 'Help & Support',
                        textColor: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.color,
                        textSize: TextSizes.heading2,
                        textWeight: FontWeight.w900,
                      ),
                    ],
                  ),
                  CustomText(
                    text: 'Get assistance and find answers',
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
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<FaqItem> _faqs = [
    FaqItem(
      question: "How do I book a car wash?",
      answer:
          "Simply tap 'Book Now' on the home screen, select your service, choose date and time, add your location and vehicle details, then confirm payment. You'll receive a confirmation with all the details.",
    ),
    FaqItem(
      question: "What payment methods do you accept?",
      answer:
          "We accept all major credit cards (Visa, MasterCard, American Express), debit cards, Apple Pay, Google Pay, and cash payments on-site.",
    ),
    FaqItem(
      question: "Can I cancel or reschedule my booking?",
      answer:
          "Yes, you can cancel or reschedule up to 2 hours before your appointment time. Go to 'My Bookings' and select the booking you want to modify.",
    ),
    FaqItem(
      question: "How is pricing determined?",
      answer:
          "Pricing depends on the service type, vehicle size, and any add-ons you select. You'll see the exact price before confirming your booking.",
    ),
    FaqItem(
      question: "Do you provide mobile car wash services?",
      answer:
          "Yes! We come to your location for mobile services. Just enter your address during booking and we'll bring everything needed to wash your car.",
    ),
    FaqItem(
      question: "How long does a car wash take?",
      answer:
          "Basic wash takes 15-20 minutes, Premium wash takes 30-45 minutes, and Premium+ with wax takes 45-60 minutes. Exact duration is shown when you select a service.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: ExpansionPanelList.radio(
        elevation: 0,
        dividerColor: Theme.of(context).textTheme.bodyMedium?.color,
        children: _faqs.map<ExpansionPanelRadio>((faq) {
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
