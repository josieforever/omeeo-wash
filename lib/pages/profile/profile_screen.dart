import 'dart:math';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/notifications/notification_service.dart';
import 'package:omeeowash/pages/profile/app_settings.dart';
import 'package:omeeowash/pages/profile/help_and_support/help_annd_support.dart';
import 'package:omeeowash/pages/profile/notifications.dart';
import 'package:omeeowash/pages/profile/addresses.dart';
import 'package:omeeowash/pages/profile/payment_methods.dart';
import 'package:omeeowash/pages/profile/personal_information.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

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
                  color: Theme.of(context).colorScheme.primary.withOpacity(.7),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
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

            return SingleChildScrollView(
              child: Column(
                children: [
                  ProfileScreenTopBar(user: user),
                  ProfileScreenMiddleSection(loyaltyPoints: user.loyaltyPoints),
                ],
              ),
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

    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: GoBack(
            bgColor: Theme.of(context).colorScheme.tertiary,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(height: 20),

        Align(
          alignment: Alignment.topCenter,
          child: GestureDetector(
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
                  radius: 35,
                  backgroundColor: avatarBg,
                  backgroundImage: user.photoUrl.isNotEmpty
                      ? NetworkImage(user.photoUrl)
                      : null,
                  child: user.photoUrl.isEmpty
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                CustomText(
                  text: displayName,
                  textColor: Theme.of(context).colorScheme.primary,
                  textSize: TextSizes.heading2,
                  textWeight: FontWeight.w900,
                ),
                CustomText(
                  text: user.email,
                  textColor: Theme.of(context).colorScheme.primary,
                  textSize: TextSizes.bodyText1,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}

class ProfileScreenMiddleSection extends StatelessWidget {
  final int loyaltyPoints;

  const ProfileScreenMiddleSection({super.key, required this.loyaltyPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFFFFF1F4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                ProfileButton(
                  textWidget1: 'Discounts and gifts',
                  textWidget2: 'Enter promo code',
                  svg: SvgPicture.asset(
                    'assets/icons/percent_discount.svg',
                    height: 30,
                    width: 30,
                    colorFilter: ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                  scale: 1,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpAndSupport()),
                    );
                  },
                ),

                Divider(
                  color: const Color(0xFF919191),
                  indent: 40,
                  endIndent: 20,
                ),
                ProfileButton(
                  textWidget1: 'Payment Methods',
                  icon2: FontAwesomeIcons.creditCard,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentMethods()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFFFFF1F4),
              borderRadius: BorderRadius.circular(15),
            ),
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
                      MaterialPageRoute(builder: (_) => const Addresses()),
                    );
                  },
                ),
                Divider(
                  color: const Color(0xFF919191),
                  indent: 40,
                  endIndent: 20,
                ),
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
                      MaterialPageRoute(builder: (_) => const AppSettings()),
                    );
                  },
                ),
                Divider(
                  color: const Color(0xFF919191),
                  indent: 40,
                  endIndent: 20,
                ),
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
                      MaterialPageRoute(builder: (_) => const Notifications()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 32, 32, 32),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  child: Icon(
                    FontAwesomeIcons.cediSign,
                    color: const Color.fromARGB(255, 255, 217, 0),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                CustomText(text: 'Earn as a rider', textColor: Colors.white),
                Expanded(child: SizedBox()),
                Icon(
                  FontAwesomeIcons.chevronRight,
                  size: 13,
                  color: const Color.fromARGB(255, 206, 0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFFFFF1F4),
              borderRadius: BorderRadius.circular(15),
            ),
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
                  MaterialPageRoute(builder: (_) => const HelpAndSupport()),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFFFFF1F4),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                ProfileButton(
                  textWidget1: 'Settings',
                  icon: Icon(
                    Icons.assignment_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  scale: 1,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppSettings()),
                    );
                  },
                ),
                Divider(
                  color: const Color(0xFF919191),
                  indent: 40,
                  endIndent: 20,
                ),
                ProfileButton(
                  textWidget1: 'Information',
                  icon: Icon(Icons.info_rounded),
                  scale: 1,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpAndSupport()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SignOut(
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
          const SizedBox(height: 75),
        ],
      ),
    );
  }
}

class RewardsCardMono extends StatelessWidget {
  final int points;
  final int goal;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final double height;
  final EdgeInsetsGeometry padding;

  const RewardsCardMono({
    super.key,
    required this.points,
    required this.goal,
    this.title = 'Rewards Points',
    this.subtitle = "You're doing great!",
    this.onTap,
    this.height = 155,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (goal - points).clamp(0, goal);
    final progress = (points / goal).clamp(0.0, 1.0);

    final textOnDark = Colors.white.withOpacity(.96);
    final textOnDarkSub = Colors.white.withOpacity(.72);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white10,
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0, -1.0),
                      end: Alignment(1.0, 1.0),
                      colors: [
                        Color(0xFF0D0D0D),
                        Color(0xFF121212),
                        Color(0xFF0A0A0A),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: -40,
                  top: -30,
                  child: _GlowBlob(
                    size: 180,
                    color: Colors.white.withOpacity(.12),
                  ),
                ),
                Positioned(
                  right: -20,
                  bottom: -30,
                  child: _GlowBlob(
                    size: 160,
                    color: Colors.white.withOpacity(.08),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StripesPainter(
                      color: Colors.white.withOpacity(.05),
                      thickness: 14,
                      gap: 30,
                      angleDeg: -18,
                    ),
                  ),
                ),
                Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '$points',
                                      style: TextStyle(
                                        color: textOnDark,
                                        fontSize: 36,
                                        height: 1.0,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 7,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.10),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: textOnDark,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: textOnDarkSub,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Next reward at ${_formatNumber(goal)} pts',
                              style: TextStyle(
                                color: textOnDarkSub,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _Pill(label: '${_formatNumber(remaining)} to go'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _ProgressBar(
                        value: progress,
                        background: Colors.white.withOpacity(.18),
                        foreground: const LinearGradient(
                          colors: [
                            Color(0xFFBDBDBD),
                            Color(0xFFEDEDED),
                            Color(0xFFFFFFFF),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(num n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buf.write(',');
      }
    }
    return buf.toString();
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0.0)]),
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double gap;
  final double angleDeg;

  _StripesPainter({
    required this.color,
    this.thickness = 12,
    this.gap = 24,
    this.angleDeg = -15,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final angle = angleDeg * math.pi / 180;
    final dx = math.cos(angle);
    final dy = math.sin(angle);

    for (double i = -size.height; i < size.width + size.height; i += gap) {
      final path = Path()
        ..moveTo(i * dx, i * dy)
        ..lineTo((i + thickness) * dx, (i + thickness) * dy)
        ..lineTo(
          (i + thickness) * dx + size.height * -dy,
          (i + thickness) * dy + size.height * dx,
        )
        ..lineTo(i * dx + size.height * -dy, i * dy + size.height * dx)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StripesPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.gap != gap ||
        oldDelegate.angleDeg != angleDeg;
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final LinearGradient foreground;
  final Color background;

  const _ProgressBar({
    required this.value,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final filled = (w * value).clamp(0.0, w);

          return Stack(
            children: [
              Container(height: 12, width: w, color: background),
              Container(
                height: 12,
                width: filled,
                decoration: BoxDecoration(gradient: foreground),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.20)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
