import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/pages/home/booking%20flow/services_screen.dart';
import 'package:omeeowash/pages/home_screen_with_nav.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

class ServicesAndPricing extends StatefulWidget {
  const ServicesAndPricing({super.key});

  @override
  State<ServicesAndPricing> createState() => _ServicesAndPricingState();
}

class _ServicesAndPricingState extends State<ServicesAndPricing> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 248, 255),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              color: const Color.fromARGB(213, 255, 255, 255),
            ),
          ),
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/background_animation_light.json',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              color: const Color.fromARGB(100, 255, 255, 255),
            ),
          ),
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ServicesAndPricingTopBar(),
                  ServicesAndPricingPage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServicesAndPricingPage extends StatefulWidget {
  const ServicesAndPricingPage({super.key});

  @override
  State<ServicesAndPricingPage> createState() => _ServicesAndPricingPageState();
}

class _ServicesAndPricingPageState extends State<ServicesAndPricingPage> {
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

  Widget _Package({
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
    required String duration,
    required List<String> includes,
    required VoidCallback onPressed,
    required bool mostPopular,
    Color iconColor = AppColors.secondary,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // So text can wrap down
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(32, 137, 43, 226),
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
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),

                    Text(
                      subtitle,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: TextSizes.bodyText2,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    text: '₵$price',
                    textColor: iconColor,
                    textSize: TextSizes.subtitle1,
                    textWeight: FontWeight.w700,
                  ),
                  CustomText(
                    text: duration,
                    textColor: Theme.of(context).textTheme.bodyMedium?.color,
                    textSize: TextSizes.bodyText2,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              CustomText(
                text: 'Includes:',
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                textSize: TextSizes.bodyText1,
                textWeight: FontWeight.w700,
              ),
              mostPopular ? const SizedBox(width: 30) : SizedBox(),
              mostPopular
                  ? RegularButton(
                      onPressed: onPressed,
                      borderRadius: 50,
                      textWidget: CustomText(
                        text: 'Most Popular',
                        textColor: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.color,
                        textSize: TextSizes.bodyText1,
                        textWeight: FontWeight.w700,
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 10,
                      ),
                      backgroundColor: iconColor,
                    )
                  : SizedBox(),
            ],
          ),
          const SizedBox(height: 5),
          for (var service in includes)
            Row(
              children: [
                Icon(Icons.do_not_disturb_on_sharp, size: 8),
                const SizedBox(width: 5),
                CustomText(
                  text: service,
                  textColor: Theme.of(context).textTheme.bodyMedium?.color,
                  textSize: TextSizes.bodyText3,
                ),
              ],
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
    required EdgeInsets margin,
    required Color backgroundColor,
    Color iconColor = AppColors.secondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      margin: margin,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: backgroundColor,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).textTheme.headlineLarge?.color,
            size: IconSizes.midSmall,
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                text: title,
                textColor: Theme.of(context).textTheme.headlineLarge?.color,
                textSize: TextSizes.bodyText3,
                textWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
              CustomText(
                text: '₵$subtitle',
                textColor: Theme.of(context).textTheme.headlineLarge?.color,
                textSize: TextSizes.caption,
                textWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQ({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = AppColors.secondary,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: TextSizes.bodyText1,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: TextSizes.bodyText1,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: Icon(FontAwesomeIcons.chevronRight, size: IconSizes.small),
    );
  }

  Widget _buildCard(String title, String subtitle, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  color: Theme.of(context).textTheme.bodyLarge?.color,
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
    final List<String> howPricingWorks = [
      'Service package selected',
      'Vehicle size (HactchBack, Sedan, SUV, Truck)',
      'Add-on services',
      'Location (mobile service included)',
      'Time slot availability',
    ];
    return Column(
      children: [
        _buildCard("Our Services Packages", "", [
          _Package(
            mostPopular: false,
            icon: FontAwesomeIcons.shower,
            title: "Basic Wash",
            subtitle: "Exterior wash & dry",
            onPressed: () {},
            duration: '15-25 min',
            includes: ['Exterior wash & rinse', 'Tyre cleaning'],
            price: '10',
          ),
          Divider(indent: 15, endIndent: 15, thickness: 0.5),
          _Package(
            mostPopular: true,
            icon: Icons.access_time,
            title: "Express Premium Wash",
            subtitle: "Quick wash, interior clean & vacuum",
            onPressed: () {},
            duration: '20-25 min',
            includes: [
              'Everything in Basic',
              'Interior vacuum',
              'Dashboard cleaning',
              'Center console cleaning',
            ],
            price: '30',
          ),
          Divider(indent: 15, endIndent: 15, thickness: 0.5),
          _Package(
            mostPopular: false,
            icon: Icons.workspace_premium_outlined,
            title: "Premium Detail",
            subtitle: "Full interior & exterior detail",
            onPressed: () {},
            duration: '15-20 min',
            includes: [
              'Everything in Premium Wash',
              'Exterior Wax application',
              'Interior protection',
              'Upholstery detail',
            ],
            price: '300',
          ),
        ]),

        _buildCard("Add-on Services", "", [
          Row(
            children: [
              Expanded(
                child: BookNow(
                  backgroundColor: // Right (periwinkle blue-purple)
                  Color(
                    0xFFA558F2,
                  ),
                  margin: EdgeInsets.only(left: 10, right: 5, bottom: 10),
                  icon: Icons.add,
                  title: "Air Freshner",
                  subtitle: "15",
                  onPressed: () {},
                ),
              ),
              Expanded(
                child: BookNow(
                  backgroundColor: Color(0xFF6D66F6),
                  margin: EdgeInsets.only(left: 5, right: 10, bottom: 10),
                  icon: Icons.add,
                  title: "Undercarriage Wash",
                  subtitle: "5",
                  onPressed: () {},
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: BookNow(
                  backgroundColor: // Right (periwinkle blue-purple)
                  Color(
                    0xFFA558F2,
                  ),
                  margin: EdgeInsets.only(left: 10, right: 5, bottom: 10),
                  icon: Icons.add,
                  title: "Engine Bay Cleaning",
                  subtitle: "10",
                  onPressed: () {},
                ),
              ),
              Expanded(
                child: BookNow(
                  backgroundColor: Color(0xFF6D66F6),
                  margin: EdgeInsets.only(left: 5, right: 10, bottom: 10),
                  icon: Icons.add,
                  title: "Pet hair Removal",
                  subtitle: "15",
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ]),
        _buildCard("How Pricing Works", "", [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'Final price depends on several factors',
                  textColor: Theme.of(context).textTheme.bodyMedium?.color,
                  textSize: TextSizes.bodyText3,
                ),
                const SizedBox(height: 10),
                for (var point in howPricingWorks)
                  Row(
                    children: [
                      Icon(Icons.do_not_disturb_on_sharp, size: 8),
                      const SizedBox(width: 5),
                      CustomText(
                        text: point,
                        textColor: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color,
                        textSize: TextSizes.bodyText3,
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color.fromARGB(92, 158, 158, 158),
                  ),
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          text:
                              'Note: All prices include mobile service. We come to your location at no extra charge!',
                          textColor: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color,
                          textSize: TextSizes.bodyText3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }
}

class ServicesAndPricingTopBar extends StatelessWidget {
  const ServicesAndPricingTopBar({super.key});

  @override
  Widget build(BuildContext context) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      CustomText(
                        text: 'Services & Pricing',
                        textColor: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.color,
                        textSize: TextSizes.heading2,
                        textWeight: FontWeight.w900,
                      ),
                    ],
                  ),
                  CustomText(
                    text: 'Information about our wash packages',
                    textColor: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.color,
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
