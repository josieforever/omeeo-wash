import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:omeeowash/models/booking_model.dart';

class LaundryRequestSentScreen extends StatelessWidget {
  final String bookingId;
  final String laundryName;
  final String laundryImagePath;
  final String pickupLocation;
  final String selectedServiceType;
  final String estimatedResponseTime;
  final double distanceKm;
  final int totalPrice;

  const LaundryRequestSentScreen({
    super.key,
    required this.bookingId,
    required this.laundryName,
    required this.laundryImagePath,
    required this.pickupLocation,
    required this.selectedServiceType,
    required this.estimatedResponseTime,
    required this.distanceKm,
    required this.totalPrice,
  });

  static const Color primaryOrange = Color(0xFFE67E22);
  static const Color softOrange = Color(0xFFFFECDB);
  static const Color appBlack = Color(0xFF212121);
  static const Color cardBg = Color(0xFFF7F7F7);
  static const Color successBg = Color.fromARGB(255, 228, 247, 216);
  static const Color successText = Color(0xFF3D8B2D);
  static const Color waitingBg = Color(0xFFFFF4EA);
  static const Color cancelledBg = Color(0xFFFFEEEE);
  static const Color cancelledText = Color(0xFFD9534F);
  static const Color activeBg = Color(0xFFFFF4EA);

  @override
  Widget build(BuildContext context) {
    final bookingStream = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: bookingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(child: Center(child: CircularProgressIndicator())),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load request.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'This request could not be found.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }

          final booking = BookingModel.fromMap(
            snapshot.data!.data() ?? <String, dynamic>{},
            snapshot.data!.id,
          );

          final view = _RequestSentViewData.fromBooking(
            booking: booking,
            fallbackLaundryName: laundryName,
            fallbackLaundryImagePath: laundryImagePath,
            fallbackPickupLocation: pickupLocation,
            fallbackSelectedServiceType: selectedServiceType,
            fallbackEstimatedResponseTime: estimatedResponseTime,
            fallbackDistanceKm: distanceKm,
            fallbackTotalPrice: totalPrice,
          );

          return _LaundryRequestSentBody(bookingId: bookingId, view: view);
        },
      ),
    );
  }
}

class _LaundryRequestSentBody extends StatefulWidget {
  final String bookingId;
  final _RequestSentViewData view;

  const _LaundryRequestSentBody({required this.bookingId, required this.view});

  @override
  State<_LaundryRequestSentBody> createState() =>
      _LaundryRequestSentBodyState();
}

