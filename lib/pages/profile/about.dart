import 'package:flutter/material.dart';
import 'package:omeeowash/pages/profile/about/licence_agreement.dart';
import 'package:omeeowash/pages/profile/about/privacy_policy.dart';
import 'package:omeeowash/pages/profile/about/user_data.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logoWidth = context.rw(170, min: 130, max: 190);
    final logoHeight = context.rh(150, min: 120, max: 170);
    final sectionGap = context.rh(28, min: 16, max: 32);
    final detailsBottomGap = context.rh(100, min: 40, max: 100);
    final dividerBandHeight = context.rh(10, min: 6, max: 10);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _AboutTopBar(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: sectionGap),

                    Container(
                      padding: const EdgeInsets.all(5),
                      width: logoWidth,
                      height: logoHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/lundri_logo_transparent_small.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    SizedBox(height: sectionGap),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Version 1.0.0, released 28 Mar 2026\nbuild 503057',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(height: context.rh(40, min: 24, max: 44)),

                    Container(
                      height: dividerBandHeight,
                      width: double.infinity,
                      color: const Color(0xFFF3F3F3),
                    ),

                    _AboutMenuTile(
                      title: 'License Agreement',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LicenseAgreementScreen(),
                          ),
                        );
                      },
                    ),
                    const _DividerLine(),

                    _AboutMenuTile(
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                    ),
                    const _DividerLine(),

                    _AboutMenuTile(
                      title: 'User data',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LundriUserDataScreen(),
                          ),
                        );
                      },
                    ),
                    const _DividerLine(),

                    SizedBox(height: detailsBottomGap),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informational service provided by:',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Omeeo Ghana., reg. number 74474332, '
                            'Accra Digital Centre, Ring Road West, Accra, Ghana',
                            style: TextStyle(
                              color: Color.fromARGB(255, 79, 79, 79),
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '© 2026 Omeeo Ghana.',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTopBar extends StatelessWidget {
  const _AboutTopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.rh(56, min: 48, max: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
            const Center(
              child: Text(
                'About',
                style: TextStyle(
                  fontSize: 22,
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

class _AboutMenuTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _AboutMenuTile({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 28, color: Colors.black87),
            ],
          ),
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFFE6E6E6),
    );
  }
}
