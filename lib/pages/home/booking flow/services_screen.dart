import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/helpers/miscellaneous.dart';
import 'package:omeeowash/pages/home/booking%20flow/common_widgets.dart';
import 'package:omeeowash/pages/home/booking%20flow/select_vehicle_size_screen.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class ServicesScreen extends StatefulWidget {
  final String? serviceType;
  const ServicesScreen({super.key, this.serviceType});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String serviceType = "none";

  @override
  void initState() {
    super.initState();
    if (widget.serviceType != null) {
      setState(() {
        serviceType = widget.serviceType!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  // BackButton(),
                  Align(
                    alignment: Alignment.topRight,
                    child: GoBack(
                      bgColor: AppColors.periwinklePurple,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  LnProgressIndicator(value: progressIndicatorValues[0]),
                  const SizedBox(height: 20),
                  Text(
                    "What service do you need?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: serviceType == "basic"
                        ? BoxDecoration(
                            border: Border.all(width: 3, color: AppColors.pink),
                            borderRadius: BorderRadius.circular(2),
                          )
                        : null,
                    child: ServiceButton(
                      textWidget1: 'Basic Wash',
                      textWidget2: 'Exterior wash & dry',
                      textWidget3: '⌚30 min',

                      icon: Icon(
                        FontAwesomeIcons.shower,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      scale: 1.2,
                      onPressed: () {
                        setState(() {
                          serviceType = "basic";
                        });
                      },
                      price: '20',
                    ),
                  ),

                  const SizedBox(height: 10),
                  Container(
                    decoration: serviceType == "express"
                        ? BoxDecoration(
                            border: Border.all(width: 3, color: AppColors.pink),
                            borderRadius: BorderRadius.circular(2),
                          )
                        : null,
                    child: ServiceButton(
                      textWidget1: 'Express Clean',
                      textWidget2: 'Quick wash & vacuum',
                      textWidget3: '⌚45 min',
                      icon: Icon(
                        Icons.alarm,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      scale: 1.2,
                      onPressed: () {
                        setState(() {
                          serviceType = "express";
                        });
                      },
                      price: '30',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: serviceType == "premium"
                        ? BoxDecoration(
                            border: Border.all(width: 3, color: AppColors.pink),
                            borderRadius: BorderRadius.circular(2),
                          )
                        : null,
                    child: ServiceButton(
                      textWidget1: 'Premium Detail',
                      textWidget2: 'Full interior & exterior',
                      textWidget3: '⌚90 min',
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
                        setState(() {
                          serviceType = "premium";
                        });
                      },
                      price: '150',
                    ),
                  ),
                  SizedBox(height: 50),

                  // Divider(),
                  // SizedBox(height: 10),
                  WashOptionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WashOptionButtons extends StatefulWidget {
  const WashOptionButtons({super.key});

  @override
  State<WashOptionButtons> createState() => _WashOptionButtonsState();
}

class _WashOptionButtonsState extends State<WashOptionButtons> {
  ServiceLocation serviceLocation = ServiceLocation.none;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            "Pick A wah location",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ),
        SizedBox(height: 10),
        // Home Service Button
        _locationButton(
          title: "Come to washing bay",
          onPressed: () {
            setState(() {
              serviceLocation = ServiceLocation.washingBay;
            });
          },
          icon: Icons.local_car_wash,
          context: context,
          isSelected: serviceLocation == ServiceLocation.washingBay
              ? true
              : false,
        ),
        const SizedBox(height: 16),
        _locationButton(
          title: "Wash at my location",
          onPressed: () {
            setState(() {
              serviceLocation = ServiceLocation.home;
            });
          },
          icon: Icons.home,
          context: context,
          isSelected: serviceLocation == ServiceLocation.home ? true : false,
        ),
        SizedBox(height: 20),
        Align(
          alignment: Alignment.bottomRight,
          child: SizedBox(
            width: 200,
            child: RegularButton(
              borderRadius: 7,
              gradient: const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Color.fromARGB(255, 73, 64, 241),
                  Color.fromARGB(255, 149, 60, 237),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              textWidget: CustomText(
                text: 'Continue',
                textColor: Theme.of(context).textTheme.headlineLarge?.color,
                textSize: 16,
                textWeight: FontWeight.bold,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) =>
                        const SelectVehicleSizeScreen(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _locationButton({
    required String title,
    required VoidCallback onPressed,
    required IconData icon,
    required BuildContext context,
    required bool isSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isSelected ? Border.all(width: 3, color: AppColors.pink) : null,
      ),
      height: MediaQuery.of(context).size.height * 0.1,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          elevation: 2,
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 24, color: AppColors.pink),
        label: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

enum ServiceLocation { none, home, washingBay }
