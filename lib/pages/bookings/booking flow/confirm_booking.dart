import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'
    show FontAwesomeIcons;
import 'package:omeeowash/helpers/miscellaneous.dart'
    show progressIndicatorValues;
import 'package:omeeowash/pages/bookings/booking%20flow/common_widgets.dart'
    show LnProgressIndicator;
import 'package:omeeowash/pages/bookings/booking%20flow/select_date_screen.dart'
    show SelectDateScreen;
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class ConfirmBooking extends StatefulWidget {
  final String? serviceType;
  final double? price;
  final DateTime scheduledTime;
  final String serviceLocation; // "washing_bay" | "mobile" | "valet"
  final String vehicleType; // "card" | "sedan" | "suv" | "truck"
  final String? address;
  final double? latitude;
  final double? longitude;

  /// NEW: duration expected as an int (in minutes)
  final int duration;

  const ConfirmBooking({
    super.key,
    this.serviceType,
    this.price,
    required this.scheduledTime,
    required this.serviceLocation,
    required this.vehicleType,
    this.address,
    this.latitude,
    this.longitude,
    required this.duration,
  });

  @override
  State<ConfirmBooking> createState() => _ConfirmBookingState();
}

class _ConfirmBookingState extends State<ConfirmBooking> {
  String serviceType = "none";
  String paymentMethodSelected = "none";

  // Which saved method (card or momo) is selected
  String? selectedPaymentDocId;
  String? selectedPaymentType; // 'card' | 'momo'

  // Card form toggle + fields
  bool showAddCardForm = false;
  final formKey = GlobalKey<FormState>();
  final cardholderName = TextEditingController();
  final cardNumber = TextEditingController();
  final month = TextEditingController();
  final year = TextEditingController();
  final cvv = TextEditingController();

  // MoMo form toggle + fields
  bool showAddMomoForm = false;
  final _momoFormKey = GlobalKey<FormState>();
  final _momoPhoneCtrl = TextEditingController();
  String? _momoProvider;
  static const List<String> _momoProviders = [
    'MTN MoMo',
    'AirtelTigo Money',
    'Vodafone Cash',
  ];

  @override
  void dispose() {
    cardholderName.dispose();
    cardNumber.dispose();
    month.dispose();
    year.dispose();
    cvv.dispose();
    _momoPhoneCtrl.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    if (paymentMethodSelected == 'Cash') return true;
    if (paymentMethodSelected == 'card' && selectedPaymentDocId != null) {
      return true;
    }
    if (paymentMethodSelected == 'momo' && selectedPaymentDocId != null) {
      return true;
    }
    return false;
  }

  void _selectPayment(String method) {
    setState(() {
      paymentMethodSelected = method; // 'card' | 'momo' | 'Cash'
      showAddCardForm = false;
      showAddMomoForm = false;
      // clear any previously selected saved method when switching payment type
      selectedPaymentDocId = null;
      selectedPaymentType = null;
    });
  }

  Future<void> _confirmAndCreateBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    try {
      // Build booking payload
      final dt = widget.scheduledTime; // required in your constructor
      final dateKey =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final timeLabel = '$hh:$mm';

      final locationTag =
          widget.serviceLocation; // 'washing_bay' | 'mobile' | 'valet'
      final slotId = '${dateKey}_${locationTag}_$hh$mm';

      // decide payment payload
      Map<String, dynamic> payment;
      if (paymentMethodSelected == 'Cash') {
        payment = {
          'method': 'cash',
          'savedMethodId': null,
          'status': 'pending_cash', // or 'unpaid'
        };
      } else if (paymentMethodSelected == 'card' &&
          selectedPaymentDocId != null) {
        payment = {
          'method': 'card',
          'savedMethodId': selectedPaymentDocId,
          'status': 'authorized_or_later', // placeholder until PSP hookup
        };
      } else if (paymentMethodSelected == 'momo' &&
          selectedPaymentDocId != null) {
        payment = {
          'method': 'momo',
          'savedMethodId': selectedPaymentDocId,
          'status': 'pending_momo', // placeholder
        };
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a payment method')),
        );
        return;
      }

