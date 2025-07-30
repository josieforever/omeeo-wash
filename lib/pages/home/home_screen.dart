import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/pages/home/booking%20flow/services_screen.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.transparent,
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
      padding: EdgeInsets.all(10),
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
                  CustomText(
                    text: 'Hello, Sarah!',
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.heading1,
                    textWeight: FontWeight.w900,
                  ),
                  CustomText(
                    text: 'Ready to wash your 🚗?',
                    textColor: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.color,
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
                      color: Theme.of(context).textTheme.headlineLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      FontAwesomeIcons.solidUser,
                      size: IconSizes.midSmall,
                      color: Theme.of(context).textTheme.headlineLarge?.color,
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
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                  ),
                  textWidget: CustomText(
                    text: 'Book Now',
                    textColor: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.color,
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
                  borderRadius: 7,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: IconStackTextButton(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  icon: Icon(
                    FontAwesomeIcons.locationDot,
                    size: IconSizes.small,
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                  ),
                  textWidget: CustomText(
                    text: 'Find Location',
                    textColor: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.color,
                    textSize: TextSizes.subtitle2,
                    textWeight: FontWeight.bold,
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
          CustomText(
            text: 'Our Services',
            textColor: Theme.of(context).textTheme.bodyLarge?.color,
            textSize: TextSizes.heading2,
            textWeight: FontWeight.w900,
          ),
          const SizedBox(height: 10),
          ServiceButton(
            textWidget1: 'Basic Wash',
            textWidget2: 'Exterior wash & dry',
            textWidget3: '⌚10 min',
            icon: Icon(
              FontAwesomeIcons.shower,
              color: Theme.of(context).colorScheme.primary,
            ),
            scale: 1.2,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      const ServicesScreen(serviceType: "basic"),
                ),
              );
            },
            price: '10',
          ),

          const SizedBox(height: 10),
          ServiceButton(
            textWidget1: 'Express Premium Wash',
            textWidget2: 'Quick wash, interior clean & vacuum',
            textWidget3: '⌚25 min',
            icon: Icon(
              Icons.alarm,
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
            price: '30',
          ),
          const SizedBox(height: 10),
          ServiceButton(
            textWidget1: 'Premium Detail',
            textWidget2: 'Full interior & exterior detail',
            textWidget3: '⌚90 min',
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              CustomText(
                text: 'Nearby Locations',
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
                textSize: TextSizes.heading2,
                textWeight: FontWeight.w900,
              ),
              const SizedBox(height: 20),
              ServiceButton(
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
              const SizedBox(height: 10),
              PromoButtom(
                padding: EdgeInsets.all(10),
                textWidget1: CustomText(text: 'First Wash Free!'),
                textWidget2: CustomText(
                  text: 'New customers get their first basic wash on us',
                  textSize: TextSizes.bodyText2,
                ),
                onPressed: () {},
                borderRadius: 7,
              ),
              const SizedBox(height: 60),
            ],
          ),
        ],
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
