import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart' hide Marker;

class FindingLaundryScreen extends StatefulWidget {
  final String bookingId;
  final String pickupTitle;
  final double latitude;
  final double longitude;
  final String serviceType;
  final List<String> selectedAddOns;

  const FindingLaundryScreen({
    super.key,
    required this.pickupTitle,
    required this.latitude,
    required this.longitude,
    required this.serviceType,
    required this.selectedAddOns,
    required this.bookingId,
  });

  @override
  State<FindingLaundryScreen> createState() => _FindingLaundryScreenState();
}

class _FindingLaundryScreenState extends State<FindingLaundryScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;

  late final AnimationController _pulseController;
  Timer? _timer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _bookingSub;

  final _repo = _FindingLaundryRepository.instance;

  int _secondsElapsed = 0;
  bool _isLoading = true;
  bool _isLoadingInfo = true;
  bool _showingDetails = false;
  bool _isCancelling = false;

  /// Keep this false until a laundry actually accepts.
  bool _hasLaundryAccepted = false;

  Map<String, dynamic>? _bookingData;
  String? _bookingStatus;
  String? _assignedLaundryId;
  String? _assignedLaundryName;
  String? _assignedLaundryPhone;
  String? _assignedLaundryPhotoUrl;

  late final LatLng _pickupLatLng;

  @override
  void initState() {
    super.initState();

    _pickupLatLng = LatLng(widget.latitude, widget.longitude);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _startFindingTimer();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _setFindingStatusIfNeeded();
    _watchBooking();
  }

  void _startFindingTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_hasLaundryAccepted || _bookingStatus == 'cancelled') {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsElapsed++;
      });
    });
  }

  Future<void> _setFindingStatusIfNeeded() async {
    try {
      final booking = await _repo.getBooking(widget.bookingId);
      final data = booking.data();

      if (data == null) {
        return;
      }

      final status = _readString(data['status']);

      const terminalStatuses = {
        'cancelled',
        'accepted',
        'looking_for_pickup_rider',
        'pickup_rider_assigned',
        'rider_arrived_for_pickup',
        'picked_up',
        'arrived_at_laundry',
        'washing',
        'ready_for_delivery',
        'looking_for_delivery_rider',
        'delivery_rider_assigned',
        'out_for_delivery',
        'delivered',
      };

      if (!terminalStatuses.contains(status) &&
          status != 'awaiting_laundry_assignment') {
        await _repo.updateBookingStatus(
          bookingId: widget.bookingId,
          status: 'awaiting_laundry_assignment',
          title: 'Finding Laundry',
          description: 'System is searching for a suitable nearby laundry.',
        );
      }
    } catch (e, st) {
      debugPrint('Failed to set finding status: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _watchBooking() {
    _bookingSub = _repo
        .watchBooking(widget.bookingId)
        .listen(
          (snapshot) {
            final data = snapshot.data();
            if (!mounted) return;

            if (data == null) {
              setState(() {
                _bookingData = null;
                _isLoadingInfo = false;
                _isLoading = false;
              });
              return;
            }

            final status = _readString(data['status']);
            final laundryId = _readString(data['laundryId']);
            final laundryName = _readString(data['laundryName']);
            final laundryPhone = _readString(data['laundryPhone']);
            final laundryPhotoUrl = _readString(data['laundryPhotoUrl']);

            final hasAccepted = _isAcceptedFlowStatus(status);

            if (hasAccepted) {
              _timer?.cancel();
            }

            setState(() {
              _bookingData = data;
              _bookingStatus = status;
              _assignedLaundryId = laundryId.isEmpty ? null : laundryId;
              _assignedLaundryName = laundryName.isEmpty ? null : laundryName;
              _assignedLaundryPhone = laundryPhone.isEmpty
                  ? null
                  : laundryPhone;
              _assignedLaundryPhotoUrl = laundryPhotoUrl.isEmpty
                  ? null
                  : laundryPhotoUrl;

              _hasLaundryAccepted = hasAccepted;

              /// The map pulse stops only when a laundry truly accepts.
              _isLoading = !_hasLaundryAccepted;

              /// Bottom sheet info should show once we have the booking loaded.
              _isLoadingInfo = false;
            });
          },
          onError: (error, stackTrace) {
            debugPrint('Booking stream error: $error');
            debugPrintStack(stackTrace: stackTrace);

            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _isLoadingInfo = false;
            });

            _showSnackBar('Something went wrong while tracking this booking.');
          },
        );
  }

  bool _isAcceptedFlowStatus(String? status) {
    switch (status) {
      case 'accepted':
      case 'looking_for_pickup_rider':
      case 'pickup_rider_assigned':
      case 'rider_arrived_for_pickup':
      case 'picked_up':
      case 'arrived_at_laundry':
      case 'washing':
      case 'ready_for_delivery':
      case 'looking_for_delivery_rider':
      case 'delivery_rider_assigned':
      case 'out_for_delivery':
      case 'delivered':
        return true;
      default:
        return false;
    }
  }

  String _readString(dynamic value) {
    if (value is String) {
      return value.trim();
    }
    return '';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bookingSub?.cancel();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Set<Marker> _markers() {
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLatLng,
        infoWindow: InfoWindow(title: widget.pickupTitle),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    };
  }

  Future<void> _goToPickup() async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _pickupLatLng, zoom: 17),
      ),
    );
  }

  Future<void> _cancelRequest() async {
    if (_isCancelling) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      await _repo.updateBookingStatus(
        bookingId: widget.bookingId,
        status: 'cancelled',
        title: 'Booking Cancelled',
        description: 'Customer cancelled the laundry request.',
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, st) {
      debugPrint('Cancel request error: $e');
      debugPrintStack(stackTrace: st);
      _showSnackBar('Failed to cancel request. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  void _showDetails() {
    if (!mounted) return;
    setState(() {
      _showingDetails = true;
    });
  }

  void _hideDetails() {
    if (!mounted) return;
    setState(() {
      _showingDetails = false;
    });
  }

  String get _statusHeadline {
    if (_bookingStatus == 'cancelled') return 'Request cancelled';
    if (_hasLaundryAccepted) return 'Laundry accepted';
    if ((_assignedLaundryId ?? '').isNotEmpty) return 'Laundry found';
    return 'Finding laundries';
  }

  String get _statusSubtitle {
    if (_bookingStatus == 'cancelled') {
      return 'This booking was cancelled.';
    }

    if (_hasLaundryAccepted) {
      if ((_assignedLaundryName ?? '').isNotEmpty) {
        return '${_assignedLaundryName!} accepted your request';
      }
      return 'A laundry has accepted your request';
    }

    if ((_assignedLaundryId ?? '').isNotEmpty) {
      if ((_assignedLaundryName ?? '').isNotEmpty) {
        return '${_assignedLaundryName!} has been matched';
      }
      return 'A nearby laundry has been matched';
    }

    return 'Finding the best laundries nearby';
  }

  @override
  Widget build(BuildContext context) {
    const sheetRadius = 28.0;

    return WillPopScope(
      onWillPop: () async {
        if (_showingDetails) {
          _hideDetails();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _pickupLatLng,
                  zoom: 14.5,
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
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withOpacity(0.20)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _RoundMapButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        if (_showingDetails) {
                          _hideDetails();
                          return;
                        }
                        Navigator.pop(context);
                      },
                      small: false,
                    ),
                    const Spacer(),
                    _RoundMapButton(
                      icon: Icons.my_location_rounded,
                      onTap: _goToPickup,
                      small: true,
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: IgnorePointer(
                child: Transform.translate(
                  offset: const Offset(0, 0),
                  child: _isLoading
                      ? AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale =
                                2.95 + (_pulseController.value * 0.25);

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 110 * scale,
                                  height: 110 * scale,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.black54,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      : const PulsingDot(size: 12),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _isLoadingInfo
                    ? _LoadingBottomSheet(
                        key: const ValueKey('loading_sheet'),
                        timerText: _formattedTime,
                        radius: sheetRadius,
                        pickupTitle: widget.pickupTitle,
                      )
                    : _LoadedBottomSheet(
                        key: const ValueKey('loaded_sheet'),
                        timerText: _formattedTime,
                        radius: sheetRadius,
                        pickupTitle: widget.pickupTitle,
                        serviceType: widget.serviceType,
                        selectedAddOns: widget.selectedAddOns,
                        isShowingDetails: _showingDetails,
                        hasLaundryAccepted: _hasLaundryAccepted,
                        assignedLaundryName: _assignedLaundryName,
                        statusHeadline: _statusHeadline,
                        statusSubtitle: _statusSubtitle,
                        isCancelling: _isCancelling,
                        onCancelTap: _cancelRequest,
                        onDetailsTap: _showDetails,
                        onCollapseTap: _hideDetails,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FindingLaundryRepository {
  _FindingLaundryRepository._();

  static final _FindingLaundryRepository instance =
      _FindingLaundryRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> bookingRef(String bookingId) =>
      _firestore.collection('bookings').doc(bookingId);

  Future<DocumentSnapshot<Map<String, dynamic>>> getBooking(
    String bookingId,
  ) async {
    return bookingRef(bookingId).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchBooking(
    String bookingId,
  ) {
    return bookingRef(bookingId).snapshots();
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
    required String title,
    required String description,
  }) async {
    final booking = bookingRef(bookingId);
    final batch = _firestore.batch();

    batch.update(booking, {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'timeline.cancelledAt': status == 'cancelled'
          ? FieldValue.serverTimestamp()
          : null,
    });

    batch.set(booking.collection('status_history').doc(), {
      'status': status,
      'title': title,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}

class _LoadingBottomSheet extends StatelessWidget {
  final String timerText;
  final double radius;
  final String pickupTitle;

  const _LoadingBottomSheet({
    super.key,
    required this.timerText,
    required this.radius,
    required this.pickupTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Expanded(child: _PulsingTextBlock()),
                    SizedBox(width: 16),
                    _PulsingBox(width: 56, height: 22, borderRadius: 12),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    _PulsingBox(width: 44, height: 44, borderRadius: 14),
                    SizedBox(width: 12),
                    Expanded(child: _PulsingTextLines()),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(
                    child: _LoadingActionButton(label: 'Cancel request'),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: _LoadingActionButton(label: 'Details')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadedBottomSheet extends StatefulWidget {
  final String timerText;
  final double radius;
  final String pickupTitle;
  final String serviceType;
  final List<String> selectedAddOns;
  final bool isShowingDetails;
  final bool hasLaundryAccepted;
  final String? assignedLaundryName;
  final String statusHeadline;
  final String statusSubtitle;
  final bool isCancelling;
  final VoidCallback onCancelTap;
  final VoidCallback onDetailsTap;
  final VoidCallback onCollapseTap;

  const _LoadedBottomSheet({
    super.key,
    required this.timerText,
    required this.radius,
    required this.pickupTitle,
    required this.serviceType,
    required this.selectedAddOns,
    required this.isShowingDetails,
    required this.hasLaundryAccepted,
    required this.assignedLaundryName,
    required this.statusHeadline,
    required this.statusSubtitle,
    required this.isCancelling,
    required this.onCancelTap,
    required this.onDetailsTap,
    required this.onCollapseTap,
  });

  @override
  State<_LoadedBottomSheet> createState() => _LoadedBottomSheetState();
}

class _LoadedBottomSheetState extends State<_LoadedBottomSheet>
    with TickerProviderStateMixin {
  late final AnimationController _detailsController;
  late final Animation<double> _detailsFade;
  late final Animation<double> _detailsSize;

  @override
  void initState() {
    super.initState();
    _detailsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _detailsFade = CurvedAnimation(
      parent: _detailsController,
      curve: Curves.easeInOut,
    );

    _detailsSize = CurvedAnimation(
      parent: _detailsController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.isShowingDetails) {
      _detailsController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _LoadedBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isShowingDetails && !oldWidget.isShowingDetails) {
      _detailsController.forward();
    } else if (!widget.isShowingDetails && oldWidget.isShowingDetails) {
      _detailsController.reverse();
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(widget.radius),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: widget.isShowingDetails ? widget.onCollapseTap : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: widget.isShowingDetails ? 52 : 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _FindingStatusCard(
                  timerText: widget.timerText,
                  isStillFinding: !widget.hasLaundryAccepted,
                  headline: widget.statusHeadline,
                  subtitle: widget.statusSubtitle,
                ),
                ClipRect(
                  child: SizeTransition(
                    sizeFactor: _detailsSize,
                    axisAlignment: -1,
                    child: FadeTransition(
                      opacity: _detailsFade,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFFE67E22),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Request details',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: widget.onCollapseTap,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F3F3),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _DetailTile(
                              title: 'Pickup',
                              subtitle: widget.pickupTitle,
                              icon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 12),
                            if ((widget.assignedLaundryName ?? '').isNotEmpty)
                              Column(
                                children: [
                                  _DetailTile(
                                    title: 'Matched laundry',
                                    subtitle: widget.assignedLaundryName!,
                                    icon: Icons.storefront_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            _AddOnsTile(addOns: widget.selectedAddOns),
                            const SizedBox(height: 12),
                            _DetailTile(
                              title: 'Service type',
                              subtitle: widget.serviceType,
                              icon: Icons.local_laundry_service_outlined,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        axisAlignment: -1,
                        child: child,
                      ),
                    );
                  },
                  child: widget.isShowingDetails
                      ? const SizedBox.shrink(
                          key: ValueKey('no_button_when_expanded'),
                        )
                      : Row(
                          key: const ValueKey('two_buttons_row'),
                          children: [
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.cancel_rounded,
                                label: widget.isCancelling
                                    ? 'Cancelling...'
                                    : 'Cancel request',
                                onTap: widget.isCancelling
                                    ? null
                                    : widget.onCancelTap,
                                isDestructive: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.grid_view_rounded,
                                label: 'Details',
                                onTap: widget.onDetailsTap,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FindingStatusCard extends StatefulWidget {
  final String timerText;
  final bool isStillFinding;
  final String headline;
  final String subtitle;

  const _FindingStatusCard({
    required this.timerText,
    required this.isStillFinding,
    required this.headline,
    required this.subtitle,
  });

  @override
  State<_FindingStatusCard> createState() => _FindingStatusCardState();
}

class _FindingStatusCardState extends State<_FindingStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _softPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _softPulse = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isStillFinding) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _FindingStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isStillFinding && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isStillFinding && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmerPosition = (_controller.value * 2) - 1;

        return Transform.scale(
          scale: widget.isStillFinding ? _softPulse.value : 1.0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: const BoxDecoration(color: Color(0xFFfff4ea)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(141, 50, 24, 0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Transform.scale(
                            scale: 1.2,
                            child: Lottie.asset(
                              'assets/animations/search_laundry.json',
                              fit: BoxFit.contain,
                              height: 56,
                              width: 56,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.headline,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          widget.timerText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isStillFinding)
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return IgnorePointer(
                            child: Transform.translate(
                              offset: Offset(
                                shimmerPosition * (constraints.maxWidth + 140),
                                0,
                              ),
                              child: Container(
                                width: 110,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.34),
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                    stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDestructive ? Colors.red : const Color(0xFFE67E22);

    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: accent, size: 20),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: accent,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isDestructive
              ? const Color(0xFFF1F1F1)
              : Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _LoadingActionButton extends StatelessWidget {
  final String label;

  const _LoadingActionButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFfff4ea),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _PulsingBox(width: 18, height: 18, borderRadius: 9),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              alignment: Alignment.centerLeft,
              child: const _PulsingBox(width: 90, height: 16, borderRadius: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingTextBlock extends StatelessWidget {
  const _PulsingTextBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PulsingBox(width: 190, height: 20, borderRadius: 8),
        SizedBox(height: 8),
        _PulsingBox(width: 150, height: 16, borderRadius: 8),
      ],
    );
  }
}

class _PulsingTextLines extends StatelessWidget {
  const _PulsingTextLines();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PulsingBox(width: 180, height: 16, borderRadius: 8),
        SizedBox(height: 8),
        _PulsingBox(width: 120, height: 14, borderRadius: 8),
      ],
    );
  }
}

class _PulsingBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _PulsingBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_PulsingBox> createState() => _PulsingBoxState();
}

class _PulsingBoxState extends State<_PulsingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _opacity = Tween<double>(
      begin: 0.45,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFEAEAEA),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _DetailTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE67E22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
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

class _AddOnsTile extends StatelessWidget {
  final List<String> addOns;

  const _AddOnsTile({required this.addOns});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.add_circle_outline_rounded,
            color: Color(0xFFE67E22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected add-ons',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                if (addOns.isEmpty)
                  const Text(
                    'No add-ons selected',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: addOns
                        .map(
                          (addOn) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 237, 220),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              addOn,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
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

  const _RoundMapButton({required this.icon, this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 44.0 : 56.0;

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
          child: Icon(icon, color: Colors.black87, size: small ? 22 : 26),
        ),
      ),
    );
  }
}

class PulsingDot extends StatefulWidget {
  final double size;

  const PulsingDot({super.key, this.size = 14});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 0.85,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _color = ColorTween(
      begin: const Color.fromARGB(255, 255, 149, 0),
      end: const Color.fromARGB(255, 66, 66, 66),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _color.value,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_color.value ?? Colors.white).withOpacity(0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
