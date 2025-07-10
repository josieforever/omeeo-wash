import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/models/user_model.dart';
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
          body: SingleChildScrollView(
            child: Container(
              color: Colors.transparent,
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
              CustomText(
                text: 'Profile',
                textColor: Theme.of(context).textTheme.headlineLarge?.color,
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
                  color: Theme.of(context).textTheme.headlineLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
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
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.heading2,
                    textWeight: FontWeight.w900,
                  ),
                  CustomText(
                    text: user.email,
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.normal,
                  ),
                  CustomText(
                    text: 'Member since ${user.memberSince}',
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.normal,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Rest of your stats row remains unchanged...
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
            ProfileButton(
              textWidget1: 'Personal Infomation',
              textWidget2: 'Update your details',
              animation: 'assets/animations/update_profile.json',
              scale: 13,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PersonalInformation()),
                );
              },
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),
            ProfileButton(
              textWidget1: 'Payment Methods',
              textWidget2: 'Manage cards & payments',
              animation: 'assets/animations/payment_method.json',
              scale: 15,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PaymentMethods()),
                );
              },
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),
            ProfileButton(
              textWidget1: 'Addresses',
              textWidget2: 'Home, work & other locations',
              animation: 'assets/animations/location.json',
              scale: 10,
              onPressed: () {},
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),
            ProfileButton(
              textWidget1: 'Notifications',
              textWidget2: 'Push notifications & alerts',
              animation: 'assets/animations/notification.json',
              scale: 12,
              onPressed: () {},
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),
            ProfileButton(
              textWidget1: 'App Settings',
              textWidget2: 'Language, theme & more',
              animation: 'assets/animations/settings.json',
              scale: 9,
              onPressed: () {},
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),
            ProfileButton(
              textWidget1: 'Help & Support',
              textWidget2: 'FAQs & contact us',
              animation: 'assets/animations/help.json',
              scale: 9,
              onPressed: () {},
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),
            LoyaltyPointsBar(
              padding: const EdgeInsets.all(10),
              textWidget1: CustomText(
                text: 'Loyalty Points',
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                textSize: TextSizes.subtitle2,
                textWeight: FontWeight.w900,
              ),
              textWidget2: CustomText(
                text: 'You have $loyaltyPointsString points',
                textColor: Theme.of(context).textTheme.headlineLarge?.color,
                textSize: TextSizes.caption,
                textWeight: FontWeight.normal,
              ),
              textWidget3: CustomText(
                text: '$remainingPoints more points for a free wash!',
                textColor: Theme.of(context).textTheme.headlineLarge?.color,
                textSize: TextSizes.caption,
                textWeight: FontWeight.normal,
              ),
              point: loyaltyPointsString,
              onPressed: () {},
              borderRadius: 7,
            ),
            SignOut(
              textWidget1: 'Sign Out',
              textWidget2: 'Sign out of your account',
              animation: 'assets/animations/logout.json',
              scale: 10,
              onPressed: () {
                FirebaseService().signOut(context);
              },
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),
            const SizedBox(height: 75),
          ],
        ),
      ),
    );
  }
}
