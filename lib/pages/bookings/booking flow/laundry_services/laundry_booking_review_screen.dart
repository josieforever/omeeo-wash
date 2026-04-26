import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'active_laundry_order_stage.dart';

class LaundryRequestFlowScreen extends StatefulWidget {
  final String laundryName;
  final String laundryImage;
  final String pickupLocation;
  final String selectedServiceType;
  final int pricePerKg;
  final int totalPrice;
  final double distanceKm;
  final String estimatedTime;
  final List<String> selectedAddOns;
  final ActiveLaundryOrderStage stage;
  final String? orderId;

  /// Added so the screen can create/update the booking properly.
  final String? laundryId;
  final String? customerId;
  final String? customerName;
  final String? customerPhoneNumber;
  final String? customerPhotoUrl;
  final String? laundryPhoneNumber;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? customerNote;

  const LaundryRequestFlowScreen({
    super.key,
    required this.laundryName,
    required this.laundryImage,
    required this.pickupLocation,
    required this.selectedServiceType,
    required this.pricePerKg,
    required this.totalPrice,
    required this.distanceKm,
    required this.estimatedTime,
    this.selectedAddOns = const [],
    this.stage = ActiveLaundryOrderStage.accepted,
    this.orderId,
    this.laundryId,
    this.customerId,
    this.customerName,
    this.customerPhoneNumber,
    this.customerPhotoUrl,
    this.laundryPhoneNumber,
    this.pickupLatitude,
    this.pickupLongitude,
    this.customerNote,
  });

  static const Color primaryOrange = Color(0xFFE67E22);
  static const Color dark = Color(0xFF1F1F1F);
  static const Color lightBg = Color(0xFFF7F7F7);
  static const Color softOrange = Color(0xFFFFECDB);
  static const Color successBg = Color.fromARGB(255, 228, 247, 216);
  static const Color successText = Color(0xFF3D8B2D);
  static const Color cancelledRed = Color(0xFFD9534F);

  @override
  State<LaundryRequestFlowScreen> createState() =>
      _LaundryRequestFlowScreenState();
}

