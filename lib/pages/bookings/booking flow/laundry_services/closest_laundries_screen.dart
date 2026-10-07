import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'manual_active_laundry_order_stage.dart'
    show ManualActiveLaundryOrderScreen;

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class ClosestLaundryService {
  final String id;
  final String name;
  final String subtitle;
  final String geohash;
  final GeoPoint geopoint;
  final double distanceKm;
  final double rating;
  final int etaMinutes;
  final bool isOpen;
  final String imagePath;
  final int basePricePerKg;
  final List<String> tags;
  final String phoneNumber;
  final String addressLine;

  const ClosestLaundryService({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.geohash,
    required this.geopoint,
    required this.distanceKm,
    required this.rating,
    required this.etaMinutes,
    required this.isOpen,
    required this.imagePath,
    required this.basePricePerKg,
    required this.tags,
    required this.phoneNumber,
    required this.addressLine,
  });

  bool get hasRating => rating > 0;

  factory ClosestLaundryService.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    required GeoPoint pickupGeopoint,
  }) {
    final profile = _asMap(data['profile']);
    final contact = _asMap(data['contact']);
    final location = _asMap(data['location']);
    final business = _asMap(data['business']);
    final ratings = _asMap(data['ratings']);
    final pricing = _asMap(data['pricing']);
    final services = _asMap(data['services']);

    final GeoPoint? laundryGeopoint = _readGeoPoint(location['geopoint']);
    final String laundryGeohash = _readString(location['geohash']) ?? '';

    if (laundryGeopoint == null || laundryGeohash.isEmpty) {
      throw Exception('Laundry location is missing geohash/geopoint.');
    }

    final distanceKm = _calculateDistanceKm(
      pickupGeopoint.latitude,
      pickupGeopoint.longitude,
      laundryGeopoint.latitude,
      laundryGeopoint.longitude,
    );

    final etaMinutes = math.max(4, (distanceKm * 5).round());

    final washFoldAvailable = _readBool(services['washFold']) ?? true;
    final washIronAvailable = _readBool(services['washIron']) ?? true;
    final ironingAvailable =
        _readBool(services['ironing']) ?? washIronAvailable;
    final pickupAvailable =
        _readBool(services['pickupAvailable']) ??
        _readBool(business['acceptingOrders']) ??
        true;

    final tags = <String>[
      if (washFoldAvailable) 'Wash & Fold',
      if (washIronAvailable) 'Wash & Iron',
      if (ironingAvailable) 'Ironing',
      if (pickupAvailable) 'Pickup',
    ];

    final isApproved = _readBool(business['isApproved']) ?? true;
    final isOnline = _readBool(business['isOnline']) ?? false;
    final acceptingOrders = _readBool(business['acceptingOrders']) ?? true;
    final isOpen = isApproved && isOnline && acceptingOrders;

    return ClosestLaundryService(
      id: id,
      name: _readString(profile['name']) ?? 'Laundry Service',
      subtitle:
          _readString(profile['subtitle']) ??
          _readString(profile['description']) ??
          _readString(location['addressLine']) ??
          'Nearby laundry service',
      geohash: laundryGeohash,
      geopoint: laundryGeopoint,
      distanceKm: distanceKm,
      rating: _readDouble(ratings['rating']) ?? 0.0,
      etaMinutes: etaMinutes,
      isOpen: isOpen,
      imagePath:
          _readString(profile['photoUrl']) ??
          _readString(profile['coverPhotoUrl']) ??
          '',
      basePricePerKg: _readInt(pricing['basePricePerKg']) ?? 18,
      tags: tags.isEmpty ? const ['Laundry'] : tags,
      phoneNumber: _readString(contact['phoneNumber']) ?? '',
      addressLine: _readString(location['addressLine']) ?? '',
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  static GeoPoint? _readGeoPoint(dynamic value) {
    if (value is GeoPoint) return value;
    return null;
  }

  static double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180);
}

// ─────────────────────────────────────────────────────────────────────────────
// REPOSITORY
// ─────────────────────────────────────────────────────────────────────────────

class _ClosestLaundriesRepository {
  _ClosestLaundriesRepository._();

  static final _ClosestLaundriesRepository instance =
      _ClosestLaundriesRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ClosestLaundryService>> watchNearbyLaundries({
    required GeoPoint pickupGeopoint,
  }) {
    return _firestore.collection('laundries').snapshots().map((snapshot) {
      final items = <ClosestLaundryService>[];

      for (final doc in snapshot.docs) {
        try {
          final laundry = ClosestLaundryService.fromFirestore(
            id: doc.id,
            data: doc.data(),
            pickupGeopoint: pickupGeopoint,
          );

          if (laundry.distanceKm <= 20) {
            items.add(laundry);
          }
        } catch (_) {
          continue;
        }
      }

      items.sort((a, b) {
        if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
        return a.distanceKm.compareTo(b.distanceKm);
      });

      return items;
    });
  }

