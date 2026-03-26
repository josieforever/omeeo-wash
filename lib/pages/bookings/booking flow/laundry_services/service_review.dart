import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickedLocationResult {
  final double latitude;
  final double longitude;
  final String addressLine;
  final String subtitle;

  const PickedLocationResult({
    required this.latitude,
    required this.longitude,
    required this.addressLine,
    required this.subtitle,
  });
}

class PickupPreviewScreen extends StatefulWidget {
  final PickedLocationResult pickupLocation;
  final String selectedService;

  const PickupPreviewScreen({
    super.key,
    required this.pickupLocation,
    required this.selectedService,
  });

  @override
  State<PickupPreviewScreen> createState() => _PickupPreviewScreenState();
}

class _PickupPreviewScreenState extends State<PickupPreviewScreen> {
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _isExpanded = false;

  late String selectedService;
  String selectedPickupSpeed = 'Standard Pickup';
  final Set<String> selectedAddOns = {};

  final Map<String, int> pickupPrices = {
    'Express Pickup': 20,
    'Standard Pickup': 12,
  };

  final Map<String, int> addOnPrices = {
    'Express Wash': 18,
    'Fragrance Booster': 6,
    'Whites Brightening Soak': 12,
    'Whites Bleach': 10,
    'Color Sorted Wash': 8,
    'Delicate Wash': 9,
  };

  late final LatLng _pickupLatLng;

  @override
  void initState() {
    super.initState();
    _pickupLatLng = LatLng(
      widget.pickupLocation.latitude,
      widget.pickupLocation.longitude,
    );
    selectedService = widget.selectedService.trim();
    _sheetController.addListener(_sheetListener);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_sheetListener);
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _sheetListener() {
    if (!_sheetController.isAttached) return;

    final expandedNow = _sheetController.size > 0.58;
    if (expandedNow != _isExpanded) {
      setState(() {
        _isExpanded = expandedNow;
      });
    }
  }

