/* import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'
    show FirebaseFirestore, GeoPoint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'closest_laundries_screen.dart';

class _CollapsedRequestBar extends StatelessWidget {
  final String selectedService;
  final int totalPrice;
  final VoidCallback onPrimaryTap;
  final bool isSubmitting;
  final VoidCallback onToggleSheet;

  const _CollapsedRequestBar({
    super.key,
    required this.selectedService,
    required this.totalPrice,
    required this.onPrimaryTap,
    required this.isSubmitting,
    required this.onToggleSheet,
  });

  @override
  Widget build(BuildContext context) {
    return _ExpandedRequestBar(
      selectedService: selectedService,
      totalPrice: totalPrice,
      onPrimaryTap: onPrimaryTap,
      actionText: 'Request',
      isSubmitting: isSubmitting,
      onToggleSheet: onToggleSheet,
    );
  }
}

class ClosestLaundrySelectedScreen extends StatefulWidget {
  final dynamic lastLocation;
  final String laundryId;
  const ClosestLaundrySelectedScreen({
    super.key,
    this.lastLocation,
    required this.laundryId,
  });

  @override
  State<ClosestLaundrySelectedScreen> createState() =>
      _ClosestLaundrySelectedScreenState();
}

class _ClosestLaundrySelectedScreenState
    extends State<ClosestLaundrySelectedScreen> {
  String selectedServiceType = 'wash_fold';
  final Set<String> selectedAddOns = {};

  String? washerInstructions;
  DateTime? scheduledPickupAt;
  bool isSubmitting = false;

  final Map<String, int> addOnPrices = const {
    'Express Wash': 18,
    'Fragrance Booster': 6,
    'Whites Bleach': 10,
    'Delicate Wash': 9,
  };

  bool _showExpandedServiceSheet = false;

  void _toggleExpandedServiceSheet() {
    HapticFeedback.lightImpact();

    setState(() {
      _showExpandedServiceSheet = !_showExpandedServiceSheet;
    });
  }

  @override
  void initState() {
    super.initState();
    _initClosestLaundryFuture();
  }

  int _totalPriceFor(ClosestLaundryService laundry) {
    final serviceExtra = selectedServiceType == 'wash_iron' ? 2 : 0;
    final addOnsTotal = selectedAddOns.fold<int>(
      0,
      (sum, item) => sum + (addOnPrices[item] ?? 0),
    );

    return laundry.basePricePerKg + serviceExtra + addOnsTotal;
  }

  String get selectedServiceLabel {
    return selectedServiceType == 'wash_iron' ? 'Wash & Iron' : 'Wash & Fold';
  }

  void _changeServiceType(String value) {
    setState(() => selectedServiceType = value);
  }

  Future<ClosestLaundryService?>? _closestLaundryFuture;

  void _initClosestLaundryFuture() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _closestLaundryFuture = _loadClosestLaundryFromSavedUserLocation(
        user.uid,
      );
    }
  }

  Future<void> _openWasherInstructions() async {
    final controller = TextEditingController(text: washerInstructions ?? '');

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Washer instructions',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Washer instructions',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, controller.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        washerInstructions = result.isEmpty ? null : result;
      });
    }
  }

  Future<void> _openSchedulePickup() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      initialDate: scheduledPickupAt ?? DateTime.now(),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(scheduledPickupAt ?? DateTime.now()),
    );

    if (pickedTime == null) return;

    setState(() {
      scheduledPickupAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _handlePrimaryAction() async {
    setState(() => isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final lastLocationMap = Map<String, dynamic>.from(
      widget.lastLocation as Map,
    );
    final addressLine =
        lastLocationMap['addressLine']?.toString() ?? 'Location unavailable';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
          child: user == null
              ? const Center(child: Text('Please sign in first.'))
              : FutureBuilder<ClosestLaundryService?>(
                  future: _closestLaundryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LaundryServiceCardShimmer();
                    }

                    final laundry = snapshot.data;

                    if (laundry == null) {
                      return const Center(
                        child: Text('No nearby laundry found.'),
                      );
                    }

                    return Container(
                      /* color: Colors.red, */
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 95,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_showExpandedServiceSheet)
                              TopBar(title: laundry.name),
                            Expanded(child: SizedBox()),
                            LaundryServiceCard(
                              laundry: laundry,
                              selectedServiceType: selectedServiceType,
                              onServiceTypeChanged: _changeServiceType,
                              onTap: () {},
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 18,
                                  color: Color(0xFFE67E22),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    addressLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return SizeTransition(
                                  sizeFactor: animation,
                                  axisAlignment: -1,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: _showExpandedServiceSheet
                                  ? _ExpandedServiceSheet(
                                      key: const ValueKey(
                                        'expanded_service_sheet',
                                      ),
                                      pickupTitle: laundry.addressLine,
                                      selectedService: selectedServiceLabel,
                                      totalPrice: _totalPriceFor(laundry),
                                      addOnPrices: addOnPrices,
                                      onPrimaryTap: _handlePrimaryAction,
                                      isManualSelection: false,
                                      isSubmitting: isSubmitting,
                                      washerInstructions: washerInstructions,
                                      scheduledPickupAt: scheduledPickupAt,
                                      onWasherInstructionsTap:
                                          _openWasherInstructions,
                                      onSchedulePickupTap: _openSchedulePickup,
                                      onAddOnsChanged: (items) {
                                        setState(() {
                                          selectedAddOns
                                            ..clear()
                                            ..addAll(items);
                                        });
                                      },
                                      onToggleSheet:
                                          _toggleExpandedServiceSheet,
                                    )
                                  : _CollapsedRequestBar(
                                      key: const ValueKey(
                                        'collapsed_request_bar',
                                      ),
                                      selectedService: selectedServiceLabel,
                                      totalPrice: _totalPriceFor(laundry),
                                      onPrimaryTap: _handlePrimaryAction,
                                      isSubmitting: isSubmitting,
                                      onToggleSheet:
                                          _toggleExpandedServiceSheet,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<ClosestLaundryService?> _loadClosestLaundryFromSavedUserLocation(
    String uid,
  ) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final userData = userDoc.data() ?? <String, dynamic>{};
    final lastLocation = userData['lastCurrentLocation'];

    GeoPoint? userGeoPoint;

    if (lastLocation is GeoPoint) {
      userGeoPoint = lastLocation;
    } else if (lastLocation is Map) {
      final map = Map<String, dynamic>.from(lastLocation);

      final lat = map['latitude'];
      final lng = map['longitude'];

      if (lat is num && lng is num) {
        userGeoPoint = GeoPoint(lat.toDouble(), lng.toDouble());
      } else {
        final geopoint = map['geopoint'];
        if (geopoint is GeoPoint) userGeoPoint = geopoint;
      }
    }

    if (userGeoPoint == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('laundries')
        .where('business.isApproved', isEqualTo: true)
        .where('business.isOnline', isEqualTo: true)
        .get();

    final laundries = <ClosestLaundryService>[];

    for (final doc in snapshot.docs) {
      try {
        laundries.add(
          ClosestLaundryService.fromFirestore(
            id: doc.id,
            data: doc.data(),
            pickupGeopoint: userGeoPoint,
          ),
        );
      } catch (_) {}
    }

    laundries.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return laundries.isEmpty ? null : laundries.first;
  }
}

class LaundryServiceCard extends StatelessWidget {
  final ClosestLaundryService laundry;
  final VoidCallback onTap;
  final String selectedServiceType;
  final ValueChanged<String> onServiceTypeChanged;

  const LaundryServiceCard({
    super.key,
    required this.laundry,
    required this.onTap,
    required this.selectedServiceType,
    required this.onServiceTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final basePrice =
        laundry.basePricePerKg + (selectedServiceType == 'wash_iron' ? 2 : 0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            _CardImageSection(laundry: laundry),
            _CardBodySection(
              laundry: laundry,
              basePricePerKg: laundry.basePricePerKg,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _StatusBadge({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _CardImageSection extends StatelessWidget {
  final ClosestLaundryService laundry;

  const _CardImageSection({required this.laundry});

  @override
  Widget build(BuildContext context) {
    final imagePath = laundry.imagePath.trim();
    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isNetwork)
              Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ImageFallback(),
              )
            else if (imagePath.isNotEmpty)
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ImageFallback(),
              )
            else
              const _ImageFallback(),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x1A000000),
                    Color(0x00000000),
                    Color(0xB2000000),
                  ],
                  stops: [0.0, 0.35, 1.0],
                ),
              ),
            ),

            Positioned(
              top: 12,
              right: 12,
              child: _StatusBadge(
                label: laundry.isOpen ? 'Open' : 'Closed',
                textColor: laundry.isOpen
                    ? const Color(0xFFE67E22)
                    : const Color(0xFF6D6D6D),
                bgColor: laundry.isOpen
                    ? const Color(0xFFFFE8D6)
                    : const Color(0xFFEEEEEE),
              ),
            ),

            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    laundry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Color(0x55000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    laundry.addressLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BODY SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _CardBodySection extends StatefulWidget {
  final ClosestLaundryService laundry;
  final int basePricePerKg;

  const _CardBodySection({required this.laundry, required this.basePricePerKg});

  @override
  State<_CardBodySection> createState() => _CardBodySectionState();
}

class _CardBodySectionState extends State<_CardBodySection> {
  String selectedServiceType = 'wash_fold';

  int get displayPrice {
    return widget.basePricePerKg + (selectedServiceType == 'wash_iron' ? 2 : 0);
  }

  void _changeServiceType(String value) {
    setState(() {
      selectedServiceType = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final laundry = widget.laundry;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.near_me_rounded,
                  label: '${laundry.distanceKm.toStringAsFixed(1)} km',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: '${laundry.etaMinutes} min',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _PriceTag(price: displayPrice)),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: SelectedService(
                  title: 'Wash & Fold',
                  serviceType: 'wash_fold',
                  isSelected: selectedServiceType == 'wash_fold',
                  onTap: () => _changeServiceType('wash_fold'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectedService(
                  title: 'Wash & Iron',
                  serviceType: 'wash_iron',
                  isSelected: selectedServiceType == 'wash_iron',
                  onTap: () => _changeServiceType('wash_iron'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD4C5B0),
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_laundry_service_rounded,
        size: 44,
        color: Color(0x66000000),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.iconColor = const Color(0xFFE67E22),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final int price;

  const _PriceTag({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'GH₵$price/kg',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
          color: Colors.black,
        ),
      ),
    );
  }
}

class LaundryServiceCardShimmer extends StatefulWidget {
  const LaundryServiceCardShimmer({super.key});

  @override
  State<LaundryServiceCardShimmer> createState() =>
      _LaundryServiceCardShimmerState();
}

class _LaundryServiceCardShimmerState extends State<LaundryServiceCardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _shine({required Widget child}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, animatedChild) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.2 + _controller.value * 2.4, -0.3),
              end: Alignment(0.2 + _controller.value * 2.4, 0.3),
              colors: const [
                Color(0xFFEFEFEF),
                Color(0xFFFFFFFF),
                Color(0xFFEFEFEF),
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: animatedChild,
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _shine(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: const [
                _ShimmerBox(
                  height: 155,
                  width: double.infinity,
                  radius: 26,
                  topOnly: true,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _ShimmerBox(width: 64, height: 34, radius: 999),
                ),
                Positioned(
                  left: 20,
                  bottom: 42,
                  child: _ShimmerBox(width: 210, height: 24, radius: 8),
                ),
                Positioned(
                  left: 20,
                  bottom: 16,
                  child: _ShimmerBox(width: 285, height: 18, radius: 8),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                children: const [
                  Row(
                    children: [
                      Expanded(child: _ShimmerBox(height: 36, radius: 999)),
                      SizedBox(width: 10),
                      Expanded(child: _ShimmerBox(height: 36, radius: 999)),
                      SizedBox(width: 10),
                      Expanded(child: _ShimmerBox(height: 36, radius: 999)),
                    ],
                  ),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      _ShimmerBox(width: 118, height: 36, radius: 999),
                      SizedBox(width: 8),
                      _ShimmerBox(width: 120, height: 36, radius: 999),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      _ShimmerBox(width: 86, height: 36, radius: 999),
                      SizedBox(width: 8),
                      _ShimmerBox(width: 82, height: 36, radius: 999),
                      Spacer(),
                      _ShimmerBox(width: 96, height: 42, radius: 999),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool topOnly;

  const _ShimmerBox({
    this.width,
    required this.height,
    this.radius = 14,
    this.topOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = topOnly
        ? BorderRadius.vertical(top: Radius.circular(radius))
        : BorderRadius.circular(radius);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 231, 216),
        borderRadius: borderRadius,
      ),
    );
  }
}

class SelectedService extends StatelessWidget {
  final String title;
  final String serviceType;
  final VoidCallback? onTap;
  final IconData icon;
  final bool isSelected;

  const SelectedService({
    super.key,
    required this.title,
    this.onTap,
    this.icon = Icons.location_on_outlined,
    required this.serviceType,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        scale: isSelected ? 1.0 : 0.96,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFECDB)
                    : const Color.fromARGB(255, 240, 240, 240),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? const Color.fromARGB(54, 230, 125, 34)
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.08 : 0.02),
                    blurRadius: isSelected ? 12 : 4,
                    offset: Offset(0, isSelected ? 5 : 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (serviceType == 'wash_iron') const SizedBox(width: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        scale: isSelected ? 1.1 : 0.9,
                        child: Image.asset(
                          serviceType == 'wash_fold'
                              ? 'assets/images/wash_foldd.png'
                              : 'assets/images/wash_ironn.png',
                          height: 60,
                          width: 60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: Colors.black.withOpacity(isSelected ? 1 : 0.9),
                        height: 1.1,
                      ),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  opacity: isSelected ? 0.0 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(165, 255, 255, 255),
                      borderRadius: BorderRadius.circular(30),
                    ),
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

class _ExpandedServiceSheet extends StatelessWidget {
  final String pickupTitle;
  final String selectedService;
  final int totalPrice;
  final Map<String, int> addOnPrices;
  final VoidCallback onPrimaryTap;
  // actionText is no longer passed in — computed from scheduledPickupAt below.
  final bool isSubmitting;
  final bool isManualSelection;
  final ValueChanged<Set<String>> onAddOnsChanged;
  final String? washerInstructions;
  final DateTime? scheduledPickupAt;
  final VoidCallback onWasherInstructionsTap;
  final VoidCallback onSchedulePickupTap;
  final VoidCallback onToggleSheet;

  const _ExpandedServiceSheet({
    super.key,
    required this.pickupTitle,
    required this.selectedService,
    required this.totalPrice,
    required this.addOnPrices,
    required this.onPrimaryTap,
    required this.isSubmitting,
    required this.isManualSelection,
    required this.washerInstructions,
    required this.scheduledPickupAt,
    required this.onWasherInstructionsTap,
    required this.onSchedulePickupTap,
    required this.onAddOnsChanged,
    required this.onToggleSheet,
  });

  bool get _isFutureScheduled {
    if (scheduledPickupAt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = DateTime(
      scheduledPickupAt!.year,
      scheduledPickupAt!.month,
      scheduledPickupAt!.day,
    );
    return picked.isAfter(today);
  }

  String get _actionText {
    if (isManualSelection) return 'Browse Laundries';
    if (_isFutureScheduled) return 'Schedule Pickup';
    return 'Request';
  }

  String _formatScheduled(DateTime dt) {
    const months = [
      '',
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
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionRow(
          title: 'Washer instructions',
          subtitle: washerInstructions,
          onTap: onWasherInstructionsTap,
        ),
        const Divider(
          height: 1,
          color: Color.fromARGB(255, 185, 185, 185),
          endIndent: 20,
          indent: 20,
        ),
        _OptionRow(
          title: 'Schedule pickup',
          subtitle: scheduledPickupAt != null
              ? _formatScheduled(scheduledPickupAt!)
              : 'ASAP',
          onTap: onSchedulePickupTap,
          subtitleHighlighted: scheduledPickupAt != null,
        ),

        const SizedBox(height: 15),
        _ExpandedAddOnCard(onChanged: onAddOnsChanged),
        const SizedBox(height: 15),
        _ExpandedRequestBar(
          selectedService: selectedService,
          totalPrice: totalPrice,
          onPrimaryTap: onPrimaryTap,
          actionText: _actionText,
          isSubmitting: isSubmitting,
          onToggleSheet: onToggleSheet,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ExpandedRequestBar extends StatelessWidget {
  final String selectedService;
  final int totalPrice;
  final VoidCallback onPrimaryTap;
  final String actionText;
  final bool isSubmitting;
  final VoidCallback onToggleSheet;

  const _ExpandedRequestBar({
    required this.selectedService,
    required this.totalPrice,
    required this.onPrimaryTap,
    required this.actionText,
    required this.isSubmitting,
    required this.onToggleSheet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F7D8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.payments_outlined, color: Color(0xFF3D8B2D)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onPrimaryTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 33, 33, 33),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFE67E22),
                        ),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.95,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        '$actionText  GH₵$totalPrice',
                        key: ValueKey(totalPrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE67E22),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onToggleSheet,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 247, 232, 216),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon( Icons.tune, color: Color.fromARGB(255, 0, 0, 0)),wrvwvawv
          ),
        ),
      ],
    );
  }
}

class _ExpandedAddOnCard extends StatefulWidget {
  final ValueChanged<Set<String>>? onChanged;

  const _ExpandedAddOnCard({this.onChanged});

  @override
  State<_ExpandedAddOnCard> createState() => _ExpandedAddOnCardState();
}

class _ExpandedAddOnCardState extends State<_ExpandedAddOnCard> {
  final Set<String> selectedAddOns = {};

  void _toggleAddOn(String value) {
    HapticFeedback.lightImpact();

    setState(() {
      selectedAddOns.contains(value)
          ? selectedAddOns.remove(value)
          : selectedAddOns.add(value);
    });

    widget.onChanged?.call(Set<String>.from(selectedAddOns));
  }

  @override
  Widget build(BuildContext context) {
    final addOns1 = [
      {'label': 'Express Wash', 'asset': 'assets/images/express_wash.png'},
      {
        'label': 'Fragrance Booster',
        'asset': 'assets/images/fragrance_booster.png',
      },
    ];

    final addOns2 = [
      {'label': 'Whites Bleach', 'asset': 'assets/images/bleach_whites.png'},
      {'label': 'Delicate Wash', 'asset': 'assets/images/delicate_wash.png'},
    ];

    Widget pillRow(List<Map<String, String>> items) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) {
          final label = item['label']!;
          final asset = item['asset']!;

          return SelectablePill(
            text: label,
            assetPath: asset,
            trailingSize: 22,
            isSelected: selectedAddOns.contains(label),
            onTap: () => _toggleAddOn(label),
          );
        }).toList(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laundry add-ons',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          pillRow(addOns1),
          const SizedBox(height: 5),
          pillRow(addOns2),
        ],
      ),
    );
  }
}

class SelectablePill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? assetPath;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double trailingSize;

  const SelectablePill({
    super.key,
    required this.text,
    required this.isSelected,
    this.onTap,
    this.icon,
    this.assetPath,
    this.backgroundColor = const Color(0xFFF3F3F3),
    this.selectedBackgroundColor = const Color(0xFFFFECDB),
    this.borderRadius = 30,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.trailingSize = 22,
  }) : assert(
         icon != null || assetPath != null,
         'Provide either an icon or an assetPath.',
       );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        width: 170,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? selectedBackgroundColor : backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
              blurRadius: isSelected ? 10 : 5,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.9,
                      end: 1.0,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: isSelected
                  ? Container(
                      key: const ValueKey('selected_check'),
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE67E22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.black,
                      ),
                    )
                  : Image.asset(
                      assetPath!,
                      key: const ValueKey('asset_trailing'),
                      width: trailingSize,
                      height: trailingSize,
                      fit: BoxFit.contain,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool subtitleHighlighted;

  const _OptionRow({
    required this.title,
    this.subtitle,
    this.onTap,
    this.subtitleHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: subtitleHighlighted
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontFamily: 'Poppins',
                        color: subtitleHighlighted
                            ? const Color(0xFFE67E22)
                            : Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  final String title;

  const TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 28,
                ),
              ),
            ),
            Center(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 */

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapPickupPickerScreen extends StatefulWidget {
  final LatLng initialPickup;
  final LatLng fixedDropoff;
  final String dropoffAddress;
  final String googleMapsApiKey;

  const MapPickupPickerScreen({
    super.key,
    required this.initialPickup,
    required this.fixedDropoff,
    required this.dropoffAddress,
    required this.googleMapsApiKey,
  });

  @override
  State<MapPickupPickerScreen> createState() => _MapPickupPickerScreenState();
}

class _MapPickupPickerScreenState extends State<MapPickupPickerScreen> {
  GoogleMapController? _mapController;

  final bool _isPickerMode = false;

  late LatLng _selectedPickup;
  late LatLng _cameraCenter;

  String _pickupTitle = 'Move map to select pickup';
  String _pickupSubtitle = 'Swipe to move map';

  bool _isMovingMap = false;
  bool _isLoadingAddress = false;
  bool _showPickupPanel = false;
  bool _isLoadingRoute = false;

  bool _isProgrammaticCameraMove = false;

  Timer? _idleDebounce;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();

    _selectedPickup = widget.initialPickup;
    _cameraCenter = widget.initialPickup;

    _markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: widget.fixedDropoff,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Drop-off',
          snippet: widget.dropoffAddress,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idleDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    await _mapController!.moveCamera(
      CameraUpdate.newLatLngZoom(widget.initialPickup, 16),
    );

    await _handlePickupChanged(
      widget.initialPickup,
      fitRoute: false, // important: do not move camera on load
      causedByUser: false,
    );
  }

  void _onCameraMoveStarted() {
    _idleDebounce?.cancel();

    if (_isProgrammaticCameraMove) return;

    if (!_isMovingMap) {
      setState(() {
        _isMovingMap = true;
        _showPickupPanel = false;
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    _cameraCenter = position.target;
  }

  void _onCameraIdle() {
    _idleDebounce?.cancel();

    if (_isProgrammaticCameraMove) {
      _isProgrammaticCameraMove = false;
      return;
    }

    _idleDebounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;

      setState(() {
        _isMovingMap = false;
      });

      await _handlePickupChanged(
        _cameraCenter,
        fitRoute: false,
        causedByUser: true,
      );
    });
  }

  Future<void> _handlePickupChanged(
    LatLng pickup, {
    required bool fitRoute,
    required bool causedByUser,
  }) async {
    _selectedPickup = pickup;

    await Future.wait([
      _reverseGeocodePickup(pickup),
      _drawRoute(
        pickup: pickup,
        dropoff: widget.fixedDropoff,
        fitRoute: fitRoute,
      ),
    ]);

    if (!mounted) return;

    setState(() {
      _showPickupPanel = true;
    });
  }

  Future<void> _confirmPickupAndShowRoute() async {
    await _drawRoute(
      pickup: _selectedPickup,
      dropoff: widget.fixedDropoff,
      fitRoute: false,
    );

    if (!mounted) return;

    setState(() {
      _showPickupPanel = true;
    });
  }

  Future<LatLng?> _getCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('CURRENT LOCATION ERROR: $e');
      return null;
    }
  }

  Future<void> _moveToCurrentLocation() async {
    final current = await _getCurrentLocation();
    if (current == null || _mapController == null) return;

    _isProgrammaticCameraMove = true;

    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _selectedPickup, zoom: 10),
      ),
    );
  }

  Future<void> _reverseGeocodePickup(LatLng pickup) async {
    if (!mounted) return;

    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        pickup.latitude,
        pickup.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final title = [
          p.street,
          p.subLocality,
        ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

        final subtitle = [
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

        _pickupTitle = title.isEmpty ? 'Selected pickup point' : title;
        _pickupSubtitle = subtitle.isEmpty
            ? '${pickup.latitude}, ${pickup.longitude}'
            : subtitle;
      }
    } catch (e) {
      debugPrint('REVERSE GEOCODING ERROR: $e');
      _pickupTitle = 'Selected pickup point';
      _pickupSubtitle = '${pickup.latitude}, ${pickup.longitude}';
    }

    if (mounted) {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _drawRoute({
    required LatLng pickup,
    required LatLng dropoff,
    required bool fitRoute,
  }) async {
    if (!mounted) return;

    setState(() {
      _isLoadingRoute = true;
    });

    if (widget.googleMapsApiKey.trim().isEmpty) {
      _drawFallbackStraightLine(pickup, dropoff);
      if (fitRoute) await _fitRouteToScreen(pickup, dropoff);
      return;
    }

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${pickup.latitude},${pickup.longitude}'
        '&destination=${dropoff.latitude},${dropoff.longitude}'
        '&mode=driving'
        '&key=${widget.googleMapsApiKey}',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        _drawFallbackStraightLine(pickup, dropoff);
        if (fitRoute) await _fitRouteToScreen(pickup, dropoff);
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final apiStatus = data['status']?.toString();

      if (apiStatus != 'OK') {
        debugPrint('DIRECTIONS API STATUS: $apiStatus');
        debugPrint('DIRECTIONS BODY: ${response.body}');

        _drawFallbackStraightLine(pickup, dropoff);
        if (fitRoute) await _fitRouteToScreen(pickup, dropoff);
        return;
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        _drawFallbackStraightLine(pickup, dropoff);
        if (fitRoute) await _fitRouteToScreen(pickup, dropoff);
        return;
      }

      final points = routes.first['overview_polyline']?['points'] as String?;
      if (points == null || points.isEmpty) {
        _drawFallbackStraightLine(pickup, dropoff);
        if (fitRoute) await _fitRouteToScreen(pickup, dropoff);
        return;
      }

      final decodedPoints = _decodePolyline(points);

      if (decodedPoints.isEmpty) {
        _drawFallbackStraightLine(pickup, dropoff);
        if (fitRoute) await _fitRouteToScreen(pickup, dropoff);
        return;
      }

      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('pickup_to_dropoff_route'),
            points: decodedPoints,
            width: 6,
            color: const Color(0xFF147EFB),
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );

      if (mounted) setState(() {});

      if (fitRoute) {
        await _fitRouteToScreen(pickup, dropoff);
      }
    } catch (e) {
      debugPrint('DIRECTIONS EXCEPTION: $e');
      _drawFallbackStraightLine(pickup, dropoff);
      if (fitRoute) await _fitRouteToScreen(pickup, dropoff);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  void _drawFallbackStraightLine(LatLng pickup, LatLng dropoff) {
    _polylines
      ..clear()
      ..add(
        Polyline(
          polylineId: const PolylineId('pickup_to_dropoff_fallback'),
          points: [pickup, dropoff],
          width: 6,
          color: const Color(0xFF147EFB),
          patterns: [PatternItem.dash(18), PatternItem.gap(10)],
        ),
      );

    if (mounted) {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  Future<void> _fitRouteToScreen(LatLng pickup, LatLng dropoff) async {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(pickup.latitude, dropoff.latitude),
        math.min(pickup.longitude, dropoff.longitude),
      ),
      northeast: LatLng(
        math.max(pickup.latitude, dropoff.latitude),
        math.max(pickup.longitude, dropoff.longitude),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 250));

    try {
      _isProgrammaticCameraMove = true;

      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 110),
      );
    } catch (e) {
      _isProgrammaticCameraMove = false;
      debugPrint('FIT ROUTE ERROR: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlat = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dlng = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPickup,
              zoom: 10,
            ),
            onMapCreated: _onMapCreated,
            onCameraMoveStarted: _onCameraMoveStarted,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),

          const Positioned(
            top: 76,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Swipe to move map',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
            ),
          ),

          Center(
            child: Transform.translate(
              offset: const Offset(0, -42), // align stick tip to map center
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                offset: _isMovingMap ? const Offset(0, -0.20) : Offset.zero,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  scale: _isMovingMap ? 1.08 : 1,
                  child: const _CenterPickupPin(),
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            bottom: _showPickupPanel ? 255 : 36,
            child: _CircleMapButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            right: 16,
            bottom: _showPickupPanel ? 255 : 36,
            child: _CircleMapButton(
              icon: Icons.near_me_outlined,
              onTap: _moveToCurrentLocation,
            ),
          ),

          if (_isLoadingRoute)
            const Positioned(
              top: 116,
              left: 0,
              right: 0,
              child: Center(
                child: _SmallLoadingPill(text: 'Updating route...'),
              ),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: _showPickupPanel ? 0 : -300,
            child: _PickupAddressPanel(
              title: _isLoadingAddress
                  ? 'Finding pickup address...'
                  : _pickupTitle,
              subtitle: _pickupSubtitle,
              isLoading: _isLoadingRoute,
              onDone: _confirmPickupAndShowRoute,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterPickupPin extends StatelessWidget {
  const _CenterPickupPin();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_laundry_service_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          Container(width: 3, height: 28, color: const Color(0xFF111111)),
          Container(
            width: 18,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupAddressPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onDone;

  const _PickupAddressPanel({
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pickup address',
              style: TextStyle(
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.local_laundry_service_rounded,
                  color: Color(0xFF111111),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8C8C8C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: Color(0xFF111111),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: isLoading ? null : onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B30),
                  disabledBackgroundColor: const Color(0xFFFFB4AD),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
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

class _CircleMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleMapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(icon, color: const Color(0xFF111111), size: 26),
        ),
      ),
    );
  }
}

class _SmallLoadingPill extends StatelessWidget {
  final String text;

  const _SmallLoadingPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class PickedMapLocationResult {
  final String address;
  final String subtitle;
  final double latitude;
  final double longitude;

  const PickedMapLocationResult({
    required this.address,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });
}
