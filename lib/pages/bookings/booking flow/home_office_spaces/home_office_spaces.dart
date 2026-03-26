import 'package:flutter/material.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/auto_care/auto_care_date_time.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/select_date_screen.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class HomeOfficeSpacesServicesScreen extends StatefulWidget {
  final String? serviceType; // optional preselect
  const HomeOfficeSpacesServicesScreen({super.key, this.serviceType});

  @override
  State<HomeOfficeSpacesServicesScreen> createState() =>
      _HomeOfficeSpacesServicesScreenState();
}

class _HomeOfficeSpacesServicesScreenState
    extends State<HomeOfficeSpacesServicesScreen> {
  String serviceType = "none";
  double? selectedPrice;
  int? duration;

  String? expandedService;
  Set<String> selectedAddOns = {};

  @override
  void initState() {
    super.initState();
    if (widget.serviceType != null && widget.serviceType!.trim().isNotEmpty) {
      serviceType = widget.serviceType!;
      // If you deep link here with a preselected service, you can also set a default price.
      selectedPrice = _priceForService(serviceType);
      duration = _durationForService(serviceType)!;
    }
  }

  bool get _canContinue => serviceType != 'none';

  // Central place to map service -> price (keeps logic consistent)
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

  void _goNext() {
    if (!_canContinue) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AutoCareSelectDateScreen(
          // Pass along what we just captured; SelectDateScreen can
          // then include these when constructing the Booking later.
          serviceType: serviceType,
          price: selectedPrice,
          duration: duration!,
          carType: '',
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
        height: 60,
        onPressed: disabled ? null : _goNext, // disable tap when none selected
        borderRadius: 8,
        textWidget: CustomText(
          text: 'Continue to Date & Time',
          textColor: Theme.of(context).colorScheme.inversePrimary,
          textSize: TextSizes.heading3,
          textWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            // deep periwinkle-purple (replaces 11, 85, 73)
            disabled
                ? const Color.fromARGB(130, 52, 37, 120)
                : const Color.fromARGB(255, 52, 37, 120),

            // soft periwinkle-purple (replaces 75, 161, 140)
            disabled
                ? const Color.fromARGB(130, 134, 120, 210)
                : const Color.fromARGB(255, 134, 120, 210),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.fromARGB(255, 69, 78, 206),
                    Color.fromARGB(255, 101, 63, 191),
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button (glass effect like screenshot)
                  GoBack(
                    bgColor: Colors.white.withOpacity(0.18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),

                  // Title + subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: "Home / Office Spaces",
                        textSize: TextSizes.heading1,
                        textWeight: FontWeight.w700,
                        textColor: Colors.white,
                      ),
                      CustomText(
                        text: "Fresh, clean & perfectly cared for",
                        textSize: TextSizes.bodyText1,
                        textWeight: FontWeight.normal,
                        textColor: Colors.white.withOpacity(0.85),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  // Standard
                  ServiceButtonExpanded(
                    textWidget1: 'Regular Cleaning',
                    textWidget2: 'Standard cleaning for homes / offices',
                    textWidget3: '⏱️ 30 min',
                    serviceItems: const [
                      'Dusting',
                      'Vacuuming',
                      'Mopping',
                      'Bathroom Clean',
                    ],
                    isSelected: serviceType == "standard",
                    selectedAddOns: selectedAddOns,
                    onAddOnToggle: _toggleAddOn,
                    isExpanded: expandedService == "standard",
                    onTap: () => _onSelect("standard"),
                    boxShadowColor: Color.fromARGB(255, 229, 231, 255),
                    deepColor: Color.fromARGB(255, 36, 53, 137),
                    backgroundColor: Color.fromARGB(207, 209, 215, 243),
                    image: Image.asset(
                      'assets/images/regular_cleaning.png',
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Premium
                  ServiceButtonExpanded(
                    textWidget1: 'Deep Cleaning',
                    textWidget2: 'Thorough top-to-bottom deep clean',
                    textWidget3: '⏱️ 120 min',
                    serviceItems: const [
                      'Appliance Clean',
                      'Grout Scrub',
                      'Window Wash',
                      'Cabinet Wipe',
                    ],

                    isSelected: serviceType == "premium",
                    selectedAddOns: selectedAddOns,
                    onAddOnToggle: _toggleAddOn,
                    isExpanded: expandedService == "premium",
                    onTap: () => _onSelect("premium"),
                    boxShadowColor: Color.fromARGB(255, 236, 229, 255),
                    deepColor: Color.fromARGB(255, 36, 53, 137),
                    backgroundColor: Color.fromARGB(207, 209, 215, 243),
                    image: Image.asset(
                      'assets/images/deep_cleaning.png',
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ServiceButtonExpanded(
                    textWidget1: 'Sofa Cleaning',
                    textWidget2: 'Specialized treatment for stains',
                    textWidget3: '⏱️ 10 min',
                    serviceItems: const [
                      'Oil & grease',
                      'Wine & coffee',
                      'Ink & dye',
                    ],
                    isSelected: serviceType == "express",
                    selectedAddOns: selectedAddOns,
                    onAddOnToggle: _toggleAddOn,
                    isExpanded: expandedService == "express",
                    onTap: () => _onSelect("express"),
                    boxShadowColor: Color.fromARGB(255, 236, 229, 255),
                    deepColor: Color.fromARGB(255, 36, 53, 137),
                    backgroundColor: Color.fromARGB(207, 209, 215, 243),
                    image: Image.asset(
                      'assets/images/sofa_cleaning.png',
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 15),

                  ServiceButtonExpanded(
                    textWidget1: 'Carpet Cleaning',
                    textWidget2: 'Specialized treatment for stains',
                    textWidget3: '⏱️ 10 min',
                    serviceItems: const [
                      'Oil & grease',
                      'Wine & coffee',
                      'Ink & dye',
                    ],
                    isSelected: serviceType == "goat",
                    selectedAddOns: selectedAddOns,
                    onAddOnToggle: _toggleAddOn,
                    isExpanded: expandedService == "goat",
                    onTap: () => _onSelect("goat"),
                    boxShadowColor: Color.fromARGB(255, 236, 229, 255),
                    deepColor: Color.fromARGB(255, 36, 53, 137),
                    backgroundColor: Color.fromARGB(207, 209, 215, 243),
                    image: Image.asset(
                      'assets/images/carpet_cleaning.png',
                      height: 70,
                      width: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),

            // prevent overlap with bottom button
            const SizedBox(height: 130),
          ],
        ),
      ),
    );
  }
}