class _LaundryRequestFlowScreenState extends State<LaundryRequestFlowScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _submitting = false;
  String? _bookingId;

  @override
  void initState() {
    super.initState();
    _bookingId = widget.orderId;

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

  String get _serviceLabel {
    return widget.selectedServiceType == 'wash_iron'
        ? 'Wash & Iron'
        : 'Wash & Fold';
  }

  DocumentReference<Map<String, dynamic>>? get _bookingRef {
    final id = _bookingId;
    if (id == null || id.trim().isEmpty) return null;
    return _firestore.collection('bookings').doc(id);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? get _bookingStream {
    final ref = _bookingRef;
    if (ref == null) return null;
    return ref.snapshots();
  }

  Future<void> _confirmRequest() async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
    });

    try {
      final docRef = _bookingRef ?? _firestore.collection('bookings').doc();
      final now = FieldValue.serverTimestamp();

      final payload = <String, dynamic>{
        'id': docRef.id,
        'status': 'pending',
        'selectedServiceType': widget.selectedServiceType,
        'serviceLabel': _serviceLabel,
        'pricePerKg': widget.pricePerKg,
        'estimatedPrice': widget.totalPrice,
        'selectedAddOns': widget.selectedAddOns,
        'distanceKm': widget.distanceKm,
        'estimatedTime': widget.estimatedTime,
        'pickupLocation': {
          'address': widget.pickupLocation,
          'latitude': widget.pickupLatitude,
          'longitude': widget.pickupLongitude,
        },
        'customerSnapshot': {
          'id': widget.customerId ?? '',
          'name': widget.customerName ?? '',
          'phoneNumber': widget.customerPhoneNumber ?? '',
          'photoUrl': widget.customerPhotoUrl ?? '',
        },
        'laundrySnapshot': {
          'id': widget.laundryId ?? '',
          'name': widget.laundryName,
          'phoneNumber': widget.laundryPhoneNumber ?? '',
          'photoUrl': widget.laundryImage,
          'distanceKm': widget.distanceKm,
        },
        'pricing': {
          'pricePerKg': widget.pricePerKg,
          'estimatedTotal': widget.totalPrice,
          'currency': 'GHS',
        },
        'note': (widget.customerNote ?? '').trim(),
        'cancellation': null,
        'timeline': {'requestSentAt': now, 'customerConfirmedAt': now},
        'createdAt': now,
        'updatedAt': now,
      };

      await docRef.set(payload, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _bookingId = docRef.id;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not send request. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _showCancelBottomSheet(Map<String, dynamic>? booking) async {
    final controller = TextEditingController(
      text: _readString(_asMap(booking?['cancellation'])['reason']) ?? '',
    );

    final canCancel = _canCancel(booking);
    if (!canCancel) {
      _showSnack('This request can no longer be cancelled from here.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (isSaving) return;
              setModalState(() => isSaving = true);

              try {
                final ref = _bookingRef;
                if (ref == null) return;

                await ref.update({
                  'status': 'cancelled',
                  'cancellation': {
                    'reason': controller.text.trim(),
                    'cancelledBy': 'customer',
                    'cancelledAt': FieldValue.serverTimestamp(),
                  },
                  'timeline.cancelledAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                _showSnack('Request cancelled.');
              } catch (_) {
                if (!mounted) return;
                _showSnack('Could not cancel request.');
              } finally {
                if (context.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 18),
                  const Text(
                    'Cancel Request',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add a short reason so the system and laundry side stay in sync.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Why are you cancelling this request?',
                      filled: true,
                      fillColor: LaundryRequestFlowScreen.lightBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F3F3),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: LaundryRequestFlowScreen
                                          .primaryOrange,
                                    ),
                                  )
                                : const Text(
                                    'Cancel Request',
                                    style: TextStyle(
                                      color: LaundryRequestFlowScreen
                                          .primaryOrange,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _trackRequest() {
    final bookingId = _bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      _showSnack('No booking found yet.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveLaundryOrderScreen(bookingId: bookingId),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isRequestCreated(Map<String, dynamic>? booking) {
    return _bookingId != null &&
        _bookingId!.isNotEmpty &&
        booking != null &&
        booking.isNotEmpty;
  }

  bool _isCancelled(Map<String, dynamic>? booking) {
    return _statusOf(booking) == 'cancelled';
  }

  bool _isCompleted(Map<String, dynamic>? booking) {
    return _statusOf(booking) == 'completed';
  }

  bool _canCancel(Map<String, dynamic>? booking) {
    final status = _statusOf(booking);

    const cancellableStatuses = {
      'pending',
      'waiting_for_laundry',
      'accepted',
      'looking_for_a_rider',
      'pickup_rider_assigned',
    };

    return cancellableStatuses.contains(status);
  }

  String _statusOf(Map<String, dynamic>? booking) {
    return (_readString(booking?['status']) ?? '').trim().toLowerCase();
  }

  String _screenTitle(Map<String, dynamic>? booking) {
    if (!_isRequestCreated(booking)) return 'Review Request';
    if (_isCancelled(booking)) return 'Request Cancelled';
    if (_isCompleted(booking)) return 'Order Completed';
    return 'Request Sent';
  }

  String _statusChipText(Map<String, dynamic>? booking) {
    final status = _statusOf(booking);

    switch (status) {
      case 'pending':
      case 'waiting_for_laundry':
        return 'Waiting';
      case 'accepted':
        return 'Accepted';
      case 'looking_for_a_rider':
        return 'Finding Rider';
      case 'pickup_rider_assigned':
        return 'Pickup Rider Assigned';
      case 'pickup_in_progress':
        return 'Pickup In Progress';
      case 'arrived_at_laundry':
        return 'At Laundry';
      case 'processing':
        return 'Processing';
      case 'ready_for_delivery':
        return 'Ready For Delivery';
      case 'delivery_rider_assigned':
        return 'Delivery Rider Assigned';
      case 'delivery_in_progress':
        return 'Delivery In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Review';
    }
  }

  String _responseText(Map<String, dynamic>? booking) {
    final status = _statusOf(booking);

    switch (status) {
      case 'pending':
      case 'waiting_for_laundry':
        return 'Usually responds in 1–3 minutes';
      case 'accepted':
        return 'Laundry accepted your request';
      case 'looking_for_a_rider':
        return 'Finding a pickup rider';
      case 'pickup_rider_assigned':
        return 'Pickup rider assigned';
      case 'pickup_in_progress':
        return 'Pickup is in progress';
      case 'arrived_at_laundry':
        return 'Laundry received your items';
      case 'processing':
        return 'Your clothes are being processed';
      case 'ready_for_delivery':
        return 'Ready for delivery';
      case 'delivery_rider_assigned':
        return 'Delivery rider assigned';
      case 'delivery_in_progress':
        return 'Delivery is in progress';
      case 'completed':
        return 'Order completed successfully';
      case 'cancelled':
        return 'This request was cancelled';
      default:
        return widget.estimatedTime;
    }
  }

  String _heroLaundryName(Map<String, dynamic>? booking) {
    final laundry = _asMap(booking?['laundrySnapshot']);
    return _readString(laundry['name']) ?? widget.laundryName;
  }

  String _heroLaundryImage(Map<String, dynamic>? booking) {
    final laundry = _asMap(booking?['laundrySnapshot']);
    return _readString(laundry['photoUrl']) ?? widget.laundryImage;
  }

  double _heroDistance(Map<String, dynamic>? booking) {
    final laundry = _asMap(booking?['laundrySnapshot']);
    return _readDouble(laundry['distanceKm']) ?? widget.distanceKm;
  }

  String _pickupAddress(Map<String, dynamic>? booking) {
    final pickup = _asMap(booking?['pickupLocation']);
    return _readString(pickup['address']) ?? widget.pickupLocation;
  }

  List<String> _addOns(Map<String, dynamic>? booking) {
    final raw = booking?['selectedAddOns'];
    if (raw is List) {
      return raw.map((e) => '$e').where((e) => e.trim().isNotEmpty).toList();
    }
    return widget.selectedAddOns;
  }

  int _displayTotalPrice(Map<String, dynamic>? booking) {
    final pricing = _asMap(booking?['pricing']);
    return _readInt(pricing['estimatedTotal']) ??
        _readInt(booking?['estimatedPrice']) ??
        widget.totalPrice;
  }

  int _displayPricePerKg(Map<String, dynamic>? booking) {
    final pricing = _asMap(booking?['pricing']);
    return _readInt(pricing['pricePerKg']) ??
        _readInt(booking?['pricePerKg']) ??
        widget.pricePerKg;
  }

  String _displayServiceLabel(Map<String, dynamic>? booking) {
    return _readString(booking?['serviceLabel']) ?? _serviceLabel;
  }

  String _noteText(Map<String, dynamic>? booking) {
    return _readString(booking?['note']) ?? '';
  }

  String _cancellationReason(Map<String, dynamic>? booking) {
    final cancellation = _asMap(booking?['cancellation']);
    return _readString(cancellation['reason']) ?? '';
  }

  Widget _buildBody(Map<String, dynamic>? booking) {
    final requestCreated = _isRequestCreated(booking);
    final totalPrice = _displayTotalPrice(booking);
    final serviceLabel = _displayServiceLabel(booking);
    final pickupLocation = _pickupAddress(booking);
    final selectedAddOns = _addOns(booking);
    final pricePerKg = _displayPricePerKg(booking);
    final laundryName = _heroLaundryName(booking);
    final laundryImage = _heroLaundryImage(booking);
    final distance = _heroDistance(booking);
    final statusChipText = _statusChipText(booking);
    final note = _noteText(booking);
    final cancellationReason = _cancellationReason(booking);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: !requestCreated
              ? _ConfirmBottomBar(
                  key: const ValueKey('confirm_bar'),
                  totalPrice: totalPrice,
                  isSubmitting: _submitting,
                  onConfirmTap: _confirmRequest,
                )
              : _DynamicRequestBottomBar(
                  key: ValueKey(_statusOf(booking)),
                  canCancel: _canCancel(booking),
                  isCancelled: _isCancelled(booking),
                  isCompleted: _isCompleted(booking),
                  onCancelTap: () => _showCancelBottomSheet(booking),
                  onTrackTap: _trackRequest,
                ),
        ),
      ),
      body: SingleChildScrollView(
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
                  child: Text(
                    _screenTitle(booking),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: Colors.black,
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

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: !requestCreated
                  ? _BeforeConfirmBanner(
                      key: const ValueKey('before_banner'),
                      isSubmitting: _submitting,
                    )
                  : _AfterConfirmBanner(
                      key: ValueKey(_statusOf(booking)),
                      laundryName: laundryName,
                      pulseController: _pulseController,
                      statusText: _responseText(booking),
                      isCancelled: _isCancelled(booking),
                      isCompleted: _isCompleted(booking),
                    ),
            ),

            const SizedBox(height: 14),

            Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: _LaundryImage(imagePath: laundryImage),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      laundryName,
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              .18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.location_on_rounded,
                                                color: LaundryRequestFlowScreen
                                                    .primaryOrange,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${distance.toStringAsFixed(1)} km away',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              .18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            requestCreated
                                                ? statusChipText
                                                : widget.estimatedTime,
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
                          icon: Icons.star_rounded,
                          title: '4.8',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickInfoCard(
                          icon: Icons.local_laundry_service_rounded,
                          title: serviceLabel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickInfoCard(
                          icon: Icons.payments_outlined,
                          title: 'GHS $totalPrice',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: !requestCreated
                  ? _RequestDetailsSection(
                      key: const ValueKey('details_section'),
                      pickupLocation: pickupLocation,
                      serviceLabel: serviceLabel,
                      pricePerKg: pricePerKg,
                      selectedAddOns: selectedAddOns,
                      note: note,
                    )
                  : _RequestStatusSection(
                      key: ValueKey(_statusOf(booking)),
                      booking: booking,
                    ),
            ),

            const SizedBox(height: 10),

            if (requestCreated && cancellationReason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReasonCard(
                  title: 'Cancellation reason',
                  value: cancellationReason,
                  icon: Icons.info_outline_rounded,
                  backgroundColor: const Color(0xFFFFEEEE),
                  iconColor: LaundryRequestFlowScreen.cancelledRed,
                ),
              ),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: requestCreated
                    ? LaundryRequestFlowScreen.softOrange
                    : const Color(0xFFFFF4EA),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          (_isCancelled(booking)
                                  ? LaundryRequestFlowScreen.cancelledRed
                                  : LaundryRequestFlowScreen.primaryOrange)
                              .withOpacity(.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _isCancelled(booking)
                          ? Icons.cancel_outlined
                          : Icons.info_outline_rounded,
                      color: _isCancelled(booking)
                          ? LaundryRequestFlowScreen.cancelledRed
                          : const Color(0xFFE67E22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCancelled(booking)
                              ? 'Request cancelled'
                              : requestCreated
                              ? 'While you wait'
                              : 'Before you confirm',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: LaundryRequestFlowScreen.dark,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          _isCancelled(booking)
                              ? 'This request is no longer active.'
                              : requestCreated
                              ? 'This screen now listens to the booking live. As the booking status changes in Firestore, the request state here updates automatically.'
                              : 'Your request will be sent to this laundry service and created in Firestore. You can still cancel while it is still in an early stage.',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.black87,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_bookingStream == null) {
      return _buildBody(null);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _bookingStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildBody(null);
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildBody(null);
        }

        final booking = snapshot.data?.data();
        return _buildBody(booking);
      },
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
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
      color: const Color(0xFFF2F2F2),
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_laundry_service_rounded,
        size: 48,
        color: LaundryRequestFlowScreen.primaryOrange,
      ),
    );
  }
}

class _BeforeConfirmBanner extends StatelessWidget {
  final bool isSubmitting;

  const _BeforeConfirmBanner({super.key, required this.isSubmitting});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: isSubmitting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Transform.scale(
                    scale: 1.4,
                    child: Lottie.asset(
                      'assets/animations/Search.json',
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review before sending',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LaundryRequestFlowScreen.dark,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check the laundry, location, service, and pricing before you confirm.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.black87,
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

class _AfterConfirmBanner extends StatelessWidget {
  final String laundryName;
  final AnimationController pulseController;
  final String statusText;
  final bool isCancelled;
  final bool isCompleted;

  const _AfterConfirmBanner({
    super.key,
    required this.laundryName,
    required this.pulseController,
    required this.statusText,
    required this.isCancelled,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isCancelled
        ? LaundryRequestFlowScreen.cancelledRed
        : LaundryRequestFlowScreen.primaryOrange;

    final title = isCancelled
        ? 'Request cancelled'
        : isCompleted
        ? 'Order completed'
        : 'Request sent to $laundryName';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = isCancelled || isCompleted
                  ? 1.0
                  : 0.95 + (pulseController.value * 0.08);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isCancelled
                        ? Icons.cancel_outlined
                        : isCompleted
                        ? Icons.check_circle_outline_rounded
                        : Icons.hourglass_top_rounded,
                    color: iconColor,
                    size: 28,
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
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
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

class _RequestDetailsSection extends StatelessWidget {
  final String pickupLocation;
  final String serviceLabel;
  final int pricePerKg;
  final List<String> selectedAddOns;
  final String note;

  const _RequestDetailsSection({
    super.key,
    required this.pickupLocation,
    required this.serviceLabel,
    required this.pricePerKg,
    required this.selectedAddOns,
    required this.note,
  });

  IconData _addOnIcon(String addOn) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailTile(
          icon: Icons.location_on_outlined,
          title: 'Pickup location',
          value: pickupLocation,
        ),
        const SizedBox(height: 12),
        _DetailTile(
          icon: Icons.local_laundry_service_outlined,
          title: 'Selected service',
          value: serviceLabel,
        ),
        const SizedBox(height: 12),
        _DetailTile(
          icon: Icons.payments_outlined,
          title: 'Price per kg',
          value: 'GHS $pricePerKg',
        ),
        if (note.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _ReasonCard(
            title: 'Customer note',
            value: note,
            icon: Icons.sticky_note_2_outlined,
            backgroundColor: LaundryRequestFlowScreen.lightBg,
            iconColor: LaundryRequestFlowScreen.primaryOrange,
          ),
        ],
        if (selectedAddOns.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: LaundryRequestFlowScreen.lightBg,
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
                    color: LaundryRequestFlowScreen.primaryOrange,
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
                        children: selectedAddOns.map((addOn) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFECDB),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _addOnIcon(addOn),
                                  size: 16,
                                  color: LaundryRequestFlowScreen.primaryOrange,
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
        ],
      ],
    );
  }
}

class _RequestStatusSection extends StatelessWidget {
  final Map<String, dynamic>? booking;

  const _RequestStatusSection({super.key, required this.booking});

  String _statusOf(Map<String, dynamic>? booking) {
    return (booking?['status'] ?? '').toString().trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusOf(booking);

    final steps = _buildSteps(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: LaundryRequestFlowScreen.lightBg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;

              return Column(
                children: [
                  _StatusRow(
                    isCompleted: step.isCompleted,
                    isCurrent: step.isCurrent,
                    title: step.title,
                    subtitle: step.subtitle,
                    isCancelled: step.isCancelled,
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
      ],
    );
  }

  List<_StatusStep> _buildSteps(String status) {
    final stageIndex = _stageIndex(status);

    if (status == 'cancelled') {
      return const [
        _StatusStep(
          title: 'Request sent',
          subtitle: 'Your request was created successfully.',
          isCompleted: true,
          isCurrent: false,
        ),
        _StatusStep(
          title: 'Cancelled',
          subtitle: 'This request has been cancelled.',
          isCompleted: false,
          isCurrent: true,
          isCancelled: true,
        ),
      ];
    }

    return [
      _StatusStep(
        title: 'Request sent',
        subtitle: 'Your request was sent successfully.',
        isCompleted: stageIndex > 0,
        isCurrent: stageIndex == 0,
      ),
      _StatusStep(
        title: 'Laundry accepted',
        subtitle: 'The laundry has reviewed and accepted your request.',
        isCompleted: stageIndex > 1,
        isCurrent: stageIndex == 1,
      ),
      _StatusStep(
        title: 'Pickup',
        subtitle: 'A rider is being assigned or is already on the way.',
        isCompleted: stageIndex > 2,
        isCurrent: stageIndex == 2,
      ),
      _StatusStep(
        title: 'At laundry / Processing',
        subtitle: 'Your items have reached the laundry and are being handled.',
        isCompleted: stageIndex > 3,
        isCurrent: stageIndex == 3,
      ),
      _StatusStep(
        title: 'Delivery',
        subtitle: 'Your cleaned items are being prepared or sent back to you.',
        isCompleted: stageIndex > 4,
        isCurrent: stageIndex == 4,
      ),
      _StatusStep(
        title: 'Completed',
        subtitle: 'Your order has been completed.',
        isCompleted: stageIndex >= 5,
        isCurrent: stageIndex == 5,
      ),
    ];
  }

  int _stageIndex(String status) {
    switch (status) {
      case 'pending':
      case 'waiting_for_laundry':
        return 0;
      case 'accepted':
      case 'looking_for_a_rider':
        return 1;
      case 'pickup_rider_assigned':
      case 'pickup_in_progress':
        return 2;
      case 'arrived_at_laundry':
      case 'processing':
        return 3;
      case 'ready_for_delivery':
      case 'delivery_rider_assigned':
      case 'delivery_in_progress':
        return 4;
      case 'completed':
        return 5;
      default:
        return 0;
    }
  }
}

class _ConfirmBottomBar extends StatelessWidget {
  final int totalPrice;
  final bool isSubmitting;
  final VoidCallback onConfirmTap;

  const _ConfirmBottomBar({
    super.key,
    required this.totalPrice,
    required this.isSubmitting,
    required this.onConfirmTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onConfirmTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: LaundryRequestFlowScreen.dark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          disabledBackgroundColor: LaundryRequestFlowScreen.dark.withOpacity(
            0.85,
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: LaundryRequestFlowScreen.primaryOrange,
                ),
              )
            : const Text(
                'Confirm Request',
                style: TextStyle(
                  color: LaundryRequestFlowScreen.primaryOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
      ),
    );
  }
}

class _DynamicRequestBottomBar extends StatelessWidget {
  final bool canCancel;
  final bool isCancelled;
  final bool isCompleted;
  final VoidCallback onCancelTap;
  final VoidCallback onTrackTap;

  const _DynamicRequestBottomBar({
    super.key,
    required this.canCancel,
    required this.isCancelled,
    required this.isCompleted,
    required this.onCancelTap,
    required this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isCancelled && !isCompleted)
            GestureDetector(
              onTap: canCancel ? onCancelTap : null,
              child: Opacity(
                opacity: canCancel ? 1 : 0.45,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.black87),
                ),
              ),
            ),
          if (!isCancelled && !isCompleted) const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onTrackTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LaundryRequestFlowScreen.dark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  isCancelled
                      ? 'View Request'
                      : isCompleted
                      ? 'View Order'
                      : 'Track Request',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: LaundryRequestFlowScreen.primaryOrange,
                  ),
                ),
              ),
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

  const _QuickInfoCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: icon == Icons.star_rounded
                ? Colors.amber
                : const Color(0xFFE67E22),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: LaundryRequestFlowScreen.dark,
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
  final String title;
  final String subtitle;
  final bool isCancelled;

  const _StatusRow({
    required this.isCompleted,
    required this.isCurrent,
    required this.title,
    required this.subtitle,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isCancelled
        ? LaundryRequestFlowScreen.cancelledRed
        : isCurrent
        ? LaundryRequestFlowScreen.primaryOrange
        : LaundryRequestFlowScreen.successText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: (isCompleted || isCurrent)
                ? activeColor.withOpacity(0.12)
                : const Color(0xFFE9E9E9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCancelled
                ? Icons.cancel_outlined
                : isCompleted
                ? Icons.check_rounded
                : isCurrent
                ? Icons.hourglass_top_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: (isCompleted || isCurrent) ? activeColor : Colors.black38,
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
                  color: (isCompleted || isCurrent)
                      ? Colors.black
                      : Colors.black54,
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
      child: Container(width: 2, height: 25, color: const Color(0xFFDCDCDC)),
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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: LaundryRequestFlowScreen.lightBg,
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
            child: Icon(icon, color: LaundryRequestFlowScreen.primaryOrange),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: LaundryRequestFlowScreen.dark,
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

class _ReasonCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _ReasonCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
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
            child: Icon(icon, color: iconColor),
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
                    fontSize: 14,
                    height: 1.45,
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

class _StatusStep {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;
  final bool isCancelled;

  const _StatusStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
    this.isCancelled = false,
  });
}
