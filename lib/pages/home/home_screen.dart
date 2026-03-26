import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/auto_care/auto_care_services.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/home_office_spaces/home_office_spaces.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/laundry_services.dart';
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
      padding: EdgeInsets.all(5),

      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 177, 177, 177),
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
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: CustomText(
                      text: 'Good morning',
                      textColor: Theme.of(context).colorScheme.surface,
                      textSize: TextSizes.subtitle1,
                      textWeight: FontWeight.w700,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: CustomText(
                      text: 'Welcome back, Sarah!',
                      textColor: Theme.of(context).colorScheme.primary,
                      textSize: TextSizes.heading2,
                      textWeight: FontWeight.w900,
                    ),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: IconStackTextButton(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  sideIconString: 'assets/images/shop.png',
                  icon: Icon(
                    FontAwesomeIcons.calendar,
                    size: IconSizes.small,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  textWidget: CustomText(
                    text: 'Shop Products',
                    textColor: Theme.of(context).colorScheme.inversePrimary,
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.bold,
                  ),
                  textWidget2: CustomText(
                    text: 'Keychains, mats, cleaning materials & more',
                    textColor: Theme.of(context).colorScheme.onSecondary,
                    textSize: TextSizes.bodyText2,
                    textWeight: FontWeight.bold,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const AutoCareServicesScreen(),
                      ),
                    );
                  },
                  borderRadius: 12,
                  lottieAsset:
                      "assets/animations/cart_icon_loader.json", // 👈 your Lottie file
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

  final chipBg = const Color(0xFFEDE9FE); // very light periwinkle-purple
  final chipBorder = const Color(0xFFC4B5FD); // soft border
  final chipFg = const Color(0xFF5B21B6); // deep readable purple (text/icon)
  final panelBg = const Color(0xFFF5F3FF); // extra light panel background
  final panelBorder = const Color(0xFFC4B5FD); // match border
  final dot = const Color(0xFF8B5CF6); // vivid periwinkle dot

  final chipBg1 = const Color(0xFFCCFBF1); // light seafoam (bg)
  final chipBorder1 = const Color(0xFF5EEAD4); // seafoam border
  final chipFg1 = const Color(0xFF0F766E); // deep teal (text/icon)
  final panelBg1 = const Color(0xFFF0FDFA); // very light seafoam panel
  final panelBorder1 = const Color(0xFF5EEAD4); // panel border
  final dot1 = const Color(0xFF14B8A6); // seafoam accent dot

  final chipBg2 = const Color(0xFFFCE7F3); // light periwinkle-pink (bg)
  final chipBorder2 = const Color(0xFFF9A8D4); // periwinkle-pink border
  final chipFg2 = const Color(0xFF7C3AED); // deep periwinkle-purple (text/icon)
  final panelBg2 = const Color(0xFFFFF1F7); // very light pink panel
  final panelBorder2 = const Color(0xFFF9A8D4); // panel border
  final dot2 = const Color(0xFFA855F7); // periwinkle accent dot

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),

          ServiceCard(
            pictureString: [
              'assets/images/house.png',
              'assets/images/office.png',
              'assets/images/sofa.png',
              'assets/images/carpet.png',
              'assets/images/toilet.png',
            ],
            title: 'Home / Office Spaces',
            subtitle: 'Home and Office cleaning service',
            priceText: r'$120',
            durationText: '3 hrs',
            icon: Icons.home,
            isPopular: true,
            sideIconString: 'assets/images/office.png',
            boxShadowColor: Color.fromARGB(255, 51, 0, 255),
            iconBackgroundColor: Color.fromARGB(255, 206, 193, 255),
            colorList: [Color(0xFFC4B5FD), Color(0xFFC4B5FD)],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const HomeOfficeSpacesServicesScreen(serviceType: ""),
                ),
              );
            },
            servicesCTA: Column(
              children: [
                const SizedBox(height: 15),
                ServiceButton(
                  modalSheet: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      isScrollControlled:
                          true, // Makes it full height if needed
                      builder: (context) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            List<String> serviceItems = [
                              'Exterior wash',
                              'Tire shine',
                            ];
                            return Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              padding: const EdgeInsets.all(17),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                        Icon(
                                          Icons.do_not_disturb_on_sharp,
                                          size: 13,
                                        ),
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
                  textWidget1: 'Apartment Cleaning',
                  textWidget2: 'Perfect for apartment & condos',
                  textWidget3: '⏱️ 2hrs',
                  serviceItems: ['Exterior wash & dry', 'Tire shine'],
                  icon: Icon(
                    FontAwesomeIcons.building,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  scale: 1.1,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const AutoCareServicesScreen(
                              serviceType: "express",
                            ),
                      ),
                    );
                  },
                  price: '10',
                ),
                const SizedBox(height: 10),
                ServiceButton(
                  modalSheet: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      isScrollControlled:
                          true, // Makes it full height if needed
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
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(17),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            text:
                                                'Complete exterior & interior',
                                            textColor: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                            textSize: TextSizes.subtitle1,
                                          ),
                                        ],
                                      ),
                                      Expanded(child: SizedBox()),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                        Icon(
                                          Icons.do_not_disturb_on_sharp,
                                          size: 13,
                                        ),
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
                  textWidget1: 'Office Cleaning',
                  textWidget2: 'Professional workspace cleaning',
                  textWidget3: '⏱️ 4 hrs',
                  serviceItems: [
                    'Exterior wash',
                    'Interior clean & vacuum',
                    'Tire shine',
                  ],
                  icon: Icon(
                    Icons.work,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  scale: 1.1,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const AutoCareServicesScreen(
                              serviceType: "standard",
                            ),
                      ),
                    );
                  },
                  price: '30',
                ),
                const SizedBox(height: 10),
                ServiceButton(
                  modalSheet: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      isScrollControlled:
                          true, // Makes it full height if needed
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
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(17),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            text:
                                                'Complete exterior & interior',
                                            textColor: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                            textSize: TextSizes.subtitle1,
                                          ),
                                        ],
                                      ),
                                      Expanded(child: SizedBox()),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                        Icon(
                                          Icons.do_not_disturb_on_sharp,
                                          size: 13,
                                        ),
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
                  textWidget1: 'Move-In/Out Cleaning',
                  textWidget2: 'Perfect for relocations',
                  textWidget3: '⏱️ 4 hrs',
                  serviceItems: [
                    'Full exterior wash',
                    'Deep interior clean',
                    'Wax protection',
                    'Tire shine',
                    'Air freshener',
                  ],
                  icon: Icon(
                    FontAwesomeIcons.doorOpen,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  scale: 1.1,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const AutoCareServicesScreen(
                              serviceType: "standard",
                            ),
                      ),
                    );
                  },
                  price: '30',
                ),
                const SizedBox(height: 10),
                ServiceButton(
                  modalSheet: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      isScrollControlled:
                          true, // Makes it full height if needed
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
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(17),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                        Icon(
                                          Icons.do_not_disturb_on_sharp,
                                          size: 13,
                                        ),
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
                  textWidget1: 'Upholstery Deep Clean',
                  textWidget2: 'Professional furniture restoration',
                  textWidget3: '⏱️ 2.5 hrs',
                  serviceItems: [
                    'Full exterior wash',
                    'Deep interior clean',
                    'Wax protection',
                    'Tire shine',
                    'Air freshener',
                  ],
                  svg: SvgPicture.asset(
                    'assets/icons/sofa.svg',
                    height: 24,
                    width: 24,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context)
                          .colorScheme
                          .primary, // 🎨 Replace with your desired color
                      BlendMode.srcIn,
                    ),
                  ),
                  scale: 1.4,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const AutoCareServicesScreen(
                              serviceType: "premium",
                            ),
                      ),
                    );
                  },
                  price: '200',
                ),
                const SizedBox(height: 10),
                ServiceButton(
                  modalSheet: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      isScrollControlled:
                          true, // Makes it full height if needed
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
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(17),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            text:
                                                'Complete exterior & interior',
                                            textColor: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                            textSize: TextSizes.subtitle1,
                                          ),
                                        ],
                                      ),
                                      Expanded(child: SizedBox()),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                        Icon(
                                          Icons.do_not_disturb_on_sharp,
                                          size: 13,
                                        ),
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
                  textWidget1: 'Carpet Cleaning',
                  textWidget2: 'Deep carpet & upholstery care',
                  textWidget3: '⏱️ 2 hrs',
                  serviceItems: [
                    'Exterior wash',
                    'Interior clean & vacuum',
                    'Tire shine',
                  ],
                  icon: Icon(
                    FontAwesomeIcons.rug,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  scale: 1.1,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const AutoCareServicesScreen(
                              serviceType: "standard",
                            ),
                      ),
                    );
                  },
                  price: '30',
                ),
              ],
            ),
          ),

          const SizedBox(height: 17),
          ServiceCard(
            pictureString: [
              'assets/images/car.png',
              'assets/images/engine.png',
              'assets/images/dashboard.png',
              'assets/images/tyre.png',
              'assets/images/seat.png',
            ],
            title: 'Auto Care',
            subtitle: 'Car cleaning and detailing service',
            priceText: r'$120',
            durationText: '3 hrs',
            isPopular: true,
            sideIconString: 'assets/images/car.png',
            boxShadowColor: Color.fromARGB(255, 0, 255, 217),
            iconBackgroundColor: Color.fromARGB(143, 166, 255, 230),
            colorList: [Color(0xFF92E6D9), Color(0xFF92E6D9)],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const AutoCareServicesScreen(serviceType: ""),
                ),
              );
            },
            servicesCTA: Column(
              children: [
                const SizedBox(height: 15),
                ServiceButton(
                  modalSheet: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      isScrollControlled:
                          true, // Makes it full height if needed
                      builder: (context) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            List<String> serviceItems = [
                              'Exterior wash',
                              'Tire shine',
                            ];
                            return Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              padding: const EdgeInsets.all(17),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                        Icon(
                                          Icons.do_not_disturb_on_sharp,
                                          size: 13,
                                        ),
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
                            const AutoCareServicesScreen(
                              serviceType: "express",
                            ),
                      ),
                    );
                  },
                  price: '10',
                ),
                const SizedBox(height: 10),
                ServiceButton(
                  modalSheet: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      isScrollControlled:
                          true, // Makes it full height if needed
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
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(17),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            text:
                                                'Complete exterior & interior',
                                            textColor: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                            textSize: TextSizes.subtitle1,
                                          ),
                                        ],
                                      ),
                                      Expanded(child: SizedBox()),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                        Icon(
                                          Icons.do_not_disturb_on_sharp,
                                          size: 13,
                                        ),
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
                            const AutoCareServicesScreen(
                              serviceType: "standard",
                            ),
                      ),
                    );
                  },
                  price: '30',
                ),
                const SizedBox(height: 10),
                ServiceButton(
                  modalSheet: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      isScrollControlled:
                          true, // Makes it full height if needed
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
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(17),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                        Icon(
                                          Icons.do_not_disturb_on_sharp,
                                          size: 13,
                                        ),
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
                      Theme.of(context)
                          .colorScheme
                          .primary, // 🎨 Replace with your desired color
                      BlendMode.srcIn,
                    ),
                  ),
                  scale: 1.5,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const AutoCareServicesScreen(
                              serviceType: "premium",
                            ),
                      ),
                    );
                  },
                  price: '200',
                ),
              ],
            ),
            onSelectedChanged: (selected) {
              // optional: keep only one card open, analytics, etc.
            },
          ),
          const SizedBox(height: 17),
          ServiceCard(
            pictureString: [
              'assets/images/washing_machine.png',
              'assets/images/basket.png',
              'assets/images/sock.png',
              'assets/images/iron.png',
              'assets/images/shirt.png',
            ],
            title: 'Laundry',
            subtitle: 'Wash, dry & iron for all garments',
            priceText: r'$120',
            durationText: '3 hrs',
            isPopular: true,
            sideIconString: 'assets/images/basket.png',
            boxShadowColor: Color.fromARGB(255, 255, 0, 140),
            iconBackgroundColor: Color.fromARGB(125, 255, 236, 246),
            colorList: [
              Color.fromARGB(255, 255, 199, 230),
              Color.fromARGB(255, 255, 199, 230),
            ],
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const LaundryServicesScreen(serviceType: ""),
                ),
              );
            },
            servicesCTA: Column(
              children: [
                const SizedBox(height: 15),
                ServiceButton(
                  modalSheet: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      isScrollControlled:
                          true, // Makes it full height if needed
                      builder: (context) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            List<String> serviceItems = [
                              'Exterior wash',
                              'Tire shine',
                            ];
                            return Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              padding: const EdgeInsets.all(17),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                        Icon(
                                          Icons.do_not_disturb_on_sharp,
                                          size: 13,
                                        ),
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
                            const AutoCareServicesScreen(
                              serviceType: "express",
                            ),
                      ),
                    );
                  },
                  price: '10',
                ),
                const SizedBox(height: 10),
                ServiceButton(
                  modalSheet: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      isScrollControlled:
                          true, // Makes it full height if needed
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
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(17),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            text:
                                                'Complete exterior & interior',
                                            textColor: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                            textSize: TextSizes.subtitle1,
                                          ),
                                        ],
                                      ),
                                      Expanded(child: SizedBox()),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                        Icon(
                                          Icons.do_not_disturb_on_sharp,
                                          size: 13,
                                        ),
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
                            const AutoCareServicesScreen(serviceType: ""),
                      ),
                    );
                  },
                  price: '30',
                ),
                const SizedBox(height: 10),
                ServiceButton(
                  modalSheet: () {
                    showModalBottomSheet(
                      showDragHandle: true,
                      context: context,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inversePrimary,
                      isScrollControlled:
                          true, // Makes it full height if needed
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
                              color: Theme.of(
                                context,
                              ).colorScheme.inversePrimary,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(17),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                        Icon(
                                          Icons.do_not_disturb_on_sharp,
                                          size: 13,
                                        ),
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
                      Theme.of(context)
                          .colorScheme
                          .primary, // 🎨 Replace with your desired color
                      BlendMode.srcIn,
                    ),
                  ),
                  scale: 1.5,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) =>
                            const AutoCareServicesScreen(serviceType: ""),
                      ),
                    );
                  },
                  price: '200',
                ),
              ],
            ),
            onSelectedChanged: (selected) {
              // optional: keep only one card open, analytics, etc.
            },
          ),

          const SizedBox(height: 20),

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
                onPressed: () async {},
              ),
              const SizedBox(height: 15),
              RewardsPointsCard(
                currentPoints: 850,
                nextThreshold: 1000,
                // Optional:
                // title: 'Rewards Points',
                // encouragingText: "You're doing great!",
              ),
              const SizedBox(height: 15),
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

    final Color bg1 = const Color.fromARGB(255, 19, 47, 46);
    final Color bg2 = const Color.fromARGB(255, 43, 37, 86);
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
                child: Icon(Icons.star_rounded, color: Colors.amber, size: 22),
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
    final Color bg1 = const Color.fromARGB(255, 19, 47, 46);
    final Color bg2 = const Color.fromARGB(255, 43, 37, 86);
    /* final Color bg1 = const Color(0xFF1F2240); // deep periwinkle (dark)
    final Color bg2 = const Color(0xFF2E335C); // lighter periwinkle (dark) */
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
            colors: [bg1, bg2],
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
          Icon(Icons.star_rounded, size: 16, color: Colors.amber),
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

