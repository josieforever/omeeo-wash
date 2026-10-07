import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omeeowash/models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';

import 'booking_chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STAGE ENUM
// ─────────────────────────────────────────────────────────────────────────────

enum ActiveLaundryOrderStage {
  riderSearch,
  pickupAssigned,
  pickupInProgress,
  atLaundry,
  processing,
  readyForDropoff,
  deliveryInProgress,
  completed,
  accepted,
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ActiveLaundryOrderScreen extends StatelessWidget {
  final String bookingId;

  const ActiveLaundryOrderScreen({super.key, required this.bookingId});

  // Design tokens
  static const Color primaryOrange = Color(0xFFE67E22);
  static const Color dark = Color(0xFF1F1F1F);
  static const Color lightBg = Color(0xFFF7F7F7);
  static const Color softOrange = Color(0xFFFFECDB);
  static const Color successBg = Color(0xFFE4F7D8);
  static const Color successText = Color(0xFF3D8B2D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
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
            snapshot.data!.data() ?? {},
            snapshot.data!.id,
          );

          debugPrint('booking ==> $booking');

          // Handle terminal states gracefully
          if (booking.isCancelled) {
            return _CancelledView(booking: booking);
          }

          final stage = _BookingStageMapper.fromBooking(booking);
          final headerData = _HeaderData.fromBooking(booking, stage);
          final statusSteps = _BookingStageMapper.buildStatusSteps(stage);

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: _ScreenHeader(booking: booking),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: _TopStatusBanner(
                      title: headerData.headline,
                      subtitle: headerData.subtitle,
                      icon: headerData.bannerIcon,
                      bgColor: headerData.bannerBg,
                      iconColor: headerData.bannerIconColor,
                      isPulsing: stage != ActiveLaundryOrderStage.completed,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: _LaundryHeroCard(
                      booking: booking,
                      headerData: headerData,
                      stage: stage,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: _CustomerActionSection(
                      booking: booking,
                      stage: stage,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: _StatusTrackerCard(steps: statusSteps),
                  ),
                ),
                if (booking.selectedAddOns.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: _AddOnsCard(addOns: booking.selectedAddOns),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: _AddressCard(
                      pickupAddress: booking.customerAddress,
                      deliveryAddress: booking.laundrySnapshotAddressLine!,
                      isSameAsPickup: booking.isSameAsPickup,
                    ),
                  ),
                ),
                if (booking.customerNotes.trim().isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: _NotesTile(notes: booking.customerNotes),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                    child: _InfoBanner(
                      message: stage == ActiveLaundryOrderStage.completed
                          ? 'Your laundry order has been completed successfully.'
                          : 'This screen updates automatically as your booking moves through pickup, washing, and delivery.',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN HEADER  (booking code + copy button)
// ─────────────────────────────────────────────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  final BookingModel booking;

  const _ScreenHeader({required this.booking});

  @override
  Widget build(BuildContext context) {
    final code = booking.bookingCode.trim().isEmpty
        ? booking.id
        : booking.bookingCode;

    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking code copied'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 15, color: Colors.black38),
              ],
            ),
          ),
        ),
        // Mirror spacer
        const SizedBox(width: 42),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP STATUS BANNER  (with optional pulse dot for active states)
// ─────────────────────────────────────────────────────────────────────────────

class _TopStatusBanner extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final bool isPulsing;

  const _TopStatusBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.isPulsing,
  });

  @override
  State<_TopStatusBanner> createState() => _TopStatusBannerState();
}

