import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/providers/top_nav_provider.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.transparent,
        child: Column(children: [BookingScreenTopBar(), TopNavTabSwitcher()]),
      ),
    );
  }
}

class BookingScreenTopBar extends StatelessWidget {
  const BookingScreenTopBar({super.key});
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
                    text: 'My Bookings',
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.heading1,
                    textWeight: FontWeight.w900,
                  ),
                  CustomText(
                    text: 'Manage appointments 📚',
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
                      FontAwesomeIcons.filter,
                      size: IconSizes.midSmall,
                      color: Theme.of(context).textTheme.headlineLarge?.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      FontAwesomeIcons.plus,
                      size: IconSizes.midSmall,
                      color: Theme.of(context).textTheme.headlineLarge?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomTopNav(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class CustomTopNav extends StatefulWidget {
  const CustomTopNav({super.key});

  @override
  State<CustomTopNav> createState() => _CustomTopNavState();
}

class _CustomTopNavState extends State<CustomTopNav> {
  @override
  Widget build(BuildContext context) {
    final topNavProvider = Provider.of<TopNavProvider>(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: const Color.fromARGB(55, 255, 255, 255),
      ),

      padding: EdgeInsets.all(6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TopNavBarTab(
            onPressed: () {
              topNavProvider.selectTab('New');
            },
            textWidget: 'New',
            numberWidget: '2',
            borderRadius: 10,
          ),
          TopNavBarTab(
            onPressed: () {
              topNavProvider.selectTab('Past');
            },
            textWidget: 'Past',
            numberWidget: '2',
            borderRadius: 10,
          ),
          TopNavBarTab(
            onPressed: () {
              topNavProvider.selectTab('Pending');
            },
            textWidget: 'Pending',
            numberWidget: '1',
            borderRadius: 10,
          ),
        ],
      ),
    );
  }
}

class TopNavTabSwitcher extends StatelessWidget {
  const TopNavTabSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTab = context.watch<TopNavProvider>().tabName;

    switch (selectedTab) {
      case 'New':
        return const NewTabScreen();
      case 'Past':
        return const PastTabScreen();
      case 'Pending':
        return const PendingTabScreen();
      default:
        return const NewTabScreen(); // default fallback
    }
  }
}

class NewTabScreen extends StatelessWidget {
  const NewTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Foreground content
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              BookingsServiceButton(
                textWidget1: 'Premium Detail',
                textWidget2: '📍Omeeo Car wash',
                status: 'Confirmed',
                day: '🗓️Today',
                time: '⌚2:30 PM',
                duration: '⌚90 min',
                icon: Icon(
                  FontAwesomeIcons.carSide,
                  size: TextSizes.bodyText1,
                  color: const Color.fromARGB(255, 226, 226, 226),
                ),
                scale: 1.7,
                onPressed: () {},
                price: '150',
                iconColor: Theme.of(context).colorScheme.primary,
                iconSize: IconSizes.medium,
              ),
              const SizedBox(height: 10),
              BookingsServiceButton(
                textWidget1: 'Premium Detail',
                textWidget2: '📍Omeeo Car wash',
                status: 'Confirmed',
                day: '🗓️Today',
                time: '⌚2:30 PM',
                duration: '⌚90 min',
                icon: Icon(
                  FontAwesomeIcons.carSide,
                  size: TextSizes.bodyText1,
                  color: const Color.fromARGB(255, 226, 226, 226),
                ),
                scale: 1.7,
                onPressed: () {},
                price: '150',
                iconColor: Theme.of(context).colorScheme.primary,
                iconSize: IconSizes.medium,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}

class PastTabScreen extends StatelessWidget {
  const PastTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      color: const Color.fromARGB(55, 255, 255, 255),
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            BookingsServiceButton(
              textWidget1: 'Express Clean',
              textWidget2: '📍Omeeo Car wash',
              status: 'Completed',
              day: '🗓️Today',
              time: '⌚2:30 PM',
              duration: '⌚90 min',
              icon: Icon(
                FontAwesomeIcons.carSide,
                size: TextSizes.bodyText1,
                color: const Color.fromARGB(255, 226, 226, 226),
              ),
              scale: 1.7,
              onPressed: () {},
              price: '45',
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),
            const SizedBox(height: 10),
            BookingsServiceButton(
              textWidget1: 'Express Clean',
              textWidget2: '📍Omeeo Car wash',
              status: 'Completed',
              day: '🗓️Today',
              time: '⌚2:30 PM',
              duration: '⌚90 min',
              icon: Icon(
                FontAwesomeIcons.carSide,
                size: TextSizes.bodyText1,
                color: const Color.fromARGB(255, 226, 226, 226),
              ),
              scale: 1.7,
              onPressed: () {},
              price: '45',
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),
            const SizedBox(height: 10),
            BookingsServiceButton(
              textWidget1: 'Express Clean',
              textWidget2: '📍Omeeo Car wash',
              status: 'Completed',
              day: '🗓️Today',
              time: '⌚2:30 PM',
              duration: '⌚90 min',
              icon: Icon(
                FontAwesomeIcons.carSide,
                size: TextSizes.bodyText1,
                color: const Color.fromARGB(255, 226, 226, 226),
              ),
              scale: 1.7,
              onPressed: () {},
              price: '45',
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),
            const SizedBox(height: 10),
            BookingsServiceButton(
              textWidget1: 'Express Clean',
              textWidget2: '📍Omeeo Car wash',
              status: 'Completed',
              day: '🗓️Today',
              time: '⌚2:30 PM',
              duration: '⌚90 min',
              icon: Icon(
                FontAwesomeIcons.carSide,
                size: TextSizes.bodyText1,
                color: const Color.fromARGB(255, 226, 226, 226),
              ),
              scale: 1.7,
              onPressed: () {},
              price: '45',
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class PendingTabScreen extends StatelessWidget {
  const PendingTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      color: const Color.fromARGB(55, 255, 255, 255),
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            BookingsServiceButton(
              textWidget1: 'Basic Wash',
              textWidget2: '📍Omeeo Car wash',
              status: 'Pending',
              day: '🗓️Today',
              time: '⌚2:30 PM',
              duration: '⌚90 min',
              icon: Icon(
                FontAwesomeIcons.carSide,
                size: TextSizes.bodyText1,
                color: const Color.fromARGB(255, 226, 226, 226),
              ),
              scale: 1.7,
              onPressed: () {},
              price: '30',
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),
            const SizedBox(height: 10),
            BookingsServiceButton(
              textWidget1: 'Basic Wash',
              textWidget2: '📍Omeeo Car wash',
              status: 'Pending',
              day: '🗓️Today',
              time: '⌚2:30 PM',
              duration: '⌚90 min',
              icon: Icon(
                FontAwesomeIcons.carSide,
                size: TextSizes.bodyText1,
                color: const Color.fromARGB(255, 226, 226, 226),
              ),
              scale: 1.7,
              onPressed: () {},
              price: '30',
              iconColor: Theme.of(context).colorScheme.primary,
              iconSize: IconSizes.medium,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