  Future<void> _goToPickup() async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _pickupLatLng, zoom: 17),
      ),
    );
  }

  Future<void> _toggleSheet() async {
    if (!_sheetController.isAttached) return;

    final target = _isExpanded ? 0.45 : 0.82;
    await _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Set<Marker> _markers() {
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLatLng,
        infoWindow: InfoWindow(title: widget.pickupLocation.addressLine),
      ),
    };
  }

  int get _basePrice => pickupPrices[selectedPickupSpeed] ?? 0;

  int get _addOnTotal {
    return selectedAddOns.fold(
      0,
      (sum, item) => sum + (addOnPrices[item] ?? 0),
    );
  }

  int get _totalPrice => _basePrice + _addOnTotal;

  void _toggleAddOn(String value) {
    setState(() {
      if (selectedAddOns.contains(value)) {
        selectedAddOns.remove(value);
      } else {
        selectedAddOns.add(value);
      }
    });
  }

  void _selectPickupSpeed(String value) {
    setState(() {
      selectedPickupSpeed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.pickupLocation.addressLine;
    final displaySubtitle = widget.pickupLocation.subtitle;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pickupLatLng,
                zoom: 16.8,
              ),
              markers: _markers(),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _RoundMapButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _RoundMapButton(
                    icon: Icons.info_outline_rounded,
                    onTap: () {},
                    small: true,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (displaySubtitle.trim().isNotEmpty)
                      Text(
                        displaySubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5B3A),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_laundry_service_outlined,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black54, width: 2.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: 300,
            child: _RoundMapButton(
              icon: Icons.navigation_outlined,
              onTap: _goToPickup,
            ),
          ),

          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.45,
            minChildSize: 0.45,
            maxChildSize: 0.82,
            snap: true,
            snapSizes: const [0.45, 0.82],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 18,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleSheet,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 8),
                          child: Center(
                            child: Container(
                              width: 42,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2425),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverToBoxAdapter(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _isExpanded
                              ? _ExpandedServiceSheet(
                                  key: const ValueKey('expanded'),
                                  pickupTitle: displayTitle,
                                  selectedService: selectedService,
                                  selectedPickupSpeed: selectedPickupSpeed,
                                  selectedAddOns: selectedAddOns,
                                  onPickupSpeedSelected: _selectPickupSpeed,
                                  onToggleAddOn: _toggleAddOn,
                                  totalPrice: _totalPrice,
                                  addOnPrices: addOnPrices,
                                )
                              : _CollapsedPickupSheet(
                                  key: const ValueKey('collapsed'),
                                  pickupTitle: displayTitle,
                                  pickupSubtitle: displaySubtitle,
                                  selectedService: selectedService,
                                  selectedPickupSpeed: selectedPickupSpeed,
                                  totalPrice: _totalPrice,
                                  onRequestTap: _toggleSheet,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CollapsedPickupSheet extends StatelessWidget {
  final String pickupTitle;
  final String pickupSubtitle;
  final String selectedService;
  final String selectedPickupSpeed;
  final int totalPrice;
  final VoidCallback onRequestTap;

  const _CollapsedPickupSheet({
    super.key,
    required this.pickupTitle,
    required this.pickupSubtitle,
    required this.selectedService,
    required this.selectedPickupSpeed,
    required this.totalPrice,
    required this.onRequestTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.moped, size: 22),
            const SizedBox(width: 10),

            Expanded(
              child: Text(
                pickupTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            pickupSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 5),
        Divider(
          color: const Color.fromARGB(255, 122, 122, 122),
          indent: 20,
          endIndent: 20,
          thickness: 1,
        ),

        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            LocationResultTile(
              title: 'Wash & Fold',
              serviceType: 'wash_fold',
              onTap: () {},
            ),

            LocationResultTile(
              title: 'Wash & Iron',
              serviceType: 'wash_iron',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            _VehicleOptionCard(
              title: 'Express',
              eta: '4 min',
              /* selected: selectedPickupSpeed == 'Express Pickup', */
              selected: true,
            ),
            const SizedBox(width: 10),
            _VehicleOptionCard(
              title: 'Standard',
              eta: '4 min',
              /* selected: selectedPickupSpeed == 'Standard Pickup', */
              selected: true,
            ),
          ],
        ),

        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '$selectedService • $selectedPickupSpeed',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F7D8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: Color(0xFF3D8B2D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: onRequestTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4B36),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Request • GH₵$totalPrice',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExpandedServiceSheet extends StatelessWidget {
  final String pickupTitle;
  final String selectedService;
  final String selectedPickupSpeed;
  final Set<String> selectedAddOns;
  final ValueChanged<String> onPickupSpeedSelected;
  final ValueChanged<String> onToggleAddOn;
  final int totalPrice;
  final Map<String, int> addOnPrices;

  const _ExpandedServiceSheet({
    super.key,
    required this.pickupTitle,
    required this.selectedService,
    required this.selectedPickupSpeed,
    required this.selectedAddOns,
    required this.onPickupSpeedSelected,
    required this.onToggleAddOn,
    required this.totalPrice,
    required this.addOnPrices,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Center(
          child: Text(
            pickupTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                selectedService,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$selectedPickupSpeed • Add-ons available',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 14),
        Text(
          'from GH₵$totalPrice',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select add-ons for this laundry service',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const Divider(height: 1),
              _ServiceClassTile(
                title: 'Express Pickup',
                subtitle: 'Priority collection',
                price: 'GH₵20',
                eta: 'Fast',
                selected: selectedPickupSpeed == 'Express Pickup',
                onTap: () => onPickupSpeedSelected('Express Pickup'),
              ),
              _ServiceClassTile(
                title: 'Standard Pickup',
                subtitle: 'Regular timing',
                price: 'GH₵12',
                eta: 'Normal',
                selected: selectedPickupSpeed == 'Standard Pickup',
                onTap: () => onPickupSpeedSelected('Standard Pickup'),
              ),
              const Divider(height: 1),
              ...addOnPrices.entries.map(
                (entry) => _ServiceClassTile(
                  title: entry.key,
                  subtitle: '',
                  price: 'GH₵${entry.value}',
                  eta: '',
                  selected: selectedAddOns.contains(entry.key),
                  onTap: () => onToggleAddOn(entry.key),
                  showDivider: entry.key != addOnPrices.keys.last,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            children: [
              _SimpleActionRow(
                title: 'Washer instructions',
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F7D8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: Color(0xFF3D8B2D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4B36),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        selectedService,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Total • GH₵$totalPrice',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const SizedBox(
              width: 24,
              child: Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _ServiceClassTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String eta;
  final bool selected;
  final bool disabled;
  final bool showDivider;
  final VoidCallback onTap;
  final IconData? icon;

  const _ServiceClassTile({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.eta,
    required this.selected,
    required this.onTap,
    this.disabled = false,
    this.showDivider = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = disabled ? 0.55 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          InkWell(
            onTap: disabled ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, size: 26),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        eta,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE36C9A)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
          if (showDivider) const Divider(height: 1),
        ],
      ),
    );
  }
}

class _SimpleActionRow extends StatelessWidget {
  final String title;
  final bool showDivider;

  const _SimpleActionRow({required this.title, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _MiniTab extends StatelessWidget {
  final String label;
  final bool selected;

  const _MiniTab({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAEAEA) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _VehicleOptionCard extends StatelessWidget {
  final String title;
  final String eta;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _VehicleOptionCard({
    required this.title,
    required this.eta,
    this.selected = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectedBg = const Color(0xFFE36C9A);
    final Color unselectedBg = const Color(0xFFF4F4F4);

    final Color selectedLabelBg = Colors.white.withOpacity(0.18);
    final Color unselectedLabelBg = Colors.white;

    final Color selectedTextColor = Colors.white;
    final Color unselectedTextColor = Colors.black;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(selected),
            height: 80,
            width: 120,
            decoration: BoxDecoration(
              color: selected ? selectedBg : unselectedBg,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(selected ? 0.10 : 0.05),
                  blurRadius: selected ? 14 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 280),
                    scale: selected ? 1.05 : 1.0,
                    child: Image.asset(
                      title == 'Express' && selected == false
                          ? 'assets/images/grey_fast_moped.png'
                          : title == 'Express' && selected == true
                          ? 'assets/images/color_fast_moped.png'
                          : title == 'Standard' && selected == false
                          ? 'assets/images/grey_moped.png'
                          : 'assets/images/color_moped.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      color: selected ? Colors.white : null,
                      colorBlendMode: selected ? BlendMode.modulate : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: selected ? selectedLabelBg : unselectedLabelBg,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? selectedTextColor
                                : unselectedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool small;

  const _RoundMapButton({required this.icon, this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 40.0 : 56.0;

    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.black87, size: small ? 20 : 24),
        ),
      ),
    );
  }
}

class LocationResultTile extends StatelessWidget {
  final String title;
  final String serviceType;
  final VoidCallback? onTap;
  final IconData icon;

  const LocationResultTile({
    super.key,
    required this.title,
    this.onTap,
    this.icon = Icons.location_on_outlined,
    required this.serviceType,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 196, 196, 196),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              serviceType == 'wash_iron'
                  ? const SizedBox(width: 5)
                  : const SizedBox(width: 0),
              Transform.scale(
                scale: serviceType == 'wash_fold' ? 0.7 : 0.85,
                child: Image.asset(
                  serviceType == 'wash_fold'
                      ? 'assets/images/machine.png'
                      : 'assets/images/machine_iron.png',
                  height: 50,
                  width: 50,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}
