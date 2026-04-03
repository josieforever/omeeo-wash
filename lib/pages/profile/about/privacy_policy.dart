import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = _privacySections;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _PrivacyPolicyTopBar(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                itemCount: sections.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const _PrivacyHeader();
                  }

                  if (index == sections.length + 1) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Last Updated: April 2026',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A8A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  final section = sections[index - 1];
                  return _PrivacySectionCard(section: section);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPolicyTopBar extends StatelessWidget {
  const _PrivacyPolicyTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 28, color: Colors.black),
            ),
          ),
          const Center(
            child: Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyHeader extends StatelessWidget {
  const _PrivacyHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18, top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/lundri_logo_transparent_small.png',
            height: 50,
          ),

          const SizedBox(height: 30),
          const Text(
            'Lundri Privacy Notice',
            style: TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Lundri provides a mobile application that allows users to schedule laundry pickup, washing, ironing, and delivery services.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'We value your privacy and are committed to protecting your personal information. This Privacy Notice explains what information we collect, why we collect it, how we use it, and the choices you have.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Effective Date: April 2026',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8A8A8A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySectionCard extends StatelessWidget {
  final PrivacySection section;

  const _PrivacySectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...section.paragraphs.map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                paragraph,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.65,
                  color: Color(0xFF444444),
                ),
              ),
            ),
          ),
          if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: 2),
            ...section.bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Color(0xFF444444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PrivacySection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const PrivacySection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

const List<PrivacySection> _privacySections = [
  PrivacySection(
    title: '1. Who Operates Lundri?',
    paragraphs: [
      'Lundri is operated by Lundri, based in Accra, Ghana.',
      'If you have any questions about this Privacy Notice or how your information is handled, you may contact us at someeogh@gmail.com.',
    ],
  ),
  PrivacySection(
    title: '2. What Information We Collect',
    paragraphs: [
      'When you use Lundri, we may collect the following information:',
    ],
    bullets: [
      'Account Information: full name, phone number, email address, and profile photo if you choose to add one.',
      'Address Information: pickup address, delivery address, and saved locations such as Home, Work, or other custom addresses.',
      'Order Information: laundry service selected, pickup and delivery dates and times, special instructions or notes, order history, and photos uploaded for stains, damaged clothing, or special care requests.',
      'Payment Information: payment method selected and transaction references for mobile money, card, or wallet payments.',
      'Device and App Information: device type, operating system, app version, IP address, crash reports, error logs, and unique device identifiers.',
      'Location Information: with your permission, we may collect location data to help you choose pickup and delivery addresses, improve rider navigation, and suggest nearby saved locations.',
      'Communication Information: messages with support, calls or messages with your assigned rider or laundry partner, and your feedback, ratings, and reviews.',
    ],
  ),
  PrivacySection(
    title: '3. Why We Use Your Information',
    bullets: [
      'Create and manage your Lundri account.',
      'Arrange laundry pickup and delivery.',
      'Process and complete your orders.',
      'Contact you about your order status.',
      'Send pickup, washing, and delivery notifications.',
      'Process payments.',
      'Improve the Lundri app and customer experience.',
      'Detect fraud, misuse, or suspicious activity.',
      'Respond to customer support requests.',
      'Comply with legal obligations.',
    ],
  ),
  PrivacySection(
    title: '4. App Permissions',
    paragraphs: ['Lundri may request the following permissions:'],
    bullets: [
      'Camera: to take photos of laundry items, stains, receipts, or profile pictures.',
      'Photos and Storage: to upload photos already saved on your phone.',
      'Location: to help you choose your pickup and delivery address and to help riders reach you.',
      'Notifications: to send updates about pickup confirmation, rider arrival, laundry in progress, delivery updates, and promotions if enabled.',
      'Contacts (Optional): used only if you choose to send or receive laundry on behalf of another person.',
      'Microphone (Optional): used if voice notes or voice search are added in the future.',
      'Phone (Optional): used to allow direct calling between you and your rider or laundry partner.',
    ],
  ),
  PrivacySection(
    title: '5. Who We Share Your Information With',
    paragraphs: [
      'We only share your information when necessary to provide the service.',
    ],
    bullets: [
      'Laundry partners processing your clothes.',
      'Riders handling pickup and delivery.',
      'Payment providers processing your payments.',
      'Cloud hosting and analytics providers.',
      'Customer support tools and service providers.',
      'Government authorities or law enforcement if required by law.',
    ],
  ),
  PrivacySection(
    title: '6. How We Protect Your Information',
    paragraphs: [
      'We use reasonable technical and organisational measures to protect your information.',
    ],
    bullets: [
      'Secure servers.',
      'Encrypted connections.',
      'Restricted staff access.',
      'Secure payment processing.',
    ],
  ),
  PrivacySection(
    title: '7. How Long We Keep Your Information',
    paragraphs: [
      'We keep your information only as long as necessary to provide our services, maintain your account, meet legal or regulatory requirements, resolve disputes, or prevent fraud.',
      'If you delete your account, we may keep some information for a limited period where required by law or for security reasons.',
    ],
  ),
  PrivacySection(
    title: '8. Your Rights',
    paragraphs: [
      'Depending on your country and applicable laws, you may have the right to:',
    ],
    bullets: [
      'Access the information we hold about you.',
      'Correct inaccurate information.',
      'Delete your account and personal information.',
      'Withdraw consent for optional permissions.',
      'Turn off marketing notifications.',
      'Request a copy of your data.',
    ],
  ),
  PrivacySection(
    title: '9. Children’s Privacy',
    paragraphs: [
      'Lundri is not intended for children under 13 years old. We do not knowingly collect personal information from children.',
      'If we learn that a child under 13 has provided personal information, we will delete it as soon as possible.',
    ],
  ),
  PrivacySection(
    title: '10. Changes to This Privacy Notice',
    paragraphs: [
      'We may update this Privacy Notice from time to time.',
      'If we make major changes, we may notify you through the app, by email, or through a message inside Lundri. The latest version will always be available in the app.',
    ],
  ),
];
