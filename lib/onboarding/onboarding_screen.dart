import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/logo_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Welcome to Omeeo Wash",
      "subtitle":
          "Transform your vehicle with our professional car wash services. Quality, convenience, and care in every wash.",
      "animation": 'assets/animations/blue_man_wash_car.json',
    },
    {
      "title": "Book Anytime",
      "subtitle":
          "Schedule your car wash at your convenience. Quick booking and real-time updates.",
      "animation": 'assets/animations/blue_booking.json',
    },
    {
      "title": "Track Your Wash",
      "subtitle": "Know exactly when and where your wash is happening.",
      "animation": 'assets/animations/track_car.json',
    },
    {
      "title": "Premium Services",
      "subtitle":
          "From basic exterior wash to premium detailing packages. Choose the perfect service for your vehicle's needs.",
      "animation": 'assets/animations/blue_car.json',
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skip() => _finishOnboarding();

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 360;
    final logoSize = (screenWidth * 0.8).clamp(220.0, 320.0);
    final topSpacing = (screenHeight * 0.26).clamp(140.0, 220.0);
    final animationHeight = (screenHeight * 0.32).clamp(180.0, 300.0);

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
          Positioned(
            height: screenHeight,
            width: screenWidth,
            child: OmeeoLogoWidget(size: logoSize, showTagline: true),
          ),
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _pages.length,
              itemBuilder: (_, index) {
                return Container(
                  padding: EdgeInsets.only(
                    top: isSmallScreen ? 20 : 30,
                    bottom: isSmallScreen ? 20 : 30,
                    left: 15,
                    right: 15,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: topSpacing),
                      Text(
                        _pages[index]['title']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 22 : 25,
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pages[index]['subtitle']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: animationHeight,
                        child: Align(
                          alignment: Alignment.center,
                          child: Lottie.asset(
                            _pages[index]['animation']!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: isSmallScreen ? 6 : 10,
            child: SafeArea(
              top: false,
              child: Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16.0 : 24.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 12 : 8,
                          height: _currentPage == index ? 12 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Theme.of(context).colorScheme.inversePrimary
                                : Theme.of(context)
                                      .colorScheme
                                      .inversePrimary
                                      .withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.inversePrimary,
                        foregroundColor: AppColors.primaryPurple,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? "Start" : "Next",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
