import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/pages/bookings_screen.dart';
import 'package:omeeowash/pages/home/home_screen.dart';
import 'package:omeeowash/pages/profile/profile_screen.dart';

class HomeScreenWithNav extends StatefulWidget {
  final String view;

  const HomeScreenWithNav({super.key, required this.view});

  @override
  State<HomeScreenWithNav> createState() => _HomeScreenWithNavState();
}

class _HomeScreenWithNavState extends State<HomeScreenWithNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(), // Index 0
    BookingScreen(), // Index 1
    ProfileScreen(), // Index 2
  ];

  @override
  void initState() {
    super.initState();
    // Set the initial tab based on the `view` argument
    switch (widget.view.toLowerCase()) {
      case 'booking':
        _selectedIndex = 1;
        break;
      case 'profile':
        _selectedIndex = 2;
        break;
      case 'home':
      default:
        _selectedIndex = 0;
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Gradient background
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
          _pages[_selectedIndex],
        ],
      ),
      bottomNavigationBar: Stack(
        children: [
          // Gradient background behind BottomNavigationBar
          Container(
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color.fromARGB(255, 122, 51, 194),
                  Color.fromARGB(255, 72, 66, 196),
                ],
              ),
            ),
          ),
          // Actual BottomNavigationBar (with transparent background)
          BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.house),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.solidCalendar),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.solidUser),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