class _TopStatusBannerState extends State<_TopStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulse = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isPulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_TopStatusBanner old) {
    super.didUpdateWidget(old);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.bgColor,
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
            child: Icon(widget.icon, color: widget.iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (widget.isPulsing) ...[
                      const SizedBox(width: 8),
                      FadeTransition(
                        opacity: _pulse,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.iconColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 13,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAUNDRY HERO CARD  (image + quick info chips)
// ─────────────────────────────────────────────────────────────────────────────

class _LaundryHeroCard extends StatelessWidget {
  final BookingModel booking;
  final _HeaderData headerData;
  final ActiveLaundryOrderStage stage;

  const _LaundryHeroCard({
    required this.booking,
    required this.headerData,
    required this.stage,
  });

  String get _laundryName {
    final name = booking.laundrySnapshotName?.trim() ?? '';
    return name.isNotEmpty ? name : 'Laundry';
  }

  String get _imageUrl {
    final url = booking.laundrySnapshotPhotoUrl?.trim() ?? '';
    return url.isNotEmpty ? url : '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image with gradient + name overlay
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _LaundryImage(imageUrl: _imageUrl),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x1A000000),
                          Color(0x00000000),
                          Color(0xCC000000),
                        ],
                        stops: [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _laundryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _OverlayChip(
                                    icon: Icons.location_on_rounded,
                                    label: headerData.distanceText,
                                  ),
                                  const SizedBox(width: 8),
                                  _OverlayChip(label: headerData.etaText),
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
          ),

          // Quick info chips row
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: _QuickInfoCard(
                    icon: Icons.local_laundry_service_rounded,
                    title: _serviceLabel(booking.serviceType),
                    subtitle: 'Service',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickInfoCard(
                    icon: Icons.payments_outlined,
                    title: 'GH₵ ${booking.totalPrice}',
                    subtitle: 'Estimated',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickInfoCard(
                    icon: _statusIconForStage(stage),
                    title: _stageShortLabel(stage),
                    subtitle: 'Status',
                  ),
                ),
              ],
            ),
          ),
        ],
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
        return raw.trim().isEmpty ? 'Laundry' : raw.replaceAll('_', ' ');
    }
  }

  static String _stageShortLabel(ActiveLaundryOrderStage stage) {
    switch (stage) {
      case ActiveLaundryOrderStage.riderSearch:
        return 'Searching';
      case ActiveLaundryOrderStage.pickupAssigned:
        return 'Assigned';
      case ActiveLaundryOrderStage.pickupInProgress:
        return 'Pickup';
      case ActiveLaundryOrderStage.atLaundry:
        return 'At Laundry';
      case ActiveLaundryOrderStage.processing:
        return 'Washing';
      case ActiveLaundryOrderStage.readyForDropoff:
        return 'Ready';
      case ActiveLaundryOrderStage.deliveryInProgress:
        return 'Delivery';
      case ActiveLaundryOrderStage.completed:
        return 'Done';
      case ActiveLaundryOrderStage.accepted:
        return 'Accepted';
    }
  }

  static IconData _statusIconForStage(ActiveLaundryOrderStage stage) {
    switch (stage) {
      case ActiveLaundryOrderStage.riderSearch:
        return Icons.search_rounded;
      case ActiveLaundryOrderStage.pickupAssigned:
        return Icons.assignment_ind_rounded;
      case ActiveLaundryOrderStage.pickupInProgress:
        return Icons.two_wheeler_rounded;
      case ActiveLaundryOrderStage.atLaundry:
        return Icons.inventory_2_rounded;
      case ActiveLaundryOrderStage.processing:
        return Icons.local_laundry_service_rounded;
      case ActiveLaundryOrderStage.readyForDropoff:
        return Icons.inventory_outlined;
      case ActiveLaundryOrderStage.deliveryInProgress:
        return Icons.local_shipping_rounded;
      case ActiveLaundryOrderStage.completed:
        return Icons.verified_rounded;
      case ActiveLaundryOrderStage.accepted:
        return Icons.check_circle_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS TRACKER CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StatusTrackerCard extends StatelessWidget {
  final List<_OrderStepData> steps;

  const _StatusTrackerCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ActiveLaundryOrderScreen.lightBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;

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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD-ONS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _AddOnsCard extends StatelessWidget {
  final List<String> addOns;

  const _AddOnsCard({required this.addOns});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ActiveLaundryOrderScreen.lightBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.add_box_outlined,
              color: ActiveLaundryOrderScreen.primaryOrange,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: addOns.map((addOn) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: ActiveLaundryOrderScreen.softOrange,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _addOnIcon(addOn),
                            size: 15,
                            color: ActiveLaundryOrderScreen.primaryOrange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            addOn,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: Colors.black87,
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
    );
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
}

// ─────────────────────────────────────────────────────────────────────────────
// ADDRESS CARD  (pickup + delivery, combined)
// ─────────────────────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final String pickupAddress;
  final String deliveryAddress;
  final bool isSameAsPickup;

  const _AddressCard({
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.isSameAsPickup,
  });

  @override
  Widget build(BuildContext context) {
    final pickup = pickupAddress.trim().isEmpty
        ? 'Pickup address not available'
        : pickupAddress;

    final delivery = isSameAsPickup
        ? 'Same as pickup'
        : (deliveryAddress.trim().isEmpty
              ? 'Delivery address not available'
              : deliveryAddress);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ActiveLaundryOrderScreen.lightBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _AddressRow(
            icon: Icons.home_rounded,
            label: 'Pickup',
            value: pickup,
            iconColor: ActiveLaundryOrderScreen.primaryOrange,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 21),
            child: Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Container(width: 2, height: 4, color: Colors.black12),
                ),
              ),
            ),
          ),
          _AddressRow(
            icon: Icons.store,
            label: 'Delivery',
            value: delivery,
            iconColor: const Color(0xFF185FA5),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _AddressRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: ActiveLaundryOrderScreen.dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTES TILE
// ─────────────────────────────────────────────────────────────────────────────

class _NotesTile extends StatelessWidget {
  final String notes;

  const _NotesTile({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ActiveLaundryOrderScreen.lightBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notes_rounded,
              color: ActiveLaundryOrderScreen.primaryOrange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your notes',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: ActiveLaundryOrderScreen.dark,
                    height: 1.5,
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

// ─────────────────────────────────────────────────────────────────────────────
// INFO BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final String message;

  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ActiveLaundryOrderScreen.softOrange,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ActiveLaundryOrderScreen.primaryOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: ActiveLaundryOrderScreen.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CANCELLED VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _CancelledView extends StatelessWidget {
  final BookingModel booking;

  const _CancelledView({required this.booking});

  @override
  Widget build(BuildContext context) {
    final reason = booking.customerNotes.trim().isNotEmpty
        ? booking.customerNotes
        : 'No reason provided.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _CircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE2E2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                size: 36,
                color: Color(0xFFC33A3A),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Booking Cancelled',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ActiveLaundryOrderScreen.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
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

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOMER ACTION SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerActionSection extends StatelessWidget {
  final BookingModel booking;
  final ActiveLaundryOrderStage stage;

  const _CustomerActionSection({required this.booking, required this.stage});

  bool get _showPickupRiderButton =>
      stage == ActiveLaundryOrderStage.pickupAssigned ||
      stage == ActiveLaundryOrderStage.pickupInProgress;

  bool get _showLaundryButtons =>
      stage == ActiveLaundryOrderStage.atLaundry ||
      stage == ActiveLaundryOrderStage.processing ||
      stage == ActiveLaundryOrderStage.readyForDropoff ||
      stage == ActiveLaundryOrderStage.deliveryInProgress;

  bool get _showDeliveryRiderButton =>
      stage == ActiveLaundryOrderStage.readyForDropoff ||
      stage == ActiveLaundryOrderStage.deliveryInProgress;

  void _openChat(
    BuildContext context, {
    required String role,
    required String? participantId,
    required String emptyMessage,
  }) {
    final id = participantId?.trim() ?? '';
    if (id.isEmpty) {
      _showSnack(context, emptyMessage);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingChatScreen(
          booking: booking,
          currentUserRole: 'customer',
          otherParticipantRole: role,
          otherParticipantId: id,
        ),
      ),
    );
  }

  Future<void> _callLaundry(BuildContext context) async {
    final phone = booking.laundrySnapshotPhone?.trim().isNotEmpty == true
        ? booking.laundrySnapshotPhone!.trim()
        : booking.laundryPhone.trim();

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
    final actions = <_ActionButtonData>[];

    if (_showPickupRiderButton) {
      actions.add(
        _ActionButtonData(
          icon: Icons.delivery_dining_rounded,
          title: 'Chat Pickup\nRider',
          filled: true,
          onTap: () => _openChat(
            context,
            role: 'rider',
            participantId: booking.pickupRiderId,
            emptyMessage: 'Pickup rider is not assigned yet.',
          ),
        ),
      );
    }

    if (_showLaundryButtons) {
      actions.add(
        _ActionButtonData(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Chat\nLaundry',
          filled: true,
          onTap: () => _openChat(
            context,
            role: 'laundry',
            participantId: booking.laundryId,
            emptyMessage: 'Laundry is not available yet.',
          ),
        ),
      );
      actions.add(
        _ActionButtonData(
          icon: Icons.call_outlined,
          title: 'Call\nLaundry',
          filled: false,
          onTap: () => _callLaundry(context),
        ),
      );
    }

    if (_showDeliveryRiderButton) {
      actions.add(
        _ActionButtonData(
          icon: Icons.local_shipping_rounded,
          title: 'Chat Delivery\nRider',
          filled: true,
          onTap: () => _openChat(
            context,
            role: 'rider',
            participantId: booking.deliveryRiderId,
            emptyMessage: 'Delivery rider is not assigned yet.',
          ),
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ActiveLaundryOrderScreen.lightBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: actions.map((a) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: a == actions.last ? 0 : 8),
              child: _ActionButton(data: a),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionButtonData {
  final IconData icon;
  final String title;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButtonData({
    required this.icon,
    required this.title,
    required this.filled,
    required this.onTap,
  });
}

class _ActionButton extends StatelessWidget {
  final _ActionButtonData data;

  const _ActionButton({required this.data});

  @override
  Widget build(BuildContext context) {
    final bg = data.filled
        ? ActiveLaundryOrderScreen.primaryOrange
        : Colors.white;
    final fg = data.filled
        ? Colors.white
        : ActiveLaundryOrderScreen.primaryOrange;
    final border = data.filled
        ? Colors.transparent
        : ActiveLaundryOrderScreen.primaryOrange.withOpacity(0.2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: data.filled
                ? [
                    BoxShadow(
                      color: ActiveLaundryOrderScreen.primaryOrange.withOpacity(
                        0.18,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, size: 20, color: fg),
              const SizedBox(height: 8),
              Text(
                data.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: fg,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING STAGE MAPPER
// ─────────────────────────────────────────────────────────────────────────────

class _BookingStageMapper {
  static ActiveLaundryOrderStage fromBooking(BookingModel booking) {
    switch (booking.status.trim().toLowerCase()) {
      case 'looking_for_pickup_rider':
        return ActiveLaundryOrderStage.riderSearch;
      case 'pickup_rider_assigned':
        // Fix: new status from refactored cloud function
        return ActiveLaundryOrderStage.pickupAssigned;
      case 'pickup_started':
      case 'arrived_at_pickup':
        return ActiveLaundryOrderStage.pickupInProgress;
      case 'arrived_at_laundry':
        return ActiveLaundryOrderStage.atLaundry;
      case 'processing':
        return ActiveLaundryOrderStage.processing;
      case 'ready_for_dropoff':
        return ActiveLaundryOrderStage.readyForDropoff;
      // Fix: new status from refactored cloud function
      case 'delivery_rider_assigned':
      case 'delivery_in_progress':
        return ActiveLaundryOrderStage.deliveryInProgress;
      case 'completed':
        return ActiveLaundryOrderStage.completed;
      case 'pending':
        return ActiveLaundryOrderStage.accepted;
      default:
        return ActiveLaundryOrderStage.riderSearch;
    }
  }

  static List<_OrderStepData> buildStatusSteps(ActiveLaundryOrderStage stage) {
    return [
      _OrderStepData(
        subtitle: 'Looking for a pickup rider.',
        isCompleted: stage.index > ActiveLaundryOrderStage.riderSearch.index,
        isCurrent: stage == ActiveLaundryOrderStage.riderSearch,
        icon: Icons.search_rounded,
      ),
      _OrderStepData(
        subtitle: 'Pickup rider assigned.',
        isCompleted: stage.index > ActiveLaundryOrderStage.pickupAssigned.index,
        isCurrent: stage == ActiveLaundryOrderStage.pickupAssigned,
        icon: Icons.assignment_ind_rounded,
      ),
      _OrderStepData(
        subtitle: 'Pickup is in progress.',
        isCompleted:
            stage.index > ActiveLaundryOrderStage.pickupInProgress.index,
        isCurrent: stage == ActiveLaundryOrderStage.pickupInProgress,
        icon: Icons.two_wheeler_rounded,
      ),
      _OrderStepData(
        subtitle: 'Items arrived at the laundry.',
        isCompleted: stage.index > ActiveLaundryOrderStage.atLaundry.index,
        isCurrent: stage == ActiveLaundryOrderStage.atLaundry,
        icon: Icons.inventory_2_rounded,
      ),
      _OrderStepData(
        subtitle: 'Wash is in progress.',
        isCompleted: stage.index > ActiveLaundryOrderStage.processing.index,
        isCurrent: stage == ActiveLaundryOrderStage.processing,
        icon: Icons.local_laundry_service_rounded,
      ),
      _OrderStepData(
        subtitle: 'Ready for dropoff.',
        isCompleted:
            stage.index > ActiveLaundryOrderStage.readyForDropoff.index,
        isCurrent: stage == ActiveLaundryOrderStage.readyForDropoff,
        icon: Icons.inventory_outlined,
      ),
      _OrderStepData(
        subtitle: 'Laundry is on its way to you.',
        isCompleted:
            stage.index > ActiveLaundryOrderStage.deliveryInProgress.index,
        isCurrent: stage == ActiveLaundryOrderStage.deliveryInProgress,
        icon: Icons.local_shipping_rounded,
      ),
      _OrderStepData(
        subtitle: 'Order completed.',
        isCompleted: stage == ActiveLaundryOrderStage.completed,
        isCurrent: stage == ActiveLaundryOrderStage.completed,
        icon: Icons.verified_rounded,
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER DATA
// ─────────────────────────────────────────────────────────────────────────────

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
    ActiveLaundryOrderStage stage,
  ) {
    final laundryName = booking.laundrySnapshotName?.trim().isNotEmpty == true
        ? booking.laundrySnapshotName!
        : booking.laundryName.trim().isNotEmpty
        ? booking.laundryName
        : 'Laundry';

    switch (stage) {
      case ActiveLaundryOrderStage.riderSearch:
        return _HeaderData(
          headline: 'Finding a pickup rider',
          subtitle: '$laundryName accepted and rider search is underway.',
          etaText: 'Finding rider',
          distanceText: 'Tracking live',
          bannerIcon: Icons.search_rounded,
          bannerBg: ActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ActiveLaundryOrderScreen.primaryOrange,
        );
      case ActiveLaundryOrderStage.pickupAssigned:
        return _HeaderData(
          headline: 'Pickup rider assigned',
          subtitle: 'A rider is on the way to your pickup location.',
          etaText: 'Rider on the way',
          distanceText: 'Tracking live',
          bannerIcon: Icons.assignment_ind_rounded,
          bannerBg: ActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ActiveLaundryOrderScreen.primaryOrange,
        );
      case ActiveLaundryOrderStage.pickupInProgress:
        return _HeaderData(
          headline: 'Pickup in progress',
          subtitle: 'Your rider is collecting your laundry.',
          etaText: 'Collecting now',
          distanceText: 'Tracking live',
          bannerIcon: Icons.two_wheeler_rounded,
          bannerBg: ActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ActiveLaundryOrderScreen.primaryOrange,
        );
      case ActiveLaundryOrderStage.atLaundry:
        return _HeaderData(
          headline: 'Laundry received at $laundryName',
          subtitle: 'Your items are now at the laundry shop.',
          etaText: 'At laundry',
          distanceText: 'With laundry',
          bannerIcon: Icons.inventory_2_rounded,
          bannerBg: ActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ActiveLaundryOrderScreen.primaryOrange,
        );
      case ActiveLaundryOrderStage.processing:
        return _HeaderData(
          headline: 'Washing in progress',
          subtitle: '$laundryName is currently processing your order.',
          etaText: 'In progress',
          distanceText: 'At laundry',
          bannerIcon: Icons.local_laundry_service_rounded,
          bannerBg: ActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ActiveLaundryOrderScreen.primaryOrange,
        );
      case ActiveLaundryOrderStage.readyForDropoff:
        return _HeaderData(
          headline: 'Your order is ready',
          subtitle: 'Clean and ready — waiting for a delivery rider.',
          etaText: 'Ready for delivery',
          distanceText: 'Ready',
          bannerIcon: Icons.inventory_outlined,
          bannerBg: ActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ActiveLaundryOrderScreen.primaryOrange,
        );
      case ActiveLaundryOrderStage.deliveryInProgress:
        return _HeaderData(
          headline: 'Your laundry is on its way',
          subtitle: 'Your clean items are being delivered to you.',
          etaText: 'Out for delivery',
          distanceText: 'Tracking live',
          bannerIcon: Icons.local_shipping_rounded,
          bannerBg: ActiveLaundryOrderScreen.softOrange,
          bannerIconColor: ActiveLaundryOrderScreen.primaryOrange,
        );
      case ActiveLaundryOrderStage.completed:
        return _HeaderData(
          headline: 'Order completed',
          subtitle: 'All done! We hope everything looks great.',
          etaText: 'Delivered',
          distanceText: 'Completed',
          bannerIcon: Icons.verified_rounded,
          bannerBg: ActiveLaundryOrderScreen.successBg,
          bannerIconColor: ActiveLaundryOrderScreen.successText,
        );
      case ActiveLaundryOrderStage.accepted:
        return _HeaderData(
          headline: '$laundryName accepted your request',
          subtitle: 'Your booking is now active.',
          etaText: 'Accepted',
          distanceText: 'Tracking live',
          bannerIcon: Icons.check_circle_rounded,
          bannerBg: ActiveLaundryOrderScreen.successBg,
          bannerIconColor: ActiveLaundryOrderScreen.successText,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _LaundryImage extends StatelessWidget {
  final String imageUrl;

  const _LaundryImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _fallback();

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFD4C5B0),
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_laundry_service_rounded,
        size: 40,
        color: Color(0x66000000),
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  final IconData? icon;
  final String label;

  const _OverlayChip({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: ActiveLaundryOrderScreen.primaryOrange, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: ActiveLaundryOrderScreen.lightBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: ActiveLaundryOrderScreen.primaryOrange, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ActiveLaundryOrderScreen.dark,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black45,
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
        ? ActiveLaundryOrderScreen.primaryOrange
        : ActiveLaundryOrderScreen.successText;

    final isDone = isCompleted && !isCurrent;

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
            isDone
                ? Icons.check_rounded
                : (isCompleted || isCurrent)
                ? icon
                : Icons.radio_button_unchecked_rounded,
            size: 17,
            color: (isCompleted || isCurrent) ? activeColor : Colors.black26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'Poppins',
              color: isCurrent
                  ? Colors.black87
                  : Colors.black.withOpacity(0.55),
            ),
          ),
        ),
        if (isCurrent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: ActiveLaundryOrderScreen.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Now',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: ActiveLaundryOrderScreen.primaryOrange,
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

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.black87, size: 20),
        ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: ActiveLaundryOrderScreen.primaryOrange,
          ),
          const SizedBox(height: 14),
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
