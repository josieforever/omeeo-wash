import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omeeowash/helpers/miscellaneous.dart';
import 'package:omeeowash/pages/bookings/booking flow/common_widgets.dart';
import 'package:omeeowash/pages/bookings/booking flow/select_vehicle_size_and_location_screen.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class SelectDateScreen extends StatefulWidget {
  final int duration;
  final String? serviceType; // e.g. express | standard | premium
  final double? price; // optional price from previous step
  // Availability filter (only for showing booked/available in this step)
  final String serviceLocation; // "washing_bay" | "mobile" | "valet"
  const SelectDateScreen({
    super.key,
    this.serviceType,
    this.price,
    this.serviceLocation = 'washing_bay',
    required this.duration, // default for availability filtering
  });

  @override
  State<SelectDateScreen> createState() => _SelectDateScreenState();
}

class _SelectDateScreenState extends State<SelectDateScreen> {
  String serviceType = "none";
  double? price;

  // Date & time selections
  DateTime? pickedDate;
  String? selectedTimeLabel; // "08:30 AM" (UI)
  String? _selectedHhmm; // "0830" (key we compute)
  bool _hasPickedDate = false;

  // live Firestore subscription for booked slots
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookedSub;

  // generated slots for the chosen date (with booked status)
  List<_SlotVM> _slots = [];
  bool _loadingSlots = false;

  // Service durations (optional)
  final Map<String, String> serviceDurations = const {
    "express": "10 min",
    "standard": "30 min",
    "premium": "120 min",
  };

  // Business hours (adjust if needed)
  static const int _startMin = 8 * 60; // 08:00
  static const int _endMin = 18 * 60; // 18:00
  static const int _stepMin = 30; // every 30 minutes

  @override
  void initState() {
    super.initState();
    if (widget.serviceType != null && widget.serviceType!.trim().isNotEmpty) {
      serviceType = widget.serviceType!;
    }
    price = widget.price;
  }

  @override
  void dispose() {
    _bookedSub?.cancel();
    super.dispose();
  }

  bool get canContinue => pickedDate != null && selectedTimeLabel != null;

  String get dateTitle =>
      pickedDate == null ? '' : DateFormat('MMMM d, y').format(pickedDate!);

  /// Build DateTime from picked date + the selected "hh:mm a" label.
  DateTime? _composeScheduledDateTime() {
    if (pickedDate == null || selectedTimeLabel == null) return null;
    final t = DateFormat('hh:mm a').parse(selectedTimeLabel!);
    return DateTime(
      pickedDate!.year,
      pickedDate!.month,
      pickedDate!.day,
      t.hour,
      t.minute,
    );
  }