      final now = FieldValue.serverTimestamp();
      final bookingData = {
        'userId': user.uid,
        'serviceType': widget.serviceType ?? 'unknown',
        'vehicleType': widget.vehicleType,
        'serviceLocation': widget.serviceLocation,
        'address': widget.address,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'scheduledTime': Timestamp.fromDate(dt),
        'scheduledDate': dateKey,
        'scheduledTimeLabel': timeLabel,
        'price': widget.price,
        'durationMinutes': widget.duration, // NEW
        'payment': payment,
        'status': 'confirmed', // or 'requested' if you want staff to accept
        'createdAt': now,
        'updatedAt': now,
      };

      final db = FirebaseFirestore.instance;

      // Atomically: ensure slot isn’t double-booked, create booking, lock slot
      await db.runTransaction((tx) async {
        final slotRef = db.collection('booked_times').doc(slotId);
        final slotSnap = await tx.get(slotRef);
        if (slotSnap.exists) {
          throw Exception(
            'That time slot was just taken. Please pick another.',
          );
        }

        final bookingRef = db.collection('bookings').doc();
        tx.set(bookingRef, {...bookingData, 'bookingId': bookingRef.id});

        tx.set(slotRef, {
          'slotId': slotId,
          'date': dateKey,
          'time': timeLabel,
          'location': locationTag,
          'userId': user.uid,
          'bookingId': bookingRef.id,
          'createdAt': now,
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking confirmed for $dateKey at $timeLabel')),
      );

      // Navigate away or pop to a “success” page as you prefer:
      Navigator.of(context).pop(); // or push a success screen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not confirm booking: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RegularButton(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: 60,
        onPressed: _canConfirm ? _confirmAndCreateBooking : null,
        borderRadius: 8,
        textWidget: CustomText(
          text: 'Confirm Booking',
          textColor: Theme.of(context).colorScheme.inversePrimary,
          textSize: TextSizes.heading3,
          textWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: _canConfirm
              ? const [
                  Color.fromARGB(255, 193, 193, 193),
                  Color.fromARGB(255, 52, 52, 52),
                ]
              : const [
                  Color.fromARGB(97, 193, 193, 193),
                  Color.fromARGB(74, 52, 52, 52),
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
            LnProgressIndicator(value: progressIndicatorValues[5]),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: "Confirmation",
                  textSize: TextSizes.subtitle1,
                  textWeight: FontWeight.w600,
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Icon(
                    Icons.check_circle,
                    size: IconSizes.large,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: "Review Your Booking",
                  textSize: TextSizes.bodyText2,
                  textWeight: FontWeight.bold,
                  textColor: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: "Please review all details before confirming",
                  textSize: TextSizes.bodyText2,
                  textWeight: FontWeight.normal,
                  textColor: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Booking details (DYNAMIC)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1,
                  color: Theme.of(context).textTheme.bodySmall!.color!,
                ),
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: IconSizes.medium,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 7),
                      CustomText(
                        text: 'Booking Details',
                        textColor: Theme.of(context).colorScheme.primary,
                        textWeight: FontWeight.bold,
                        textSize: TextSizes.subtitle2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  _kvRow(
                    context,
                    'Service',
                    _titleCase(widget.serviceType ?? '—'),
                  ),
                  const SizedBox(height: 4),

                  _kvRow(
                    context,
                    'Date & Time',
                    _formatDateTime(widget.scheduledTime),
                  ),
                  const SizedBox(height: 4),

                  // UPDATED: show duration from widget.duration (int)
                  _kvRow(context, 'Duration', '${widget.duration}min'),
                  const SizedBox(height: 4),

                  _kvRow(
                    context,
                    'Vehicle Type',
                    _titleCase(widget.vehicleType),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Location (DYNAMIC)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1,
                  color: Theme.of(context).textTheme.bodySmall!.color!,
                ),
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: IconSizes.medium,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 7),
                      CustomText(
                        text: 'Location',
                        textColor: Theme.of(context).colorScheme.primary,
                        textWeight: FontWeight.bold,
                        textSize: TextSizes.subtitle2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  CustomText(
                    text: _prettyLocation(widget.serviceLocation),
                    textColor: Theme.of(context).textTheme.bodyMedium!.color!,
                    textSize: TextSizes.bodyText2,
                    textWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),

                  if ((widget.address ?? '').trim().isNotEmpty)
                    CustomText(
                      text: widget.address!.trim(),
                      textColor: Theme.of(context).textTheme.bodyMedium!.color!,
                      textSize: TextSizes.bodyText2,
                    ),

                  if (widget.latitude != null && widget.longitude != null) ...[
                    const SizedBox(height: 4),
                    CustomText(
                      text:
                          '(${widget.latitude!.toStringAsFixed(5)}, ${widget.longitude!.toStringAsFixed(5)})',
                      textColor: Theme.of(context).textTheme.bodyMedium!.color!,
                      textSize: TextSizes.bodyText2,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 15),

            // Payment
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  width: 1,
                  color: Theme.of(context).textTheme.bodySmall!.color!,
                ),
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wallet,
                        size: IconSizes.medium,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 7),
                      CustomText(
                        text: 'Payment',
                        textColor: Theme.of(context).colorScheme.primary,
                        textWeight: FontWeight.bold,
                        textSize: TextSizes.subtitle2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Credit/debit tile
                  GestureDetector(
                    onTap: () => _selectPayment('card'),
                    child: _CarTile(
                      selected: paymentMethodSelected == 'card',
                      borderColor: paymentMethodSelected == 'card'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.inversePrimary,
                      fillColor: paymentMethodSelected == 'card'
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.inversePrimary,
                      iconBgSelected: paymentMethodSelected == "card",
                      title: 'Credit card/ debit card',
                      icon: Icon(
                        Icons.credit_card,
                        color: Theme.of(context).colorScheme.primary,
                        size: IconSizes.medium,
                      ),
                      iconScale: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (paymentMethodSelected == 'card')
                    _buildCardSection(context),

                  const SizedBox(height: 10),

                  // MoMo tile
                  GestureDetector(
                    onTap: () => _selectPayment('momo'),
                    child: _CarTile(
                      selected: paymentMethodSelected == 'momo',
                      borderColor: paymentMethodSelected == 'momo'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.inversePrimary,
                      fillColor: paymentMethodSelected == 'momo'
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.inversePrimary,
                      iconBgSelected: paymentMethodSelected == "momo",
                      title: 'Mobile Money',
                      icon: Icon(
                        Icons.mobile_friendly,
                        color: Theme.of(context).colorScheme.primary,
                        size: IconSizes.medium,
                      ),
                      iconScale: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (paymentMethodSelected == 'momo')
                    _buildMomoSection(context),

                  const SizedBox(height: 10),

                  // Cash tile
                  GestureDetector(
                    onTap: () => _selectPayment('Cash'),
                    child: _CarTile(
                      selected: paymentMethodSelected == 'Cash',
                      borderColor: paymentMethodSelected == 'Cash'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.inversePrimary,
                      fillColor: paymentMethodSelected == 'Cash'
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.inversePrimary,
                      iconBgSelected: paymentMethodSelected == "Cash",
                      title: 'Cash on service',
                      icon: Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).colorScheme.primary,
                        size: IconSizes.medium,
                      ),
                      iconScale: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  // ---- Sections ----

  Widget _buildCardSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: Theme.of(context).textTheme.bodySmall!.color!,
        ),
        color: Theme.of(context).colorScheme.inversePrimary,
      ),
      child: Column(
        children: [
          // Header + Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Saved payment methods',
                textColor: Theme.of(context).colorScheme.primary,
                textSize: TextSizes.bodyText1,
                textWeight: FontWeight.bold,
              ),
              RegularIconButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                onPressed: () => setState(() => showAddCardForm = true),
                borderRadius: 12,
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                textWidget: CustomText(
                  text: 'Add card',
                  textColor: Theme.of(context).colorScheme.inversePrimary,
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                border: Border.all(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: showAddCardForm
                ? _buildAddCardForm(context)
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 10),
          _buildSavedCardsList(context),
        ],
      ),
    );
  }

  Widget _buildMomoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: Theme.of(context).textTheme.bodySmall!.color!,
        ),
        color: Theme.of(context).colorScheme.inversePrimary,
      ),
      child: Column(
        children: [
          // Header + Add momo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Saved mobile money',
                textColor: Theme.of(context).colorScheme.primary,
                textSize: TextSizes.bodyText1,
                textWeight: FontWeight.bold,
              ),
              RegularIconButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                onPressed: () => setState(() => showAddMomoForm = true),
                borderRadius: 12,
                icon: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                textWidget: CustomText(
                  text: 'Add momo',
                  textColor: Theme.of(context).colorScheme.inversePrimary,
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
                backgroundColor: Theme.of(context).colorScheme.primary,
                border: Border.all(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: showAddMomoForm
                ? _buildAddMomoForm(context)
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 10),
          _buildSavedMomoList(context),
        ],
      ),
    );
  }

  Widget _buildAddCardForm(BuildContext context) {
    return Container(
      key: const ValueKey('add-card-form'),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.onSecondary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: 'Add Credit/Debit Card',
            textSize: TextSizes.bodyText1,
            textColor: Theme.of(context).textTheme.bodyLarge?.color,
            textWeight: FontWeight.w900,
          ),
          const SizedBox(height: 10),

          Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
                  controller: cardholderName,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Enter cardholder name'
                      : null,
                  decoration: _inputDecoration(
                    context,
                    'Cardholder Name (eg: John Doe)',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
                  controller: cardNumber,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(19),
                    const CardNumberFormatter(),
                  ],
                  validator: (value) {
                    final raw = (value ?? '').replaceAll(RegExp(r'\s+'), '');
                    if (raw.isEmpty) return 'Enter your card number';
                    if (raw.length < 12 || raw.length > 19) {
                      return 'Enter a valid card number';
                    }
                    if (!_luhnValid(raw)) return 'Invalid card number';
                    return null;
                  },
                  decoration: _inputDecoration(
                    context,
                    'Card Number (e.g. 1234 5678 9012 3456)',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
                  controller: month,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '';
                    if (value.length > 2) return '';
                    return null;
                  },
                  decoration: _inputDecoration(context, 'Month'),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: TextFormField(
                  cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
                  controller: year,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '';
                    if (value.length > 3) return '';
                    return null;
                  },
                  decoration: _inputDecoration(context, 'Year'),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: TextFormField(
                  cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
                  controller: cvv,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return '';
                    if (value.length > 3) return '';
                    return null;
                  },
                  decoration: _inputDecoration(context, 'CVV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: RegularButton(
                  onPressed: () => setState(() => showAddCardForm = false),
                  borderRadius: 7,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textWidget: CustomText(
                    text: 'Cancel',
                    textColor: Theme.of(context).textTheme.bodyLarge?.color,
                    textSize: TextSizes.caption,
                    textWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RegularButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    FocusScope.of(context).unfocus();
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please sign in first.'),
                          ),
                        );
                        return;
                      }

                      final holder = cardholderName.text.trim();
                      final rawNumber = cardNumber.text.replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      final mmStr = month.text.trim();
                      final yyStr = year.text.trim();
                      final mm = int.tryParse(mmStr);
                      var yy = int.tryParse(yyStr);

                      if (rawNumber.length < 12 ||
                          rawNumber.length > 19 ||
                          !_luhnValid(rawNumber)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid card number.')),
                        );
                        return;
                      }
                      if (mm == null || mm < 1 || mm > 12 || yy == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid expiry date.')),
                        );
                        return;
                      }
                      yy = _normalizeYear(yy);

                      final last4 = rawNumber.substring(rawNumber.length - 4);
                      final brand = _detectBrand(rawNumber);

                      final ref = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('payment_methods')
                          .add({
                            'type': 'card',
                            'provider': 'unknown',
                            'label': holder.isNotEmpty
                                ? "$holder's card"
                                : 'Saved Card',
                            'brand': brand,
                            'last4': last4,
                            'expMonth': mm,
                            'expYear': yy,
                            'isDefault': false,
                            'status': 'needs_token',
                            'createdAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                      // clear sensitive fields + hide form + select the new card
                      cardNumber.clear();
                      cvv.clear();
                      setState(() {
                        showAddCardForm = false;
                        selectedPaymentDocId = ref.id;
                        selectedPaymentType = 'card';
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Card saved.')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save card: $e')),
                      );
                    }
                  },
                  borderRadius: 7,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textWidget: CustomText(
                    text: 'Add Card',
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.caption,
                    textWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMomoForm(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bodyColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      key: const ValueKey('add-momo-form'),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.onSecondary,
      ),
      child: Form(
        key: _momoFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: 'Add Mobile Money',
              textSize: TextSizes.bodyText1,
              textColor: bodyColor,
              textWeight: FontWeight.w900,
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _momoProvider,
              isExpanded: true,
              items: _momoProviders
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _momoProvider = v),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Choose provider' : null,
              decoration: InputDecoration(
                hintText: 'Choose mobile money provider',
                filled: true,
                fillColor: cs.onSecondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: bodyColor ?? Colors.black,
                    width: 2,
                  ),
                ),
                errorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _momoPhoneCtrl,
              keyboardType: TextInputType.phone,
              validator: _validateMomoPhone,
              decoration: InputDecoration(
                hintText: 'e.g., 0241234567',
                filled: true,
                fillColor: cs.onSecondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: bodyColor ?? Colors.black,
                    width: 2,
                  ),
                ),
                errorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: RegularButton(
                    onPressed: () {
                      _momoFormKey.currentState?.reset();
                      _momoPhoneCtrl.clear();
                      setState(() {
                        _momoProvider = null;
                        showAddMomoForm = false;
                      });
                    },
                    borderRadius: 7,
                    backgroundColor: cs.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textWidget: CustomText(
                      text: 'Cancel',
                      textColor: bodyColor,
                      textSize: TextSizes.caption,
                      textWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RegularButton(
                    onPressed: _saveMomo,
                    borderRadius: 7,
                    backgroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textWidget: CustomText(
                      text: 'Save Mobile Money',
                      textColor: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.color,
                      textSize: TextSizes.caption,
                      textWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCardsList(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('payment_methods')
        .where('type', isEqualTo: 'card')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Error loading cards: ${snap.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final cs = Theme.of(context).colorScheme;
        final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          snap.data?.docs ?? const [],
        );
        docs.sort((a, b) {
          final ta = a.data()['createdAt'];
          final tb = b.data()['createdAt'];
          final va = (ta is Timestamp) ? ta : null;
          final vb = (tb is Timestamp) ? tb : null;
          if (va == null && vb == null) return 0;
          if (va == null) return 1;
          if (vb == null) return -1;
          return vb.compareTo(va);
        });

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: CustomText(
              text: 'No saved cards yet.',
              textColor: Theme.of(context).textTheme.bodyMedium?.color,
              textSize: TextSizes.bodyText2,
            ),
          );
        }

        return Column(
          children: docs.map((d) {
            final data = d.data();
            final brand = (data['brand'] ?? 'CARD').toString().toUpperCase();
            final last4 = data['last4'] ?? '••••';
            final m = (data['expMonth'] is int)
                ? (data['expMonth'] as int).toString().padLeft(2, '0')
                : '${data['expMonth'] ?? '--'}';
            final y = '${data['expYear'] ?? '----'}';

            final isSelected =
                (selectedPaymentDocId == d.id && selectedPaymentType == 'card');

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedPaymentDocId = d.id;
                  selectedPaymentType = 'card';
                });
              },
              child: SavedPaymentMethodTile(
                selected: isSelected,
                borderColor: isSelected
                    ? cs.primary
                    : cs.inversePrimary, // black when selected
                fillColor: isSelected ? cs.secondary : cs.inversePrimary,
                iconBgSelected: isSelected,
                icon: Icon(
                  Icons.credit_card_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: IconSizes.medium,
                ),
                iconScale: 1,
                ending: '$brand •••• $last4',
                expires: 'Exp $m/$y',
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSavedMomoList(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('payment_methods')
        .where('type', isEqualTo: 'momo')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Error loading Mobile Money: ${snap.error}',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final cs = Theme.of(context).colorScheme;
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: CustomText(
              text: 'No saved Mobile Money yet.',
              textColor: Theme.of(context).textTheme.bodyMedium?.color,
              textSize: TextSizes.bodyText2,
            ),
          );
        }

        return Column(
          children: docs.map((d) {
            final data = d.data();
            final provider = data['provider'] ?? 'Mobile Money';
            final masked =
                data['masked'] ??
                (data['msisdn'] is String &&
                        (data['msisdn'] as String).length >= 4
                    ? '•••• ${(data['msisdn'] as String).substring((data['msisdn'] as String).length - 4)}'
                    : '••••');

            final isSelected =
                (selectedPaymentDocId == d.id && selectedPaymentType == 'momo');

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedPaymentDocId = d.id;
                  selectedPaymentType = 'momo';
                });
              },
              child: SavedPaymentMethodTile(
                selected: isSelected,
                borderColor: isSelected
                    ? cs.primary
                    : cs.inversePrimary, // black when selected
                fillColor: isSelected ? cs.secondary : cs.inversePrimary,
                iconBgSelected: isSelected,
                icon: Icon(
                  Icons.phone_iphone,
                  color: Theme.of(context).colorScheme.primary,
                  size: IconSizes.medium,
                ),
                iconScale: 1,
                ending: '$provider $masked',
                expires: '',
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ---- MoMo helpers ----
  String _normalizeMsisdn(String raw) => raw.replaceAll(RegExp(r'\D'), '');
  String? _validateMomoPhone(String? value) {
    final v = _normalizeMsisdn(value ?? '');
    if (v.isEmpty) return 'Enter mobile number';
    if (!RegExp(r'^0\d{9}$').hasMatch(v))
      return 'Enter a valid 10-digit number';
    return null;
  }

  Future<void> _saveMomo() async {
    if (!_momoFormKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }
    if (_momoProvider == null || _momoProvider!.isEmpty) {
      _momoFormKey.currentState!.validate();
      return;
    }

    final msisdn = _normalizeMsisdn(_momoPhoneCtrl.text.trim());
    final last4 = msisdn.substring(msisdn.length - 4);

    final payload = <String, dynamic>{
      'type': 'momo',
      'provider': _momoProvider,
      'msisdn': msisdn,
      'masked': '•••• $last4',
      'isDefault': false,
      'status': 'ready',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final ref = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .add(payload);

      _momoPhoneCtrl.clear();
      setState(() {
        showAddMomoForm = false;
        selectedPaymentDocId = ref.id;
        selectedPaymentType = 'momo';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mobile money saved.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }
}

// -----------------------------------------------------------------------------
// Presentational tiles
// -----------------------------------------------------------------------------
class _CarTile extends StatelessWidget {
  final bool selected;
  final Color borderColor;
  final Color? fillColor;
  final bool iconBgSelected;
  final Icon icon;
  final double iconScale;
  final String title;

  const _CarTile({
    required this.selected,
    required this.borderColor,
    required this.fillColor,
    required this.iconBgSelected,
    required this.title,
    required this.icon,
    required this.iconScale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(width: 2, color: borderColor),
        color: fillColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: iconBgSelected
                  ? Theme.of(context).colorScheme.inversePrimary
                  : Theme.of(context).colorScheme.onSecondary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Transform.scale(scale: iconScale, child: icon),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SavedPaymentMethodTile extends StatelessWidget {
  final bool selected;
  final Color borderColor;
  final Color? fillColor;
  final bool iconBgSelected;
  final Icon icon;
  final double iconScale;
  final String ending; // e.g. "VISA •••• 1234" or "MTN MoMo •••• 4567"
  final String expires; // e.g. "Exp 08/2027" or ""

  const SavedPaymentMethodTile({
    super.key,
    required this.selected,
    required this.borderColor,
    required this.fillColor,
    required this.iconBgSelected,
    required this.icon,
    required this.iconScale,
    required this.ending,
    required this.expires,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(width: 2, color: borderColor),
        color: fillColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Transform.scale(scale: iconScale, child: icon),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: ending,
                  textColor: Theme.of(context).colorScheme.primary,
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
                if (expires.isNotEmpty)
                  CustomText(
                    text: expires,
                    textColor: Theme.of(context).colorScheme.surface,
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.bold,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------
InputDecoration _inputDecoration(BuildContext context, String hint) {
  return InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: TextSizes.caption,
      color: const Color.fromARGB(255, 91, 91, 91),
      fontWeight: FontWeight.bold,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      gapPadding: 10,
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color:
            Theme.of(context).textTheme.bodyLarge?.color ??
            AppColors.textPrimary,
        width: 2.0,
      ),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Colors.red, width: 2.0),
    ),
  );
}

String _detectBrand(String digits) {
  if (RegExp(r'^4').hasMatch(digits)) return 'visa';
  if (RegExp(r'^(5[1-5])').hasMatch(digits)) return 'mastercard';
  if (RegExp(r'^(22[2-9]|2[3-6]\d|27[01]|2720)').hasMatch(digits))
    return 'mastercard';
  if (RegExp(r'^3[47]').hasMatch(digits)) return 'amex';
  if (RegExp(r'^(6011|65|64[4-9])').hasMatch(digits)) return 'discover';
  return 'other';
}

bool _luhnValid(String digits) {
  int sum = 0;
  bool alt = false;
  for (int i = digits.length - 1; i >= 0; i--) {
    int n = int.parse(digits[i]);
    if (alt) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alt = !alt;
  }
  return sum % 10 == 0;
}

int _normalizeYear(int yy) {
  if (yy < 100) return 2000 + yy;
  return yy;
}

String _formatDateTime(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final m = months[dt.month - 1];
  final d = dt.day.toString();
  final y = dt.year.toString();
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$m $d, $y at $hh:$mm';
}

String _titleCase(String? s) {
  final v = (s ?? '').replaceAll('_', ' ').trim();
  if (v.isEmpty) return '—';
  return v
      .split(' ')
      .map(
        (w) =>
            w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase(),
      )
      .join(' ');
}

String _prettyLocation(String raw) {
  switch (raw) {
    case 'washing_bay':
      return 'Omeeo Car wash / Washing Bay';
    case 'mobile':
      return 'Mobile Service';
    case 'valet':
      return 'Valet Service';
    default:
      return _titleCase(raw);
  }
}

Widget _kvRow(BuildContext context, String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      CustomText(
        text: label,
        textColor: Theme.of(context).textTheme.bodyMedium!.color!,
        textSize: TextSizes.bodyText2,
      ),
      CustomText(
        text: value,
        textWeight: FontWeight.bold,
        textSize: TextSizes.bodyText2,
      ),
    ],
  );
}

// Card number pretty formatter
class CardNumberFormatter extends TextInputFormatter {
  const CardNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
