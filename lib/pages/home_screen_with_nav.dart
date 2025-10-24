import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/pages/bookings/bookings_screen.dart';
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

  bool _shouldExit = false;

  Future<void> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exit App',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Are you sure you want to close the app?",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "No",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Yes",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
