import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/finding_laundry_screen.dart'
    show FindingLaundryScreen;
import 'closest_laundries_screen.dart';

// ---------------------------------------------------------------------------
// Data model returned by location picker
// ---------------------------------------------------------------------------

class PickedLocationResult {
  final double latitude;
  final double longitude;
  final String addressLine;
  final String subtitle;
  final String serviceType;

  const PickedLocationResult({
    required this.latitude,
    required this.longitude,
    required this.addressLine,
    required this.subtitle,
    required this.serviceType,
  });
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

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
  bool isManualSelection = false;
  bool _isSubmitting = false;
  bool _isRecentering = false;

  static const double _pickupOverlayWidth = 240;
  static const double _pickupOverlayHeight = 200;
  static const double _pickupPinTipBottomInset = 14;

  // -------------------------------------------------------------------------
  // PIN VISUAL TUNING
  // -------------------------------------------------------------------------
  //
  // The GoogleMap camera is always centered on the TRUE pickup LatLng.
  // Since gestures are disabled, the pickup point always remains at the exact
  // center of the visible map.
  //
  // These only fine-tune the artwork itself:
  // positive X = right, negative X = left
  // positive Y = down, negative Y = up
  static const double _pinVisualOffsetX = 0;
  static const double _pinVisualOffsetY = 0;

  late String selectedService;
  late String selectedServiceType;

  final Set<String> selectedAddOns = {};

  // Washer instructions (null = not set, uses "now" on submit)
  String? _washerInstructions;

  // Scheduled pickup (null = immediate / ASAP)
  DateTime? _scheduledPickupAt;

  static const int _baseWashFoldPricePerKg = 18;
  static const int _washIronExtraPerKg = 2;
  static const int _pickupFee = 0;
  static const int _deliveryFee = 0;
  static const int _estimatedWeightKg = 1;

  final Map<String, int> addOnPrices = {
    'Express Wash': 18,
    'Fragrance Booster': 6,
    'Whites Bleach': 10,
    'Color Sorted Wash': 8,
    'Delicate Wash': 9,
  };

  late final LatLng _pickupLatLng;
  final _bookingRepository = _BookingRepository.instance;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

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

