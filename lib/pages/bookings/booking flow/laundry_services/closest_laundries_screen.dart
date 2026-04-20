import 'package:flutter/material.dart';

import 'laundry_booking_review_screen.dart';

class ClosestLaundryService {
  final String id;
  final String name;
  final String subtitle;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final double rating;
  final int etaMinutes;
  final bool isOpen;
  final String imagePath;
  final int basePricePerKg;
  final List<String> tags;

  const ClosestLaundryService({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.rating,
    required this.etaMinutes,
    required this.isOpen,
    required this.imagePath,
    required this.basePricePerKg,
    required this.tags,
  });
}

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
  String? _selectedLaundryId;

  final List<ClosestLaundryService> laundries = const [
    ClosestLaundryService(
      id: 'laundry_1',
      name: 'Sparkle Wash',
      subtitle: 'Fast pickup and same-day wash available',
      latitude: 5.6039,
      longitude: -0.1870,
      distanceKm: 1.2,
      rating: 4.8,
      etaMinutes: 6,
      isOpen: true,
      imagePath: 'assets/images/wash_fold_backdropp.png',
      basePricePerKg: 18,
      tags: ['Wash & Fold', 'Express', 'Pickup'],
    ),
    ClosestLaundryService(
      id: 'laundry_2',
      name: 'Fresh Basket Laundry',
      subtitle: 'Reliable family laundry service nearby',
      latitude: 5.6052,
      longitude: -0.1848,
      distanceKm: 1.8,
      rating: 4.6,
      etaMinutes: 8,
      isOpen: true,
      imagePath: 'assets/images/wash_iron_backdropp.png',
      basePricePerKg: 20,
      tags: ['Wash & Iron', 'Pickup'],
    ),
    ClosestLaundryService(
      id: 'laundry_3',
      name: 'Prime Laundry Hub',
      subtitle: 'Premium garment care and ironing',
      latitude: 5.6078,
      longitude: -0.1825,
      distanceKm: 2.4,
      rating: 4.9,
      etaMinutes: 10,
      isOpen: true,
      imagePath: 'assets/images/wash_fold_backdropp.png',
      basePricePerKg: 22,
      tags: ['Premium', 'Ironing', 'Delicates'],
    ),
    ClosestLaundryService(
      id: 'laundry_4',
      name: 'Quick Rinse',
      subtitle: 'Affordable laundry with quick turnaround',
      latitude: 5.6008,
      longitude: -0.1912,
      distanceKm: 2.9,
      rating: 4.4,
      etaMinutes: 11,
      isOpen: false,
      imagePath: 'assets/images/wash_iron_backdropp.png',
      basePricePerKg: 17,
      tags: ['Budget', 'Pickup'],
    ),
    ClosestLaundryService(
      id: 'laundry_5',
      name: 'Urban Cleaners',
      subtitle: 'Trusted local laundry and garment care',
      latitude: 5.6095,
      longitude: -0.1789,
      distanceKm: 3.1,
      rating: 4.7,
      etaMinutes: 12,
      isOpen: true,
      imagePath: 'assets/images/wash_fold_backdropp.png',
      basePricePerKg: 19,
      tags: ['Wash & Fold', 'Ironing'],
    ),
  ];

  void _selectLaundry(ClosestLaundryService laundry) {
    setState(() {
      _selectedLaundryId = laundry.id;
    });
  }

  ClosestLaundryService? get _selectedLaundry {
    if (_selectedLaundryId == null) return null;
    try {
      return laundries.firstWhere((item) => item.id == _selectedLaundryId);
    } catch (_) {
      return null;
    }
  }

  int _calculateReviewTotal(ClosestLaundryService laundry) {
    final isWashIron = widget.selectedServiceType == 'wash_iron';
    final washIronExtra = isWashIron ? 2 : 0;
    return laundry.basePricePerKg + washIronExtra;
  }

  @override
  Widget build(BuildContext context) {
    final selectedLaundry = _selectedLaundry;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      _RoundTopButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${laundries.length} laundries nearby',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
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
                ),
                const SizedBox(height: 10),

                if (selectedLaundry != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _BottomSelectedLaundryBar(
                      laundry: selectedLaundry,
                      onChangeTap: () {
                        setState(() {
                          _selectedLaundryId = null;
                        });
                      },
                      onContinueTap: () {
                        final totalPrice = _calculateReviewTotal(
                          selectedLaundry,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LaundryRequestFlowScreen(
                              laundryName: selectedLaundry.name,
                              laundryImage: selectedLaundry.imagePath,
                              pickupLocation: widget.pickupTitle,
                              selectedServiceType: widget.selectedServiceType,
                              pricePerKg: selectedLaundry.basePricePerKg,
                              totalPrice: totalPrice,
                              distanceKm: selectedLaundry.distanceKm,
                              estimatedTime:
                                  '${selectedLaundry.etaMinutes} min away',
                              selectedAddOns: widget.selectedAddOns,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                    itemCount: laundries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final laundry = laundries[index];
                      final isSelected = _selectedLaundryId == laundry.id;

                      return LaundryServiceCard(
                        laundry: laundry,
                        isSelected: isSelected,
                        onTap: () => _selectLaundry(laundry),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(29),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(110, 230, 126, 34)
                : Colors.transparent,
            width: isSelected ? 3 : 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(
                255,
                255,
                115,
                0,
              ).withOpacity(isSelected ? 0.2 : 0.04),
              blurRadius: isSelected ? 18 : 12,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Image.asset(laundry.imagePath, fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.10),
                            Colors.black.withOpacity(0.08),
                            Colors.black.withOpacity(0.40),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: laundry.isOpen
                            ? const Color(0xFFE4F7D8)
                            : const Color(0xFFFFE2E2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        laundry.isOpen ? 'Open' : 'Closed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: laundry.isOpen
                              ? const Color(0xFF3D8B2D)
                              : const Color(0xFFC33A3A),
                        ),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      left: 14,
                      top: 14,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE67E22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
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
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          laundry.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.near_me_rounded,
                          text: '${laundry.distanceKm.toStringAsFixed(1)} km',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.schedule_rounded,
                          text: '${laundry.etaMinutes} min away',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.star_rounded,
                          text: laundry.rating.toStringAsFixed(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: laundry.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECDB),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: Color(0xFFE67E22),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GH₵${laundry.basePricePerKg}/kg',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Colors.black,
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
    );
  }
}

class _BottomSelectedLaundryBar extends StatelessWidget {
  final ClosestLaundryService laundry;
  final VoidCallback onChangeTap;
  final VoidCallback onContinueTap;

  const _BottomSelectedLaundryBar({
    required this.laundry,
    required this.onChangeTap,
    required this.onContinueTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFFFECDB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Color(0xFFE67E22),
              size: 40,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onChangeTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Color.fromARGB(126, 255, 226, 226),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color.fromARGB(255, 87, 0, 0),
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 20),

          GestureDetector(
            onTap: onContinueTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Color.fromARGB(126, 228, 247, 216),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.check,
                color: Color.fromARGB(255, 20, 108, 0),
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE67E22)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.black87,
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
