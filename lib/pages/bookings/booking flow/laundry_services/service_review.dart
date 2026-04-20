import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/finding_laundry_screen.dart'
    show FindingLaundryScreen;

import 'closest_laundries_screen.dart';

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

  late String selectedService;
  late String selectedServiceType;

  final Set<String> selectedAddOns = {};

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

    final target = _isExpanded ? 0.51 : 1.0;
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

  void _toggleManualSelection(bool? value) {
    setState(() {
      isManualSelection = value ?? false;
    });
  }

  Set<Marker> _markers() {
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLatLng,
        infoWindow: InfoWindow(title: widget.pickupLocation.addressLine),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    };
  }

  int get _serviceExtraPerKg =>
      selectedServiceType == 'wash_iron' ? _washIronExtraPerKg : 0;

  int get _baseServiceRatePerKg => _baseWashFoldPricePerKg + _serviceExtraPerKg;

  int get _addOnRatePerKg => _addOnTotal ~/ _estimatedWeightKg;

  int get _pricePerKg => _baseServiceRatePerKg + _addOnRatePerKg;

  int get _addOnTotal {
    return selectedAddOns.fold(
      0,
      (sum, item) => sum + (addOnPrices[item] ?? 0),
    );
  }

  int get _estimatedLaundrySubtotal =>
      _baseServiceRatePerKg * _estimatedWeightKg + _addOnTotal;

  int get _totalPrice => _estimatedLaundrySubtotal + _pickupFee + _deliveryFee;
  void _toggleAddOn(String value) {
    setState(() {
      if (selectedAddOns.contains(value)) {
        selectedAddOns.remove(value);
      } else {
        selectedAddOns.add(value);
      }
    });
  }

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
        estimatedWeightKg: 1,
        serviceType: selectedServiceType,
        selectedAddOns: selectedAddOns.toList()..sort(),
        pickupAddress: widget.pickupLocation.addressLine,
        pickupLatitude: widget.pickupLocation.latitude,
        pickupLongitude: widget.pickupLocation.longitude,
        pickupSubtitle: widget.pickupLocation.subtitle,
        pricingBasePrice: _baseServiceRatePerKg * _estimatedWeightKg,
        pricingAddOnsPrice: _addOnTotal,
        pricingPickupFee: _pickupFee,
        pricingDeliveryFee: _deliveryFee,
        pricingTotalPrice: _totalPrice,
        status: isManualSelection ? 'awaiting_laundry_selection' : 'pending',
      );
      final bookingId = await _bookingRepository.createBooking(bookingDraft);

      if (!mounted) return;

      if (isManualSelection) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClosestLaundriesScreen(
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
            builder: (context) => FindingLaundryScreen(
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
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return fallback;
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
            bottom: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pickupLatLng,
                zoom: 16,
              ),
              markers: _markers(),
              zoomControlsEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
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
                    small: true,
                    icon: Icons.arrow_back_rounded,
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
            initialChildSize: 0.51,
            minChildSize: 0.51,
            maxChildSize: 1.0,
            snap: true,
            snapSizes: const [0.51, 1.0],
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
                                  onCollapseTap: _toggleSheet,
                                  onPrimaryTap: _handlePrimaryAction,
                                  actionText: isManualSelection
                                      ? 'Browse Laundries'
                                      : 'Request',
                                  isSubmitting: _isSubmitting,
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

class _BookingDraft {
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerPhotoUrl;
  final int estimatedWeightKg;

  final String serviceType;
  final List<String> selectedAddOns;

  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupSubtitle;

  final int pricingBasePrice;
  final int pricingAddOnsPrice;
  final int pricingPickupFee;
  final int pricingDeliveryFee;
  final int pricingTotalPrice;

  final String status;

  const _BookingDraft({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerPhotoUrl,
    required this.estimatedWeightKg,
    required this.serviceType,
    required this.selectedAddOns,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupSubtitle,
    required this.pricingBasePrice,
    required this.pricingAddOnsPrice,
    required this.pricingPickupFee,
    required this.pricingDeliveryFee,
    required this.pricingTotalPrice,
    required this.status,
  });

  Map<String, dynamic> toMap(String bookingId) {
    return {
      'id': bookingId,
      'bookingCode': _buildBookingCode(bookingId),

      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerPhotoUrl': customerPhotoUrl,

      'laundryId': null,
      'laundryName': null,
      'laundryPhone': null,
      'laundryPhotoUrl': null,

      'serviceType': serviceType,
      'selectedAddOns': selectedAddOns,

      'items': [
        {
          'name': 'Laundry Load',
          'estimatedWeightKg': estimatedWeightKg,
          'actualWeightKg': null,
        },
      ],

      'customerNotes': null,

      'pickupAddress': {
        'address': pickupAddress,
        'latitude': pickupLatitude,
        'longitude': pickupLongitude,
        'subtitle': pickupSubtitle,
      },

      'deliveryAddress': {
        'address': pickupAddress,
        'latitude': pickupLatitude,
        'longitude': pickupLongitude,
        'subtitle': pickupSubtitle,
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

      'timeline': {
        'requestedAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'pickedUpAt': null,
        'arrivedAtLaundryAt': null,
        'washingStartedAt': null,
        'washingCompletedAt': null,
        'outForDeliveryAt': null,
        'deliveredAt': null,
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

  static String generateBookingCode() {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    return 'LND-${now.substring(now.length - 6)}';
  }

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
      'title': draft.status == 'choosing_laundry'
          ? 'Choosing Laundry'
          : 'Booking Requested',
      'description': draft.status == 'choosing_laundry'
          ? 'Customer started booking and is selecting a laundry.'
          : 'Customer submitted a laundry request.',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return doc.id;
  }
}

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
  });

  @override
  Widget build(BuildContext context) {
    final actionText = isManualSelection ? 'Browse Laundries' : 'Request';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        PricePerKgCard(
          pricePerKg: pricePerKg,
          washIronExtra: serviceExtraPerKg,
          addOnTotal: addOnTotal,
          estimatedWeightKg: estimatedWeightKg,
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
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () {
            onManualSelectionChanged(!isManualSelection);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isManualSelection
                    ? const Color(0xFFFFD6A5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    CircleAvatar(
                      backgroundColor: Color(0xFFFFD6A5),
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.touch_app, color: Colors.black),
                      ),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Select laundry myself',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Checkbox(
                  value: isManualSelection,
                  onChanged: onManualSelectionChanged,
                  activeColor: const Color(0xFFE67E22),
                  checkColor: Colors.black,
                  side: const BorderSide(color: Colors.black26, width: 1.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
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

class _ExpandedServiceSheet extends StatelessWidget {
  final String pickupTitle;
  final String selectedService;
  final Set<String> selectedAddOns;
  final ValueChanged<String> onToggleAddOn;
  final int totalPrice;
  final Map<String, int> addOnPrices;
  final VoidCallback onCollapseTap;
  final VoidCallback onPrimaryTap;
  final String actionText;
  final bool isSubmitting;

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
    required this.actionText,
    required this.isSubmitting,
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
              ? 'assets/images/wash_iron_backdropp.png'
              : 'assets/images/wash_fold_backdropp.png',
        ),
        const SizedBox(height: 16),
        _ExpandedOptionCard(
          child: Column(
            children: const [
              _OptionRow(title: 'Washer instructions'),
              Divider(
                height: 1,
                color: Color.fromARGB(255, 185, 185, 185),
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
          onCollapseTap: onCollapseTap,
          onPrimaryTap: onPrimaryTap,
          actionText: actionText,
          isSubmitting: isSubmitting,
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

class _OptionRow extends StatelessWidget {
  final String title;

  const _OptionRow({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: addOns1.map((item) {
                final label = item['label'] as String;
                final asset = item['asset'] as String;

                return SelectablePill(
                  text: label,
                  assetPath: asset,
                  trailingSize: 22,
                  isSelected: selectedAddOns.contains(label),
                  onTap: () => onToggleAddOn(label),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: addOns2.map((item) {
                final label = item['label'] as String;
                final asset = item['asset'] as String;

                return SelectablePill(
                  text: label,
                  assetPath: asset,
                  trailingSize: 22,
                  isSelected: selectedAddOns.contains(label),
                  onTap: () => onToggleAddOn(label),
                );
              }).toList(),
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

    if (isWashIron) {
      parts.add('GH₵$washIronExtra');
    }

    if (addOnTotal > 0) {
      parts.add('GH₵$addOnTotal add-ons');
    }

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
