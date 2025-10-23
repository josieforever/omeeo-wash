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
  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.loadUser(uid: FirebaseAuth.instance.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ProfileScreenTopBar(user: user),
                  ProfileScreenMiddleSection(loyaltyPoints: user.loyaltyPoints),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProfileScreenTopBar extends StatelessWidget {
  final UserModel user;

  const ProfileScreenTopBar({super.key, required this.user});

  // Generate initials from name
  String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    } else {
      return '';
    }
  }

  // Generate a random color
  Color getRandomColor() {
    final colors = [
      Colors.deepPurple,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.redAccent,
      Colors.blueGrey,
    ];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(user.name);
    final randomColor = getRandomColor();

    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6), // x, y
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Profile',
                textColor: Theme.of(context).colorScheme.primary,
                textSize: TextSizes.heading1,
                textWeight: FontWeight.w900,
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PersonalInformation()),
                  );
                },
                icon: Icon(
                  FontAwesomeIcons.penToSquare,
                  size: IconSizes.midSmall,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),

          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: randomColor,
                backgroundImage: (user.photoUrl.isNotEmpty)
                    ? NetworkImage(user.photoUrl)
                    : null,
                child: (user.photoUrl.isEmpty)
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
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: user.name,
                    textColor: Theme.of(context).colorScheme.primary,
                    textSize: TextSizes.heading2,
                    textWeight: FontWeight.w900,
                  ),
                  CustomText(
                    text: user.email,
                    textColor: Theme.of(context).colorScheme.primary,
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.normal,
                  ),
                  CustomText(
                    text: 'Member since ${user.memberSince}',
                    textColor: Theme.of(context).colorScheme.primary,
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.normal,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: IconStackTextButton(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                  icon: Icon(
                    Icons.local_car_wash,
                    size: IconSizes.small,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  numberWidget: CustomText(
                    text: user.totalWashes.toString(),
                    textColor: Theme.of(context).colorScheme.inversePrimary,
                    textSize: TextSizes.subtitle1,
                    textWeight: FontWeight.w900,
                  ),
                  textWidget: CustomText(
                    text: 'Total Washes',
                    textColor: Theme.of(context).colorScheme.primary,
                    textSize: TextSizes.caption,
                    textWeight: FontWeight.bold,
                  ),
                  onPressed: () {},
                  borderRadius: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: IconStackTextButton(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                  icon: Icon(
                    FontAwesomeIcons.calendar,
                    size: IconSizes.small,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  numberWidget: CustomText(
                    text: user.washesThisMonth.toString(),
                    textColor: Theme.of(context).colorScheme.inversePrimary,
                    textSize: TextSizes.subtitle1,
                    textWeight: FontWeight.w900,
                  ),
                  textWidget: CustomText(
                    text: 'This month',
                    textColor: Theme.of(context).colorScheme.primary,
                    textSize: TextSizes.caption,
                    textWeight: FontWeight.bold,
                  ),
                  onPressed: () {},
                  borderRadius: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileScreenMiddleSection extends StatelessWidget {
  final int loyaltyPoints;

  const ProfileScreenMiddleSection({super.key, required this.loyaltyPoints});

  @override
  Widget build(BuildContext context) {
    String remainingPoints = (200 - loyaltyPoints).toString();
    String loyaltyPointsString = loyaltyPoints.toString();

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            RewardsCardMono(
              points: 850,
              goal: 1000,
              subtitle: "You're doing great! ✨",
              onTap: () {},
            ),
            const SizedBox(height: 10),
            ProfileButton(
              textWidget1: 'Personal Infomation',
              textWidget2: 'Update your details',
              icon: Icon(
                Icons.supervised_user_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              scale: 1.2,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PersonalInformation()),
                );
              },
            ),
            ProfileButton(
              textWidget1: 'Payment Methods',
              textWidget2: 'Manage cards & payments',
              icon: Icon(
                Icons.payment,
                color: Theme.of(context).colorScheme.primary,
              ),
              scale: 1.2,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentMethods()),
                );
              },
            ),
            ProfileButton(
              textWidget1: 'Addresses',
              textWidget2: 'Home, work & other locations',
              icon: Icon(
                Icons.add_location_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              scale: 1.2,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Addresses()),
                );
              },
            ),
            ProfileButton(
              textWidget1: 'Notifications',
              textWidget2: 'Push notifications & alerts',
              svg: SvgPicture.asset(
                'assets/icons/notification_settings.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(
                    context,
                  ).colorScheme.primary, // 🎨 Replace with your desired color
                  BlendMode.srcIn,
                ),
              ),
              scale: 1.2,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Notifications()),
                );
              },
            ),
            ProfileButton(
              textWidget1: 'App Settings',
              textWidget2: 'Language, theme & more',
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
              ),
              scale: 1.2,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AppSettings()),
                );
              },
            ),
            ProfileButton(
              textWidget1: 'Help & Support',
              textWidget2: 'FAQs & contact us',
              icon: Icon(
                Icons.help,
                color: Theme.of(context).colorScheme.primary,
              ),
              scale: 1.2,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HelpAndSupport()),
                );
              },
            ),

            SignOut(
              textWidget1: 'Sign Out',
              textWidget2: 'Sign out of your account',
              icon: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              scale: 1.2,
              onPressed: () async {
                await NotificationService().removeToken();
                await FirebaseService().signOut(context);
              },
            ),
            const SizedBox(height: 75),
          ],
        ),
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

    // Monochrome text on dark
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
                // Monochrome gradient base
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0, -1.0),
                      end: Alignment(1.0, 1.0),
                      colors: [
                        Color(0xFF0D0D0D), // near-black
                        Color(0xFF121212), // dark gray
                        Color(0xFF0A0A0A), // deeper black
                      ],
                    ),
                  ),
                ),

                // Soft grayscale glows
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

                // Subtle diagonal stripes in white @ low opacity
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

                // Content
                Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top: big number on left, title on right
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

                      // Meta row
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

                      // Grayscale progress
                      _ProgressBar(
                        value: progress,
                        background: Colors.white.withOpacity(.18),
                        foreground: const LinearGradient(
                          colors: [
                            Color(0xFFBDBDBD), // light gray
                            Color(0xFFEDEDED), // very light gray
                            Color(0xFFFFFFFF), // white center highlight
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
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

// ==== visual bits (unchanged, but used with grayscale) ====

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
  bool shouldRepaint(covariant _StripesPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.thickness != thickness ||
      oldDelegate.gap != gap ||
      oldDelegate.angleDeg != angleDeg;
}

class _ProgressBar extends StatelessWidget {
  final double value; // 0..1
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
