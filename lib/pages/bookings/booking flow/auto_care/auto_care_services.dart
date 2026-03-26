import 'package:flutter/material.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/auto_care/auto_care_date_time.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class AutoCareServicesScreen extends StatefulWidget {
  final String? serviceType; // optional preselect
  final String? carType; // optional preselect
  const AutoCareServicesScreen({super.key, this.serviceType, this.carType});

  @override
  State<AutoCareServicesScreen> createState() => _AutoCareServicesScreenState();
}

class _AutoCareServicesScreenState extends State<AutoCareServicesScreen> {
  String serviceType = "none"; // express | standard | premium | none
  double? selectedPrice;
  int? duration;
  String? expandedService;
  String carSelected = "none"; // hatchback | sedan | suv | truck | none
  Set<String> selectedAddOns = {};

  // Theme colors (your seafoam/teal scheme)
  static const Color _deepTeal = Color.fromARGB(255, 11, 85, 73);
  static const Color _teal = Color.fromARGB(255, 75, 161, 140);
  static const Color _mintBg = Color(0xFFE2F3ED);
  static const Color _accent = Color(0xFF45A182);
  static const Color _shadow = Color.fromARGB(255, 167, 189, 187);

  @override
  void initState() {
    super.initState();

    // Preselect service if provided
    if (widget.serviceType != null && widget.serviceType!.trim().isNotEmpty) {
      serviceType = widget.serviceType!;
      selectedPrice = _priceForService(serviceType);
      duration = _durationForService(serviceType);
    }

    // Preselect car if provided
    if (widget.carType != null && widget.carType!.trim().isNotEmpty) {
      carSelected = widget.carType!;
    }
  }

  /// ✅ Must have BOTH service + car selected before continuing
  bool get _canContinue => serviceType != 'none' && carSelected != 'none';

  double? _priceForService(String type) {
    switch (type) {
      case 'express':
        return 20.0;
      case 'standard':
        return 30.0;
      case 'premium':
        return 150.0;
      default:
        return null;
    }
  }

  int? _durationForService(String type) {
    switch (type) {
      case 'express':
        return 10;
      case 'standard':
        return 30;
      case 'premium':
        return 120;
      default:
        return null;
    }
  }

  void _onSelect(String type) {
    setState(() {
      serviceType = type;
      selectedPrice = _priceForService(type);
      duration = _durationForService(type);

      // toggle expansion
      if (expandedService == type) {
        expandedService = null;
      } else {
        expandedService = type;
      }
    });
  }

  void _onSelectCar(String type) {
    setState(() => carSelected = type);
  }

