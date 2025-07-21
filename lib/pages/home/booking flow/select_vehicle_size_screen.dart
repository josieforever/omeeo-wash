import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/helpers/miscellaneous.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

import 'common_widgets.dart';

class SelectVehicleSizeScreen extends StatefulWidget {
  const SelectVehicleSizeScreen({super.key});

  @override
  State<SelectVehicleSizeScreen> createState() =>
      _SelectVehicleSizeScreenState();
}

class _SelectVehicleSizeScreenState extends State<SelectVehicleSizeScreen> {
  String selectedSize = ''; // Moved selection here

  final List<Map<String, String>> vehicleSizes = [
    {
      "size": "Small",
      "type": "Hatchbacks",
      "brand": "Mercedes A Class, VW Polo & Porsche Boxster",
    },
    {
      "size": "Medium",
      "type": "Saloons, Coupes & Compact SUVs",
      "brand": "Tesla Model 3, Mercedes E Class & Range Rover Evoque",
    },
    {
      "size": "Large",
      "type": "Vans, Pick-up, Trucks & Large SUVs",
      "brand": "Ford Transit, Ford Ranger & Range Rover Discovery",
    },
  ];
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
                  LnProgressIndicator(value: progressIndicatorValues[1]),
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
                  Column(
                    children: vehicleSizes
                        .map(
                          (vehicle) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: VehicleSizeTile(
                              vehicleDetails: vehicle,
                              isSelected:
                                  selectedSize.toLowerCase() ==
                                  vehicle["size"]!.toLowerCase(),
                              onSelect: () {
                                setState(() {
                                  selectedSize = vehicle["size"]!;
                                });
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleSizeTile extends StatelessWidget {
  final Map<String, String> vehicleDetails;
  final bool isSelected;
  final VoidCallback onSelect;

  const VehicleSizeTile({
    super.key,
    required this.vehicleDetails,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const String smallVpath = 'assets/images/small_vehicle.png';
    const String mediumVpath = 'assets/images/medium_vehicle.png';
    const String largeVpath = 'assets/images/large_vehicle.png';
    final size = vehicleDetails["size"]!.toLowerCase();

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pink : AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              height: 120,
              // width: 90,
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.periwinklePurple,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Image.asset(
                size == "small"
                    ? smallVpath
                    : size == "medium"
                    ? mediumVpath
                    : largeVpath,
                height: 70,
                width: 70,
              ),
              // child: Icon(
              //   size == "small"
              //       ? FontAwesomeIcons.carSide
              //       : size == "medium"
              //       ? FontAwesomeIcons.car
              //       : FontAwesomeIcons.vanShuttle,
              //   size: 48,
              // ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicleDetails["size"]!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isSelected ? AppColors.white : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicleDetails["type"]!,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      //color:  whiteText : hintTextColor,
                      color: isSelected
                          ? const Color.fromARGB(255, 213, 210, 210)
                          : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  Text(
                    vehicleDetails["brand"]!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      color: isSelected ? AppColors.white : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectVehicleSizeScreens extends StatefulWidget {
  const SelectVehicleSizeScreens({super.key});

  @override
  State<SelectVehicleSizeScreens> createState() =>
      _SelectVehicleSizeScreenStates();
}

class _SelectVehicleSizeScreenStates extends State<SelectVehicleSizeScreens> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Fixed progress indicator

              // Scrollable list
              Expanded(
                child: SingleChildScrollView(
                  // child:,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