class _LaundryRequestSentBodyState extends State<_LaundryRequestSentBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _cancelRequest() async {
    if (_isCancelling || !widget.view.canCancel) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
            'status': 'cancelled',
            'cancellation': {
              'cancelledBy': 'customer',
              'reason': 'Cancelled by customer from request sent screen',
              'cancelledAt': FieldValue.serverTimestamp(),
            },
            'timeline.cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Request cancelled.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to cancel request.')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RoundTopButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    v.headerTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: Colors.black,
                    ),
                  ),
                ),
                if (v.canCancel)
                  GestureDetector(
                    onTap: _isCancelling ? null : _cancelRequest,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _isCancelling
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Icon(
                              Icons.close_rounded,
                              color: Colors.black87,
                            ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: v.bannerBgColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final shouldPulse = !v.isCancelled && !v.isCompleted;
                      final scale = shouldPulse
                          ? 0.95 + (_pulseController.value * 0.08)
                          : 1.0;

                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            v.bannerIcon,
                            color: v.bannerIconColor,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.bannerTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v.bannerSubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                            color: Colors.black.withOpacity(0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                color: const Color(0xFFEDEDED),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: _LaundryImage(imagePath: v.laundryImagePath),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.08),
                                  Colors.black.withOpacity(0.10),
                                  Colors.black.withOpacity(0.48),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.laundryName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _HeroChip(
                                    icon: Icons.schedule_rounded,
                                    text: v.heroEtaText,
                                  ),
                                  const SizedBox(width: 8),
                                  _HeroChip(
                                    icon: Icons.near_me_rounded,
                                    text:
                                        '${v.distanceKm.toStringAsFixed(1)} km away',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuickInfoCard(
                              icon: Icons.local_laundry_service_outlined,
                              title: v.serviceLabel,
                              subtitle: 'Service',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickInfoCard(
                              icon: Icons.payments_outlined,
                              title: 'GH₵${v.totalPrice}',
                              subtitle: 'Estimated',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickInfoCard(
                              icon: v.statusCardIcon,
                              title: v.statusChipText,
                              subtitle: 'Status',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              v.statusHeadline,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LaundryRequestSentScreen.cardBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: List.generate(v.statusSteps.length, (index) {
                  final step = v.statusSteps[index];
                  final isLast = index == v.statusSteps.length - 1;

                  return Column(
                    children: [
                      _StatusRow(
                        isActive: step.isActive,
                        title: step.title,
                        subtitle: step.subtitle,
                        stepType: step.stepType,
                      ),
                      if (!isLast) ...[
                        const SizedBox(height: 14),
                        const _StatusConnector(),
                        const SizedBox(height: 14),
                      ],
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Request Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            _DetailTile(
              icon: Icons.location_on_outlined,
              title: 'Pickup location',
              value: v.pickupLocation,
            ),
            const SizedBox(height: 12),
            _DetailTile(
              icon: Icons.local_laundry_service_outlined,
              title: 'Selected service',
              value: v.serviceLabel,
            ),
            const SizedBox(height: 12),
            _DetailTile(
              icon: Icons.access_time_rounded,
              title: v.hasBeenAccepted
                  ? 'Order reference'
                  : 'Usual response time',
              value: v.hasBeenAccepted
                  ? v.shortBookingId
                  : v.estimatedResponseTime,
            ),
            const SizedBox(height: 12),
            _DetailTile(
              icon: Icons.payments_outlined,
              title: 'Estimated total',
              value: 'GH₵${v.totalPrice}',
            ),

            if (v.selectedAddOns.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Selected add-ons',
                value: v.selectedAddOns.join(', '),
              ),
            ],

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: v.isCancelled
                    ? LaundryRequestSentScreen.cancelledBg
                    : LaundryRequestSentScreen.softOrange,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      v.isCancelled
                          ? Icons.cancel_outlined
                          : Icons.info_outline_rounded,
                      color: v.isCancelled
                          ? LaundryRequestSentScreen.cancelledText
                          : LaundryRequestSentScreen.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      v.statusInfoText,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (v.canCancel)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isCancelling ? null : _cancelRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LaundryRequestSentScreen.appBlack,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: LaundryRequestSentScreen.primaryOrange,
                          ),
                        )
                      : const Text(
                          'Cancel Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: LaundryRequestSentScreen.primaryOrange,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestSentViewData {
  final String status;
  final String headerTitle;
  final String laundryName;
  final String laundryImagePath;
  final double distanceKm;
  final String serviceLabel;
  final String pickupLocation;
  final String estimatedResponseTime;
  final int totalPrice;
  final List<String> selectedAddOns;
  final String shortBookingId;
  final bool canCancel;
  final bool isCancelled;
  final bool isCompleted;
  final bool hasBeenAccepted;
  final String statusChipText;
  final String heroEtaText;
  final String bannerTitle;
  final String bannerSubtitle;
  final String statusHeadline;
  final String statusInfoText;
  final Color bannerBgColor;
  final Color bannerIconColor;
  final IconData bannerIcon;
  final IconData statusCardIcon;
  final List<_StatusStepData> statusSteps;

  const _RequestSentViewData({
    required this.status,
    required this.headerTitle,
    required this.laundryName,
    required this.laundryImagePath,
    required this.distanceKm,
    required this.serviceLabel,
    required this.pickupLocation,
    required this.estimatedResponseTime,
    required this.totalPrice,
    required this.selectedAddOns,
    required this.shortBookingId,
    required this.canCancel,
    required this.isCancelled,
    required this.isCompleted,
    required this.hasBeenAccepted,
    required this.statusChipText,
    required this.heroEtaText,
    required this.bannerTitle,
    required this.bannerSubtitle,
    required this.statusHeadline,
    required this.statusInfoText,
    required this.bannerBgColor,
    required this.bannerIconColor,
    required this.bannerIcon,
    required this.statusCardIcon,
    required this.statusSteps,
  });

  factory _RequestSentViewData.fromBooking({
    required BookingModel booking,
    required String fallbackLaundryName,
    required String fallbackLaundryImagePath,
    required String fallbackPickupLocation,
    required String fallbackSelectedServiceType,
    required String fallbackEstimatedResponseTime,
    required double fallbackDistanceKm,
    required int fallbackTotalPrice,
  }) {
    final status = _normalizeStatus(booking.status);
    final isCancelled = status == 'cancelled';
    final isCompleted = status == 'completed';

    final hasBeenAccepted = <String>{
      'accepted',
      'looking_for_a_rider',
      'looking_for_pickup_rider',
      'pickup_rider_assigned',
      'pickup_started',
      'arrived_at_pickup',
      'arrived_at_laundry',
      'processing',
      'ready_for_dropoff',
      'delivery_in_progress',
      'completed',
    }.contains(status);

    final laundryName = _firstNonEmpty([
      booking.laundrySnapshotName ?? '',
      booking.laundryName ?? '',
      fallbackLaundryName,
    ]);

    final laundryImagePath = _firstNonEmpty([
      booking.laundrySnapshotPhotoUrl ?? '',
      booking.laundryPhotoUrl ?? '',
      fallbackLaundryImagePath,
    ]);

    final serviceLabel = _serviceLabel(
      booking.serviceType.trim().isEmpty
          ? fallbackSelectedServiceType
          : booking.serviceType,
    );

    final pickupLocation = booking.pickupAddress.trim().isEmpty
        ? fallbackPickupLocation
        : booking.pickupAddress;

    final totalPrice = booking.totalPrice == 0
        ? fallbackTotalPrice
        : booking.totalPrice;

    final distanceKm = fallbackDistanceKm;

    final shortBookingId = (() {
      final raw = booking.bookingCode.trim().isNotEmpty
          ? booking.bookingCode
          : booking.id;
      if (raw.length <= 8) return raw.toUpperCase();
      return raw.substring(0, 8).toUpperCase();
    })();

    final headerTitle = isCancelled
        ? 'Request Cancelled'
        : hasBeenAccepted
        ? shortBookingId
        : 'Request Sent';

    final statusChipText = switch (status) {
      'offered_to_laundry' => 'Offered',
      'awaiting_laundry_acceptance' => 'Waiting',
      'pending' => 'Pending',
      'accepted' => 'Accepted',
      'looking_for_a_rider' ||
      'looking_for_pickup_rider' => 'Looking for rider',
      'pickup_rider_assigned' => 'Rider Assigned',
      'pickup_started' => 'Pickup Started',
      'arrived_at_pickup' => 'At Pickup',
      'arrived_at_laundry' => 'At Laundry',
      'processing' => 'Processing',
      'ready_for_dropoff' => 'Ready',
      'delivery_in_progress' => 'Delivering',
      'completed' => 'Completed',
      'cancelled' => 'Cancelled',
      _ => 'Pending',
    };

    final heroEtaText = switch (status) {
      'accepted' => 'Accepted',
      'looking_for_a_rider' || 'looking_for_pickup_rider' => 'Finding rider',
      'pickup_rider_assigned' => 'Rider assigned',
      'pickup_started' => 'Pickup started',
      'arrived_at_pickup' => 'At pickup',
      'arrived_at_laundry' => 'At laundry',
      'processing' => 'In progress',
      'ready_for_dropoff' => 'Ready',
      'delivery_in_progress' => 'On the way',
      'completed' => 'Delivered',
      'cancelled' => 'Cancelled',
      _ => fallbackEstimatedResponseTime,
    };

    final bannerTitle = switch (status) {
      'cancelled' => 'Request cancelled',
      'accepted' => 'Laundry accepted your request',
      'looking_for_a_rider' ||
      'looking_for_pickup_rider' => 'Looking for a pickup rider',
      'pickup_rider_assigned' => 'Pickup rider assigned',
      'pickup_started' => 'Pickup has started',
      'arrived_at_pickup' => 'Rider arrived at pickup',
      'arrived_at_laundry' => 'Your items reached the laundry',
      'processing' => 'Laundry in progress',
      'ready_for_dropoff' => 'Ready for dropoff',
      'delivery_in_progress' => 'Your order is on the way',
      'completed' => 'Order completed',
      _ => 'Request sent to $laundryName',
    };

    final bannerSubtitle = switch (status) {
      'offered_to_laundry' => 'Your request has been offered to the laundry.',
      'awaiting_laundry_acceptance' =>
        'We’re waiting for the laundry to accept your request.',
      'pending' => 'Your request is still in the new order queue.',
      'accepted' => 'The laundry has accepted your request.',
      'looking_for_a_rider' || 'looking_for_pickup_rider' =>
        'The laundry accepted your request and rider search has started.',
      'pickup_rider_assigned' =>
        'A pickup rider has been assigned to your booking.',
      'pickup_started' => 'Your clothes are currently being picked up.',
      'arrived_at_pickup' => 'The rider has arrived at your pickup location.',
      'arrived_at_laundry' => 'Your items have arrived at the laundry.',
      'processing' => 'Washing and treatment are currently in progress.',
      'ready_for_dropoff' => 'Your order is ready to be delivered back to you.',
      'delivery_in_progress' => 'Your cleaned items are on the way.',
      'completed' => 'Everything is done and the order is complete.',
      'cancelled' => 'This request is no longer active.',
      _ => 'We’re waiting for the laundry to accept your request.',
    };

    final statusHeadline = switch (status) {
      'offered_to_laundry' => 'Offer sent to laundry',
      'awaiting_laundry_acceptance' => 'Waiting for acceptance',
      'pending' => 'Pending in new orders',
      'accepted' => 'Laundry accepted',
      'looking_for_a_rider' ||
      'looking_for_pickup_rider' => 'Looking for pickup rider',
      'pickup_rider_assigned' => 'Pickup rider assigned',
      'pickup_started' => 'Pickup started',
      'arrived_at_pickup' => 'Arrived at pickup',
      'arrived_at_laundry' => 'Arrived at laundry',
      'processing' => 'Processing',
      'ready_for_dropoff' => 'Ready for dropoff',
      'delivery_in_progress' => 'Delivery in progress',
      'completed' => 'Completed',
      'cancelled' => 'Request cancelled',
      _ => 'Request status',
    };

    final statusInfoText = switch (status) {
      'offered_to_laundry' || 'awaiting_laundry_acceptance' || 'pending' =>
        'You can still cancel this request before the laundry accepts it.',
      'accepted' ||
      'looking_for_a_rider' ||
      'looking_for_pickup_rider' ||
      'pickup_rider_assigned' ||
      'pickup_started' ||
      'arrived_at_pickup' ||
      'arrived_at_laundry' ||
      'processing' ||
      'ready_for_dropoff' ||
      'delivery_in_progress' =>
        'This screen reacts live to your booking and updates automatically as the order moves through acceptance, pickup, washing, and delivery.',
      'completed' => 'Your order has been completed successfully.',
      'cancelled' => 'This request has been cancelled.',
      _ => 'This request is being tracked live.',
    };

    final bannerBgColor = isCancelled
        ? LaundryRequestSentScreen.cancelledBg
        : isCompleted
        ? LaundryRequestSentScreen.successBg
        : hasBeenAccepted
        ? LaundryRequestSentScreen.activeBg
        : status == 'pending'
        ? LaundryRequestSentScreen.waitingBg
        : LaundryRequestSentScreen.successBg;

    final bannerIconColor = isCancelled
        ? LaundryRequestSentScreen.cancelledText
        : isCompleted
        ? LaundryRequestSentScreen.successText
        : hasBeenAccepted
        ? LaundryRequestSentScreen.primaryOrange
        : status == 'pending'
        ? LaundryRequestSentScreen.primaryOrange
        : LaundryRequestSentScreen.successText;

    final bannerIcon = switch (status) {
      'cancelled' => Icons.cancel_rounded,
      'accepted' => Icons.check_circle_rounded,
      'looking_for_a_rider' ||
      'looking_for_pickup_rider' => Icons.search_rounded,
      'pickup_rider_assigned' => Icons.assignment_ind_rounded,
      'pickup_started' || 'arrived_at_pickup' => Icons.two_wheeler_rounded,
      'arrived_at_laundry' => Icons.inventory_2_rounded,
      'processing' => Icons.local_laundry_service_rounded,
      'ready_for_dropoff' => Icons.inventory_outlined,
      'delivery_in_progress' => Icons.local_shipping_rounded,
      'completed' => Icons.verified_rounded,
      'pending' => Icons.hourglass_top_rounded,
      _ => Icons.check_circle_rounded,
    };

    final statusCardIcon = isCancelled
        ? Icons.cancel_outlined
        : isCompleted
        ? Icons.verified_rounded
        : Icons.hourglass_top_rounded;

    final statusSteps = _buildStatusSteps(status);

    return _RequestSentViewData(
      status: status,
      headerTitle: headerTitle,
      laundryName: laundryName,
      laundryImagePath: laundryImagePath,
      distanceKm: distanceKm,
      serviceLabel: serviceLabel,
      pickupLocation: pickupLocation,
      estimatedResponseTime: fallbackEstimatedResponseTime,
      totalPrice: totalPrice,
      selectedAddOns: booking.selectedAddOns,
      shortBookingId: shortBookingId,
      canCancel: <String>{
        'offered_to_laundry',
        'awaiting_laundry_acceptance',
        'pending',
        'accepted',
      }.contains(status),
      isCancelled: isCancelled,
      isCompleted: isCompleted,
      hasBeenAccepted: hasBeenAccepted,
      statusChipText: statusChipText,
      heroEtaText: heroEtaText,
      bannerTitle: bannerTitle,
      bannerSubtitle: bannerSubtitle,
      statusHeadline: statusHeadline,
      statusInfoText: statusInfoText,
      bannerBgColor: bannerBgColor,
      bannerIconColor: bannerIconColor,
      bannerIcon: bannerIcon,
      statusCardIcon: statusCardIcon,
      statusSteps: statusSteps,
    );
  }

  static String _normalizeStatus(String raw) {
    final status = raw.trim().toLowerCase();
    if (status == 'looking_for_rider') return 'looking_for_a_rider';
    return status;
  }

  static String _serviceLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'wash_iron':
        return 'Wash & Iron';
      case 'wash_fold':
        return 'Wash & Fold';
      default:
        return raw.trim().isEmpty
            ? 'Laundry Service'
            : raw.replaceAll('_', ' ');
    }
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static List<_StatusStepData> _buildStatusSteps(String status) {
    if (status == 'cancelled') {
      return const [
        _StatusStepData(
          isActive: true,
          title: 'Request sent',
          subtitle: 'Your request was delivered successfully.',
          stepType: _StepType.done,
        ),
        _StatusStepData(
          isActive: true,
          title: 'Cancelled',
          subtitle: 'This request has been cancelled.',
          stepType: _StepType.cancelled,
        ),
        _StatusStepData(
          isActive: false,
          title: 'Completed',
          subtitle: 'This request did not continue.',
          stepType: _StepType.idle,
        ),
      ];
    }

    final stage = switch (status) {
      'offered_to_laundry' || 'awaiting_laundry_acceptance' || 'pending' => 1,
      'accepted' || 'looking_for_a_rider' || 'looking_for_pickup_rider' => 2,
      'pickup_rider_assigned' || 'pickup_started' || 'arrived_at_pickup' => 3,
      'arrived_at_laundry' || 'processing' => 4,
      'ready_for_dropoff' || 'delivery_in_progress' => 5,
      'completed' => 6,
      _ => 1,
    };

    String pickupSubtitle() {
      switch (status) {
        case 'pickup_rider_assigned':
          return 'A pickup rider has been assigned.';
        case 'pickup_started':
          return 'Pickup is currently in progress.';
        case 'arrived_at_pickup':
          return 'The rider has arrived at the pickup point.';
        default:
          return 'Pickup will begin after rider assignment.';
      }
    }

    String laundrySubtitle() {
      switch (status) {
        case 'arrived_at_laundry':
          return 'Your items have arrived at the laundry.';
        case 'processing':
          return 'Washing and treatment are in progress.';
        default:
          return 'Your items will be handled at the laundry.';
      }
    }

    String deliverySubtitle() {
      switch (status) {
        case 'ready_for_dropoff':
          return 'Your order is ready for delivery.';
        case 'delivery_in_progress':
          return 'Your cleaned items are currently on the way.';
        default:
          return 'Delivery will begin once processing is done.';
      }
    }

    String waitingSubtitle() {
      switch (status) {
        case 'offered_to_laundry':
          return 'Your request has been offered to a laundry.';
        case 'awaiting_laundry_acceptance':
          return 'Waiting for a laundry to accept your request.';
        case 'pending':
          return 'Your request is still in the new orders queue.';
        default:
          return 'Waiting for a laundry to accept your request.';
      }
    }

    return [
      _StatusStepData(
        isActive: true,
        title: 'Request sent',
        subtitle: 'Your request was delivered successfully.',
        stepType: _StepType.done,
      ),
      _StatusStepData(
        isActive: true,
        title: 'Waiting for acceptance',
        subtitle: waitingSubtitle(),
        stepType: stage <= 1 ? _StepType.waiting : _StepType.done,
      ),
      _StatusStepData(
        isActive: stage >= 2,
        title: 'Laundry accepted',
        subtitle: 'The laundry accepted your request.',
        stepType: stage == 2
            ? _StepType.current
            : stage > 2
            ? _StepType.done
            : _StepType.idle,
      ),
      _StatusStepData(
        isActive: stage >= 3,
        title: 'Pickup',
        subtitle: pickupSubtitle(),
        stepType: stage == 3
            ? _StepType.current
            : stage > 3
            ? _StepType.done
            : _StepType.idle,
      ),
      _StatusStepData(
        isActive: stage >= 4,
        title: 'At laundry / Processing',
        subtitle: laundrySubtitle(),
        stepType: stage == 4
            ? _StepType.current
            : stage > 4
            ? _StepType.done
            : _StepType.idle,
      ),
      _StatusStepData(
        isActive: stage >= 5,
        title: 'Delivery',
        subtitle: deliverySubtitle(),
        stepType: stage == 5
            ? _StepType.current
            : stage > 5
            ? _StepType.done
            : _StepType.idle,
      ),
      _StatusStepData(
        isActive: stage >= 6,
        title: 'Completed',
        subtitle: 'Your order has been completed.',
        stepType: stage == 6 ? _StepType.current : _StepType.idle,
      ),
    ];
  }
}

class _LaundryImage extends StatelessWidget {
  final String imagePath;

  const _LaundryImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final path = imagePath.trim();

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (path.isEmpty) {
      return _fallback();
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF1F1F1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_laundry_service_rounded,
        size: 52,
        color: Color(0xFFE67E22),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _QuickInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFE67E22)),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepType { done, waiting, idle, cancelled, current }

class _StatusStepData {
  final bool isActive;
  final String title;
  final String subtitle;
  final _StepType stepType;

  const _StatusStepData({
    required this.isActive,
    required this.title,
    required this.subtitle,
    required this.stepType,
  });
}

class _StatusRow extends StatelessWidget {
  final bool isActive;
  final String title;
  final String subtitle;
  final _StepType stepType;

  const _StatusRow({
    required this.isActive,
    required this.title,
    required this.subtitle,
    required this.stepType,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = switch (stepType) {
      _StepType.done => const Color(0xFF3D8B2D),
      _StepType.waiting => const Color(0xFFE67E22),
      _StepType.cancelled => const Color(0xFFD9534F),
      _StepType.current => const Color(0xFFE67E22),
      _StepType.idle => const Color(0xFFE9E9E9),
    };

    final IconData icon = switch (stepType) {
      _StepType.done => Icons.check_rounded,
      _StepType.waiting => Icons.hourglass_top_rounded,
      _StepType.cancelled => Icons.cancel_outlined,
      _StepType.current => Icons.radio_button_checked_rounded,
      _StepType.idle => Icons.radio_button_unchecked_rounded,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.12)
                : const Color(0xFFE9E9E9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? activeColor : Colors.black38,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: isActive ? Colors.black : Colors.black54,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                  color: Colors.black.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusConnector extends StatelessWidget {
  const _StatusConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Container(width: 2, height: 16, color: const Color(0xFFDCDCDC)),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFE67E22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundTopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundTopButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }
}
