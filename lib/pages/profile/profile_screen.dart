import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/models/user_model.dart';
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
          body: SingleChildScrollView(
            child: Container(
              color: Colors.transparent,
              child: Column(
                children: [
                  ProfileScreenTopBar(user: user),
                  ProfileScreenMiddleSection(
                    loyaltyPoints: user.loyaltyPoints!,
                  ),
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
          Row(
            children: [
              Expanded(
                child: IconStackTextButton(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  icon: Icon(
                    Icons.local_car_wash,
                    size: IconSizes.small,
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                  ),
                  numberWidget: CustomText(
                    text: user.totalWashes.toString(),
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.subtitle1,
                    textWeight: FontWeight.w900,
                  ),
                  textWidget: CustomText(
                    text: 'Total Washes',
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.caption,
                    textWeight: FontWeight.normal,
                  ),
                  onPressed: () {},
                  borderRadius: 7,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: IconStackTextButton(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  icon: Icon(
                    FontAwesomeIcons.calendar,
                    size: IconSizes.small,
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                  ),
                  numberWidget: CustomText(
                    text: user.washesThisMonth.toString(),
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.subtitle1,
                    textWeight: FontWeight.w900,
                  ),
                  textWidget: CustomText(
                    text: 'This month',
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.caption,
                    textWeight: FontWeight.normal,
                  ),
                  onPressed: () {},
                  borderRadius: 7,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: IconStackTextButton(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  icon: Icon(
                    FontAwesomeIcons.solidStar,
                    size: IconSizes.small,
                    color: Colors.amber,
                  ),
                  numberWidget: CustomText(
                    text: user.rating.toString(),
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.subtitle1,
                    textWeight: FontWeight.w900,
                  ),
                  textWidget: CustomText(
                    text: 'Rating',
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.caption,
                    textWeight: FontWeight.normal,
                  ),
                  onPressed: () {},
                  borderRadius: 7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
              onPressed: () {},
            ),
            ProfileButton(
              textWidget1: 'Help & Support',
              textWidget2: 'FAQs & contact us',
              icon: Icon(
                Icons.help,
                color: Theme.of(context).colorScheme.primary,
              ),
              scale: 1.2,

              onPressed: () {},
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
              icon: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              scale: 1.2,
              onPressed: () {
                FirebaseService().signOut(context);
              },
            ),
            const SizedBox(height: 75),
          ],
        ),
      ),
    );
  }
}
