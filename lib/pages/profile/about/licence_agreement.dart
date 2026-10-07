import 'package:flutter/material.dart';

class LicenseAgreementScreen extends StatelessWidget {
  const LicenseAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _LicenseTopBar(title: 'License Agreement'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(theme),
                        const SizedBox(height: 20),
                        const _LicenseSection(
                          title: '1. General Provisions',
                          body:
                              '1.1. This License Agreement (“Agreement”) governs the use of the Lundri mobile application, website, and related services (collectively, the “Application”).\n\n'
                              '1.2. This Agreement is entered into between Lundri, the owner and operator of the Application (“Lundri”, “we”, “our”, or “us”), and any individual who downloads, installs, accesses, or uses the Application (“User”, “you”, or “your”).\n\n'
                              '1.3. By creating an account, using the Application, or placing an order through Lundri, you confirm that you have read and understood this Agreement, agree to comply with it, are at least 13 years old, and have the legal ability to enter into this Agreement.\n\n'
                              '1.4. Lundri grants you a limited, non-exclusive, non-transferable, revocable licence to use the Application for personal, non-commercial purposes in accordance with this Agreement.\n\n'
                              '1.5. You may only use the Application in the country where Lundri officially operates.',
                        ),
                        const _LicenseSection(
                          title: '2. Permitted Use',
                          body:
                              'You may use Lundri to create and manage your account, schedule laundry pickup and delivery, select laundry services and options, communicate with riders, laundry partners, and customer support, make payments, and view order history and saved addresses.\n\n'
                              'You agree to use the Application only for lawful purposes.',
                        ),
                        const _LicenseSection(
                          title: '3. Prohibited Use',
                          body:
                              'You must not use the Application for fraudulent, unlawful, or misleading purposes; create more than one account using false information; impersonate another person or use another person’s account; upload false, offensive, harmful, or illegal content; abuse riders, laundry partners, or support staff; attempt to interfere with or disrupt the Application; copy, modify, reverse engineer, decompile, or attempt to access the source code of the Application; use automated systems, bots, scripts, or software to access the Application; or use the Application in a way that may damage Lundri’s reputation or services.\n\n'
                              'Lundri may suspend or permanently disable your account if you violate these rules.',
                        ),
                        const _LicenseSection(
                          title: '4. User Account',
                          body:
                              '4.1. You are responsible for keeping your login details secure.\n\n'
                              '4.2. You are responsible for all activity that occurs under your account.\n\n'
                              '4.3. You must provide accurate and up-to-date information when creating your account.\n\n'
                              '4.4. If you believe your account has been accessed without your permission, you must notify us immediately.',
                        ),
                        const _LicenseSection(
                          title: '5. Orders and Services',
                          body:
                              '5.1. Lundri connects you with laundry partners and delivery riders.\n\n'
                              '5.2. Pickup and delivery times are estimates and may vary due to weather, traffic, laundry volume, or other circumstances.\n\n'
                              '5.3. You are responsible for ensuring that the pickup and delivery address is correct, someone is available at the scheduled time if necessary, and your laundry is properly packaged and prepared for collection.\n\n'
                              '5.4. Lundri and its partners may refuse to process dangerous or prohibited items, wet or hazardous materials, or items that violate the law.\n\n'
                              '5.5. Lundri is not responsible for damage caused by incorrect care instructions provided by you, existing defects or wear on the clothing, or items left in pockets or attached to garments.',
                        ),
                        const _LicenseSection(
                          title: '6. Payments',
                          body:
                              '6.1. You agree to pay all charges shown in the Application before confirming an order.\n\n'
                              '6.2. Payments may be made through mobile money, debit card, credit card, or other supported payment methods.\n\n'
                              '6.3. Additional fees may apply if you change your order after confirmation, pickup fails because no one is available, your address is incorrect, or extra services are requested.\n\n'
                              '6.4. Lundri reserves the right to cancel or suspend an order if payment fails or is suspected to be fraudulent.',
                        ),
                        const _LicenseSection(
                          title: '7. Intellectual Property',
                          body:
                              '7.1. All rights, title, and interest in the Application, including the Lundri name, logos, designs, text, illustrations, software, features, and content, remain the property of Lundri or its licensors.\n\n'
                              '7.2. This Agreement does not transfer any ownership rights to you.\n\n'
                              '7.3. You may not copy, reproduce, distribute, or use any part of the Application without written permission from Lundri.',
                        ),
                        const _LicenseSection(
                          title: '8. Privacy',
                          body:
                              'Your use of the Application is also governed by the Lundri Privacy Notice.\n\n'
                              'By using Lundri, you agree that we may collect and process your information as described in that notice.',
                        ),
                        const _LicenseSection(
                          title: '9. Limitation of Liability',
                          body:
                              '9.1. Lundri provides the Application on an “as is” and “as available” basis.\n\n'
                              '9.2. To the fullest extent permitted by law, Lundri is not liable for service interruptions, delays, technical problems, loss of profits, or indirect or consequential damages.\n\n'
                              '9.3. Lundri’s maximum liability relating to a specific order will not exceed the amount paid for that order.',
                        ),
                        const _LicenseSection(
                          title: '10. Suspension and Termination',
                          body:
                              '10.1. We may suspend or terminate your access to Lundri at any time if you violate this Agreement, we suspect fraud or misuse, or we are required to do so by law.\n\n'
                              '10.2. You may stop using the Application at any time by deleting your account and uninstalling the app.',
                        ),
                        const _LicenseSection(
                          title: '11. Changes to This Agreement',
                          body:
                              'We may update this License Agreement from time to time.\n\n'
                              'If we make important changes, we may notify you through the Application, email, or SMS.\n\n'
                              'Your continued use of Lundri after the changes take effect means that you accept the updated Agreement.',
                        ),
                        const _LicenseSection(
                          title: '12. Governing Law',
                          body:
                              'This Agreement is governed by the laws of Ghana.\n\n'
                              'Any dispute arising from this Agreement or your use of Lundri shall be resolved by the courts of Ghana.',
                        ),
                        const _LicenseSection(
                          title: '13. Contact Information',
                          body:
                              'If you have any questions about this Agreement, please contact:\n\n'
                              'Email: omeeogh@gmail.com',
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Last Updated: April 2026',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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

          const SizedBox(height: 36),
          Text(
            'Lundri Mobile Application License Agreement',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Before using the Lundri mobile application, please read this License Agreement carefully. By downloading, installing, accessing, or using Lundri, you agree to be bound by these terms.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseTopBar extends StatelessWidget {
  final String title;
  const _LicenseTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
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
                  size: 28,
                  color: Colors.black,
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

class _LicenseSection extends StatelessWidget {
  final String title;
  final String body;

  const _LicenseSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9E9E9)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade800,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