  Future<void> offerLaundryForBooking({
    required String bookingId,
    required ClosestLaundryService laundry,
    required String selectedServiceType,
    required List<String> selectedAddOns,
    required String pickupTitle,
    required GeoFirePoint pickupGeoFirePoint,
    required int totalPrice,
  }) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingId);

    await bookingRef.set({
      'status': 'offered_to_laundry',
      'selectedServiceType': selectedServiceType,
      'selectedAddOns': selectedAddOns,

      'pickup': {
        'addressLine': pickupTitle,
        'geohash': pickupGeoFirePoint.geohash,
        'geopoint': pickupGeoFirePoint.geopoint,
      },

      'pickupAddress': pickupTitle,
      'distanceKm': laundry.distanceKm,
      'estimatedPrice': totalPrice,
      'pricePerKg': laundry.basePricePerKg,

      'laundrySnapshot': {
        'id': laundry.id,
        'name': laundry.name,
        'phoneNumber': laundry.phoneNumber,
        'photoUrl': laundry.imagePath,
        'addressLine': laundry.addressLine,
        'geohash': laundry.geohash,
        'geopoint': laundry.geopoint,
        'distanceKm': laundry.distanceKm,
        'rating': laundry.rating,
        'etaMinutes': laundry.etaMinutes,
        'basePricePerKg': laundry.basePricePerKg,
        'tags': laundry.tags,
      },

      'laundryOffer': {
        'offeredLaundryId': laundry.id,
        'offeredAt': FieldValue.serverTimestamp(),
        'offerExpiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 5)),
        ),
      },

      'timeline.offeredToLaundryAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await bookingRef.collection('status_history').add({
      'status': 'awaiting_laundry_acceptance',
      'title': 'Laundry selected',
      'description': 'Customer selected ${laundry.name}.',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ClosestLaundriesScreen extends StatefulWidget {
  final String bookingId;
  final String pickupTitle;
  final double pickupLatitude;
  final double pickupLongitude;
  final String selectedServiceType;
  final List<String> selectedAddOns;

  const ClosestLaundriesScreen({
    super.key,
    required this.pickupTitle,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.selectedServiceType,
    this.selectedAddOns = const [],
    required this.bookingId,
  });

  @override
  State<ClosestLaundriesScreen> createState() => _ClosestLaundriesScreenState();
}

class _ClosestLaundriesScreenState extends State<ClosestLaundriesScreen> {
  final _repo = _ClosestLaundriesRepository.instance;

  String? _selectedLaundryId;
  bool _isSubmittingSelection = false;

  GeoFirePoint get _pickupGeoFirePoint {
    return GeoFirePoint(
      GeoPoint(widget.pickupLatitude, widget.pickupLongitude),
    );
  }

  GeoPoint get _pickupGeopoint => _pickupGeoFirePoint.geopoint;

  void _selectLaundry(ClosestLaundryService laundry) {
    setState(() => _selectedLaundryId = laundry.id);
  }

  void _clearSelection() {
    setState(() => _selectedLaundryId = null);
  }

  ClosestLaundryService? _findSelectedLaundry(
    List<ClosestLaundryService> items,
  ) {
    final id = _selectedLaundryId;
    if (id == null) return null;

    try {
      return items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  int _calculateTotalPrice(ClosestLaundryService laundry) {
    final isWashIron = widget.selectedServiceType == 'wash_iron';
    return laundry.basePricePerKg + (isWashIron ? 2 : 0);
  }

  Future<void> _handleContinue(ClosestLaundryService laundry) async {
    if (_isSubmittingSelection) return;

    setState(() => _isSubmittingSelection = true);

    try {
      await _repo.offerLaundryForBooking(
        bookingId: widget.bookingId,
        laundry: laundry,
        selectedServiceType: widget.selectedServiceType,
        selectedAddOns: widget.selectedAddOns,
        pickupTitle: widget.pickupTitle,
        pickupGeoFirePoint: _pickupGeoFirePoint,
        totalPrice: _calculateTotalPrice(laundry),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ManualActiveLaundryOrderScreen(bookingId: widget.bookingId),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not select this laundry. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _isSubmittingSelection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final laundryStream = _repo.watchNearbyLaundries(
      pickupGeopoint: _pickupGeopoint,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      body: SafeArea(
        child: StreamBuilder<List<ClosestLaundryService>>(
          stream: laundryStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const _LoadingView();
            }

            if (snapshot.hasError) {
              return _ErrorView(onRetry: () => setState(() {}));
            }

            final laundries = snapshot.data ?? const [];

            if (laundries.isEmpty) {
              return _EmptyView(onBack: () => Navigator.pop(context));
            }

            final selectedLaundry = _findSelectedLaundry(laundries);

            return Column(
              children: [
                _ScreenHeader(
                  count: laundries.length,
                  onBack: () => Navigator.pop(context),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: selectedLaundry != null
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: _SelectionBar(
                            laundry: selectedLaundry,
                            isSubmitting: _isSubmittingSelection,
                            onClear: _clearSelection,
                            onConfirm: () => _handleContinue(selectedLaundry),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => setState(() {}),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                      itemCount: laundries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final laundry = laundries[index];

                        return LaundryServiceCard(
                          laundry: laundry,
                          isSelected: _selectedLaundryId == laundry.id,
                          onTap: () => _selectLaundry(laundry),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  final int count;
  final VoidCallback onBack;

  const _ScreenHeader({required this.count, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          _CircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          Expanded(
            child: Center(
              child: Text(
                '$count laundries nearby',
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
          const SizedBox(width: 42),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SELECTION BAR
// ─────────────────────────────────────────────────────────────────────────────

class _SelectionBar extends StatelessWidget {
  final ClosestLaundryService laundry;
  final bool isSubmitting;
  final VoidCallback onClear;
  final VoidCallback onConfirm;

  const _SelectionBar({
    required this.laundry,
    required this.isSubmitting,
    required this.onClear,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECDB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Color(0xFFE67E22),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  laundry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Colors.black,
                  ),
                ),
                Text(
                  'GH₵${laundry.basePricePerKg}/kg  ·  ${laundry.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _ActionButton(
            color: const Color(0xFFFFF0F0),
            icon: Icons.close_rounded,
            iconColor: const Color(0xFFA32D2D),
            onTap: isSubmitting ? null : onClear,
          ),
          const SizedBox(width: 8),
          _ActionButton(
            color: const Color(0xFFEAF3DE),
            icon: Icons.check_rounded,
            iconColor: const Color(0xFF27500A),
            onTap: isSubmitting ? null : onConfirm,
            isLoading: isSubmitting,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAUNDRY SERVICE CARD
// ─────────────────────────────────────────────────────────────────────────────

class LaundryServiceCard extends StatelessWidget {
  final ClosestLaundryService laundry;
  final bool isSelected;
  final VoidCallback onTap;

  const LaundryServiceCard({
    super.key,
    required this.laundry,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? const Color(0xFFE67E22) : Colors.transparent,
            width: isSelected ? 2.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFE67E22).withOpacity(0.18)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 20 : 12,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _CardImageSection(laundry: laundry, isSelected: isSelected),
            _CardBodySection(laundry: laundry),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _CardImageSection extends StatelessWidget {
  final ClosestLaundryService laundry;
  final bool isSelected;

  const _CardImageSection({required this.laundry, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final imagePath = laundry.imagePath.trim();
    final isNetwork =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: SizedBox(
        height: 155,
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
              child: _StatusBadge(isOpen: laundry.isOpen),
            ),

            if (isSelected)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE67E22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
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
                    laundry.subtitle,
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

class _CardBodySection extends StatelessWidget {
  final ClosestLaundryService laundry;

  const _CardBodySection({required this.laundry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        children: [
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
              Expanded(
                child: laundry.hasRating
                    ? _InfoChip(
                        icon: Icons.star_rounded,
                        label: laundry.rating.toStringAsFixed(1),
                        iconColor: const Color(0xFFE67E22),
                      )
                    : const _NewBadgeChip(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: laundry.tags
                      .map((tag) => _ServiceTag(label: tag))
                      .toList(),
                ),
              ),
              const SizedBox(width: 8),
              _PriceTag(price: laundry.basePricePerKg),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

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

class _StatusBadge extends StatelessWidget {
  final bool isOpen;

  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFE4F7D8) : const Color(0xFFFFE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
          color: isOpen ? const Color(0xFF3D8B2D) : const Color(0xFFC33A3A),
        ),
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

class _NewBadgeChip extends StatelessWidget {
  const _NewBadgeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 13, color: Color(0xFF185FA5)),
          SizedBox(width: 4),
          Text(
            'New',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: Color(0xFF185FA5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTag extends StatelessWidget {
  final String label;

  const _ServiceTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECDB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          color: Color(0xFFC05E10),
        ),
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

class _ActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.color,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.45 : 1.0,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(13),
          ),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(9),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: iconColor,
                  ),
                )
              : Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING / ERROR / EMPTY STATES
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFFE67E22)),
          SizedBox(height: 14),
          Text(
            'Finding nearby laundries...',
            style: TextStyle(
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

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Could not load nearby laundries.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onBack;

  const _EmptyView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_mall_directory_outlined, size: 40),
            const SizedBox(height: 12),
            const Text(
              'No nearby laundries found right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onBack, child: const Text('Go back')),
          ],
        ),
      ),
    );
  }
}