  void _goNext() {
    if (!_canContinue) {
      // optional: show quick hint if user taps while disabled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a service and car type to continue.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AutoCareSelectDateScreen(
          serviceType: serviceType,
          price: selectedPrice,
          duration: duration ?? 30,

          // ✅ add this parameter in AutoCareSelectDateScreen
          carType: carSelected,
        ),
      ),
    );
  }

  void _toggleAddOn(String addOn) {
    setState(() {
      if (selectedAddOns.contains(addOn)) {
        selectedAddOns.remove(addOn);
      } else {
        selectedAddOns.add(addOn);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !_canContinue;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RegularButton(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: 50,
        onPressed: disabled ? null : _goNext,
        borderRadius: 8,
        textWidget: CustomText(
          text: 'Continue to Date & Time',
          textColor: Theme.of(context).colorScheme.inversePrimary,
          textSize: TextSizes.heading3,
          textWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            disabled ? _deepTeal.withOpacity(.45) : _deepTeal,
            disabled ? _teal.withOpacity(.45) : _teal,
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 5,
                right: 5,
                top: 30,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_teal, Color.fromARGB(255, 30, 122, 107)],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GoBack(
                    bgColor: Colors.white.withOpacity(0.18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: "Auto Care",
                        textSize: TextSizes.heading1,
                        textWeight: FontWeight.w700,
                        textColor: Colors.white,
                      ),
                      CustomText(
                        text: "Professional car wash & detailing",
                        textSize: TextSizes.bodyText1,
                        textWeight: FontWeight.normal,
                        textColor: Colors.white.withOpacity(0.85),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Services
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  ServiceButtonExpanded(
                    textWidget1: 'Standard Wash',
                    textWidget2: 'Complete exterior & interior',
                    textWidget3: '⏱️ 30 min',
                    serviceItems: const [
                      'Hand wash',
                      'Interior clean & vacuum',
                      'Tire shine',
                    ],
                    selectedAddOns: selectedAddOns,
                    onAddOnToggle: _toggleAddOn,
                    isSelected: serviceType == "standard",

                    isExpanded: expandedService == "standard",
                    onTap: () => _onSelect("standard"),
                    boxShadowColor: _shadow,
                    deepColor: _accent,
                    backgroundColor: _mintBg,
                    image: Image.asset(
                      'assets/images/standard_wash.png',
                      height: 70,
                      width: 70,
                    ),
                  ),
                  const SizedBox(height: 15),

                  ServiceButtonExpanded(
                    textWidget1: 'Premium Detail',
                    textWidget2: 'Complete interior & exterior detailing',
                    textWidget3: '⏱️ 120 min',
                    serviceItems: const [
                      'Interior Detail',
                      'Exterior Polish',
                      'Vacuum',
                      'Dashboard Care',
                    ],
                    isSelected: serviceType == "premium",
                    selectedAddOns: selectedAddOns,
                    onAddOnToggle: _toggleAddOn,
                    isExpanded: expandedService == "premium",
                    onTap: () => _onSelect("premium"),
                    boxShadowColor: _shadow,
                    deepColor: _accent,
                    backgroundColor: _mintBg,
                    image: Image.asset(
                      'assets/images/premium_detail.png',
                      height: 70,
                      width: 70,
                    ),
                  ),
                  const SizedBox(height: 15),

                  ServiceButtonExpanded(
                    textWidget1: 'Wax & Polish',
                    textWidget2: 'Paint correction and protective wax coat',
                    textWidget3: '⏱️ 10 min',
                    serviceItems: const [
                      'Paint Correction',
                      'Wax Coat',
                      'UV Protection',
                    ],
                    selectedAddOns: selectedAddOns,
                    onAddOnToggle: _toggleAddOn,
                    isSelected: serviceType == "express",
                    isExpanded: expandedService == "express",
                    onTap: () => _onSelect("express"),
                    boxShadowColor: _shadow,
                    deepColor: _accent,
                    backgroundColor: _mintBg,
                    image: Image.asset(
                      'assets/images/wax_polish.png',
                      height: 70,
                      width: 70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Car Type title
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: CustomText(
                text: "Car Type",
                textSize: TextSizes.heading3,
                textWeight: FontWeight.w700,
                textColor: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 10),

            // Car grid (2x2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onSelectCar('hatchback'),
                          child: _CarTile(
                            selected: carSelected == 'hatchback',
                            borderColor: carSelected == 'hatchback'
                                ? _accent
                                : Theme.of(context).colorScheme.inversePrimary,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.inversePrimary,
                            imageAsset: 'assets/images/hatchback_teal.png',
                            imageScale: 1.5,
                            title: 'Hatchback',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onSelectCar('sedan'),
                          child: _CarTile(
                            selected: carSelected == 'sedan',
                            borderColor: carSelected == 'sedan'
                                ? _accent
                                : Theme.of(context).colorScheme.inversePrimary,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.inversePrimary,
                            imageAsset: 'assets/images/sedan_teal.png',
                            imageScale: 1.5,
                            title: 'Sedan',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onSelectCar('suv'),
                          child: _CarTile(
                            selected: carSelected == 'suv',
                            borderColor: carSelected == 'suv'
                                ? _accent
                                : Theme.of(context).colorScheme.inversePrimary,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.inversePrimary,
                            imageAsset: 'assets/images/suv_teal.png',
                            imageScale: 1.5,
                            title: 'SUV',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onSelectCar('truck'),
                          child: _CarTile(
                            selected: carSelected == 'truck',
                            borderColor: carSelected == 'truck'
                                ? _accent
                                : Theme.of(context).colorScheme.inversePrimary,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.inversePrimary,
                            imageAsset: 'assets/images/truck_teal.png',
                            imageScale: 1.6,
                            title: 'Truck',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Optional helper hint
            if (!_canContinue)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: CustomText(
                  text: 'Select a service and a car type to continue.',
                  textColor: Theme.of(context).textTheme.bodySmall?.color,
                  textSize: TextSizes.bodyText2,
                  textWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CarTile extends StatelessWidget {
  final bool selected;
  final Color borderColor;
  final Color? fillColor;
  final String imageAsset;
  final double imageScale;
  final String title;

  const _CarTile({
    required this.selected,
    required this.borderColor,
    required this.fillColor,
    required this.imageAsset,
    required this.imageScale,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 3, color: borderColor),
        color: fillColor,
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(255, 167, 189, 187),
            blurRadius: 30,
            spreadRadius: 1,
            offset: Offset(0, 13),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2F3ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Transform.scale(
              scale: imageScale,
              child: Image.asset(
                imageAsset,
                width: 45,
                height: 26,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomText(
              text: title,
              textColor: Theme.of(context).textTheme.bodyLarge?.color,
              textSize: TextSizes.bodyText1,
              textWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
