import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/services_screen.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

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
            color: Color.fromARGB(60, 0, 0, 0),
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
                  /*  border: Border.all(color: Colors.white, width: 2), */
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
              Row(
                children: [
                  Expanded(
                    child: LocationTab(
                      textWidget1: 'Omeeo Wash',
                      textWidget3: '0.8 mi away',
                      icon: Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      scale: 1.5,
                      onPressed: () {},
                      stars: '4.9',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LocationTab(
                      textWidget1: 'Omeeo Wash',
                      textWidget3: '0.8 mi away',
                      icon: Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      scale: 1.5,
                      onPressed: () {},
                      stars: '4.9',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PromoButtom(
                padding: EdgeInsets.all(15),
                textWidget1: CustomText(text: 'First Wash Free!'),
                textWidget2: CustomText(
                  text: 'New customers get their first basic wash on us',
                  textSize: TextSizes.bodyText2,
                ),
                onPressed: () {},
                borderRadius: 20,
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

class LocationTab extends StatelessWidget {
  final String textWidget1;
  final String? animation;
  final String? textWidget2;
  final String textWidget3;
  final String? price;
  final String? stars;
  final Icon? icon;
  final SvgPicture? svg;
  final double? scale;
  final VoidCallback onPressed;
  final bool isSelected;
  const LocationTab({
    super.key,
    required this.textWidget1,
    this.textWidget2,
    required this.textWidget3,
    this.price,
    this.icon,
    required this.onPressed,
    this.stars,
    this.animation,
    this.scale,
    this.svg,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: isSelected
              ? AppColors.pink
              : Theme.of(context).colorScheme.inversePrimary,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(26, 12, 0, 235),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 6), // x, y
            ),
          ],
        ),
        padding: EdgeInsets.all(10),

        child: Column(
          children: [
            Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromARGB(196, 235, 204, 255)
                            : Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(20),
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
                      textColor: isSelected
                          ? AppColors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      textSize: TextSizes.bodyText1,
                      textWeight: FontWeight.bold,
                    ),

                    CustomText(
                      text: textWidget3,
                      textColor: isSelected
                          ? AppColors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      textSize: TextSizes.bodyText1,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.solidStar,
                          size: IconSizes.tiny,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 5),
                        CustomText(
                          text: stars!,
                          textColor: Theme.of(context).colorScheme.primary,
                          textSize: TextSizes.caption,
                          textWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* class HomeScreenBottomSection extends StatelessWidget {
  const HomeScreenBottomSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // background
        Positioned.fill(
          child: Container(
            color: const Color.fromARGB(213, 255, 255, 255),
            height: 600,
          ),
        ),
        Positioned.fill(
          child: Lottie.asset(
            'assets/animations/background_animation.json',
            fit: BoxFit.cover,
          ),
        ),

        // Foreground content
        Container(
          color: const Color.fromARGB(55, 255, 255, 255),
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: 'Nearby Locations',
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                textSize: TextSizes.heading2,
                textWeight: FontWeight.bold,
              ),
              const SizedBox(height: 20),
              ServiceButton(
                textWidget1: 'Omeeo Wash',
                textWidget3: '0.8 mi away',
                icon: FontAwesomeIcons.locationDot,
                onPressed: () {},
                stars: '4.9',
                iconColor: Theme.of(context).colorScheme.primary,
                iconSize: IconSizes.medium,
              ),
              const SizedBox(height: 20),
              PromoButtom(
                padding: EdgeInsets.all(10),
                textWidget1: CustomText(text: 'First Wash Free!'),
                textWidget2: CustomText(
                  text: 'New customers get their first basic wash on us',
                ),
                onPressed: () {},
                borderRadius: 7,
              ),
            ],
          ),
        ),
      ],
    );
  }
} */

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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onCancel != null) onCancel();
                      },
                      child: Text(cancelText),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
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
