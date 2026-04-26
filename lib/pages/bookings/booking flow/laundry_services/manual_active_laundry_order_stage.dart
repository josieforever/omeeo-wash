import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:omeeowash/models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';

import 'booking_chat_screen.dart';

enum ManualActiveLaundryOrderStage {
  offeredToLaundry,
  accepted,
  riderSearch,
  pickupAssigned,
  pickupInProgress,
  atLaundry,
  processing,
  readyForDropoff,
  deliveryInProgress,
  completed,
}

class ManualActiveLaundryOrderScreen extends StatelessWidget {
  final String bookingId;

  const ManualActiveLaundryOrderScreen({super.key, required this.bookingId});

  static const Color primaryOrange = Color(0xFFE67E22);
  static const Color dark = Color(0xFF1F1F1F);
  static const Color lightBg = Color(0xFFF7F7F7);
  static const Color softOrange = Color(0xFFFFECDB);
  static const Color successBg = Color.fromARGB(255, 228, 247, 216);
  static const Color successText = Color(0xFF3D8B2D);

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
            return const _CenteredLoadingView(message: 'Loading order...');
          }

          if (snapshot.hasError) {
            return _CenteredErrorView(
              message: 'Failed to load order.\n${snapshot.error}',
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const _CenteredErrorView(
              message: 'This booking could not be found.',
            );
          }

          final booking = BookingModel.fromMap(
            snapshot.data!.data() ?? <String, dynamic>{},
            snapshot.data!.id,
          );

          final stage = _BookingStageMapper.fromBooking(booking);
          final headerData = _HeaderData.fromBooking(booking, stage);
          final statusSteps = _BookingStageMapper.buildStatusSteps(stage);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    _RoundTopButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          booking.bookingCode.trim().isEmpty
                              ? booking.id
                              : booking.bookingCode,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: 0,
                      child: _RoundTopButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _TopStatusBanner(
                  title: headerData.headline,
                  subtitle: headerData.subtitle,
                  icon: headerData.bannerIcon,
                  bgColor: headerData.bannerBg,
                  iconColor: headerData.bannerIconColor,
                ),

                const SizedBox(height: 14),

                Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        child: Stack(
                          children: [
                            _LaundryImageHeader(
                              imageUrl:
                                  booking.laundrySnapshotPhotoUrl ??
                                  booking.laundryPhotoUrl ??
                                  '',
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(.55),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _cleanText(
                                            booking.laundrySnapshotName ??
                                                booking.laundryName ??
                                                'Laundry',
                                          ),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  .18,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.location_on_rounded,
                                                    color: primaryOrange,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    headerData.distanceText,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  .18,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                headerData.etaText,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickInfoCard(
                              icon: Icons.local_laundry_service_rounded,
                              title: _serviceLabel(booking.serviceType),
                              subtitle: 'Service',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickInfoCard(
                              icon: Icons.payments_outlined,
                              title: 'GHS ${booking.totalPrice}',
                              subtitle: 'Estimated',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickInfoCard(
                              icon: _statusIconForStage(stage),
                              title: headerData.etaText,
                              subtitle: 'Status',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                _CustomerActionSection(booking: booking, stage: stage),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightBg,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: List.generate(statusSteps.length, (index) {
                      final step = statusSteps[index];
                      final isLast = index == statusSteps.length - 1;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusRow(
                            isCompleted: step.isCompleted,
                            isCurrent: step.isCurrent,
                            subtitle: step.subtitle,
                            icon: step.icon,
                          ),
                          if (!isLast) ...[
                            const SizedBox(height: 5),
                            const _StatusConnector(),
                            const SizedBox(height: 5),
                          ],
                        ],
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 10),

                if (booking.selectedAddOns.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: lightBg,
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
                          child: const Icon(
                            Icons.add_box_outlined,
                            color: primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected add-ons',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: booking.selectedAddOns.map((addOn) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: softOrange,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _addOnIcon(addOn),
                                          size: 16,
                                          color: primaryOrange,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          addOn,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins',
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                _DetailTile(
                  icon: Icons.location_on_outlined,
                  value: booking.customerAddress.trim().isEmpty
                      ? 'Pickup address not available'
                      : booking.customerAddress,
                ),

                const SizedBox(height: 10),

                _DetailTile(
                  icon: Icons.store,
                  value: booking.laundrySnapshotAddressLine!.trim().isEmpty
                      ? 'Delivery address not available'
                      : booking.laundrySnapshotAddressLine!,
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: softOrange,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: primaryOrange.withOpacity(.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: primaryOrange,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          stage == ManualActiveLaundryOrderStage.completed
                              ? 'Your laundry order has been completed successfully.'
                              : 'This screen updates automatically as your booking moves through offer, acceptance, pickup, washing, and delivery.',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.black87,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

  static String _cleanText(String value) {
    final text = value.trim();
    return text.isEmpty ? '—' : text;
  }

  static IconData _addOnIcon(String addOn) {
    switch (addOn) {
      case 'Express Wash':
        return Icons.local_laundry_service_outlined;
      case 'Fragrance Booster':
        return Icons.cleaning_services_outlined;
      case 'Whites Bleach':
        return Icons.opacity_outlined;
      case 'Delicate Wash':
        return Icons.checkroom_outlined;
      default:
        return Icons.add_circle_outline_rounded;
    }
  }

  static IconData _statusIconForStage(ManualActiveLaundryOrderStage stage) {
    switch (stage) {
      case ManualActiveLaundryOrderStage.offeredToLaundry:
        return Icons.send;
      case ManualActiveLaundryOrderStage.accepted:
        return Icons.check_circle_rounded;
      case ManualActiveLaundryOrderStage.riderSearch:
        return Icons.search_rounded;
      case ManualActiveLaundryOrderStage.pickupAssigned:
        return Icons.assignment_ind_rounded;
      case ManualActiveLaundryOrderStage.pickupInProgress:
        return Icons.two_wheeler_rounded;
      case ManualActiveLaundryOrderStage.atLaundry:
        return Icons.inventory_2_rounded;
      case ManualActiveLaundryOrderStage.processing:
        return Icons.local_laundry_service_rounded;
      case ManualActiveLaundryOrderStage.readyForDropoff:
        return Icons.inventory_outlined;
      case ManualActiveLaundryOrderStage.deliveryInProgress:
        return Icons.local_shipping_rounded;
      case ManualActiveLaundryOrderStage.completed:
        return Icons.verified_rounded;
    }
  }
}

class _CustomerActionSection extends StatelessWidget {
  final BookingModel booking;
  final ManualActiveLaundryOrderStage stage;

  const _CustomerActionSection({required this.booking, required this.stage});

  bool get _showPickupRiderButton {
    return stage == ManualActiveLaundryOrderStage.pickupAssigned ||
        stage == ManualActiveLaundryOrderStage.pickupInProgress;
  }

  bool get _showLaundryButtons {
    return stage == ManualActiveLaundryOrderStage.atLaundry ||
        stage == ManualActiveLaundryOrderStage.processing ||
        stage == ManualActiveLaundryOrderStage.readyForDropoff ||
        stage == ManualActiveLaundryOrderStage.deliveryInProgress;
  }

  bool get _showDeliveryRiderButton {
    return stage == ManualActiveLaundryOrderStage.readyForDropoff ||
        stage == ManualActiveLaundryOrderStage.deliveryInProgress;
  }

  void _openPickupRiderChat(BuildContext context) {
    final riderId = booking.pickupRiderId?.trim() ?? '';
    if (riderId.isEmpty) {
      _showSnack(context, 'Pickup rider is not assigned yet.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingChatScreen(
          booking: booking,
          currentUserRole: 'customer',
          otherParticipantRole: 'rider',
          otherParticipantId: riderId,
        ),
      ),
    );
  }

  void _openLaundryChat(BuildContext context) {
    final laundryId = booking.laundryId?.trim() ?? '';
    if (laundryId.isEmpty) {
      _showSnack(context, 'Laundry is not available yet.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingChatScreen(
          booking: booking,
          currentUserRole: 'customer',
          otherParticipantRole: 'laundry',
          otherParticipantId: laundryId,
        ),
      ),
    );
  }

  void _openDeliveryRiderChat(BuildContext context) {
    final riderId = booking.deliveryRiderId?.trim() ?? '';
    if (riderId.isEmpty) {
      _showSnack(context, 'Delivery rider is not assigned yet.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingChatScreen(
          booking: booking,
          currentUserRole: 'customer',
          otherParticipantRole: 'rider',
          otherParticipantId: riderId,
        ),
      ),
    );
  }

  Future<void> _callLaundry(BuildContext context) async {
    final phone = (booking.laundrySnapshotPhone?.trim().isNotEmpty == true)
        ? booking.laundrySnapshotPhone!.trim()
        : (booking.laundryPhone?.trim() ?? '');

    if (phone.isEmpty) {
      _showSnack(context, 'Laundry phone number is not available.');
      return;
    }

    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack(context, 'Could not open dialer.');
    }
  }

  void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (_showPickupRiderButton) {
      actions.add(
        _ActionButton(
          icon: Icons.delivery_dining_rounded,
          title: 'Chat Pickup Rider',
          filled: true,
          onTap: () => _openPickupRiderChat(context),
        ),
      );
    }

    if (_showLaundryButtons) {
      actions.add(
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Chat Laundry',
          filled: true,
          onTap: () => _openLaundryChat(context),
        ),
      );
      actions.add(
        _ActionButton(
          icon: Icons.call_outlined,
          title: 'Call Laundry',
          filled: false,
          onTap: () => _callLaundry(context),
        ),
      );
    }

    if (_showDeliveryRiderButton) {
      actions.add(
        _ActionButton(
          icon: Icons.local_shipping_rounded,
          title: 'Chat Delivery Rider',
          filled: true,
          onTap: () => _openDeliveryRiderChat(context),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: actions
            .map(
              (action) => SizedBox(
                width: _buttonWidth(context, actions.length),
                child: action,
              ),
            )
            .toList(),
      ),
    );
  }

  double _buttonWidth(BuildContext context, int count) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalPadding = 20.0;
    const cardPadding = 24.0;
    final spacing = count == 1
        ? 0.0
        : count == 2
        ? 10.0
        : 20.0;
    return (screenWidth - horizontalPadding - cardPadding - spacing) / count;
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? ManualActiveLaundryOrderScreen.primaryOrange
        : Colors.white;
    final fg = filled
        ? Colors.white
        : ManualActiveLaundryOrderScreen.primaryOrange;
    final border = filled
        ? Colors.transparent
        : ManualActiveLaundryOrderScreen.primaryOrange.withOpacity(0.18);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: ManualActiveLaundryOrderScreen.primaryOrange
                          .withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingStageMapper {
  static ManualActiveLaundryOrderStage fromBooking(BookingModel booking) {
    final status = booking.status.trim().toLowerCase();

    switch (status) {
      case 'offered_to_laundry':
        return ManualActiveLaundryOrderStage.offeredToLaundry;

      case 'pending':
        return ManualActiveLaundryOrderStage.accepted;

      case 'looking_for_pickup_rider':
        return ManualActiveLaundryOrderStage.riderSearch;

      case 'pickup_rider_assigned':
        return ManualActiveLaundryOrderStage.pickupAssigned;

      case 'pickup_started':
      case 'arrived_at_pickup':
        return ManualActiveLaundryOrderStage.pickupInProgress;

      case 'arrived_at_laundry':
        return ManualActiveLaundryOrderStage.atLaundry;

      case 'processing':
        return ManualActiveLaundryOrderStage.processing;

      case 'ready_for_dropoff':
        return ManualActiveLaundryOrderStage.readyForDropoff;

      case 'delivery_in_progress':
      case 'arrived_at_customer':
        return ManualActiveLaundryOrderStage.deliveryInProgress;

      case 'completed':
        return ManualActiveLaundryOrderStage.completed;

      default:
        return ManualActiveLaundryOrderStage.offeredToLaundry;
    }
  }

  static List<_OrderStepData> buildStatusSteps(
    ManualActiveLaundryOrderStage stage,
  ) {
    return [
      _OrderStepData(
        subtitle: 'Offer has been sent to the selected laundry.',
        isCompleted:
            stage.index > ManualActiveLaundryOrderStage.offeredToLaundry.index,
        isCurrent: stage == ManualActiveLaundryOrderStage.offeredToLaundry,
        icon: Icons.send,
      ),
      _OrderStepData(
        subtitle: 'Laundry accepted your request.',
        isCompleted: stage.index > ManualActiveLaundryOrderStage.accepted.index,
        isCurrent: stage == ManualActiveLaundryOrderStage.accepted,
        icon: Icons.check_circle_rounded,
      ),
      _OrderStepData(
        subtitle: 'We are looking for a pickup rider.',
        isCompleted:
            stage.index > ManualActiveLaundryOrderStage.riderSearch.index,
        isCurrent: stage == ManualActiveLaundryOrderStage.riderSearch,
        icon: Icons.search_rounded,
      ),
      _OrderStepData(
        subtitle: 'A pickup rider has been assigned.',
        isCompleted:
            stage.index > ManualActiveLaundryOrderStage.pickupAssigned.index,
        isCurrent: stage == ManualActiveLaundryOrderStage.pickupAssigned,
        icon: Icons.assignment_ind_rounded,
      ),
      _OrderStepData(
        subtitle: 'Pickup is in progress.',
        isCompleted:
            stage.index > ManualActiveLaundryOrderStage.pickupInProgress.index,
        isCurrent: stage == ManualActiveLaundryOrderStage.pickupInProgress,
        icon: Icons.two_wheeler_rounded,
      ),
      _OrderStepData(
        subtitle: 'Your items have arrived at the laundry.',
        isCompleted:
            stage.index > ManualActiveLaundryOrderStage.atLaundry.index,
        isCurrent: stage == ManualActiveLaundryOrderStage.atLaundry,
        icon: Icons.inventory_2_rounded,
      ),
      _OrderStepData(
        subtitle: 'Wash is in progress.',
        isCompleted:
            stage.index > ManualActiveLaundryOrderStage.processing.index,
        isCurrent: stage == ManualActiveLaundryOrderStage.processing,
        icon: Icons.local_laundry_service_rounded,
      ),
      _OrderStepData(
        subtitle: 'Order is ready for dropoff.',
        isCompleted:
            stage.index > ManualActiveLaundryOrderStage.readyForDropoff.index,
        isCurrent: stage == ManualActiveLaundryOrderStage.readyForDropoff,
        icon: Icons.inventory_outlined,
      ),
      _OrderStepData(
        subtitle: 'Laundry is returning to you.',
        isCompleted:
            stage.index >
            ManualActiveLaundryOrderStage.deliveryInProgress.index,
        isCurrent: stage == ManualActiveLaundryOrderStage.deliveryInProgress,
        icon: Icons.local_shipping_rounded,
      ),
      _OrderStepData(
        subtitle: 'Order has been completed.',
        isCompleted: stage == ManualActiveLaundryOrderStage.completed,
        isCurrent: stage == ManualActiveLaundryOrderStage.completed,
        icon: Icons.verified_rounded,
      ),
    ];
  }
}

class _HeaderData {
  final String headline;
  final String subtitle;
  final String etaText;
  final String distanceText;
  final IconData bannerIcon;
  final Color bannerBg;
  final Color bannerIconColor;

  const _HeaderData({
    required this.headline,
    required this.subtitle,
    required this.etaText,
    required this.distanceText,
    required this.bannerIcon,
    required this.bannerBg,
    required this.bannerIconColor,
  });

  factory _HeaderData.fromBooking(
    BookingModel booking,
    ManualActiveLaundryOrderStage stage,
  ) {
    final laundryName = (booking.laundrySnapshotName?.trim().isNotEmpty == true)
        ? booking.laundrySnapshotName!
        : ((booking.laundryName?.trim().isNotEmpty == true)
              ? booking.laundryName!
              : 'Laundry');

    switch (stage) {
      case ManualActiveLaundryOrderStage.offeredToLaundry:
        return _HeaderData(
          headline: 'Offer sent to laundry',
          subtitle: 'Offer has been sent to $laundryName.',
          etaText: 'Sent',
          distanceText: 'Awaiting response',
          bannerIcon: Icons.send,
          bannerBg: ManualActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ManualActiveLaundryOrderScreen.primaryOrange,
        );

      case ManualActiveLaundryOrderStage.accepted:
        return _HeaderData(
          headline: '$laundryName accepted your request',
          subtitle: 'Your booking is now active.',
          etaText: 'Accepted',
          distanceText: 'Confirmed',
          bannerIcon: Icons.check_circle_rounded,
          bannerBg: ManualActiveLaundryOrderScreen.successBg,
          bannerIconColor: ManualActiveLaundryOrderScreen.successText,
        );

      case ManualActiveLaundryOrderStage.riderSearch:
        return _HeaderData(
          headline: 'Finding a pickup rider',
          subtitle:
              '$laundryName accepted the request and rider search is underway.',
          etaText: 'Finding rider',
          distanceText: 'Tracking live',
          bannerIcon: Icons.search_rounded,
          bannerBg: ManualActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ManualActiveLaundryOrderScreen.primaryOrange,
        );

      case ManualActiveLaundryOrderStage.pickupAssigned:
        return _HeaderData(
          headline: 'Pickup rider assigned',
          subtitle: 'A pickup rider has been assigned to your booking.',
          etaText: 'Rider assigned',
          distanceText: 'Tracking live',
          bannerIcon: Icons.assignment_ind_rounded,
          bannerBg: ManualActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ManualActiveLaundryOrderScreen.primaryOrange,
        );

      case ManualActiveLaundryOrderStage.pickupInProgress:
        return _HeaderData(
          headline: '$laundryName is handling pickup',
          subtitle: 'Pickup is in progress now.',
          etaText: 'Pickup in progress',
          distanceText: 'Tracking live',
          bannerIcon: Icons.two_wheeler_rounded,
          bannerBg: ManualActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ManualActiveLaundryOrderScreen.primaryOrange,
        );

      case ManualActiveLaundryOrderStage.atLaundry:
        return _HeaderData(
          headline: 'Your laundry has reached the shop',
          subtitle: 'Your items are now at the laundry.',
          etaText: 'At laundry',
          distanceText: 'With laundry',
          bannerIcon: Icons.inventory_2_rounded,
          bannerBg: ManualActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ManualActiveLaundryOrderScreen.primaryOrange,
        );

      case ManualActiveLaundryOrderStage.processing:
        return _HeaderData(
          headline: 'Your laundry is being processed',
          subtitle: 'Washing and treatment are currently in progress.',
          etaText: 'In progress',
          distanceText: 'At laundry',
          bannerIcon: Icons.local_laundry_service_rounded,
          bannerBg: ManualActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ManualActiveLaundryOrderScreen.primaryOrange,
        );

      case ManualActiveLaundryOrderStage.readyForDropoff:
        return _HeaderData(
          headline: 'Your order is ready for dropoff',
          subtitle: 'Your cleaned items are prepared for delivery.',
          etaText: 'Ready for dropoff',
          distanceText: 'Ready',
          bannerIcon: Icons.inventory_outlined,
          bannerBg: ManualActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ManualActiveLaundryOrderScreen.primaryOrange,
        );

      case ManualActiveLaundryOrderStage.deliveryInProgress:
        return _HeaderData(
          headline: 'Your laundry is on its way back',
          subtitle: 'Your cleaned items are being returned to you.',
          etaText: 'Out for delivery',
          distanceText: 'Tracking live',
          bannerIcon: Icons.local_shipping_rounded,
          bannerBg: ManualActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ManualActiveLaundryOrderScreen.primaryOrange,
        );

      case ManualActiveLaundryOrderStage.completed:
        return _HeaderData(
          headline: 'Your order has been completed',
          subtitle: 'Everything is done. You can review the order anytime.',
          etaText: 'Delivered',
          distanceText: 'Completed',
          bannerIcon: Icons.verified_rounded,
          bannerBg: ManualActiveLaundryOrderScreen.successBg,
          bannerIconColor: ManualActiveLaundryOrderScreen.successText,
        );
    }
  }
}

class _TopStatusBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _TopStatusBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
    );
  }
}

class _LaundryImageHeader extends StatelessWidget {
  final String imageUrl;

  const _LaundryImageHeader({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        color: const Color(0xFFEFEFEF),
        child: const Center(
          child: Icon(
            Icons.local_laundry_service_rounded,
            size: 36,
            color: Colors.black45,
          ),
        ),
      );
    }

    if (imageUrl.startsWith('http')) {
      return SizedBox(
        height: 100,
        width: double.infinity,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: const Color(0xFFEFEFEF),
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 34,
                  color: Colors.black38,
                ),
              ),
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            color: const Color(0xFFEFEFEF),
            child: const Center(
              child: Icon(
                Icons.local_laundry_service_rounded,
                size: 36,
                color: Colors.black45,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CenteredLoadingView extends StatelessWidget {
  final String message;

  const _CenteredLoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredErrorView extends StatelessWidget {
  final String message;

  const _CenteredErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _OrderStepData {
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final IconData icon;

  const _OrderStepData({
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
    required this.icon,
  });
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: ManualActiveLaundryOrderScreen.primaryOrange),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ManualActiveLaundryOrderScreen.dark,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;
  final String subtitle;
  final IconData icon;

  const _StatusRow({
    required this.isCompleted,
    required this.isCurrent,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isCurrent
        ? ManualActiveLaundryOrderScreen.primaryOrange
        : ManualActiveLaundryOrderScreen.successText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: (isCompleted || isCurrent)
                ? activeColor.withOpacity(0.12)
                : const Color(0xFFE9E9E9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted || isCurrent
                ? (isCompleted && !isCurrent ? Icons.check_rounded : icon)
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: (isCompleted || isCurrent) ? activeColor : Colors.black38,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: Colors.black.withOpacity(0.65),
            ),
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
      padding: const EdgeInsets.only(left: 14),
      child: Container(width: 2, height: 16, color: const Color(0xFFDCDCDC)),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String value;

  const _DetailTile({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ManualActiveLaundryOrderScreen.lightBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: ManualActiveLaundryOrderScreen.primaryOrange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ManualActiveLaundryOrderScreen.dark,
                fontFamily: 'Poppins',
              ),
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