class ServiceCard extends StatefulWidget {
  const ServiceCard({
    super.key,
    required this.title,
    required this.colorList,
    required this.iconBackgroundColor,
    required this.subtitle,
    required this.priceText, // e.g. "$120" or "₵120"
    required this.durationText, // e.g. "3 hrs"
    this.icon = Icons.home_outlined,
    this.isPopular = false,
    this.onTap,
    required this.pictureString,
    this.initiallySelected = false,
    this.onSelectedChanged,
    this.servicesCTA,
    this.sideIconString,
    required this.boxShadowColor, // what appears when selected (e.g., ServiceButton)
  });

  final String title;
  final List<Color> colorList;
  final Color iconBackgroundColor;
  final Color boxShadowColor;
  final String subtitle;
  final String? sideIconString;
  final String priceText;
  final String durationText;
  final IconData icon;
  final bool isPopular;
  final List<String> pictureString;
  final VoidCallback? onTap;

  /// selection controls
  final bool initiallySelected;
  final ValueChanged<bool>? onSelectedChanged;
  final Widget? servicesCTA;

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface.withOpacity(0.85);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colorList,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.boxShadowColor.withOpacity(0.22),
                blurRadius: 30,
                spreadRadius: 1,
                offset: const Offset(0, 13),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => SizeTransition(
                  sizeFactor: anim, // smooth collapse/expand
                  axisAlignment: -1.0,
                  child: FadeTransition(
                    opacity: anim, // fade while resizing
                    child: child,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,

                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: widget.iconBackgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3.5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),

                          child: Image.asset(
                            widget.sideIconString!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // —— title ——
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w800,
                            // keep your TextSizes if you have them in your project
                            // fontSize: TextSizes.subtitle1,
                          ),
                        ),

