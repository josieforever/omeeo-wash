import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/helpers/miscellaneous.dart';
import 'package:omeeowash/pages/bookings/booking flow/common_widgets.dart';
import 'package:omeeowash/pages/bookings/booking flow/select_date_screen.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class ServicesScreen extends StatefulWidget {
  final String? serviceType; // optional preselect
  const ServicesScreen({super.key, this.serviceType});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String serviceType = "none";
  double? selectedPrice;
  int? duration;

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
    });
  }

  void _goNext() {
    if (!_canContinue) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectDateScreen(
          // Pass along what we just captured; SelectDateScreen can
          // then include these when constructing the Booking later.
          serviceType: serviceType,
          price: selectedPrice,
          duration: duration!,
        ),
      ),
    );
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
            disabled
                ? const Color.fromARGB(97, 193, 193, 193)
                : const Color.fromARGB(255, 193, 193, 193),
            disabled
                ? const Color.fromARGB(74, 52, 52, 52)
                : const Color.fromARGB(255, 52, 52, 52),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            Align(
              alignment: Alignment.topRight,
              child: GoBack(
                bgColor: Theme.of(context).colorScheme.tertiary,
                onPressed: () => Navigator.pop(context),
              ),
            ),

            const SizedBox(height: 10),
            LnProgressIndicator(value: progressIndicatorValues[1]),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: "Choose Your Service",
                  textSize: TextSizes.subtitle1,
                  textWeight: FontWeight.w600,
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: "Select the perfect wash package for your vehicle",
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.normal,
                  textColor: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Express
            ServiceButtonExpanded(
              textWidget1: 'Express Wash',
              textWidget2: 'Quick exterior wash',
              textWidget3: '⏱️ 10 min',
              serviceItems: const ['Exterior wash & dry', 'Tire shine'],
              isSelected: serviceType == "express",
              icon: Icon(
                FontAwesomeIcons.shower,
                color: Theme.of(context).colorScheme.primary,
              ),
              scale: 1.2,
              onPressed: () => _onSelect("express"),
              price: '20',
            ),

            const SizedBox(height: 15),

            // Standard
            ServiceButtonExpanded(
              textWidget1: 'Standard Wash',
              textWidget2: 'Complete exterior & interior',
              textWidget3: '⏱️ 30 min',
              serviceItems: const [
                'Exterior wash',
                'Interior clean & vacuum',
                'Tire shine',
              ],
              isSelected: serviceType == "standard",
              icon: Icon(
                Icons.alarm,
                color: Theme.of(context).colorScheme.primary,
              ),
              scale: 1.2,
              onPressed: () => _onSelect("standard"),
              price: '30',
            ),

            const SizedBox(height: 15),

            // Premium
            ServiceButtonExpanded(
              textWidget1: 'Premium Detail',
              textWidget2: 'Full detailing service',
              textWidget3: '⏱️ 120 min',
              serviceItems: const [
                'Full exterior wash',
                'Deep interior clean',
                'Wax protection',
                'Tire shine',
                'Air freshener',
              ],
              isSelected: serviceType == "premium",
              svg: SvgPicture.asset(
                'assets/icons/cleaning.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              scale: 1.5,
              onPressed: () => _onSelect("premium"),
              price: '150',
            ),

            // prevent overlap with bottom button
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
