import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/services_screen.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [HomeScreenTopBar(), HomeScreenMiddleSection()],
        ),
      ),
    );
  }
}

class HomeScreenTopBar extends StatelessWidget {
  const HomeScreenTopBar({super.key});
  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'Hello, Sarah!',
                    textColor: Theme.of(context).colorScheme.primary,
                    textSize: TextSizes.heading1,
                    textWeight: FontWeight.w900,
                  ),
                  CustomText(
                    text: 'Ready to wash your 🚗?',
                    textColor: Theme.of(context).colorScheme.primary,
                    textSize: TextSizes.heading3,
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      FontAwesomeIcons.solidBell,
                      size: IconSizes.midSmall,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      FontAwesomeIcons.solidUser,
                      size: IconSizes.midSmall,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: IconStackTextButton(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),

                  icon: Icon(
                    FontAwesomeIcons.calendar,
                    size: IconSizes.small,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  textWidget: CustomText(
                    text: 'Book Now',
                    textColor: Theme.of(context).colorScheme.inversePrimary,
                    textSize: TextSizes.subtitle2,
                    textWeight: FontWeight.bold,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const ServicesScreen(),
                      ),
                    );
                  },
                  borderRadius: 25,
                  lottieAsset:
                      "assets/animations/floating_black.json", // 👈 your Lottie file
                  /*  border: Border.all(color: Theme.of(context).colorScheme.inversePrimary, width: 2), */
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeScreenMiddleSection extends StatelessWidget {
  const HomeScreenMiddleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          RewardsPointsCard(
            currentPoints: 850,
            nextThreshold: 1000,
            // Optional:
            // title: 'Rewards Points',
            // encouragingText: "You're doing great!",
          ),

          const SizedBox(height: 10),
          CustomText(
            text: 'Our Services',
            textColor: Theme.of(context).textTheme.bodyLarge?.color,
            textSize: TextSizes.heading2,
            textWeight: FontWeight.w900,
          ),
          const SizedBox(height: 5),
          ServiceButton(
            modalSheet: () {
              showModalBottomSheet(
                showDragHandle: true,
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                isScrollControlled: true, // Makes it full height if needed
                builder: (context) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      List<String> serviceItems = [
                        'Exterior wash',
                        'Tire shine',
                      ];
                      return Container(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        padding: const EdgeInsets.all(17),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Transform.scale(
                                        scale: 2,
                                        child: Center(
                                          child: Icon(
                                            Icons.alarm,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: 'Express Wash',
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                      textSize: TextSizes.heading2,
                                      textWeight: FontWeight.bold,
                                    ),
                                    CustomText(
                                      text: 'Quick exterior wash',
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      textSize: TextSizes.subtitle1,
                                    ),
                                  ],
                                ),
                                Expanded(child: SizedBox()),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    CustomText(
                                      text: "\$12",
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.labelLarge?.color,
                                      textSize: TextSizes.heading1,
                                      textWeight: FontWeight.w800,
                                    ),
                                    CustomText(
                                      text: "10 min",
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      textSize: TextSizes.subtitle2,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                CustomText(
                                  text: "Includes :",
                                  textSize: TextSizes.subtitle1,
                                  textWeight: FontWeight.bold,
                                  textColor: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (var service in serviceItems)
                              Row(
                                children: [
                                  Icon(Icons.do_not_disturb_on_sharp, size: 13),
                                  const SizedBox(width: 5),
                                  CustomText(
                                    text: service,
                                    textColor: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                    textSize: TextSizes.subtitle1,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            textWidget1: 'Express Wash',
            textWidget2: 'Quick exterior wash',
            textWidget3: '⏱️10 min',
            serviceItems: ['Exterior wash & dry', 'Tire shine'],
            icon: Icon(
              FontAwesomeIcons.shower,
              color: Theme.of(context).colorScheme.primary,
            ),
            scale: 1.2,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const ServicesScreen(serviceType: "express"),
                ),
              );
            },
            price: '10',
          ),

          const SizedBox(height: 15),
          ServiceButton(
            modalSheet: () {
              showModalBottomSheet(
                showDragHandle: true,
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                isScrollControlled: true, // Makes it full height if needed
                builder: (context) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      List<String> serviceItems = [
                        'Exterior wash',
                        'DashBoard shine',
                        'Upholstry clean',
                        'Car fLooring vacuum',
                        'Tire shine',
                      ];
                      return Container(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(17),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Transform.scale(
                                        scale: 1.5,
                                        child: Center(
                                          child: Icon(
                                            FontAwesomeIcons.shower,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: 'Standard Wash',
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                      textSize: TextSizes.heading2,
                                      textWeight: FontWeight.bold,
                                    ),
                                    CustomText(
                                      text: 'Complete exterior & interior',
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      textSize: TextSizes.subtitle1,
                                    ),
                                  ],
                                ),
                                Expanded(child: SizedBox()),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    CustomText(
                                      text: "\$12",
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.labelLarge?.color,
                                      textSize: TextSizes.heading1,
                                      textWeight: FontWeight.w800,
                                    ),
                                    CustomText(
                                      text: "30 min",
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      textSize: TextSizes.subtitle2,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                CustomText(
                                  text: "Includes :",
                                  textSize: TextSizes.subtitle1,
                                  textWeight: FontWeight.bold,
                                  textColor: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (var service in serviceItems)
                              Row(
                                children: [
                                  Icon(Icons.do_not_disturb_on_sharp, size: 13),
                                  const SizedBox(width: 5),
                                  CustomText(
                                    text: service,
                                    textColor: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                    textSize: TextSizes.subtitle1,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            textWidget1: 'Standard Wash',
            textWidget2: 'Complete exterior & interior',
            textWidget3: '⏱️ 30 min',
            serviceItems: [
              'Exterior wash',
              'Interior clean & vacuum',
              'Tire shine',
            ],
            icon: Icon(
              Icons.alarm,
              color: Theme.of(context).colorScheme.primary,
            ),
            scale: 1.2,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const ServicesScreen(serviceType: "standard"),
                ),
              );
            },
            price: '30',
          ),
          const SizedBox(height: 15),
          ServiceButton(
            modalSheet: () {
              showModalBottomSheet(
                showDragHandle: true,
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                isScrollControlled: true, // Makes it full height if needed
                builder: (context) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      List<String> serviceItems = [
                        'Full exterior wash',
                        'Deep interior clean',
                        'Wax protection',
                        'Tire shine',
                        'Air freshener',
                      ];
                      return Container(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(17),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Transform.scale(
                                        scale: 1.8,
                                        child: Center(
                                          child: SvgPicture.asset(
                                            'assets/icons/cleaning.svg',
                                            height: 24,
                                            width: 24,
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary, // 🎨 Replace with your desired color
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      text: 'Premium Detail',
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                      textSize: TextSizes.heading2,
                                      textWeight: FontWeight.bold,
                                    ),
                                    CustomText(
                                      text: 'Full detailing service',
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      textSize: TextSizes.subtitle1,
                                    ),
                                  ],
                                ),
                                Expanded(child: SizedBox()),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    CustomText(
                                      text: "\$12",
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.labelLarge?.color,
                                      textSize: TextSizes.heading1,
                                      textWeight: FontWeight.w800,
                                    ),
                                    CustomText(
                                      text: "120 min",
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      textSize: TextSizes.subtitle2,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CustomText(
                                      text: "Includes :",
                                      textSize: TextSizes.subtitle1,
                                      textWeight: FontWeight.bold,
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ],
                                ),

                                RegularButton(
                                  onPressed: () {},
                                  borderRadius: 50,
                                  textWidget: CustomText(
                                    text: 'Most Popular',
                                    textColor: Theme.of(
                                      context,
                                    ).colorScheme.inversePrimary,
                                    textSize: TextSizes.bodyText1,
                                    textWeight: FontWeight.w700,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 3,
                                    horizontal: 10,
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (var service in serviceItems)
                              Row(
                                children: [
                                  Icon(Icons.do_not_disturb_on_sharp, size: 13),
                                  const SizedBox(width: 5),
                                  CustomText(
                                    text: service,
                                    textColor: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                    textSize: TextSizes.subtitle1,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            textWidget1: 'Premium Detail',
            textWidget2: 'Full detailing service',
            textWidget3: '⏱️ 120 min',
            serviceItems: [
              'Full exterior wash',
              'Deep interior clean',
              'Wax protection',
              'Tire shine',
              'Air freshener',
            ],
            svg: SvgPicture.asset(
              'assets/icons/cleaning.svg',
              height: 24,
              width: 24,
              colorFilter: ColorFilter.mode(
                Theme.of(
                  context,
                ).colorScheme.primary, // 🎨 Replace with your desired color
                BlendMode.srcIn,
              ),
            ),
            scale: 1.5,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const ServicesScreen(serviceType: "premium"),
                ),
              );
            },
            price: '200',
          ),
          const SizedBox(height: 30),
          BannerCarousel(
            assets: [
              "assets/images/omeeo_banner.png",
              "assets/images/cleaning_banner.png",
            ],
            onTap: (i) {
              // handle tap per banner if you want
              // e.g., navigate or open a promo
            },
          ),

          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: 'Nearby Locations',
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                textSize: TextSizes.heading2,
                textWeight: FontWeight.w900,
              ),
              const SizedBox(height: 5),
              StationCard(
                title: 'Omeeo Car wash',
                address: 'Israel teikofio street, Sowutuom, Accra',
                rating: 5.0,
                reviews: 10,
                isOpen: true,
                openLabel: 'Open until 8:00 PM',
                phone: '+233557112580',
                lat: 5.6289516,
                lng: -0.2701519,
              ),

              const SizedBox(height: 20),
              PromoBannerCard(
                title: 'First Wash Free!',
                badgeText: 'New Customers',
                subtitle: 'First standard wash on us',
                onPressed: () async {
                  // 1) start a stage
                  // Make PRE-RINSE the only active stage (earlier=done, later=pending)
                  await adminSetActiveWashStageStrict(
                    bookingId: 'vNUu5adYrTlADdwzaoC1',
                    activeStageKey:
                        'cleaning', // hyphen/space/underscore all OK
                    adminId: 'admin_123',
                  );

                  /*  // Move to WASHING (pre-rinse becomes done, others pending)
                  await adminSetActiveWashStage(
                    bookingId: 'Qp9iq8FgsABY0vn79qCH',
                    activeStageKey: 'washing',
                    adminId: 'admin_123',
                  );

                  // Jump directly to RINSING (pre-rinse & washing become done)
                  await adminSetActiveWashStage(
                    bookingId: 'Qp9iq8FgsABY0vn79qCH',
                    activeStageKey: 'rinsing',
                  ); */
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class ServiceTabExpanded extends StatelessWidget {
  final String textWidget1;
  final String? animation;
  final String? textWidget2;
  final String textWidget3;
  final String? price;
  final String? stars;
  final Icon? icon;
  final SvgPicture? svg;
  final double? scale;
  final List<String>? serviceItems;
  const ServiceTabExpanded({
    super.key,
    required this.textWidget1,
    this.textWidget2,
    required this.textWidget3,
    this.price,
    this.icon,
    this.stars,
    this.animation,
    this.scale,
    this.svg,
    this.serviceItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(32, 137, 43, 226),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Transform.scale(
                    scale: scale,
                    child: Center(child: icon ?? svg),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: textWidget1,
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
                textWidget2 == null
                    ? SizedBox()
                    : CustomText(
                        text: textWidget2!,
                        textColor: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color,
                        textSize: TextSizes.bodyText1,
                      ),
                CustomText(
                  text: textWidget3,
                  textColor: Theme.of(context).textTheme.bodyMedium?.color,
                  textSize: TextSizes.bodyText1,
                ),
              ],
            ),
            Expanded(child: SizedBox()),
            price == null
                ? Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.solidStar,
                        size: IconSizes.midSmall,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 5),
                      CustomText(
                        text: stars!,
                        textColor: Theme.of(context).textTheme.bodyLarge?.color,
                        textSize: TextSizes.subtitle1,
                        textWeight: FontWeight.bold,
                      ),
                    ],
                  )
                : SizedBox(),
          ],
        ),

        Row(
          children: [
            CustomText(
              text: "Includes :",
              textSize: TextSizes.bodyText1,
              textWeight: FontWeight.bold,
              textColor: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ],
        ),

        for (var service in serviceItems!)
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
    );
  }
}

class CustomDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = "OK",
    String cancelText = "Cancel",
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.inversePrimary,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onCancel != null) onCancel();
                      },
                      child: Text(cancelText),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.inversePrimary,
                        foregroundColor: AppColors.primaryPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onConfirm != null) onConfirm();
                      },
                      child: Text(confirmText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.assets,
    this.cornerRadius = 20,
    this.viewportFraction = .92,
    this.onTap,
  });

  final List<String> assets;
  final double cornerRadius;
  final double viewportFraction;
  final void Function(int index)? onTap;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: widget.viewportFraction,
  );
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.cornerRadius);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.assets.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: widget.onTap == null ? null : () => widget.onTap!(i),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: Image.asset(
                      widget.assets[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.assets.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: active ? 18 : 8,
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// A sleek, dynamic rewards card.
/// Example:
/// RewardsPointsCard(currentPoints: 850, nextThreshold: 1000)
class RewardsPointsCard extends StatelessWidget {
  final int currentPoints;
  final int nextThreshold;
  final String title;
  final String encouragingText;
  final double height;
  final EdgeInsetsGeometry padding;

  const RewardsPointsCard({
    super.key,
    required this.currentPoints,
    required this.nextThreshold,
    this.title = 'Rewards Points',
    this.encouragingText = "You're doing great!",
    this.height = 120,
    this.padding = const EdgeInsets.all(15),
  });

  @override
  Widget build(BuildContext context) {
    final int toGoRaw = (nextThreshold - currentPoints);
    final int toGo = toGoRaw > 0 ? toGoRaw : 0;
    final double progress = nextThreshold <= 0
        ? 1.0
        : (currentPoints / nextThreshold).clamp(0.0, 1.0);

    final Color bg1 = const Color(0xFF1E1E1E);
    final Color bg2 = const Color(0xFF2D2D2D);
    final Color surface = const Color(0xFF121212);
    final Color track = Theme.of(
      context,
    ).colorScheme.inversePrimary.withOpacity(0.10);
    final Color fill = Theme.of(
      context,
    ).colorScheme.inversePrimary.withOpacity(0.85);
    final Color subtle = Theme.of(
      context,
    ).colorScheme.inversePrimary.withOpacity(0.70);
    final Color verySubtle = Theme.of(
      context,
    ).colorScheme.inversePrimary.withOpacity(0.55);

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg1, bg2],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: surface.withOpacity(.45),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Star in a pill
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.inversePrimary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Title + encouragement
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      encouragingText,
                      style: TextStyle(
                        color: subtle,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Points number on the right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(currentPoints),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'points',
                    style: TextStyle(
                      color: verySubtle,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Next reward + to-go
          Row(
            children: [
              Expanded(
                child: Text(
                  'Next reward at ${_fmt(nextThreshold)} pts',
                  style: TextStyle(
                    color: verySubtle,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                toGo > 0 ? '${_fmt(toGo)} to go' : 'Goal reached!',
                style: TextStyle(
                  color: subtle,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          _AnimatedProgressBar(
            progress: progress,
            backgroundColor: track,
            fillColor: fill,
            height: 10,
            borderRadius: 99,
          ),
        ],
      ),
    );
  }

  // Minimal thousands separator without extra deps.
  static String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      b.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        b.write(',');
        count = 0;
      }
    }
    return b.toString().split('').reversed.join();
  }
}

/// Smooth animated progress bar used by the card
class _AnimatedProgressBar extends StatelessWidget {
  final double progress; // 0..1
  final Color backgroundColor;
  final Color fillColor;
  final double height;
  final double borderRadius;

  const _AnimatedProgressBar({
    required this.progress,
    required this.backgroundColor,
    required this.fillColor,
    this.height = 8,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          return Stack(
            children: [
              Container(width: maxW, height: height, color: backgroundColor),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: maxW * progress,
                height: height,
                // a subtle sheen across the fill
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [fillColor, fillColor.withOpacity(.65)],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Callout / promo banner, e.g. "First Wash Free!"
class PromoBannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final String? badgeText;
  final IconData leadingIcon;
  final VoidCallback onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const PromoBannerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.buttonText = 'Claim Now',
    this.badgeText,
    this.leadingIcon =
        Icons.flare, // (Material 3 alt) use Icons.star_rounded if you like
    this.borderRadius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final Color dark1 = const Color(0xFF1F1F1F);
    final Color dark2 = const Color(0xFF2B2B2B);
    final Color pillFg = Theme.of(
      context,
    ).colorScheme.inversePrimary.withOpacity(.9);
    final Color pillBg = Theme.of(
      context,
    ).colorScheme.inversePrimary.withOpacity(.12);
    final Color btnFg = Colors.black87;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [dark1, dark2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.surface,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: padding,
        child: Row(
          children: [
            // Left: circular icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                leadingIcon,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: IconSizes.medium,
              ),
            ),
            const SizedBox(width: 12),

            // Middle: title (+ optional badge) and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Badge row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right: CTA button
            TextButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.chevron_right_rounded, size: 16),
              label: Text(
                buttonText,
                style: TextStyle(
                  color: btnFg,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.inversePrimary,
                ),
                foregroundColor: WidgetStatePropertyAll(btnFg),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                overlayColor: WidgetStatePropertyAll(Colors.black12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StationCard extends StatelessWidget {
  final String title;
  final String address;
  final double rating; // e.g. 4.8
  final int reviews; // e.g. 342
  final bool isOpen; // true = open, false = closed
  final String openLabel; // e.g. "Open until 8:00 PM" or "Closed"
  final String? phone; // for "Call Now"
  final double? lat; // for "Get Directions"
  final double? lng;

  final VoidCallback? onDirections; // optional override
  final VoidCallback? onCall; // optional override

  const StationCard({
    super.key,
    required this.title,
    required this.address,
    required this.rating,
    required this.reviews,
    required this.isOpen,
    required this.openLabel,
    this.phone,
    this.lat,
    this.lng,
    this.onDirections,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Theme.of(context).brightness == Brightness.dark
        ? cs.surface
        : Theme.of(context).colorScheme.inversePrimary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontSize: TextSizes.subtitle1,
              fontWeight: FontWeight.w800,
            ),
          ),

          // Address
          Text(
            address,
            style: TextStyle(
              color: Theme.of(context).colorScheme.tertiary,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),

          // Rating pill + open pill
          Row(
            children: [
              _ratingPill(context, rating, reviews),
              const SizedBox(width: 12),
              _openPill(context, openLabel, isOpen),
            ],
          ),

          const SizedBox(height: 8),

          // Buttons row
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onDirections ?? () => _launchDirections(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.inversePrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Get Directions',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCall ?? () => _launchCall(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.inversePrimary,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Call Now',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Pills ---

  Widget _ratingPill(BuildContext context, double rating, int reviews) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($reviews)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _openPill(BuildContext context, String label, bool isOpen) {
    final color = isOpen ? const Color(0xFF1F8F3A) : const Color(0xFFAA2E2E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // --- Launchers (maps / phone) ---

  Future<void> _launchDirections() async {
    final encodedAddress = Uri.encodeComponent(address);
    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&q=$encodedAddress',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress',
      );
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _launchCall() async {
    if (phone == null || phone!.trim().isEmpty) return;
    final tel = Uri(scheme: 'tel', path: phone!.trim());
    await launchUrl(tel);
  }
}

/// Make `activeStageKey` the ONLY active stage:
/// - all stages BEFORE it → `done` (+completedAt)
/// - that stage → `in_progress` (+startedAt, completedAt=null)
/// - all stages AFTER it → `pending` (startedAt/completedAt=null)
///
/// If `washStageOrder` is missing, we derive an order from washStages keys or
/// fall back to the default order.

Future<void> adminSetActiveWashStageStrict({
  required String bookingId,
  required String activeStageKey, // e.g. "pre-rinse", "washing"
  String? adminId, // optional for audit
  List<String> defaultOrder = const [
    'pre_rinse',
    'washing',
    'rinsing',
    'cleaning',
  ],
  bool createIfMissing =
      false, // set true only if you WANT to seed missing keys
}) async {
  final db = FirebaseFirestore.instance;
  final ref = db.collection('bookings').doc(bookingId);

  String norm(String k) =>
      k.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]+'), '_');

  await db.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) throw Exception('Booking not found: $bookingId');

    final data = Map<String, dynamic>.from(snap.data() ?? {});

    // Existing map of stages (normalized keys)
    final rawStages =
        (data['washStages'] as Map?)?.cast<String, dynamic>() ?? {};
    final hasSchema = rawStages.isNotEmpty;

    if (!hasSchema && !createIfMissing) {
      // abort: nothing to update without creating fields
      throw Exception(
        'washStages schema not present on booking; not creating new fields.',
      );
    }

    final stages = <String, Map<String, dynamic>>{};
    rawStages.forEach(
      (k, v) => stages[norm(k)] = Map<String, dynamic>.from(v ?? {}),
    );

    // Use existing order if present; otherwise fall back (but only write it if createIfMissing)
    final rawOrder =
        (data['washStageOrder'] as List?)
            ?.map((e) => norm(e.toString()))
            .toList() ??
        defaultOrder;

    // If we are not creating, restrict the order to keys that already exist
    List<String> order = createIfMissing
        ? List<String>.from(rawOrder)
        : rawOrder.where((k) => stages.containsKey(k)).toList();

    final active = norm(activeStageKey);

    if (!order.contains(active)) {
      if (createIfMissing) {
        order.add(active); // allowed to seed
      } else {
        throw Exception(
          "Stage '$activeStageKey' doesn't exist in washStages; strict mode won't create it.",
        );
      }
    }
    if (!createIfMissing && !stages.containsKey(active)) {
      throw Exception(
        "Stage '$activeStageKey' missing in washStages; strict mode won't create it.",
      );
    }

    final activeIdx = order.indexOf(active);
    bool anyActive = false;
    bool allDone = true;

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only write washStageOrder if it already exists OR we're allowed to create
    if (data.containsKey('washStageOrder') || createIfMissing) {
      updates['washStageOrder'] = order;
    }

    // Update only existing keys unless we allow creation
    for (int i = 0; i < order.length; i++) {
      final key = order[i];
      final exists = stages.containsKey(key);

      if (!createIfMissing && !exists) continue; // skip non-existent keys

      final prev = Map<String, dynamic>.from(stages[key] ?? const {});
      final isBefore = i < activeIdx;
      final isActive = i == activeIdx;

      if (isBefore) {
        updates['washStages.$key.status'] = 'done';
        updates['washStages.$key.startedAt'] =
            prev['startedAt'] ?? FieldValue.serverTimestamp();
        updates['washStages.$key.completedAt'] =
            prev['completedAt'] ?? FieldValue.serverTimestamp();
      } else if (isActive) {
        anyActive = true;
        allDone = false;
        updates['washStages.$key.status'] = 'in_progress';
        updates['washStages.$key.startedAt'] =
            prev['startedAt'] ?? FieldValue.serverTimestamp();
        updates['washStages.$key.completedAt'] = null;
      } else {
        allDone = false;
        updates['washStages.$key.status'] = 'pending';
        updates['washStages.$key.startedAt'] = null;
        updates['washStages.$key.completedAt'] = null;
      }
    }

    // Overall booking.status
    final currentOverall = '${data['status'] ?? ''}'.toLowerCase();
    String nextOverall;
    if (allDone) {
      nextOverall = 'completed';
      updates['completedAt'] = FieldValue.serverTimestamp();
    } else if (anyActive) {
      nextOverall = 'in_progress';
    } else {
      nextOverall = currentOverall.isEmpty ? 'confirmed' : currentOverall;
    }
    if (nextOverall != currentOverall) updates['status'] = nextOverall;

    tx.update(ref, updates);
  });

  // Best-effort audit trail (doesn't create structural fields)
  try {
    await ref.update({
      'washHistory': FieldValue.arrayUnion([
        {
          'action': 'set_active_stage',
          'stage': activeStageKey,
          'to': 'in_progress',
          'at': Timestamp.now(),
          if (adminId != null) 'by': adminId,
        },
      ]),
    });
  } catch (_) {
    /* ignore */
  }
}
