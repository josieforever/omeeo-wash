import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class Help extends StatefulWidget {
  const Help({super.key});

  @override
  State<Help> createState() => _HelpState();
}

class _HelpState extends State<Help> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: const [
            HelpTopBar(),
            Expanded(child: SingleChildScrollView(child: HelpPage())),
          ],
        ),
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Widget _buildFAQTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
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
      trailing: Icon(
        FontAwesomeIcons.chevronRight,
        size: IconSizes.small,
        color: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: Theme.of(context).colorScheme.inversePrimary,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: TextSizes.subtitle2,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSupportActionCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.inversePrimary,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Need more help?",
                    style: TextStyle(
                      fontSize: TextSizes.subtitle2,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "If you have an issue with pickup, delivery, payment, pricing, damaged items, or missing clothes, contact support immediately from here.",
              style: TextStyle(
                fontSize: TextSizes.bodyText1,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LiveSupportPlaceholderScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CustomText(
                        text: "Live Support",
                        textColor: Theme.of(context).colorScheme.inversePrimary,
                        textSize: TextSizes.bodyText1,
                        textWeight: FontWeight.w700,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportIssueScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                      child: CustomText(
                        text: "Report Issue",
                        textColor: Theme.of(context).colorScheme.primary,
                        textSize: TextSizes.bodyText1,
                        textWeight: FontWeight.w700,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCard(
          context,
          title: "Frequently Asked Questions",
          children: const [FaqScreen()],
        ),
        _buildCard(
          context,
          title: "Help Topics",
          children: [
            _buildFAQTile(
              context,
              icon: Icons.local_laundry_service_rounded,
              title: "How Lundri Works",
              subtitle: "Understand pickup, washing, payment, and delivery",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrderFlowHelpScreen(),
                  ),
                );
              },
            ),
            const Divider(indent: 15, endIndent: 15, thickness: 0.5),
            _buildFAQTile(
              context,
              icon: Icons.payments_rounded,
              title: "Pricing & Payments",
              subtitle: "Learn how estimated and final prices work",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PricingAndPaymentHelpScreen(),
                  ),
                );
              },
            ),
            const Divider(indent: 15, endIndent: 15, thickness: 0.5),
            _buildFAQTile(
              context,
              icon: Icons.delivery_dining_rounded,
              title: "Pickup, Riders & Tracking",
              subtitle: "Track riders and understand delivery updates",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RiderAndTrackingHelpScreen(),
                  ),
                );
              },
            ),
            const Divider(indent: 15, endIndent: 15, thickness: 0.5),
            _buildFAQTile(
              context,
              icon: Icons.cancel_schedule_send_rounded,
              title: "Cancellations & Order Problems",
              subtitle: "Know when you can cancel and how issues are handled",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CancellationsAndIssuesHelpScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        _buildSupportActionCard(context),
        const SizedBox(height: 20),
      ],
    );
  }
}

