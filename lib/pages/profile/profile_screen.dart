import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/notifications/notification_service.dart';
import 'package:omeeowash/pages/profile/about.dart';
import 'package:omeeowash/pages/profile/addresses.dart';
import 'package:omeeowash/pages/profile/all_support.dart';
import 'package:omeeowash/pages/profile/settings.dart';
import 'package:omeeowash/pages/profile/discounts_gifts.dart';
import 'package:omeeowash/pages/profile/help/help.dart';
import 'package:omeeowash/pages/profile/history.dart';
import 'package:omeeowash/pages/profile/payment_methods.dart';
import 'package:omeeowash/pages/profile/personal_information.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

import 'help/live_chat/app.config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _uid;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    _uid = currentUser?.uid;

    if (_uid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.loadUser(uid: _uid!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No user signed in',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please log in to view your profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(.7),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('Go to Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: const Color(0xFFFFFFFF),
      child: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final user = userProvider.user;

            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 360
                    ? 10.0
                    : 14.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        children: [
                          ProfileScreenTopBar(user: user),
                          const SizedBox(height: 8),
                          ProfileScreenMiddleSection(
                            loyaltyPoints: user.loyaltyPoints,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ProfileScreenTopBar extends StatelessWidget {
  final UserModel user;
  const ProfileScreenTopBar({super.key, required this.user});

  String _safeInitials({required String? name, required String? email}) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    final e = (email ?? '').trim();
    if (e.isNotEmpty) return e[0].toUpperCase();
    return 'U';
  }

  Color _avatarColor(String seed) {
    final palette = <Color>[
      Colors.deepPurple,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.redAccent,
      Colors.blueGrey,
    ];
    final idx = seed.hashCode.abs() % palette.length;
    return palette[idx];
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance.currentUser;
    final size = MediaQuery.of(context).size;
    final isSmallPhone = size.width < 360;

    String displayName = user.name.trim();
    if (displayName.isEmpty) {
      displayName = (auth?.displayName ?? '').trim();
    }
    if (displayName.isEmpty) {
      final emailLocal = user.email.split('@').first;
      displayName = emailLocal.isNotEmpty ? emailLocal : 'User';
    }

    final initials = _safeInitials(name: displayName, email: user.email);
    final avatarBg = _avatarColor(user.uid);

    final avatarRadius = isSmallPhone ? 38.0 : 45.0;
    final nameFontSize = isSmallPhone ? 22.0 : TextSizes.heading2.toDouble();
    final emailFontSize = isSmallPhone ? 13.0 : TextSizes.bodyText1.toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GoBack(
              bgColor: Theme.of(context).colorScheme.tertiary,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonalInformation()),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: avatarBg,
                  backgroundImage: user.photoUrl.isNotEmpty
                      ? NetworkImage(user.photoUrl)
                      : null,
                  child: user.photoUrl.isEmpty
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: isSmallPhone ? 20 : 24,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    user.email,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: emailFontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreenMiddleSection extends StatefulWidget {
  final int loyaltyPoints;

  const ProfileScreenMiddleSection({super.key, required this.loyaltyPoints});

  @override
  State<ProfileScreenMiddleSection> createState() =>
      _ProfileScreenMiddleSectionState();
}

class _ProfileScreenMiddleSectionState
    extends State<ProfileScreenMiddleSection> {
  bool isAdmin = AppConfig().isAdmin;

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      vertical: 18,
      horizontal: 0,
    ),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }

  Widget _sectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        color: Color(0xFF919191),
        indent: 40,
        endIndent: 20,
        height: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;
    final verticalGap = isSmallPhone ? 16.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 8,
        left: isSmallPhone ? 2 : 0,
        right: isSmallPhone ? 2 : 0,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            child: Column(
              children: [
                ProfileButton(
                  textWidget1: 'Discounts and gifts',
                  textWidget2: 'Enter promo code',
                  svg: SvgPicture.asset(
                    'assets/icons/percent_discount.svg',
                    height: isSmallPhone ? 24 : 30,
                    width: isSmallPhone ? 24 : 30,
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                  scale: 1,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GiftsAndDiscountsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                _sectionDivider(),
                const SizedBox(height: 4),
                ProfileButton(
                  textWidget1: 'Payment Methods',
                  selectedPaymentMethod: 'card',
                  icon2: Icons.payment,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PaymentMethodsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: verticalGap),

          _sectionCard(
            child: Column(
              children: [
                ProfileButton(
                  textWidget1: 'Addresses',
                  icon: Icon(
                    Icons.add_location_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  scale: 1,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyAddressesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                _sectionDivider(),
                const SizedBox(height: 4),
                ProfileButton(
                  textWidget1: 'History',
                  icon: Icon(
                    Icons.assignment_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  scale: 1,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const History()),
                    );
                  },
                ),
                const SizedBox(height: 4),
                _sectionDivider(),
                const SizedBox(height: 4),
                ProfileButton(
                  textWidget1: 'Support',
                  icon: Icon(
                    FontAwesomeIcons.headset,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  scale: 1,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AllSupportScreen(isAdmin: false),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: verticalGap),

          GestureDetector(
            onTap: () {
              // TODO: connect to rider onboarding screen
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isSmallPhone ? 13 : 15,
                horizontal: isSmallPhone ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 32, 32, 32),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: isSmallPhone ? 14 : 15,
                    backgroundColor: Colors.white,
                    child: Icon(
                      FontAwesomeIcons.cediSign,
                      color: const Color.fromARGB(255, 255, 217, 0),
                      size: isSmallPhone ? 14 : 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Earn as a rider',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallPhone ? 14 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    FontAwesomeIcons.chevronRight,
                    size: 13,
                    color: Color.fromARGB(255, 206, 0, 0),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: verticalGap),

          _sectionCard(
            child: ProfileButton(
              textWidget1: 'Help',
              icon: Icon(
                Icons.help,
                color: Theme.of(context).colorScheme.primary,
              ),
              scale: 1,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Help()),
                );
              },
            ),
          ),

          SizedBox(height: verticalGap),

          _sectionCard(
            child: Column(
              children: [
                ProfileButton(
                  textWidget1: 'Settings',
                  icon: Icon(
                    Icons.settings,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  scale: 1,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Settings()),
                    );
                  },
                ),
                _sectionDivider(),
                ProfileButton(
                  textWidget1: 'About',
                  icon: const Icon(Icons.info_rounded),
                  scale: 1,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