  void _goNext() {
    if (!canContinue) return;
    final scheduled = _composeScheduledDateTime();
    if (scheduled == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => SelectVehicleAndLocationScreen(
          serviceType: serviceType, // "express" | "standard" | "premium"
          price: price,
          scheduledTime: scheduled,
          duration: widget.duration,
          // Note: actual serviceLocation will be chosen next screen.
        ),
      ),
    );
  }

  // --- Availability: Firestore integration ---

  // Generate list of hhmm keys between start/end by step
  List<String> _generateHhmmKeys() {
    final keys = <String>[];
    for (int m = _startMin; m <= _endMin; m += _stepMin) {
      final h = (m ~/ 60).toString().padLeft(2, '0');
      final mm = (m % 60).toString().padLeft(2, '0');
      keys.add('$h$mm'); // e.g., "0830"
    }
    return keys;
  }

  String _toLabel(String hhmm) {
    final h = int.parse(hhmm.substring(0, 2));
    final m = int.parse(hhmm.substring(2, 4));
    final dt = DateTime(0, 1, 1, h, m);
    return DateFormat('hh:mm a').format(dt); // "08:30 AM"
  }

  Future<void> _onPickDate(DateTime? date) async {
    _bookedSub?.cancel();
    setState(() {
      pickedDate = date;
      _hasPickedDate = date != null;
      selectedTimeLabel = null;
      _selectedHhmm = null;
      _slots = [];
    });

    if (date == null) return;

    setState(() => _loadingSlots = true);

    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final location = widget.serviceLocation; // e.g., "washing_bay"

    // 🔁 Only filter by date (avoids needing a composite index); filter location client-side
    final q = FirebaseFirestore.instance
        .collection('booked_times')
        .where('date', isEqualTo: dateKey);

    _bookedSub = q.snapshots().listen(
      (snap) {
        final booked = snap.docs
            .where((d) => (d.data()['location'] as String?) == location)
            .map((d) => (d.data()['hhmm'] as String?) ?? '')
            .where((s) => s.isNotEmpty)
            .toSet();

        final keys = _generateHhmmKeys();
        final slots = keys
            .map(
              (k) => _SlotVM(
                hhmm: k,
                label: _toLabel(k),
                isBooked: booked.contains(k),
              ),
            )
            .toList();

        setState(() {
          _slots = slots; // if booked.isEmpty → all available
          _loadingSlots = false;
        });
      },
      onError: (_) {
        // 👇 Fallback: show all times as available so the UI still works
        final keys = _generateHhmmKeys();
        setState(() {
          _slots = keys
              .map((k) => _SlotVM(hhmm: k, label: _toLabel(k), isBooked: false))
              .toList();
          _loadingSlots = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Using offline availability')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = !canContinue;
    final String duration =
        serviceDurations[serviceType] ?? "60 min"; // fallback

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RegularButton(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: 60,
        onPressed: disabled ? null : _goNext,
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
          colors: disabled
              ? const [
                  Color.fromARGB(184, 215, 215, 215),
                  Color.fromARGB(162, 65, 65, 65),
                ]
              : const [
                  Color.fromARGB(255, 198, 198, 198),
                  Color.fromARGB(255, 44, 44, 44),
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

            // Calendar (toggleable selection)
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
                          : Theme.of(context),
                      child: CalendarDatePicker(
                        key: ValueKey(
                          '${_hasPickedDate}_${pickedDate?.toIso8601String() ?? "none"}',
                        ),
                        initialDate: pickedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                        selectableDayPredicate: (day) => true,
                        onDateChanged: (date) {
                          if (pickedDate != null &&
                              DateUtils.isSameDay(pickedDate!, date)) {
                            // deselect same date
                            _bookedSub?.cancel();
                            setState(() {
                              pickedDate = null;
                              _hasPickedDate = false;
                              selectedTimeLabel = null;
                              _selectedHhmm = null;
                              _slots = [];
                            });
                          } else {
                            _onPickDate(date);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Times after date picked
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
                        if (_loadingSlots)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
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
                                    for (final slot in _slots)
                                      SizedBox(
                                        width: itemWidth,
                                        child: GestureDetector(
                                          onTap: () {
                                            if (slot.isBooked) return;
                                            setState(() {
                                              _selectedHhmm = slot.hhmm;
                                              selectedTimeLabel = slot.label;
                                            });
                                          },
                                          child: _TimeTile(
                                            label: slot.label,
                                            isSelected:
                                                _selectedHhmm == slot.hhmm,
                                            isBooked: slot.isBooked,
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
            // Summary box (dynamic)
            Container(
              padding: const EdgeInsets.all(8),
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
                      CustomText(
                        text: serviceDurations[serviceType] ?? '60 min',
                        textWeight: FontWeight.bold,
                      ),
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
                        text: _displayServiceName(serviceType),
                        textWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  if (price != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText(
                          text: 'Estimated Price',
                          textColor: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.color!,
                        ),
                        CustomText(
                          text: '${price!.toStringAsFixed(0)}',
                          textWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  String _displayServiceName(String type) {
    switch (type) {
      case 'express':
        return 'Express Wash';
      case 'standard':
        return 'Standard Wash';
      case 'premium':
        return 'Premium Detail';
      default:
        return 'Not selected';
    }
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

class _SlotVM {
  final String hhmm; // "0830"
  final String label; // "08:30 AM"
  final bool isBooked;
  const _SlotVM({
    required this.hhmm,
    required this.label,
    required this.isBooked,
  });
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