class HelpTopBar extends StatelessWidget {
  const HelpTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
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
                    size: 28,
                  ),
                ),
              ),
              Center(
                child: CustomText(
                  text: 'Help',
                  textColor: Theme.of(context).colorScheme.primary,
                  textSize: 21,
                  textWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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
      question: "How does Lundri work?",
      answer:
          "Lundri automatically matches your laundry request with an available laundry partner near you. Once a laundry accepts, a rider is assigned to pick up your clothes, deliver them to the laundry, and later return them to you after washing.",
    ),
    FaqItem(
      question: "Do I choose the laundry service myself?",
      answer:
          "No. Lundri automatically finds the best available laundry partner near your location based on distance, service type, availability, and response time.",
    ),
    FaqItem(
      question: "How is the final price calculated?",
      answer:
          "You will first see an estimated price. After the laundry receives and weighs your clothes, the laundry confirms the final amount. You must pay the final amount in the app before delivery begins.",
    ),
    FaqItem(
      question: "When do I pay?",
      answer:
          "Payment is made online after the laundry finishes processing your clothes and confirms the final amount. Delivery only starts after payment is completed.",
    ),
    FaqItem(
      question: "What happens if no laundry accepts my order?",
      answer:
          "Lundri automatically tries multiple laundry partners nearby. If no laundry accepts, you will be notified immediately and your order will not be charged.",
    ),
    FaqItem(
      question: "What happens if the rider does not arrive?",
      answer:
          "If a rider rejects the request or fails to arrive within the allowed time, Lundri automatically assigns another rider.",
    ),
    FaqItem(
      question: "Can I track my order?",
      answer:
          "Yes. You can track every stage of your order in real time, including when a laundry accepts, when a rider is on the way, when your clothes are being washed, and when they are out for delivery.",
    ),
    FaqItem(
      question: "Can I cancel my order?",
      answer:
          "You can cancel before a laundry partner accepts your request. Once pickup has started, cancellation may be restricted.",
    ),
    FaqItem(
      question: "What payment methods are supported?",
      answer:
          "Lundri supports online payments only, including Mobile Money, debit cards, and other supported digital payment methods.",
    ),
    FaqItem(
      question: "What if my clothes are missing or damaged?",
      answer:
          "Use the Support section immediately to report missing or damaged items. Lundri will review the issue with the assigned laundry partner and rider.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: ExpansionPanelList.radio(
        elevation: 0,
        dividerColor: Theme.of(context).colorScheme.surface,
        children: _faqs.map<ExpansionPanelRadio>((faq) {
          return ExpansionPanelRadio(
            backgroundColor: Theme.of(context).colorScheme.onSecondary,
            value: faq.question,
            headerBuilder: (context, isExpanded) {
              return Container(
                color: Theme.of(context).colorScheme.onSecondary,
                child: ListTile(
                  title: Text(
                    faq.question,
                    style: TextStyle(
                      fontSize: TextSizes.bodyText1,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
            body: Container(
              color: Theme.of(context).colorScheme.inversePrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

class HelpDetailScaffold extends StatelessWidget {
  final String title;
  final List<String> points;

  const HelpDetailScaffold({
    super.key,
    required this.title,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.onSecondary,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: points.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: const Color.fromARGB(255, 242, 88, 206),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    points[index],
                    style: TextStyle(
                      fontSize: TextSizes.bodyText1,
                      color: Theme.of(context).colorScheme.primary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrderFlowHelpScreen extends StatelessWidget {
  const OrderFlowHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScaffold(
      title: "How Lundri Works",
      points: [
        "Create your order by entering your pickup address, delivery address, laundry details, and any special instructions.",
        "Lundri automatically searches for a suitable laundry partner near you based on service type, availability, and response speed.",
        "Once a laundry partner accepts your order, the system begins searching for a rider to pick up your clothes.",
        "The rider collects your clothes and delivers them to the assigned laundry partner.",
        "The laundry partner receives, inspects, and processes your clothes.",
        "After inspection or weighing, the laundry confirms the final amount due.",
        "You pay online in the app before delivery begins.",
        "A delivery rider is assigned to return your cleaned clothes to you.",
      ],
    );
  }
}

class PricingAndPaymentHelpScreen extends StatelessWidget {
  const PricingAndPaymentHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScaffold(
      title: "Pricing & Payments",
      points: [
        "Lundri may show an estimated price when you place your order.",
        "The final price can change after the laundry partner receives and weighs or inspects your clothes.",
        "You will be notified once the final amount is ready.",
        "Payment is online only and must be completed before delivery starts.",
        "Supported methods can include Mobile Money, debit cards, and other available digital payment options in the app.",
        "If no laundry accepts your request, your order is not charged.",
      ],
    );
  }
}

class RiderAndTrackingHelpScreen extends StatelessWidget {
  const RiderAndTrackingHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScaffold(
      title: "Pickup, Riders & Tracking",
      points: [
        "Once your order is accepted by a laundry partner, Lundri searches for an available rider nearby.",
        "If a rider rejects or fails to arrive on time, another rider is automatically assigned.",
        "You can track order progress from rider assignment to pickup, washing, and delivery.",
        "You will receive status updates when the rider is on the way, when clothes are received by the laundry, and when delivery has started.",
        "Tracking helps you know where your order is without needing to call support.",
      ],
    );
  }
}

class CancellationsAndIssuesHelpScreen extends StatelessWidget {
  const CancellationsAndIssuesHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScaffold(
      title: "Cancellations & Order Problems",
      points: [
        "You may be able to cancel before a laundry partner accepts your order.",
        "Once pickup has started, cancellation may no longer be possible.",
        "If there is a delay, a missing item, damaged clothing, or a rider issue, report it immediately through support.",
        "Lundri reviews issues using the order details, assigned laundry partner, and rider activity.",
        "Fast reporting makes it easier to investigate and resolve problems properly.",
      ],
    );
  }
}

class LiveSupportPlaceholderScreen extends StatelessWidget {
  const LiveSupportPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScaffold(
      title: "Live Support",
      points: [
        "Connect this screen to your in-app live chat or customer support channel.",
        "Use it for urgent order issues, pricing disputes, delivery delays, missing items, or damaged clothes.",
      ],
    );
  }
}

class ReportIssueScreen extends StatelessWidget {
  const ReportIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScaffold(
      title: "Report Issue",
      points: [
        "Use this section to report order problems such as late pickup, delivery issues, wrong pricing, damaged clothes, or missing items.",
        "In your final version, this screen should let users select an order, choose an issue type, add notes, and upload photos if needed.",
      ],
    );
  }
}