                        // —— subtitle ——
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(
                              0.55,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(path, fit: BoxFit.cover),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}




/* AnimatedSwitcher(
                        duration: const Duration(milliseconds: 0),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => SizeTransition(
                          sizeFactor: anim, // smooth collapse/expand
                          axisAlignment: -1.0,
                          child: FadeTransition(
                            opacity: anim, // fade while resizing
                            child: child,
                          ),
                        ),
                        child: _selected
                            ? Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.asset(
                                    widget.sideIconString!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : const SizedBox(key: ValueKey('thumbs-hidden')),
                      ), */



































  /*    AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => SizeTransition(
                  sizeFactor: anim, // smooth collapse/expand
                  axisAlignment: -1.0,
                  child: FadeTransition(
                    opacity: anim, // fade while resizing
                    child: child,
                  ),
                ),
                child: _selected
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // —— title ——
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: onSurface,
                                  fontWeight: FontWeight.w800,
                                  // keep your TextSizes if you have them in your project
                                  // fontSize: TextSizes.subtitle1,
                                ),
                              ),

                              // —— subtitle ——
                              Text(
                                widget.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.55),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: widget.iconBackgroundColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3.5),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),

                                child: Image.asset(
                                  widget.sideIconString!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(key: ValueKey('thumbs-hidden')),
              ),
 */
            






































                      /* // —— thumbnails row (HIDES on tap) ——
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => SizeTransition(
                  sizeFactor: anim, // smooth collapse/expand
                  axisAlignment: -1.0,
                  child: FadeTransition(
                    opacity: anim, // fade while resizing
                    child: child,
                  ),
                ),
                child: !_selected
                    ? Padding(
                        key: const ValueKey('thumbs'),
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: widget.pictureString
                              .take(math.min(widget.pictureString.length, 5))
                              .map((p) => _Thumbnail(path: p))
                              .toList(),
                        ),
                      )
                    : const SizedBox(key: ValueKey('thumbs-hidden')),
              ),*/
