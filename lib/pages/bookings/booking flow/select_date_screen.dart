import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/helpers/miscellaneous.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/common_widgets.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/select_vehicle_size_and_location_screen.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class SelectDateScreen extends StatefulWidget {
  final String? serviceType;
  const SelectDateScreen({super.key, this.serviceType});

  @override
  State<SelectDateScreen> createState() => _SelectDateScreenState();
}

class _SelectDateScreenState extends State<SelectDateScreen> {
  String serviceType = "none";

  // Make date nullable so we can "deselect".
  DateTime? pickedDate;
  String? selectedTime; // track currently selected time label
  bool _hasPickedDate = false; // controls when times appear

  // sample times
  final List<Map<String, dynamic>> availableTimes = [
    {"time": "08:00 AM", "isSelected": false, "isBooked": true},
    {"time": "08:30 AM", "isSelected": false, "isBooked": false},
    {"time": "09:00 AM", "isSelected": false, "isBooked": false},
    {"time": "09:30 AM", "isSelected": false, "isBooked": false},
    {"time": "10:00 AM", "isSelected": false, "isBooked": false},
    {"time": "10:30 AM", "isSelected": false, "isBooked": false},
    {"time": "11:00 AM", "isSelected": false, "isBooked": false},
    {"time": "11:30 AM", "isSelected": false, "isBooked": true},
    {"time": "12:00 PM", "isSelected": false, "isBooked": false},
    {"time": "12:30 PM", "isSelected": false, "isBooked": false},
    {"time": "01:00 PM", "isSelected": false, "isBooked": false},
    {"time": "01:30 PM", "isSelected": false, "isBooked": false},
    {"time": "02:00 PM", "isSelected": false, "isBooked": false},
    {"time": "02:30 PM", "isSelected": false, "isBooked": false},
    {"time": "03:00 PM", "isSelected": false, "isBooked": true},
    {"time": "03:30 PM", "isSelected": false, "isBooked": false},
    {"time": "04:00 PM", "isSelected": false, "isBooked": false},
    {"time": "04:30 PM", "isSelected": false, "isBooked": false},
    {"time": "05:00 PM", "isSelected": false, "isBooked": false},
    {"time": "05:30 PM", "isSelected": false, "isBooked": false},
    {"time": "06:00 PM", "isSelected": false, "isBooked": false},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.serviceType != null) {
      serviceType = widget.serviceType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = pickedDate != null && selectedTime != null;
    final String dateTitle = pickedDate == null
        ? ''
        : DateFormat('MMMM d, y').format(pickedDate!);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RegularButton(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: 60,
        onPressed: () {
          if (!canContinue) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) =>
                  const SelectVehicleAndLocationScreen(),
            ),
          );
        },
        borderRadius: 8,
        textWidget: CustomText(
          text: 'Continue to Location',
          textColor: Theme.of(context).textTheme.headlineLarge?.color,
          textSize: TextSizes.heading3,
          textWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: canContinue
              ? const [
                  Color.fromARGB(255, 198, 198, 198),
                  Color.fromARGB(255, 44, 44, 44),
                ]
              : [
                  Color.fromARGB(184, 215, 215, 215),
                  Color.fromARGB(162, 65, 65, 65),
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
            LnProgressIndicator(value: progressIndicatorValues[2]),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: "Select Date & Time",
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
                  text: "Choose when you'd like your car washed",
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.normal,
                  textColor: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Calendar (simulate deselect by toggling pickedDate nullable)
            Container(
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 30),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(97, 193, 193, 193),
                        Color.fromARGB(255, 193, 193, 193),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeBottom: true,
                    child: Theme(
                      // 👉 Only override the selection color if a date is picked
                      data: _hasPickedDate
                          ? Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme
                                  .copyWith(
                                    primary: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    onPrimary: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            )
                          : Theme.of(
                              context,
                            ), // default app colors (no purple override)
                      child: CalendarDatePicker(
                        key: ValueKey(
                          '${_hasPickedDate}_${pickedDate?.toIso8601String() ?? "none"}',
                        ), // forces rebuild when toggle/deselect
                        initialDate: pickedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                        selectableDayPredicate: (day) => true,
                        onDateChanged: (date) {
                          setState(() {
                            if (pickedDate != null &&
                                DateUtils.isSameDay(pickedDate!, date)) {
                              // deselect same day
                              pickedDate = null;
                              _hasPickedDate = false;
                              selectedTime = null;
                              for (var t in availableTimes)
                                t['isSelected'] = false;
                            } else {
                              // select new day
                              pickedDate = date;
                              _hasPickedDate = true;
                              selectedTime = null;
                              for (var t in availableTimes)
                                t['isSelected'] = false;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Smoothly reveal the Available Times section AFTER picking a date
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, .04),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _hasPickedDate
                  ? Column(
                      key: const ValueKey('times-section'),
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText(
                              text: "Available Times for $dateTitle",
                              textSize: TextSizes.bodyText1,
                              textWeight: FontWeight.normal,
                              textColor: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Legend
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Row(
                            children: [
                              _legendDot(
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.labelSmall?.color ??
                                    Colors.grey,
                                label: "Available",
                              ),
                              const SizedBox(width: 12),
                              _legendDot(
                                color: Colors.grey,
                                label: "Booked",
                                borderOnly: true,
                              ),
                              const SizedBox(width: 12),
                              _legendDot(
                                color: Theme.of(context).colorScheme.surface,
                                label: "Selected",
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Time grid
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const double spacing = 10.0;
                              const double runSpacing = 10.0;
                              const double targetTileWidth = 120;

                              int columns =
                                  (constraints.maxWidth / targetTileWidth)
                                      .floor()
                                      .clamp(2, 4);

                              final double totalSpacing =
                                  spacing * (columns - 1);
                              final double itemWidth =
                                  (constraints.maxWidth - totalSpacing) /
                                  columns;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: runSpacing,
                                children: [
                                  for (var time in availableTimes)
                                    SizedBox(
                                      width: itemWidth,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (time['isBooked'] == true) {
                                            return; // locked
                                          }
                                          setState(() {
                                            for (var t in availableTimes) {
                                              t['isSelected'] = false;
                                            }
                                            time['isSelected'] = true;
                                            selectedTime =
                                                time['time'] as String;
                                          });
                                        },
                                        child: _TimeTile(
                                          label: time['time'] as String,
                                          isSelected:
                                              time['isSelected'] as bool,
                                          isBooked: time['isBooked'] as bool,
                                          selectedFill: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  width: 1,
                  color: Theme.of(context).textTheme.bodySmall!.color!,
                ),
                color: Theme.of(context).colorScheme.secondary,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: 'Service Duration',
                        textColor: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.color!,
                      ),
                      CustomText(text: '60 min', textWeight: FontWeight.bold),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: 'Selected Service',
                        textColor: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.color!,
                      ),
                      CustomText(
                        text: 'Premium Detail',
                        textWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _legendDot({
    required Color color,
    required String label,
    bool borderOnly = false,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: borderOnly ? Colors.transparent : color,
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        CustomText(
          text: label,
          textColor: Theme.of(context).textTheme.bodySmall?.color,
          textSize: TextSizes.bodyText2,
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isBooked;
  final Color selectedFill;

  const _TimeTile({
    required this.label,
    required this.isSelected,
    required this.isBooked,
    required this.selectedFill,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? Theme.of(context).textTheme.headlineLarge!.color!
        : Theme.of(context).textTheme.bodySmall!.color!;

    final bgColor = isSelected ? selectedFill : Colors.transparent;

    final textColor = isSelected
        ? Theme.of(context).textTheme.headlineLarge?.color
        : Theme.of(context).textTheme.labelSmall?.color;

    return Opacity(
      opacity: isBooked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(width: 2, color: borderColor),
          color: bgColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBooked) ...[
              Icon(
                Icons.lock,
                size: 16,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 2),
            ],
            Flexible(
              child: CustomText(
                text: label,
                textColor: textColor,
                textSize: TextSizes.subtitle2,
                textWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* void killer({required String name, required double age}) {
  const String water = "Poison";
  // ignore: avoid_print
  print("Please drink this $water, it does not contain any poison");

  .
} */
