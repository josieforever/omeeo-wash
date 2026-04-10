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
  late String selectedServiceType;

  final Set<String> selectedAddOns = {};

  static const int _baseWashFoldPricePerKg = 18;
  static const int _washIronExtraPerKg = 2;

  final Map<String, int> addOnPrices = {
    'Express Wash': 18,
    'Fragrance Booster': 6,
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
    selectedServiceType = _mapSelectedServiceType(widget.selectedService);

    _sheetController.addListener(_sheetListener);
  }

  String _mapSelectedServiceType(String service) {
    final value = service.toLowerCase().trim();
    if (value.contains('iron')) return 'wash_iron';
    return 'wash_fold';
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

    final target = _isExpanded ? 0.45 : 0.94;
    await _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _changeServiceType(String value) {
    setState(() {
      selectedServiceType = value;
      selectedService = value == 'wash_iron' ? 'Wash & Iron' : 'Wash & Fold';
    });
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

  int get _serviceExtraPerKg =>
      selectedServiceType == 'wash_iron' ? _washIronExtraPerKg : 0;

  int get _pricePerKg => _baseWashFoldPricePerKg + _serviceExtraPerKg;

  int get _addOnTotal {
    return selectedAddOns.fold(
      0,
      (sum, item) => sum + (addOnPrices[item] ?? 0),
    );
  }

  int get _totalPrice => _pricePerKg + _addOnTotal;

  void _toggleAddOn(String value) {
    setState(() {
      if (selectedAddOns.contains(value)) {
        selectedAddOns.remove(value);
      } else {
        selectedAddOns.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.pickupLocation.addressLine;
    final displaySubtitle = widget.pickupLocation.subtitle;

    return Scaffold(
      backgroundColor: Colors.white,
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
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (displaySubtitle.trim().isNotEmpty)
                      Text(
                        displaySubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
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
            maxChildSize: 0.94,
            snap: true,
            snapSizes: const [0.45, 0.94],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
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
                                  selectedAddOns: selectedAddOns,
                                  onToggleAddOn: _toggleAddOn,
                                  totalPrice: _totalPrice,
                                  addOnPrices: addOnPrices,
                                )
                              : _CollapsedPickupSheet(
                                  key: const ValueKey('collapsed'),
                                  pickupTitle: displayTitle,
                                  pickupSubtitle: displaySubtitle,
                                  totalPrice: _totalPrice,
                                  pricePerKg: _pricePerKg,
                                  serviceExtraPerKg: _serviceExtraPerKg,
                                  selectedServiceType: selectedServiceType,
                                  onServiceTypeChanged: _changeServiceType,
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
  final int totalPrice;
  final int pricePerKg;
  final int serviceExtraPerKg;
  final String selectedServiceType;
  final ValueChanged<String> onServiceTypeChanged;
  final VoidCallback onRequestTap;

  const _CollapsedPickupSheet({
    super.key,
    required this.pickupTitle,
    required this.pickupSubtitle,
    required this.totalPrice,
    required this.pricePerKg,
    required this.serviceExtraPerKg,
    required this.selectedServiceType,
    required this.onServiceTypeChanged,
    required this.onRequestTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.moped, size: 35),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pickupTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
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
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Divider(
          color: Color.fromARGB(255, 171, 171, 171),
          indent: 20,
          endIndent: 20,
          thickness: 1,
        ),
        const SizedBox(height: 10),
        PricePerKgCard(
          pricePerKg: pricePerKg,
          washIronExtra: serviceExtraPerKg,
          isWashIron: selectedServiceType == 'wash_iron',
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SelectedService(
                title: 'Wash & Fold',
                serviceType: 'wash_fold',
                isSelected: selectedServiceType == 'wash_fold',
                onTap: () => onServiceTypeChanged('wash_fold'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectedService(
                title: 'Wash & Iron',
                serviceType: 'wash_iron',
                isSelected: selectedServiceType == 'wash_iron',
                onTap: () => onServiceTypeChanged('wash_iron'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
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
            const SizedBox(width: 20),
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: onRequestTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 33, 33, 33),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Request',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Poppins',
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
  final Set<String> selectedAddOns;
  final ValueChanged<String> onToggleAddOn;
  final int totalPrice;
  final Map<String, int> addOnPrices;

  const _ExpandedServiceSheet({
    super.key,
    required this.pickupTitle,
    required this.selectedService,
    required this.selectedAddOns,
    required this.onToggleAddOn,
    required this.totalPrice,
    required this.addOnPrices,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWashIron = selectedService.toLowerCase().contains('iron');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExpandedServiceHeroCard(
          pickupTitle: pickupTitle,
          selectedService: selectedService,
          totalPrice: totalPrice,

          imagePath: isWashIron
              ? 'assets/images/wash_iron_backdrop.png'
              : 'assets/images/wash_fold_backdrop.png',
        ),
        const SizedBox(height: 16),
        _ExpandedOptionCard(
          child: Column(
            children: const [
              _OptionRow(title: 'Washer instructions'),
              Divider(
                height: 1,
                color: Color.fromARGB(255, 129, 129, 129),
                endIndent: 20,
                indent: 20,
              ),
              _OptionRow(title: 'Schedule pickup'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ExpandedAddOnCard(
          selectedAddOns: selectedAddOns,
          onToggleAddOn: onToggleAddOn,
        ),
        const SizedBox(height: 18),
        _ExpandedRequestBar(
          selectedService: selectedService,
          totalPrice: totalPrice,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ExpandedServiceHeroCard extends StatelessWidget {
  final String pickupTitle;
  final String selectedService;
  final int totalPrice;

  final String imagePath;

  const _ExpandedServiceHeroCard({
    required this.pickupTitle,
    required this.selectedService,
    required this.totalPrice,

    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 360,
        width: double.infinity,
        color: const Color(0xFFEDEDED),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imagePath, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.06),
                    Colors.black.withOpacity(0.38),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      pickupTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedService,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'GH₵$totalPrice',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 22,
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

class _ExpandedOptionCard extends StatelessWidget {
  final Widget child;

  const _ExpandedOptionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String title;

  const _OptionRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.black87),
        ],
      ),
    );
  }
}

class _ExpandedAddOnCard extends StatelessWidget {
  final Set<String> selectedAddOns;
  final ValueChanged<String> onToggleAddOn;

  const _ExpandedAddOnCard({
    required this.selectedAddOns,
    required this.onToggleAddOn,
  });

  @override
  Widget build(BuildContext context) {
    return _ExpandedOptionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SelectablePill(
                  text: 'Express Wash',
                  assetPath: 'assets/images/express_wash.png',
                  trailingSize: 28,
                  isSelected: selectedAddOns.contains('Express Wash'),
                  onTap: () => onToggleAddOn('Express Wash'),
                ),
                SelectablePill(
                  text: 'Fragrance Booster',
                  assetPath: 'assets/images/fragrance_booster.png',
                  trailingSize: 28,
                  isSelected: selectedAddOns.contains('Fragrance Booster'),
                  onTap: () => onToggleAddOn('Fragrance Booster'),
                ),
                SelectablePill(
                  text: 'Whites Bleach',
                  assetPath: 'assets/images/bleach_whites.png',
                  trailingSize: 28,
                  isSelected: selectedAddOns.contains('Whites Bleach'),
                  onTap: () => onToggleAddOn('Whites Bleach'),
                ),
                SelectablePill(
                  text: 'Delicate Wash',
                  assetPath: 'assets/images/delicate_wash.png',
                  trailingSize: 28,
                  isSelected: selectedAddOns.contains('Delicate Wash'),
                  onTap: () => onToggleAddOn('Delicate Wash'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedRequestBar extends StatelessWidget {
  final String selectedService;
  final int totalPrice;

  const _ExpandedRequestBar({
    required this.selectedService,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F7D8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.payments_outlined, color: Color(0xFF3D8B2D)),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 33, 33, 33),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'Request',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Poppins',
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
          child: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
        ),
      ],
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color.fromARGB(255, 245, 245, 245)
                    : const Color.fromARGB(255, 240, 240, 240),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? const Color.fromARGB(255, 225, 225, 225)
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
                        scale: isSelected ? 1.05 : 1.0,
                        child: Image.asset(
                          serviceType == 'wash_fold'
                              ? 'assets/images/machine_black.png'
                              : 'assets/images/black_machine_iron.png',
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

class PricePerKgCard extends StatelessWidget {
  final int pricePerKg;
  final int washIronExtra;
  final bool isWashIron;

  const PricePerKgCard({
    super.key,
    required this.pricePerKg,
    required this.washIronExtra,
    required this.isWashIron,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 245),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.scale_outlined,
              size: 22,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWashIron
                      ? '1 kg = GH₵18 + GH₵$washIronExtra'
                      : '1 kg = GH₵18',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Total rate: GH₵$pricePerKg / kg',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Colors.black,
                    height: 1.1,
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
    this.selectedBackgroundColor = const Color(0xFFE0E0E0),
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
        width: 160,
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
                  fontSize: 14,
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
                        color: Colors.green,
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
