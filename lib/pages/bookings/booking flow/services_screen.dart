import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:omeeowash/helpers/miscellaneous.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/common_widgets.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/select_date_screen.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
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
      serviceType = widget.serviceType!;
    }
  }

  bool get _canContinue => serviceType != 'none';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RegularButton(
        margin: EdgeInsets.symmetric(horizontal: 10),
        height: 60,
        onPressed: () {
          if (!_canContinue) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => const SelectDateScreen(),
            ),
          );
        },

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
            serviceType == 'none'
                ? Color.fromARGB(97, 193, 193, 193)
                : Color.fromARGB(255, 193, 193, 193),
            serviceType == 'none'
                ? Color.fromARGB(74, 52, 52, 52)
                : Color.fromARGB(255, 52, 52, 52),
          ],
        ),
      ),
      body: // ---- Scrollable content only (no fixed height) ----
      SingleChildScrollView(
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

            // Express / Basic
            ServiceButtonExpanded(
              textWidget1: 'Express Wash',
              textWidget2: 'Quick exterior wash',
              textWidget3: '⏱️ 10 min',
              serviceItems: ['Exterior wash & dry', 'Tire shine'],
              isSelected: serviceType == "express",
              icon: Icon(
                FontAwesomeIcons.shower,
                color: Theme.of(context).colorScheme.primary,
              ),
              scale: 1.2,
              onPressed: () => setState(() => serviceType = "express"),
              price: '20',
            ),

            const SizedBox(height: 15),

            // Standard / Express
            ServiceButtonExpanded(
              textWidget1: 'Standard Wash',
              textWidget2: 'Complete exterior & interior',
              textWidget3: '⏱️ 30 min',
              serviceItems: [
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
              onPressed: () => setState(() => serviceType = "standard"),
              price: '30',
            ),

            const SizedBox(height: 15),

            // Premium
            ServiceButtonExpanded(
              textWidget1: 'Premium Detail',
              textWidget2: 'Full detailing service',
              textWidget3: '⏱️ 120 min',
              serviceItems: [
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
              onPressed: () => setState(() => serviceType = "premium"),
              price: '150',
            ),

            // Extra padding so last cards aren't hidden behind bottom button
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
