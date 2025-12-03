import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/services_screen.dart';
import 'package:omeeowash/pages/home_screen_with_nav.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

class BookingAndScheduling extends StatefulWidget {
  const BookingAndScheduling({super.key});

  @override
  State<BookingAndScheduling> createState() => _BookingAndSchedulingState();
}

class _BookingAndSchedulingState extends State<BookingAndScheduling> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BookingAndSchedulingTopBar(),
              BookingAndSchedulingPage(),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingAndSchedulingPage extends StatefulWidget {
  const BookingAndSchedulingPage({super.key});

  @override
  State<BookingAndSchedulingPage> createState() =>
      _BookingAndSchedulingPageState();
}

class _BookingAndSchedulingPageState extends State<BookingAndSchedulingPage> {
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
  }) {
    Color iconColor = Theme.of(context).colorScheme.primary;
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
              color: Theme.of(context).colorScheme.secondary,
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: TextSizes.bodyText1,
                    color: Theme.of(context).colorScheme.surface,
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
  }) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      padding: EdgeInsets.symmetric(horizontal: 10),
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
                borderRadius: BorderRadius.circular(15),
                color: Theme.of(context).colorScheme.primary,
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
          const SizedBox(height: 15),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const HomeScreenWithNav(view: 'booking'),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Theme.of(context).colorScheme.secondary,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              child: CustomText(
                text: subtitle,
                textColor: Theme.of(context).colorScheme.primary,
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

  Widget _buildFAQ(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    Color iconColor = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: iconColor),
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
      trailing: Icon(FontAwesomeIcons.chevronRight, size: IconSizes.small),
    );
  }

  Widget _buildCard(String title, String subtitle, List<Widget> children) {
    return Card(
      color: Theme.of(context).colorScheme.inversePrimary,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        _buildCard("How to Book a Car Wash", "", [
          _buildHowToBook(
            icon: Icons.calendar_month,
            title: "Select Service",
            subtitle: "Choose from Basic or Premium wash packages",
            onPressed: () {},
            number: '1',
          ),
          Divider(indent: 15, endIndent: 15, thickness: 0.5),
          _buildHowToBook(
            icon: Icons.access_time,
            title: "Pick Date & TIme",
            subtitle: "Select yout prefered appointment slot",
            onPressed: () {},
            number: '2',
          ),
          Divider(indent: 15, endIndent: 15, thickness: 0.5),
          _buildHowToBook(
            icon: Icons.location_on,
            title: "Add Location",
            subtitle: "Enter your address for mobile service",
            onPressed: () {},
            number: '3',
          ),
          Divider(indent: 15, endIndent: 15, thickness: 0.5),
          _buildHowToBook(
            icon: Icons.payment_rounded,
            title: "Payment",
            subtitle: "Complete payment to confirm booking",
            onPressed: () {},
            number: '4',
          ),
        ]),
        _buildCard("Frequently Asked Questions", "", [FaqScreen()]),

        _buildCard("Quick Actions", "", [
          BookNow(
            icon: Icons.phone_in_talk_outlined,
            title: "Book Now",
            subtitle: "View My Bookings",
            onPressed: () {},
          ),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }
}

class BookingAndSchedulingTopBar extends StatelessWidget {
  const BookingAndSchedulingTopBar({super.key});

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
                        text: 'Booking & Scheduling',
                        textColor: Theme.of(context).colorScheme.primary,
                        textSize: TextSizes.heading2,
                        textWeight: FontWeight.w900,
                      ),
                    ],
                  ),
                  CustomText(
                    text: 'How to book and manage appointments',
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

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<FaqItem> _faqs = [
    FaqItem(
      question: "How do i view my bookings?",
      answer:
          "Go to the 'Bookings' tab on the main screen to see all your past and upcoming appointments.",
    ),
    FaqItem(
      question: "Can i modify my bookings?",
      answer:
          "Yes, tap on any upcoming booking and select 'Modify' to change date, time, or service type up to 2 hours before the appointment.",
    ),
    FaqItem(
      question: "How can i cancel a booking?",
      answer:
          "Open your booking details and tap 'Cancel Booking'. Cancellations made more than 2 hours in advance receive full refunds.",
    ),
    FaqItem(
      question: "WHat if i need to reschedule?",
      answer:
          "Use the 'Reschedule' option in your booking details. You can reschedule up to 2 hours before your appointment time.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.inversePrimary,
      margin: EdgeInsets.symmetric(horizontal: 15),
      child: ExpansionPanelList.radio(
        elevation: 0,
        dividerColor: Theme.of(context).colorScheme.surface,
        children: _faqs.map<ExpansionPanelRadio>((faq) {
          return ExpansionPanelRadio(
            backgroundColor: Theme.of(context).colorScheme.onSecondary,
            value: faq.question,
            headerBuilder: (context, isExpanded) {
              return ListTile(
                title: Text(
                  faq.question,
                  style: TextStyle(
                    fontSize: TextSizes.bodyText1,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            },
            body: Container(
              color: Theme.of(context).colorScheme.inversePrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Text(
                faq.answer,
                style: TextStyle(
                  fontSize: TextSizes.bodyText1,
                  color: Theme.of(context).colorScheme.surface,
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