  @override
  void dispose() {
    _sheetController.removeListener(_sheetListener);
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String _mapSelectedServiceType(String service) {
    final value = service.toLowerCase().trim();
    if (value.contains('iron')) return 'wash_iron';
    return 'wash_fold';
  }

  void _sheetListener() {
    if (!_sheetController.isAttached) return;
    final expandedNow = _sheetController.size > 0.58;
    if (expandedNow != _isExpanded) {
      setState(() => _isExpanded = expandedNow);
    }
  }

  void _handleMapCreated(GoogleMapController controller) {
    _mapController = controller;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _pickupLatLng, zoom: 16),
        ),
      );
    });
  }

  Future<void> _goToPickup() async {
    if (_isRecentering) return;

    HapticFeedback.selectionClick();
    setState(() => _isRecentering = true);

    try {
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _pickupLatLng, zoom: 17),
        ),
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (mounted) setState(() => _isRecentering = false);
    }
  }

  Future<void> _toggleSheet() async {
    if (!_sheetController.isAttached) return;
    final target = _isExpanded ? 0.51 : 1.0;
    await _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _changeServiceType(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      selectedServiceType = value;
      selectedService = value == 'wash_iron' ? 'Wash & Iron' : 'Wash & Fold';
    });
  }

  void _toggleManualSelection(bool? value) {
    HapticFeedback.selectionClick();
    setState(() => isManualSelection = value ?? false);
  }

  void _toggleAddOn(String value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (selectedAddOns.contains(value)) {
        selectedAddOns.remove(value);
      } else {
        selectedAddOns.add(value);
      }
    });
  }

  Set<Circle> _pickupCircles() {
    return {
      Circle(
        circleId: const CircleId('pickup_glow_outer'),
        center: _pickupLatLng,
        radius: 42,
        fillColor: const Color(0xFFE67E22).withOpacity(0.08),
        strokeColor: const Color(0xFFE67E22).withOpacity(0.18),
        strokeWidth: 1,
      ),
      Circle(
        circleId: const CircleId('pickup_glow_inner'),
        center: _pickupLatLng,
        radius: 18,
        fillColor: const Color(0xFFE67E22).withOpacity(0.12),
        strokeColor: const Color(0xFFE67E22).withOpacity(0.26),
        strokeWidth: 1,
      ),
    };
  }

  void _showPickupInfo() {
    HapticFeedback.lightImpact();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2425),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECDB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFFE67E22),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Your pickup point',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.pickupLocation.addressLine,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (widget.pickupLocation.subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.pickupLocation.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.black45,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Your pickup rider will come to this location. Make sure it matches where you want your laundry collected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF212121),
                      foregroundColor: const Color(0xFFE67E22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Pricing
  // -------------------------------------------------------------------------

  int get _serviceExtraPerKg =>
      selectedServiceType == 'wash_iron' ? _washIronExtraPerKg : 0;

  int get _baseServiceRatePerKg => _baseWashFoldPricePerKg + _serviceExtraPerKg;

  int get _addOnTotal =>
      selectedAddOns.fold(0, (sum, item) => sum + (addOnPrices[item] ?? 0));

  int get _addOnRatePerKg => _addOnTotal ~/ _estimatedWeightKg;

  int get _pricePerKg => _baseServiceRatePerKg + _addOnRatePerKg;

  int get _estimatedLaundrySubtotal =>
      _baseServiceRatePerKg * _estimatedWeightKg + _addOnTotal;

  int get _totalPrice => _estimatedLaundrySubtotal + _pickupFee + _deliveryFee;

  // -------------------------------------------------------------------------
  // Bottom-sheet actions
  // -------------------------------------------------------------------------

  /// Opens the "Washer instructions" bottom sheet (Image 2 style).
  void _openWasherInstructions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _WasherInstructionsSheet(initialValue: _washerInstructions),
    ).then((result) {
      if (result != null) {
        setState(() => _washerInstructions = result.isEmpty ? null : result);
      }
    });
  }

  /// Opens the "Schedule pickup" bottom sheet (Image 1 style).
  void _openSchedulePickup() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<DateTime?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SchedulePickupSheet(initialDateTime: _scheduledPickupAt),
    ).then((result) {
      if (result != null) {
        setState(() => _scheduledPickupAt = result);
      }
    });
  }

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  Future<void> _handlePrimaryAction() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Please sign in first.');
        return;
      }

      final userData = await _bookingRepository.getCustomerProfile(user.uid);

      final pickupGeoFirePoint = GeoFirePoint(
        GeoPoint(
          widget.pickupLocation.latitude,
          widget.pickupLocation.longitude,
        ),
      );

      final bookingDraft = _BookingDraft(
        customerId: user.uid,
        customerName: _readString(
          userData,
          keys: const ['name', 'fullName', 'displayName'],
          fallback: user.displayName ?? 'Customer',
        ),
        customerPhone: _readString(
          userData,
          keys: const ['phoneNumber', 'phone'],
          fallback: user.phoneNumber ?? '',
        ),
        customerPhotoUrl: _readString(
          userData,
          keys: const ['photoUrl', 'avatarUrl', 'imageUrl'],
          fallback: user.photoURL ?? '',
        ),
        estimatedWeightKg: _estimatedWeightKg,
        serviceType: selectedServiceType,
        selectedAddOns: selectedAddOns.toList()..sort(),
        pickupAddress: widget.pickupLocation.addressLine,
        pickupSubtitle: widget.pickupLocation.subtitle,
        pickupGeoFirePoint: pickupGeoFirePoint,
        pricingBasePrice: _baseServiceRatePerKg * _estimatedWeightKg,
        pricingAddOnsPrice: _addOnTotal,
        pricingPickupFee: _pickupFee,
        pricingDeliveryFee: _deliveryFee,
        pricingTotalPrice: _totalPrice,
        status: isManualSelection
            ? 'manual_laundry_selection'
            : 'awaiting_laundry_assignment',
        washerInstructions: _washerInstructions,
        scheduledPickupAt: _scheduledPickupAt,
      );

      final bookingId = await _bookingRepository.createBooking(bookingDraft);

      if (!mounted) return;

      if (isManualSelection) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClosestLaundriesScreen(
              bookingId: bookingId,
              pickupTitle: widget.pickupLocation.addressLine,
              pickupLatitude: widget.pickupLocation.latitude,
              pickupLongitude: widget.pickupLocation.longitude,
              selectedServiceType: selectedServiceType,
              selectedAddOns: selectedAddOns.toList(),
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FindingLaundryScreen(
              bookingId: bookingId,
              selectedAddOns: selectedAddOns.toList(),
              serviceType: selectedServiceType,
              pickupTitle: widget.pickupLocation.addressLine,
              latitude: widget.pickupLocation.latitude,
              longitude: widget.pickupLocation.longitude,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Failed to create booking. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _readString(
    Map<String, dynamic>? map, {
    required List<String> keys,
    required String fallback,
  }) {
    if (map == null) return fallback;
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return fallback;
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.pickupLocation.addressLine;
    final displaySubtitle = widget.pickupLocation.subtitle;

    final screenHeight = MediaQuery.sizeOf(context).height;

    // The collapsed sheet occupies 51% of the screen. Make the GoogleMap end
    // exactly where the visible sheet begins instead of allowing a large part
    // of the map to sit hidden behind the sheet.
    //
    // Because the GoogleMap camera target is _pickupLatLng, this makes the
    // true pickup coordinate the visual center of the exposed map.
    final mapBottomInset = screenHeight * 0.51;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: mapBottomInset,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pickupLatLng,
                zoom: 16,
              ),
              circles: _pickupCircles(),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              onMapCreated: _handleMapCreated,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: mapBottomInset,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                color: _isExpanded
                    ? Colors.black.withOpacity(0.055)
                    : Colors.transparent,
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: mapBottomInset,
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: Offset(
                    _pinVisualOffsetX,
                    -((_pickupOverlayHeight / 2) - _pickupPinTipBottomInset) +
                        _pinVisualOffsetY,
                  ),
                  child: SizedBox(
                    width: _pickupOverlayWidth,
                    height: _pickupOverlayHeight,
                    child: _AnimatedPickupPin(
                      title: 'Pickup here',
                      subtitle: widget.pickupLocation.addressLine,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _RoundMapButton(
                    small: true,
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _RoundMapButton(
                    icon: Icons.info_outline_rounded,
                    onTap: _showPickupInfo,
                    small: true,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: mapBottomInset + 16,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              scale: _isRecentering ? 0.88 : 1.0,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                turns: _isRecentering ? 0.06 : 0.0,
                child: _RoundMapButton(
                  icon: Icons.navigation_rounded,
                  onTap: _goToPickup,
                  highlighted: _isRecentering,
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.51,
            minChildSize: 0.51,
            maxChildSize: 1.0,
            snap: true,
            snapSizes: const [0.51, 1.0],
            builder: (context, scrollController) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        _isExpanded ? 0.15 : 0.09,
                      ),
                      blurRadius: _isExpanded ? 28 : 18,
                      offset: const Offset(0, -5),
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
                                  onCollapseTap: _toggleSheet,
                                  onPrimaryTap: _handlePrimaryAction,
                                  isManualSelection: isManualSelection,
                                  isSubmitting: _isSubmitting,
                                  washerInstructions: _washerInstructions,
                                  scheduledPickupAt: _scheduledPickupAt,
                                  onWasherInstructionsTap:
                                      _openWasherInstructions,
                                  onSchedulePickupTap: _openSchedulePickup,
                                )
                              : _CollapsedPickupSheet(
                                  key: const ValueKey('collapsed'),
                                  pickupTitle: displayTitle,
                                  pickupSubtitle: displaySubtitle,
                                  pickupLatitude:
                                      widget.pickupLocation.latitude,
                                  pickupLongitude:
                                      widget.pickupLocation.longitude,
                                  totalPrice: _totalPrice,
                                  pricePerKg: _pricePerKg,
                                  serviceExtraPerKg: _serviceExtraPerKg,
                                  selectedServiceType: selectedServiceType,
                                  isManualSelection: isManualSelection,
                                  selectedAddOns: selectedAddOns,
                                  onManualSelectionChanged:
                                      _toggleManualSelection,
                                  onServiceTypeChanged: _changeServiceType,
                                  onTuneTap: _toggleSheet,
                                  onPrimaryTap: _handlePrimaryAction,
                                  isSubmitting: _isSubmitting,
                                  addOnTotal: _addOnTotal,
                                  estimatedWeightKg: _estimatedWeightKg,
                                  scheduledPickupAt: _scheduledPickupAt,
                                  onSchedulePickupTap: _openSchedulePickup,
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

// ===========================================================================
// Washer Instructions Bottom Sheet  (matches Image 2)
// ===========================================================================

class _WasherInstructionsSheet extends StatefulWidget {
  final String? initialValue;

  const _WasherInstructionsSheet({this.initialValue});

  @override
  State<_WasherInstructionsSheet> createState() =>
      _WasherInstructionsSheetState();
}

class _WasherInstructionsSheetState extends State<_WasherInstructionsSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
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

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Washer instructions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Text field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                ),
                decoration: const InputDecoration(
                  hintText: 'Washer instructions',
                  hintStyle: TextStyle(
                    color: Colors.black38,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black87, width: 1.2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black87, width: 1.6),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Done button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Schedule Pickup Bottom Sheet  (matches Image 1)
// ===========================================================================

class _SchedulePickupSheet extends StatefulWidget {
  final DateTime? initialDateTime;

  const _SchedulePickupSheet({this.initialDateTime});

  @override
  State<_SchedulePickupSheet> createState() => _SchedulePickupSheetState();
}

class _SchedulePickupSheetState extends State<_SchedulePickupSheet> {
  // We track day index (0=today, 1=tomorrow, …) and hour/minute independently
  // so the three drums are always in sync.

  late int _dayIndex; // 0 = today, 1 = tomorrow, etc. (up to 6 days ahead)
  late int _hour; // 0–23
  late int _minute; // 0, 10, 20, 30, 40, 50

  static const List<int> _minuteSteps = [0, 10, 20, 30, 40, 50];

  /// Returns the concrete DateTime for the currently selected values.
  DateTime get _selectedDateTime {
    final base = DateTime.now();
    final day = DateTime(
      base.year,
      base.month,
      base.day,
    ).add(Duration(days: _dayIndex));
    return DateTime(day.year, day.month, day.day, _hour, _minuteSteps[_minute]);
  }

  String get _arrivalWindowText {
    final start = _selectedDateTime;
    final end = start.add(const Duration(minutes: 10));
    fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(start)}–${fmt(end)}';
  }

  String _dayLabel(int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    final d = DateTime.now().add(Duration(days: index));
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
    return '${d.day} ${months[d.month]}';
  }

  @override
  void initState() {
    super.initState();
    final now = widget.initialDateTime ?? DateTime.now();
    final todayMidnight = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(todayMidnight).inDays;
    _dayIndex = diff.clamp(0, 6);
    _hour = now.hour;
    // Find closest minute step
    _minute = _minuteSteps.indexWhere((m) => m >= now.minute);
    if (_minute == -1) _minute = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle + close button row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2425),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(null),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Title
            const Text(
              'Date and time of ride',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 12),

            // Three-drum picker
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Day column
                  Expanded(
                    flex: 5,
                    child: _buildDrum(
                      itemCount: 7,
                      selectedIndex: _dayIndex,
                      labelBuilder: _dayLabel,
                      onChanged: (i) => setState(() => _dayIndex = i),
                      alignment: Alignment.centerRight,
                      rightPadding: 8,
                    ),
                  ),
                  // Hour column
                  Expanded(
                    flex: 3,
                    child: _buildDrum(
                      itemCount: 24,
                      selectedIndex: _hour,
                      labelBuilder: (i) => i.toString().padLeft(2, '0'),
                      onChanged: (i) => setState(() => _hour = i),
                      alignment: Alignment.center,
                    ),
                  ),
                  // Minute column
                  Expanded(
                    flex: 3,
                    child: _buildDrum(
                      itemCount: _minuteSteps.length,
                      selectedIndex: _minute,
                      labelBuilder: (i) =>
                          _minuteSteps[i].toString().padLeft(2, '0'),
                      onChanged: (i) => setState(() => _minute = i),
                      alignment: Alignment.centerLeft,
                      leftPadding: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // "Driver will arrive at …" banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_walk_rounded,
                    size: 22,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(text: 'Driver will arrive at '),
                          TextSpan(
                            text: _arrivalWindowText,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Done button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDateTime),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrum({
    required int itemCount,
    required int selectedIndex,
    required String Function(int) labelBuilder,
    required ValueChanged<int> onChanged,
    Alignment alignment = Alignment.center,
    double rightPadding = 0,
    double leftPadding = 0,
  }) {
    return Stack(
      children: [
        // Selection highlight
        Center(
          child: Container(
            height: 46,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        ListWheelScrollView.useDelegate(
          itemExtent: 46,
          diameterRatio: 2.8,
          physics: const FixedExtentScrollPhysics(),
          controller: FixedExtentScrollController(initialItem: selectedIndex),
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) {
              final isSelected = index == selectedIndex;
              return Padding(
                padding: EdgeInsets.only(
                  right: rightPadding,
                  left: leftPadding,
                ),
                child: Align(
                  alignment: alignment,
                  child: Text(
                    labelBuilder(index),
                    style: TextStyle(
                      fontSize: isSelected ? 18 : 16,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontFamily: 'Poppins',
                      color: isSelected ? Colors.black : Colors.black38,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Booking draft & repository
// ===========================================================================

class _BookingDraft {
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerPhotoUrl;
  final int estimatedWeightKg;

  final String serviceType;
  final List<String> selectedAddOns;

  final String pickupAddress;
  final String pickupSubtitle;
  final GeoFirePoint pickupGeoFirePoint;

  final int pricingBasePrice;
  final int pricingAddOnsPrice;
  final int pricingPickupFee;
  final int pricingDeliveryFee;
  final int pricingTotalPrice;

  final String status;

  /// Free-text instructions left by the customer for the washer.
  final String? washerInstructions;

  /// When the customer wants the pickup to happen.
  /// null = ASAP / immediate.
  final DateTime? scheduledPickupAt;

  const _BookingDraft({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerPhotoUrl,
    required this.estimatedWeightKg,
    required this.serviceType,
    required this.selectedAddOns,
    required this.pickupAddress,
    required this.pickupSubtitle,
    required this.pickupGeoFirePoint,
    required this.pricingBasePrice,
    required this.pricingAddOnsPrice,
    required this.pricingPickupFee,
    required this.pricingDeliveryFee,
    required this.pricingTotalPrice,
    required this.status,
    this.washerInstructions,
    this.scheduledPickupAt,
  });

  Map<String, dynamic> toMap(String bookingId) {
    return {
      'id': bookingId,
      'bookingCode': _buildBookingCode(bookingId),

      'customerSnapshot': {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerPhotoUrl': customerPhotoUrl,
      },

      'laundrySnapshot': {
        'id': null,
        'name': null,
        'phoneNumber': null,
        'photoUrl': null,
        'addressLine': null,
        'geohash': null,
        'geopoint': null,
        'rating': null,
        'totalRatings': null,
      },

      'serviceType': serviceType,
      'selectedAddOns': selectedAddOns,

      'items': [
        {
          'name': 'Laundry Load',
          'estimatedWeightKg': estimatedWeightKg,
          'actualWeightKg': null,
        },
      ],

      // ── NEW FIELDS ──────────────────────────────────────────────────────
      /// Stored under 'customerNotes' to stay consistent with the existing
      /// schema field name used by laundry-side readers.
      'customerNotes': washerInstructions,

      /// Null means immediate / ASAP. Stored as a Firestore Timestamp when set.
      'scheduledPickupAt': scheduledPickupAt != null
          ? Timestamp.fromDate(scheduledPickupAt!)
          : null,

      // ────────────────────────────────────────────────────────────────────
      'pickup': {
        'addressLine': pickupAddress,
        'subtitle': pickupSubtitle,
        'geohash': pickupGeoFirePoint.geohash,
        'geopoint': pickupGeoFirePoint.geopoint,
      },

      'pickupAddress': pickupAddress,

      'customerAddress': {
        'addressLine': pickupAddress,
        'subtitle': pickupSubtitle,
        'geohash': pickupGeoFirePoint.geohash,
        'geopoint': pickupGeoFirePoint.geopoint,
        'isSameAsPickup': true,
      },

      'pricing': {
        'basePrice': pricingBasePrice,
        'addOnsPrice': pricingAddOnsPrice,
        'pickupFee': pricingPickupFee,
        'deliveryFee': pricingDeliveryFee,
        'totalPrice': pricingTotalPrice,
        'currency': 'GHS',
      },

      'status': status,

      'pickupRider': {
        'riderId': null,
        'fullName': null,
        'phoneNumber': null,
        'photoUrl': null,
        'vehicleType': null,
        'plateNumber': null,
        'assignedAt': null,
        'pickedUpAt': null,
      },

      'deliveryRider': {
        'riderId': null,
        'fullName': null,
        'phoneNumber': null,
        'photoUrl': null,
        'vehicleType': null,
        'plateNumber': null,
        'assignedAt': null,
        'deliveredAt': null,
      },

      'payment': {
        'method': 'cash',
        'status': 'pending',
        'transactionRef': null,
        'paidAt': null,
      },

      'chat': {
        'hasUnreadForCustomer': false,
        'hasUnreadForLaundry': false,
        'lastMessage': '',
        'lastMessageAt': null,
      },

      'laundryAssignment': {'assignedAutomatically': false, 'assignedAt': null},

      'laundryOffer': {
        'offeredLaundryId': null,
        'offeredAt': null,
        'offerExpiresAt': null,
      },

      'rejectedLaundryIds': [],

      'searchMeta': {
        'assignmentAttempts': 0,
        'lastAssignmentAttemptAt': null,
        'maxSearchRadiusKm': 8,
      },

      'timeline': {
        'requestedAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'pickupRiderAssignedAt': null,
        'pickupStartedAt': null,
        'arrivedAtLaundryAt': null,
        'processingStartedAt': null,
        'readyForDropoffAt': null,
        'deliveryStartedAt': null,
        'completedAt': null,
        'cancelledAt': null,
      },

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String _buildBookingCode(String bookingId) {
    final safe = bookingId.replaceAll('-', '').toUpperCase();
    final end = safe.length >= 6 ? safe.substring(0, 6) : safe;
    return 'LND-$end';
  }
}

class _BookingRepository {
  _BookingRepository._();

  static final _BookingRepository instance = _BookingRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');

  Future<Map<String, dynamic>> getCustomerProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() ?? <String, dynamic>{};
  }

  Future<String> createBooking(_BookingDraft draft) async {
    final doc = _bookings.doc();
    final batch = _firestore.batch();

    batch.set(doc, draft.toMap(doc.id));

    final historyRef = doc.collection('status_history').doc();
    batch.set(historyRef, {
      'status': draft.status,
      'title': _historyTitleForStatus(draft.status),
      'description': _historyDescriptionForStatus(draft.status),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return doc.id;
  }

  String _historyTitleForStatus(String status) {
    switch (status) {
      case 'awaiting_laundry_assignment':
        return 'Finding Laundry';
      case 'manual_laundry_selection':
        return 'Manual Laundry Selection';
      case 'offered_to_laundry':
        return 'Offer Sent To Laundry';
      case 'pending':
        return 'Booking Confirmed';
      case 'looking_for_pickup_rider':
        return 'Looking For Pickup Rider';
      case 'pickup_rider_assigned':
        return 'Pickup Rider Assigned';
      case 'pickup_started':
        return 'Pickup Started';
      case 'arrived_at_laundry':
        return 'Arrived At Laundry';
      case 'processing':
        return 'Laundry Processing';
      case 'ready_for_dropoff':
        return 'Ready For Dropoff';
      case 'delivery_in_progress':
        return 'Delivery In Progress';
      case 'completed':
        return 'Booking Completed';
      case 'cancelled':
        return 'Booking Cancelled';
      case 'rejected_by_laundry':
        return 'Rejected By Laundry';
      case 'no_laundry_found':
        return 'No Laundry Found';
      default:
        return 'Booking Updated';
    }
  }

  String _historyDescriptionForStatus(String status) {
    switch (status) {
      case 'awaiting_laundry_assignment':
        return 'We are searching for the best laundry near the customer.';
      case 'manual_laundry_selection':
        return 'The customer chose to manually select a laundry.';
      case 'offered_to_laundry':
        return 'This booking was offered to a laundry for acceptance.';
      case 'pending':
        return 'A laundry accepted this booking.';
      case 'looking_for_pickup_rider':
        return 'The system is searching for a pickup rider.';
      case 'pickup_rider_assigned':
        return 'A pickup rider has been assigned.';
      case 'pickup_started':
        return 'Pickup is now in progress.';
      case 'arrived_at_laundry':
        return 'The clothes have arrived at the laundry.';
      case 'processing':
        return 'The laundry is processing the clothes.';
      case 'ready_for_dropoff':
        return 'The order is ready for delivery.';
      case 'delivery_in_progress':
        return 'The order is currently being delivered.';
      case 'completed':
        return 'The booking has been completed successfully.';
      case 'cancelled':
        return 'This booking was cancelled.';
      case 'rejected_by_laundry':
        return 'A laundry rejected this booking.';
      case 'no_laundry_found':
        return 'No suitable laundry was found for this booking.';
      default:
        return 'Booking status was updated.';
    }
  }
}

// ===========================================================================
// Collapsed sheet
// ===========================================================================

class _CollapsedPickupSheet extends StatelessWidget {
  final String pickupTitle;
  final String pickupSubtitle;
  final double pickupLatitude;
  final double pickupLongitude;
  final int totalPrice;
  final int pricePerKg;
  final int serviceExtraPerKg;
  final String selectedServiceType;
  final bool isManualSelection;
  final ValueChanged<bool?> onManualSelectionChanged;
  final ValueChanged<String> onServiceTypeChanged;
  final VoidCallback onTuneTap;
  final Set<String> selectedAddOns;
  final VoidCallback onPrimaryTap;
  final bool isSubmitting;
  final int addOnTotal;
  final int estimatedWeightKg;
  final DateTime? scheduledPickupAt;
  final VoidCallback onSchedulePickupTap;

  const _CollapsedPickupSheet({
    super.key,
    required this.pickupTitle,
    required this.pickupSubtitle,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.totalPrice,
    required this.pricePerKg,
    required this.serviceExtraPerKg,
    required this.selectedServiceType,
    required this.isManualSelection,
    required this.onManualSelectionChanged,
    required this.onServiceTypeChanged,
    required this.onTuneTap,
    required this.selectedAddOns,
    required this.onPrimaryTap,
    required this.isSubmitting,
    required this.addOnTotal,
    required this.estimatedWeightKg,
    required this.scheduledPickupAt,
    required this.onSchedulePickupTap,
  });

  // ── helpers ──────────────────────────────────────────────────────────────

  /// True when the selected date is strictly in the future (not today).
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

  String _formatScheduleChip(DateTime dt) {
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
    return '${months[dt.month]} ${dt.day}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSchedule = scheduledPickupAt != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Address row ────────────────────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.location_on, size: 30, color: Color(0xFFE67E22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$pickupTitle -  $pickupSubtitle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Price card ─────────────────────────────────────────────────────
        PricePerKgCard(
          pricePerKg: pricePerKg,
          washIronExtra: serviceExtraPerKg,
          addOnTotal: addOnTotal,
          estimatedWeightKg: estimatedWeightKg,
          isWashIron: selectedServiceType == 'wash_iron',
        ),
        const SizedBox(height: 20),

        // ── Service type selectors ─────────────────────────────────────────
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
        const SizedBox(height: 14),

        // ── Schedule chip  +  Select laundry myself  (shared row) ─────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Schedule date/time chip (Image 1 style)
            hasSchedule
                ? Expanded(
                    flex: 9,
                    child: GestureDetector(
                      onTap: onSchedulePickupTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Calendar icon badge
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 17,
                              color: Colors.black87,
                            ),

                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasSchedule
                                    ? _formatScheduleChip(scheduledPickupAt!)
                                    : 'ASAP',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: hasSchedule
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontFamily: 'Poppins',
                                  color: hasSchedule
                                      ? Colors.black
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SizedBox(),

            hasSchedule ? const SizedBox(width: 5) : SizedBox(),

            // Select laundry myself toggle
            Expanded(
              flex: 11,
              child: GestureDetector(
                onTap: () => onManualSelectionChanged(!isManualSelection),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isManualSelection
                          ? const Color(0xFFFFD6A5)
                          : Colors.transparent,
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(0xFFFFD6A5),
                        child: const Icon(
                          Icons.touch_app,
                          size: 17,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Select laundry myself',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Action bar ─────────────────────────────────────────────────────
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
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 60,
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
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFE67E22),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Creating request...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE67E22),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _actionText,
                            key: ValueKey(_actionText),
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
              onTap: onTuneTap,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.tune_rounded),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// Expanded sheet
// ===========================================================================

class _ExpandedServiceSheet extends StatelessWidget {
  final String pickupTitle;
  final String selectedService;
  final Set<String> selectedAddOns;
  final ValueChanged<String> onToggleAddOn;
  final int totalPrice;
  final Map<String, int> addOnPrices;
  final VoidCallback onCollapseTap;
  final VoidCallback onPrimaryTap;
  // actionText is no longer passed in — computed from scheduledPickupAt below.
  final bool isSubmitting;
  final bool isManualSelection;

  final String? washerInstructions;
  final DateTime? scheduledPickupAt;
  final VoidCallback onWasherInstructionsTap;
  final VoidCallback onSchedulePickupTap;

  const _ExpandedServiceSheet({
    super.key,
    required this.pickupTitle,
    required this.selectedService,
    required this.selectedAddOns,
    required this.onToggleAddOn,
    required this.totalPrice,
    required this.addOnPrices,
    required this.onCollapseTap,
    required this.onPrimaryTap,
    required this.isSubmitting,
    required this.isManualSelection,
    required this.washerInstructions,
    required this.scheduledPickupAt,
    required this.onWasherInstructionsTap,
    required this.onSchedulePickupTap,
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
    final bool isWashIron = selectedService.toLowerCase().contains('iron');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExpandedServiceHeroCard(
          pickupTitle: pickupTitle,
          selectedService: selectedService,
          totalPrice: totalPrice,
          imagePath: isWashIron
              ? 'assets/images/wash_iron_backdropp.png'
              : 'assets/images/wash_fold_backdropp.png',
        ),
        const SizedBox(height: 16),

        _ExpandedOptionCard(
          child: Column(
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
          onCollapseTap: onCollapseTap,
          onPrimaryTap: onPrimaryTap,
          actionText: _actionText,
          isSubmitting: isSubmitting,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ===========================================================================
// Shared sub-widgets
// ===========================================================================

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
        height: 300,
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
                          fontSize: 15,
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

/// Refactored _OptionRow — now tappable and shows optional subtitle + chevron.
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
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
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

class _ExpandedAddOnCard extends StatelessWidget {
  final Set<String> selectedAddOns;
  final ValueChanged<String> onToggleAddOn;

  const _ExpandedAddOnCard({
    required this.selectedAddOns,
    required this.onToggleAddOn,
  });

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

    Widget pillRow(List<Map<String, String>> items) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((item) {
        final label = item['label']!;
        final asset = item['asset']!;
        return SelectablePill(
          text: label,
          assetPath: asset,
          trailingSize: 22,
          isSelected: selectedAddOns.contains(label),
          onTap: () => onToggleAddOn(label),
        );
      }).toList(),
    );

    return _ExpandedOptionCard(
      child: Padding(
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
            const SizedBox(height: 12),
            pillRow(addOns1),
            const SizedBox(height: 10),
            pillRow(addOns2),
          ],
        ),
      ),
    );
  }
}

class _ExpandedRequestBar extends StatelessWidget {
  final String selectedService;
  final int totalPrice;
  final VoidCallback onCollapseTap;
  final VoidCallback onPrimaryTap;
  final String actionText;
  final bool isSubmitting;

  const _ExpandedRequestBar({
    required this.selectedService,
    required this.totalPrice,
    required this.onCollapseTap,
    required this.onPrimaryTap,
    required this.actionText,
    required this.isSubmitting,
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
              onPressed: isSubmitting ? null : onPrimaryTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 33, 33, 33),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFE67E22),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Creating request...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE67E22),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    )
                  : Text(
                      actionText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE67E22),
                        fontFamily: 'Poppins',
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onCollapseTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          ),
        ),
      ],
    );
  }
}

class _AnimatedPickupPin extends StatefulWidget {
  final String title;
  final String subtitle;

  const _AnimatedPickupPin({required this.title, required this.subtitle});

  @override
  State<_AnimatedPickupPin> createState() => _AnimatedPickupPinState();
}

class _AnimatedPickupPinState extends State<_AnimatedPickupPin>
    with TickerProviderStateMixin {
  static const Color _orange = Color(0xFFE67E22);
  static const Color _black = Color(0xFF111111);

  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final AnimationController _floatController;

  late final Animation<double> _dropAnimation;
  late final Animation<double> _pinScaleAnimation;
  late final Animation<double> _labelOpacityAnimation;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // One-time entrance: the pin drops onto the pickup point and settles.
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );

    // Repeating ground ripple.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Slow idle hover after the entrance animation has completed.
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    );

    _dropAnimation = Tween<double>(begin: -84, end: 0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _pinScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.72,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 28,
      ),
    ]).animate(_introController);

    _labelOpacityAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.58, 1.0, curve: Curves.easeOut),
    );

    // Negative Y moves the complete pin/label upward.
    // 8 logical pixels is enough to feel alive without looking jumpy.
    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _introController.forward().whenComplete(() {
      if (!mounted) return;

      _pulseController.repeat();
      _floatController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortSubtitle = widget.subtitle.trim();

    return SizedBox(
      width: 240,
      height: 200,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // -----------------------------------------------------------------
          // Soft contact shadow.
          //
          // As the pin rises, the shadow becomes smaller and lighter. This is
          // what makes the up/down movement read as floating instead of simply
          // sliding vertically.
          // -----------------------------------------------------------------
          Positioned(
            bottom: 7,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                final progress = _floatController.value;

                final scaleX = 1.0 - (0.20 * progress);
                final opacity = 0.16 - (0.08 * progress);

                return Transform.scale(
                  scaleX: scaleX,
                  scaleY: 1.0 - (0.10 * progress),
                  child: Container(
                    width: 46,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _black.withOpacity(opacity),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: _black.withOpacity(opacity * 0.55),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // -----------------------------------------------------------------
          // Orange pickup pulse stays attached to the map location while the
          // pin itself floats above it.
          // -----------------------------------------------------------------
          Positioned(
            bottom: 2,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final value = _pulseController.value;
                final scale = 0.55 + value;
                final opacity = (1.0 - value) * 0.14;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 74,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _orange.withOpacity(opacity * 0.20),
                      border: Border.all(
                        color: _orange.withOpacity(opacity),
                        width: 0.8,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // -----------------------------------------------------------------
          // Pin + label.
          //
          // During startup:
          //   drop from above -> overshoot -> settle
          //
          // After startup:
          //   slowly float from 0 to -8 px and back forever.
          // -----------------------------------------------------------------
          Positioned(
            bottom: 14,
            child: AnimatedBuilder(
              animation: Listenable.merge([_introController, _floatController]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    _dropAnimation.value + _floatAnimation.value,
                  ),
                  child: Transform.scale(
                    scale: _pinScaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _labelOpacityAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 210),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.13),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _black,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (shortSubtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              shortSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Main Lundri pickup marker.
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromARGB(108, 0, 0, 0),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _orange.withOpacity(0.36),
                          blurRadius: 20,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1),
                      child: Image.asset(
                        'assets/images/lundri_scooter_pin.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Pin stem.
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _black,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundMapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool small;
  final bool highlighted;

  const _RoundMapButton({
    required this.icon,
    this.onTap,
    this.small = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 40.0 : 56.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: highlighted
                ? const Color(0xFFE67E22).withOpacity(0.20)
                : Colors.black.withOpacity(0.10),
            blurRadius: highlighted ? 18 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: highlighted ? const Color(0xFFFFECDB) : Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              color: highlighted ? const Color(0xFFE67E22) : Colors.black87,
              size: small ? 20 : 24,
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Public reusable widgets
// ===========================================================================

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

class PricePerKgCard extends StatelessWidget {
  final int pricePerKg;
  final int washIronExtra;
  final bool isWashIron;
  final int addOnTotal;
  final int estimatedWeightKg;

  const PricePerKgCard({
    super.key,
    required this.pricePerKg,
    required this.washIronExtra,
    required this.addOnTotal,
    required this.estimatedWeightKg,
    required this.isWashIron,
  });

  String _buildRateBreakdownText() {
    final parts = <String>['GH₵18'];
    if (isWashIron) parts.add('GH₵$washIronExtra');
    if (addOnTotal > 0) parts.add('GH₵$addOnTotal add-ons');
    return '$estimatedWeightKg kg = ${parts.join(' + ')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECDB),
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
                  _buildRateBreakdownText(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Average rate: GH₵$pricePerKg / kg',
                  style: const TextStyle(
                    fontSize: 15,
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
