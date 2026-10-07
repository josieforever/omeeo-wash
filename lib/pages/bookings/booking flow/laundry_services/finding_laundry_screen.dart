import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' hide Marker;
import 'active_laundry_order_stage.dart';
import 'closest_laundries_screen.dart';

class FindingLaundryScreen extends StatefulWidget {
  final String bookingId;
  final String pickupTitle;
  final double latitude;
  final double longitude;
  final String serviceType;
  final List<String> selectedAddOns;

  /// Legacy Google Maps key parameter retained for existing callers.
  ///
  /// Routes API no longer reads from this value. Use [routesApiKey] or
  /// --dart-define=GOOGLE_ROUTES_API_KEY=...
  /// Dedicated key for Google Routes API v2.
  ///
  /// Prefer passing this, or use:
  /// --dart-define=GOOGLE_ROUTES_API_KEY=...
  final String routesApiKey;

  /// Kept only for backwards compatibility with existing callers.
  ///
  /// IMPORTANT: this value is NOT used for Routes API calls anymore because
  /// your normal Android Maps SDK key can be Android-restricted and therefore
  /// blocked by the Routes REST endpoint.
  final String googleMapsApiKey;

  const FindingLaundryScreen({
    super.key,
    required this.pickupTitle,
    required this.latitude,
    required this.longitude,
    required this.serviceType,
    required this.selectedAddOns,
    required this.bookingId,
    this.routesApiKey = '',
    this.googleMapsApiKey = '',
  });

  @override
  State<FindingLaundryScreen> createState() => _FindingLaundryScreenState();
}

class _FindingLaundryScreenState extends State<FindingLaundryScreen>
    with TickerProviderStateMixin {
  static const List<String> _findingStatuses = [
    'pending',
    'awaiting_laundry_assignment',
    'offered_to_laundry',
    'awaiting_laundry_acceptance',
  ];

  static const List<String> _activeStatuses = [
    'looking_for_pickup_rider',
    'pickup_rider_assigned',
    'pickup_started',
    'arrived_at_pickup',
    'arrived_at_laundry',
    'processing',
    'ready_for_dropoff',
    'delivery_in_progress',
    'completed',
  ];

  GoogleMapController? _mapController;

  Timer? _timer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _bookingSub;

  final _repo = _FindingLaundryRepository.instance;

  int _secondsElapsed = 0;
  bool _isLoading = true;
  bool _isLoadingInfo = true;
  bool _showingDetails = false;
  bool _isCancelling = false;
  bool _isRecentering = false;

  bool _hasLaundryAccepted = false;
  bool _hasNavigatedToActiveOrder = false;
  bool _activeTransitionInProgress = false;

  // Route state: customer pickup -> accepted laundry.
  LatLng? _laundryLatLng;
  List<LatLng> _routePoints = const [];
  String? _routeDurationText;
  String? _routeDistanceText;
  bool _isLoadingRoute = false;
  String? _routeError;
  String? _lastRouteDestinationKey;

  BitmapDescriptor? _pickupMapMarkerIcon;
  BitmapDescriptor? _laundryMapMarkerIcon;

  Map<String, dynamic>? _bookingData;
  String? _bookingStatus;
  String? _assignedLaundryId;
  String? _assignedLaundryName;
  String? _assignedLaundryPhone;
  String? _assignedLaundryPhotoUrl;

  late final LatLng _pickupLatLng;

  // Same pickup-pin geometry used on PickupPreviewScreen.
  static const double _pickupOverlayWidth = 240;
  static const double _pickupOverlayHeight = 200;
  static const double _pickupPinTipBottomInset = 14;

  // Tiny artwork-only correction if the scooter PNG ever needs it.
  // These do NOT change the real geographic pickup location.
  static const double _pinVisualOffsetX = 0;
  static const double _pinVisualOffsetY = 0;

  // Route/destination accent. Chosen to stay vivid on Google Maps while still
  // feeling clean beside Lundri orange, black and warm-white surfaces.
  static const Color _routeGreen = Color(0xFF1FA463);

  static const String _envRoutesApiKey = String.fromEnvironment(
    'GOOGLE_ROUTES_API_KEY',
  );

  String get _routeApiKey {
    final explicitRoutesKey = widget.routesApiKey.trim();
    if (explicitRoutesKey.isNotEmpty) {
      return explicitRoutesKey;
    }

    final environmentRoutesKey = _envRoutesApiKey.trim();
    if (environmentRoutesKey.isNotEmpty) {
      return environmentRoutesKey;
    }

    // Deliberately DO NOT fall back to googleMapsApiKey or
    // GOOGLE_MAPS_API_KEY here. Those are commonly Android-restricted keys
    // used by the native Maps SDK and can be rejected by Routes API REST.
    return '';
  }

  String get _routeApiKeySource {
    if (widget.routesApiKey.trim().isNotEmpty) {
      return 'FindingLaundryScreen.routesApiKey';
    }

    if (_envRoutesApiKey.trim().isNotEmpty) {
      return 'GOOGLE_ROUTES_API_KEY dart-define';
    }

    return 'MISSING';
  }

  bool get _hasVisibleRoute =>
      _routePoints.length >= 2 && _laundryLatLng != null;

  bool get _isLaundryOfferStage =>
      _bookingStatus == 'offered_to_laundry' ||
      _bookingStatus == 'awaiting_laundry_acceptance';

  bool get _shouldShowLaundryDestination =>
      _isLaundryOfferStage ||
      _hasLaundryAccepted ||
      _hasVisibleRoute ||
      _laundryLatLng != null;

  @override
  void initState() {
    super.initState();

    _pickupLatLng = LatLng(widget.latitude, widget.longitude);

    debugPrint('Routes API key source: $_routeApiKeySource');

    if (widget.googleMapsApiKey.trim().isNotEmpty &&
        _routeApiKeySource == 'MISSING') {
      debugPrint(
        'WARNING: googleMapsApiKey was supplied, but it is intentionally '
        'not used for Routes API. Supply routesApiKey or '
        'GOOGLE_ROUTES_API_KEY instead.',
      );
    }

    unawaited(_loadPickupMapMarkerIcon());
    unawaited(_loadLaundryMapMarkerIcon());
    _startFindingTimer();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _setFindingStatusIfNeeded();
    _watchBooking();
  }

  Future<void> _loadPickupMapMarkerIcon() async {
    try {
      final data = await rootBundle.load(
        'assets/images/lundri_scooter_pin.png',
      );

      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 64,
        targetHeight: 64,
      );

      final frame = await codec.getNextFrame();
      final scooterImage = frame.image;

      // Static pickup pin canvas.
      //
      // Same overall shape as the laundry destination pin, but pickup keeps
      // Lundri orange as its accent while laundry uses route green.
      const canvasWidth = 112.0;
      const canvasHeight = 142.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      );

      const orange = Color(0xFFE67E22);
      const black = Color(0xFF111111);

      // Soft contact shadow.
      final shadowPaint = Paint()
        ..color = black.withOpacity(0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawOval(const Rect.fromLTWH(31, 124, 50, 10), shadowPaint);

      // Static pickup focus ring.
      final focusFillPaint = Paint()
        ..color = orange.withOpacity(0.06)
        ..style = PaintingStyle.fill;

      final focusStrokePaint = Paint()
        ..color = orange.withOpacity(0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      const focusRect = Rect.fromLTWH(20, 116, 72, 22);

      canvas.drawOval(focusRect, focusFillPaint);

      canvas.drawOval(focusRect, focusStrokePaint);

      // Pin stem.
      final stemPaint = Paint()
        ..color = black
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(53, 96, 6, 28),
          const Radius.circular(99),
        ),
        stemPaint,
      );

      // Icon card shadow.
      final cardShadowPaint = Paint()
        ..color = orange.withOpacity(0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(19, 22, 74, 74),
          const Radius.circular(18),
        ),
        cardShadowPaint,
      );

      // White icon card.
      final cardPaint = Paint()
        ..color = Colors.white.withOpacity(0.96)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = black.withOpacity(0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final cardRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 18, 72, 72),
        const Radius.circular(18),
      );

      canvas.drawRRect(cardRect, cardPaint);

      canvas.drawRRect(cardRect, borderPaint);

      // Scooter artwork inside the card.
      final srcRect = Rect.fromLTWH(
        0,
        0,
        scooterImage.width.toDouble(),
        scooterImage.height.toDouble(),
      );

      const dstRect = Rect.fromLTWH(25, 23, 62, 62);

      canvas.drawImageRect(
        scooterImage,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );

      final picture = recorder.endRecording();

      final rendered = await picture.toImage(
        canvasWidth.toInt(),
        canvasHeight.toInt(),
      );

      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);

      scooterImage.dispose();
      rendered.dispose();

      if (bytes == null) {
        throw Exception('Could not encode static pickup pin.');
      }

      final icon = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());

      if (!mounted) return;

      setState(() {
        _pickupMapMarkerIcon = icon;
      });
    } catch (e) {
      debugPrint('Could not load static Lundri pickup pin: $e');
    }
  }

  Future<void> _loadLaundryMapMarkerIcon() async {
    try {
      final data = await rootBundle.load('assets/images/laundry_shop_icon.png');

      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 64,
        targetHeight: 64,
      );

      final frame = await codec.getNextFrame();
      final shopImage = frame.image;

      // Static destination pin canvas.
      //
      // This deliberately borrows the visual language of the pickup pin
      // (shadow + focus ring + rounded icon card + stem) without using any
      // animation controllers, transforms or repeating effects.
      const canvasWidth = 112.0;
      const canvasHeight = 142.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      );

      const green = Color(0xFF1FA463);
      const black = Color(0xFF111111);

      // Soft contact shadow.
      final shadowPaint = Paint()
        ..color = black.withOpacity(0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawOval(const Rect.fromLTWH(31, 124, 50, 10), shadowPaint);

      // Static ground focus ring. Same idea as the pickup radar pulse,
      // but fixed in place because the user requested no animation.
      final focusFillPaint = Paint()
        ..color = green.withOpacity(0.06)
        ..style = PaintingStyle.fill;

      final focusStrokePaint = Paint()
        ..color = green.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      const focusRect = Rect.fromLTWH(20, 116, 72, 22);

      canvas.drawOval(focusRect, focusFillPaint);

      canvas.drawOval(focusRect, focusStrokePaint);

      // Pin stem.
      final stemPaint = Paint()
        ..color = black
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(53, 96, 6, 28),
          const Radius.circular(99),
        ),
        stemPaint,
      );

      // Icon card shadow.
      final cardShadowPaint = Paint()
        ..color = green.withOpacity(0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(19, 22, 74, 74),
          const Radius.circular(18),
        ),
        cardShadowPaint,
      );

      // White icon card.
      final cardPaint = Paint()
        ..color = Colors.white.withOpacity(0.96)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = black.withOpacity(0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final cardRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 18, 72, 72),
        const Radius.circular(18),
      );

      canvas.drawRRect(cardRect, cardPaint);

      canvas.drawRRect(cardRect, borderPaint);

      // Laundry shop artwork inside the card.
      final srcRect = Rect.fromLTWH(
        0,
        0,
        shopImage.width.toDouble(),
        shopImage.height.toDouble(),
      );

      const dstRect = Rect.fromLTWH(25, 23, 62, 62);

      canvas.drawImageRect(
        shopImage,
        srcRect,
        dstRect,
        Paint()..filterQuality = FilterQuality.high,
      );

      final picture = recorder.endRecording();

      final rendered = await picture.toImage(
        canvasWidth.toInt(),
        canvasHeight.toInt(),
      );

      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);

      shopImage.dispose();
      rendered.dispose();

      if (bytes == null) {
        throw Exception('Could not encode static laundry destination pin.');
      }

      final icon = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());

      if (!mounted) return;

      setState(() {
        _laundryMapMarkerIcon = icon;
      });
    } catch (e) {
      debugPrint('Could not load static Lundri laundry destination pin: $e');
    }
  }

  void _startFindingTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_hasMovedIntoActiveFlow || _bookingStatus == 'cancelled') {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsElapsed++;
      });
    });
  }

  bool get _isStillFindingLaundry {
    final status = _bookingStatus;
    return status == null || status.isEmpty || _isFindingFlowStatus(status);
  }

  bool get _hasMovedIntoActiveFlow => _isActiveFlowStatus(_bookingStatus);

  Future<void> _tryAgain() async {
    try {
      setState(() {
        _isLoading = true;
        _secondsElapsed = 0;
        _hasLaundryAccepted = false;
        _hasNavigatedToActiveOrder = false;
      });

      _startFindingTimer();

      await _repo.updateBookingStatus(
        bookingId: widget.bookingId,
        status: 'awaiting_laundry_assignment',
        title: 'Retrying Search',
        description: 'Trying again to find a suitable laundry.',
      );
    } catch (e, st) {
      debugPrint('Retry search error: $e');
      debugPrintStack(stackTrace: st);
      _showSnackBar('Failed to retry search. Please try again.');
    }
  }

  void _selectLaundryManually() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClosestLaundriesScreen(
          bookingId: widget.bookingId,
          pickupTitle: widget.pickupTitle,
          pickupLatitude: widget.latitude,
          pickupLongitude: widget.longitude,
          selectedServiceType: widget.serviceType,
          selectedAddOns: widget.selectedAddOns,
        ),
      ),
    );
  }

  Future<void> _setFindingStatusIfNeeded() async {
    try {
      final booking = await _repo.getBooking(widget.bookingId);
      final data = booking.data();

      if (data == null) return;

      final currentStatus = _readString(data['status']);

      if (currentStatus.isEmpty || currentStatus == 'pending') {
        await _repo.updateBookingStatus(
          bookingId: widget.bookingId,
          status: 'awaiting_laundry_assignment',
          title: 'Finding Laundry',
          description: 'System is searching for a suitable nearby laundry.',
        );
      }
    } catch (e, st) {
      debugPrint('Failed to initialize laundry finding status: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _watchBooking() {
    _bookingSub?.cancel();

    _bookingSub = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen(
          (snapshot) {
            if (!snapshot.exists || !mounted) return;

            final data = snapshot.data() ?? <String, dynamic>{};
            final status = _readString(data['status']);
            final laundrySnapshot = _readMap(data['laundrySnapshot']);
            final laundryOffer = _readMap(data['laundryOffer']);

            final assignedLaundryId = _firstNonEmpty([
              _readString(laundrySnapshot['id']),
              _readString(data['laundryId']),
              _readString(laundryOffer['offeredLaundryId']),
              _readString(laundryOffer['laundryId']),
            ]);

            final assignedLaundryName = _firstNonEmpty([
              _readString(laundrySnapshot['name']),
              _readString(data['laundryName']),
              _readString(laundryOffer['laundryName']),
              _readString(laundryOffer['offeredLaundryName']),
            ]);

            final assignedLaundryPhone = _firstNonEmpty([
              _readString(laundrySnapshot['phoneNumber']),
              _readString(data['laundryPhoneNumber']),
              _readString(data['laundryPhone']),
            ]);

            final assignedLaundryPhotoUrl = _firstNonEmpty([
              _readString(laundrySnapshot['photoUrl']),
              _readString(data['laundryPhotoUrl']),
            ]);

            final laundryLatLngFromSnapshot = _extractLaundryLatLng(
              laundrySnapshot: laundrySnapshot,
              bookingData: data,
            );

            final isActive = _isActiveFlowStatus(status);

            setState(() {
              _bookingData = data;
              _bookingStatus = status;

              _assignedLaundryId = assignedLaundryId;
              _assignedLaundryName = assignedLaundryName;
              _assignedLaundryPhone = assignedLaundryPhone;
              _assignedLaundryPhotoUrl = assignedLaundryPhotoUrl;

              if (laundryLatLngFromSnapshot != null) {
                _laundryLatLng = laundryLatLngFromSnapshot;
              }

              _isLoading = false;
              _isLoadingInfo = false;
              _hasLaundryAccepted = isActive;
            });

            if (status == 'cancelled') {
              _timer?.cancel();
            }

            final shouldPreviewRoute =
                status == 'offered_to_laundry' ||
                status == 'awaiting_laundry_acceptance';

            if (shouldPreviewRoute) {
              // This is the exact point requested:
              // as soon as the app says "Offer sent to laundry", resolve the
              // offered laundry and draw pickup -> laundry immediately.
              unawaited(
                _prepareRouteToLaundry(
                  laundrySnapshot: laundrySnapshot,
                  bookingData: data,
                  initialLaundryLatLng: laundryLatLngFromSnapshot,
                ),
              );
            }

            if (isActive) {
              _timer?.cancel();

              unawaited(
                _handleAcceptedLaundryTransition(
                  laundrySnapshot: laundrySnapshot,
                  bookingData: data,
                  laundryLatLngFromSnapshot: laundryLatLngFromSnapshot,
                ),
              );
            }
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

  Future<void> _handleAcceptedLaundryTransition({
    required Map<String, dynamic> laundrySnapshot,
    required Map<String, dynamic> bookingData,
    required LatLng? laundryLatLngFromSnapshot,
  }) async {
    if (!mounted || _hasNavigatedToActiveOrder || _activeTransitionInProgress) {
      return;
    }

    _activeTransitionInProgress = true;

    var routeWasShown = false;

    try {
      routeWasShown =
          await _prepareRouteToLaundry(
            laundrySnapshot: laundrySnapshot,
            bookingData: bookingData,
            initialLaundryLatLng: laundryLatLngFromSnapshot,
          ).timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              debugPrint('Laundry route request timed out.');
              return false;
            },
          );
    } catch (e, st) {
      debugPrint('Laundry route preparation failed: $e');
      debugPrintStack(stackTrace: st);
    }

    if (!mounted || _hasNavigatedToActiveOrder) return;

    // Keep the successful route visible long enough for the customer to see
    // where their laundry is going, just like the reference app transition.
    await Future<void>.delayed(
      Duration(milliseconds: routeWasShown ? 3200 : 900),
    );

    if (!mounted || _hasNavigatedToActiveOrder) return;

    _hasNavigatedToActiveOrder = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ActiveLaundryOrderScreen(bookingId: widget.bookingId),
      ),
    );
  }

  Future<bool> _prepareRouteToLaundry({
    required Map<String, dynamic> laundrySnapshot,
    required Map<String, dynamic> bookingData,
    LatLng? initialLaundryLatLng,
  }) async {
    final destination =
        initialLaundryLatLng ??
        await _resolveLaundryLatLng(
          laundrySnapshot: laundrySnapshot,
          bookingData: bookingData,
        );

    if (!mounted || destination == null) {
      debugPrint(
        'Laundry route requested but no laundry coordinates were available.',
      );
      return false;
    }

    final destinationKey =
        '${destination.latitude.toStringAsFixed(6)},'
        '${destination.longitude.toStringAsFixed(6)}';

    if (_lastRouteDestinationKey != null &&
        _lastRouteDestinationKey != destinationKey &&
        mounted) {
      setState(() {
        _routePoints = const [];
        _routeDurationText = null;
        _routeDistanceText = null;
        _routeError = null;
      });
    }

    if (_lastRouteDestinationKey == destinationKey && _hasVisibleRoute) {
      await _fitRouteInView();
      return true;
    }

    if (_isLoadingRoute && _lastRouteDestinationKey == destinationKey) {
      return false;
    }

    final apiKey = _routeApiKey;

    if (apiKey.isEmpty) {
      debugPrint(
        'Routes API key is missing. Pass routesApiKey to '
        'FindingLaundryScreen or use --dart-define='
        'GOOGLE_ROUTES_API_KEY=YOUR_KEY.',
      );

      if (mounted) {
        setState(() {
          _laundryLatLng = destination;
          _routeError = 'Routes API key missing';
          _isLoadingRoute = false;
        });
      }

      return false;
    }

    setState(() {
      _laundryLatLng = destination;
      _isLoadingRoute = true;
      _routeError = null;
      _lastRouteDestinationKey = destinationKey;
    });

    try {
      final route = await _DirectionsRouteService.fetchDrivingRoute(
        origin: _pickupLatLng,
        destination: destination,
        apiKey: apiKey,
      );

      if (!mounted) return false;

      setState(() {
        _routePoints = route.points;
        _routeDurationText = route.durationText;
        _routeDistanceText = route.distanceText;
        _routeError = null;
        _isLoadingRoute = false;
      });

      HapticFeedback.lightImpact();

      await Future<void>.delayed(const Duration(milliseconds: 120));

      await _fitRouteInView();

      return true;
    } catch (e, st) {
      debugPrint('Routes API route failed: $e');
      debugPrint('Routes API key source used: $_routeApiKeySource');
      debugPrintStack(stackTrace: st);

      if (mounted) {
        setState(() {
          _routePoints = const [];
          _routeDurationText = null;
          _routeDistanceText = null;
          _routeError = e.toString();
          _isLoadingRoute = false;
        });
      }

      return false;
    }
  }

  Future<LatLng?> _resolveLaundryLatLng({
    required Map<String, dynamic> laundrySnapshot,
    required Map<String, dynamic> bookingData,
  }) async {
    final snapshotLocation = _extractLaundryLatLng(
      laundrySnapshot: laundrySnapshot,
      bookingData: bookingData,
    );

    if (snapshotLocation != null) return snapshotLocation;

    final laundryOffer = _readMap(bookingData['laundryOffer']);

    final laundryId = _firstNonEmpty([
      _readString(laundrySnapshot['id']),
      _readString(bookingData['laundryId']),
      _readString(laundryOffer['offeredLaundryId']),
      _readString(laundryOffer['laundryId']),
      _assignedLaundryId ?? '',
    ]);

    if (laundryId.isEmpty) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('laundries')
          .doc(laundryId)
          .get();

      final data = doc.data();
      if (data == null) return null;

      final profile = _readMap(data['profile']);
      final resolvedName = _firstNonEmpty([
        _readString(profile['name']),
        _readString(data['name']),
        _assignedLaundryName ?? '',
      ]);

      if (mounted && resolvedName.isNotEmpty) {
        setState(() {
          _assignedLaundryName = resolvedName;
        });
      }

      return _latLngFromMap(data);
    } catch (e) {
      debugPrint('Could not load laundry coordinates: $e');
      return null;
    }
  }

  LatLng? _extractLaundryLatLng({
    required Map<String, dynamic> laundrySnapshot,
    required Map<String, dynamic> bookingData,
  }) {
    final laundryOffer = _readMap(bookingData['laundryOffer']);

    return _latLngFromMap(laundrySnapshot) ??
        _latLngFromMap(_readMap(bookingData['laundryLocation'])) ??
        _latLngFromMap(_readMap(bookingData['laundry'])) ??
        _latLngFromValue(bookingData['laundryGeopoint']) ??
        _latLngFromMap(_readMap(laundryOffer['location'])) ??
        _latLngFromValue(laundryOffer['geopoint']) ??
        _latLngFromValue(laundryOffer['geoPoint']);
  }

  LatLng? _latLngFromMap(Map<String, dynamic> data) {
    final directGeopoint =
        _latLngFromValue(data['geopoint']) ??
        _latLngFromValue(data['geoPoint']);

    if (directGeopoint != null) return directGeopoint;

    final location = _readMap(data['location']);
    if (location.isNotEmpty) {
      final nested = _latLngFromMap(location);
      if (nested != null) return nested;
    }

    final latitude = _readDouble(data['latitude'] ?? data['lat']);
    final longitude = _readDouble(
      data['longitude'] ?? data['lng'] ?? data['lon'],
    );

    if (latitude != null && longitude != null) {
      return LatLng(latitude, longitude);
    }

    return null;
  }

  LatLng? _latLngFromValue(dynamic value) {
    if (value is GeoPoint) {
      return LatLng(value.latitude, value.longitude);
    }

    if (value is Map) {
      return _latLngFromMap(Map<String, dynamic>.from(value));
    }

    return null;
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  Future<void> _fitRouteInView() async {
    final controller = _mapController;
    final destination = _laundryLatLng;

    if (controller == null || destination == null) return;

    final points = <LatLng>[_pickupLatLng, ..._routePoints, destination];

    if (points.length < 2) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final latSpread = (maxLat - minLat).abs();
    final lngSpread = (maxLng - minLng).abs();

    if (latSpread < 0.00001 && lngSpread < 0.00001) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _pickupLatLng, zoom: 16),
        ),
      );
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 86));
    } catch (e) {
      debugPrint('Could not fit route bounds: $e');

      final midpoint = LatLng(
        (_pickupLatLng.latitude + destination.latitude) / 2,
        (_pickupLatLng.longitude + destination.longitude) / 2,
      );

      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: midpoint, zoom: 13.5),
        ),
      );
    }
  }

  bool _isFindingFlowStatus(String? status) {
    return _findingStatuses.contains(status);
  }

  bool _isActiveFlowStatus(String? status) {
    return _activeStatuses.contains(status);
  }

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  String _readString(dynamic value) {
    if (value is String) {
      return value.trim();
    }
    return '';
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bookingSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Set<Circle> _pickupCircles() {
    final circles = <Circle>{
      Circle(
        circleId: const CircleId('pickup_glow_outer'),
        center: _pickupLatLng,
        radius: 34,
        fillColor: const Color(0xFFE67E22).withOpacity(0.045),
        strokeColor: const Color(0xFFE67E22).withOpacity(0.12),
        strokeWidth: 1,
      ),
      Circle(
        circleId: const CircleId('pickup_glow_inner'),
        center: _pickupLatLng,
        radius: 14,
        fillColor: const Color(0xFFE67E22).withOpacity(0.07),
        strokeColor: const Color(0xFFE67E22).withOpacity(0.18),
        strokeWidth: 1,
      ),
    };

    final laundry = _laundryLatLng;

    if (_shouldShowLaundryDestination && laundry != null) {
      circles.add(
        Circle(
          circleId: const CircleId('laundry_destination_glow'),
          center: laundry,
          radius: 28,
          fillColor: _routeGreen.withOpacity(0.08),
          strokeColor: _routeGreen.withOpacity(0.34),
          strokeWidth: 1,
        ),
      );
    }

    return circles;
  }

  Set<Polyline> _routePolylines() {
    if (_routePoints.length < 2) return const <Polyline>{};

    return {
      // Soft dark underlay keeps the green route readable over pale roads
      // without making the line look heavy.
      Polyline(
        polylineId: const PolylineId('laundry_route_underlay'),
        points: _routePoints,
        color: const Color(0xFF111111).withOpacity(0.30),
        width: 9,
        zIndex: 1,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
      Polyline(
        polylineId: const PolylineId('laundry_route'),
        points: _routePoints,
        color: _routeGreen,
        width: 6,
        zIndex: 2,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  Set<Marker> _routeMarkers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('route_pickup'),
        position: _pickupLatLng,
        // Bottom-centre anchor keeps the static pin tip/focus ring attached
        // to the exact pickup coordinate.
        anchor: const Offset(0.5, 0.96),
        icon:
            _pickupMapMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: 'Pickup', snippet: widget.pickupTitle),
        zIndex: 4,
      ),
    };

    final laundry = _laundryLatLng;

    if (_shouldShowLaundryDestination && laundry != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('route_laundry'),
          position: laundry,
          // Bottom-centre anchor keeps the static pin tip/focus ring attached
          // to the exact laundry destination coordinate.
          anchor: const Offset(0.5, 0.96),
          icon:
              _laundryMapMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: (_assignedLaundryName ?? '').trim().isNotEmpty
                ? _assignedLaundryName!
                : 'Laundry',
            snippet: _routeDurationText == null
                ? (_isLaundryOfferStage ? 'Offer destination' : 'Drop-off')
                : '${_routeDurationText!} away',
          ),
          zIndex: 5,
        ),
      );
    }

    return markers;
  }

  Future<void> _goToPickup() async {
    if (_isRecentering) return;

    HapticFeedback.selectionClick();

    setState(() => _isRecentering = true);

    try {
      if (_hasVisibleRoute) {
        await _fitRouteInView();
      } else {
        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _pickupLatLng, zoom: 17),
          ),
        );
      }
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 220));

      if (mounted) {
        setState(() => _isRecentering = false);
      }
    }
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
    switch (_bookingStatus) {
      case 'cancelled':
        return 'Request cancelled';
      case 'no_laundry_found':
        return 'No laundry found';
      case 'awaiting_laundry_assignment':
        return 'Finding laundries';
      case 'offered_to_laundry':
        return 'Offer sent to laundry';
      case 'awaiting_laundry_acceptance':
        return 'Waiting for acceptance';
      case 'pending':
        return 'Pending in new orders';
      case 'looking_for_pickup_rider':
        return 'Laundry found';
      case 'pickup_rider_assigned':
        return 'Pickup rider assigned';
      case 'pickup_started':
        return 'Pickup started';
      case 'arrived_at_pickup':
        return 'Rider arrived at pickup';
      case 'arrived_at_laundry':
        return 'Arrived at laundry';
      case 'processing':
        return 'Processing';
      case 'ready_for_dropoff':
        return 'Ready for dropoff';
      case 'delivery_in_progress':
        return 'Delivery in progress';
      case 'completed':
        return 'Completed';
      default:
        return 'Finding laundries';
    }
  }

  String get _statusSubtitle {
    switch (_bookingStatus) {
      case 'cancelled':
        return 'This booking was cancelled.';

      case 'no_laundry_found':
        return 'No suitable laundry was found yet.';

      case 'awaiting_laundry_assignment':
        return 'We are checking nearby laundries that match your service.';

      case 'offered_to_laundry':
        if ((_assignedLaundryName ?? '').isNotEmpty) {
          return 'Offer has been sent to ${_assignedLaundryName!}.';
        }
        return 'Your request has been offered to a laundry.';

      case 'awaiting_laundry_acceptance':
        if ((_assignedLaundryName ?? '').isNotEmpty) {
          return 'Waiting for ${_assignedLaundryName!} to accept.';
        }
        return 'Waiting for a laundry to accept your request.';

      case 'pending':
        return 'Your request is still in the new orders queue.';

      case 'looking_for_pickup_rider':
        final laundryName = (_assignedLaundryName ?? '').trim();
        if (laundryName.isNotEmpty) {
          return '$laundryName accepted your request. Here is the route from your pickup point to the laundry.';
        }
        return 'A laundry accepted your request. Here is the route from your pickup point to the laundry.';

      case 'pickup_rider_assigned':
        return 'A pickup rider has been assigned.';

      case 'pickup_started':
        return 'Your clothes are being picked up.';

      case 'arrived_at_pickup':
        return 'The rider has arrived at the pickup location.';

      case 'arrived_at_laundry':
        return 'Your clothes arrived at the laundry.';

      case 'processing':
        return 'Your clothes are being processed.';

      case 'ready_for_dropoff':
        return 'Your order is ready for delivery.';

      case 'delivery_in_progress':
        return 'Your order is on the way.';

      case 'completed':
        return 'Your booking has been completed.';

      default:
        return 'Finding the best laundries nearby.';
    }
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
                  zoom: 16,
                ),
                circles: _pickupCircles(),
                polylines: _routePolylines(),
                markers: _routeMarkers(),
                // Reserve enough space above the fitted route for the
                // floating laundry/ETA bar. This keeps the laundry destination
                // pin visible instead of letting the bar sit on top of it.
                padding: _hasVisibleRoute
                    ? EdgeInsets.only(
                        top: 190,
                        bottom: _showingDetails ? 400 : 285,
                        left: 34,
                        right: 34,
                      )
                    : EdgeInsets.zero,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!mounted) return;

                    // Keep the native map camera centered on the TRUE pickup
                    // coordinate. The Flutter pin uses this exact same anchor.
                    await controller.moveCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(target: _pickupLatLng, zoom: 16),
                      ),
                    );

                    if (_hasVisibleRoute) {
                      await _fitRouteInView();
                    }
                  });
                },
              ),
            ),

            // Same subtle focus treatment used on PickupPreviewScreen.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  color: _showingDetails
                      ? Colors.black.withOpacity(0.055)
                      : Colors.transparent,
                ),
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
                    AnimatedScale(
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
                          small: true,
                          highlighted: _isRecentering,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_shouldShowLaundryDestination &&
                (_isLoadingRoute ||
                    _routeDurationText != null ||
                    _routeError != null))
              Positioned(
                top: MediaQuery.paddingOf(context).top + 70,
                left: 86,
                right: 86,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: _RouteSummaryPill(
                      key: ValueKey(
                        _isLoadingRoute
                            ? 'route_loading'
                            : '${_routeDurationText}_${_routeDistanceText}',
                      ),
                      laundryName: (_assignedLaundryName ?? '').trim(),
                      durationText: _routeDurationText,
                      distanceText: _routeDistanceText,
                      routeError: _routeError,
                      isLoading: _isLoadingRoute,
                    ),
                  ),
                ),
              ),

            // Pickup and laundry are now both static native GoogleMap markers.
            // This keeps both pins locked to their exact geographic coordinates
            // with no floating, drop, pulse, or other animation.

            // Bottom sheet stays shrink-wrapped to its actual content.
            //
            // Using Align here prevents the switcher from inheriting the full
            // Stack height. That was what allowed the white sheet to cover the
            // entire map in the no-laundry-found state.
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    fit: StackFit.loose,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
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
                        isStillFinding: _isStillFindingLaundry,
                        isNoLaundryFound: _bookingStatus == 'no_laundry_found',
                        onTryAgainTap: _tryAgain,
                        onSelectLaundryTap: _selectLaundryManually,
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

class _RouteSummaryPill extends StatelessWidget {
  final String laundryName;
  final String? durationText;
  final String? distanceText;
  final String? routeError;
  final bool isLoading;

  const _RouteSummaryPill({
    super.key,
    required this.laundryName,
    required this.durationText,
    required this.distanceText,
    required this.routeError,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final destinationName = laundryName.isNotEmpty
        ? laundryName
        : 'Laundry found';

    final hasRouteError = (routeError ?? '').trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1FA463).withOpacity(0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1FA463),
                      ),
                    ),
                  )
                : const Icon(
                    Icons.route_rounded,
                    color: Color(0xFF1FA463),
                    size: 19,
                  ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLoading
                      ? 'Building route…'
                      : hasRouteError
                      ? 'Route unavailable'
                      : destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoading
                      ? 'Pickup → laundry'
                      : hasRouteError
                      ? 'Check Routes API key / configuration'
                      : [
                          if ((durationText ?? '').isNotEmpty) durationText!,
                          if ((distanceText ?? '').isNotEmpty) distanceText!,
                        ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(0.52),
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

class _DirectionsRouteResult {
  final List<LatLng> points;
  final String durationText;
  final String distanceText;

  const _DirectionsRouteResult({
    required this.points,
    required this.durationText,
    required this.distanceText,
  });
}

class _DirectionsRouteService {
  const _DirectionsRouteService._();

  /// Modern Google Maps Platform Routes API (v2).
  ///
  /// This uses:
  /// POST https://routes.googleapis.com/directions/v2:computeRoutes
  ///
  /// Requested fields:
  /// - routes.duration
  /// - routes.distanceMeters
  /// - routes.polyline.encodedPolyline
  static Future<_DirectionsRouteResult> fetchDrivingRoute({
    required LatLng origin,
    required LatLng destination,
    required String apiKey,
  }) async {
    final uri = Uri.parse(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
    );

    final requestBody = <String, dynamic>{
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          },
        },
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          },
        },
      },
      'travelMode': 'DRIVE',
      'routingPreference': 'TRAFFIC_AWARE',
      'computeAlternativeRoutes': false,
      'routeModifiers': {
        'avoidTolls': false,
        'avoidHighways': false,
        'avoidFerries': false,
      },
      'languageCode': 'en-US',
      'units': 'METRIC',
    };

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'routes.duration,'
                'routes.distanceMeters,'
                'routes.polyline.encodedPolyline',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic decodedBody = response.body.trim().isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(response.body);

    final body = decodedBody is Map<String, dynamic>
        ? decodedBody
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'];
      String message = 'Routes HTTP ${response.statusCode}';

      if (error is Map) {
        final errorMap = Map<String, dynamic>.from(error);
        final apiMessage = (errorMap['message'] ?? '').toString().trim();
        final status = (errorMap['status'] ?? '').toString().trim();

        if (apiMessage.isNotEmpty) {
          message = status.isEmpty ? apiMessage : '$status: $apiMessage';
        }
      }

      throw Exception(message);
    }

    final routes = body['routes'];

    if (routes is! List || routes.isEmpty) {
      throw Exception('Routes API returned no driving route.');
    }

    final route = Map<String, dynamic>.from(routes.first as Map);

    final polylineMap = route['polyline'];

    if (polylineMap is! Map) {
      throw Exception('Routes API polyline was missing.');
    }

    final encoded = (polylineMap['encodedPolyline'] ?? '').toString().trim();

    if (encoded.isEmpty) {
      throw Exception('Routes API polyline was empty.');
    }

    final distanceMeters = _asInt(route['distanceMeters']);
    final durationSeconds = _parseDurationSeconds(
      route['duration']?.toString(),
    );

    final points = _decodePolyline(encoded);

    if (points.length < 2) {
      throw Exception(
        'Decoded Routes API polyline did not contain enough points.',
      );
    }

    return _DirectionsRouteResult(
      points: points,
      durationText: durationSeconds == null
          ? 'Route ready'
          : _formatDuration(durationSeconds),
      distanceText: distanceMeters == null
          ? ''
          : _formatDistance(distanceMeters),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// Routes API returns protobuf Duration strings such as:
  /// "165s", "165.4s", etc.
  static int? _parseDurationSeconds(String? raw) {
    final value = (raw ?? '').trim();

    if (value.isEmpty || !value.endsWith('s')) {
      return null;
    }

    final numberPart = value.substring(0, value.length - 1);

    final seconds = double.tryParse(numberPart);
    if (seconds == null) return null;

    return seconds.round();
  }

  static String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) {
      return '< 1 min';
    }

    final totalMinutes = (totalSeconds / 60).ceil();

    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (minutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${minutes}m';
  }

  static String _formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters m';
    }

    final kilometres = meters / 1000;

    if (kilometres < 10) {
      return '${kilometres.toStringAsFixed(1)} km';
    }

    return '${kilometres.toStringAsFixed(0)} km';
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];

    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      var result = 0;
      var shift = 0;
      int byte;

      do {
        if (index >= encoded.length) {
          throw const FormatException('Invalid encoded route polyline.');
        }

        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final latitudeDelta = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      latitude += latitudeDelta;

      result = 0;
      shift = 0;

      do {
        if (index >= encoded.length) {
          throw const FormatException('Invalid encoded route polyline.');
        }

        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      final longitudeDelta = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      longitude += longitudeDelta;

      points.add(LatLng(latitude / 1E5, longitude / 1E5));
    }

    return points;
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

    final updateData = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'cancelled') {
      updateData['timeline.cancelledAt'] = FieldValue.serverTimestamp();
      updateData['laundryOffer.offeredLaundryId'] = null;
      updateData['laundryOffer.offeredAt'] = null;
      updateData['laundryOffer.offerExpiresAt'] = null;
    }

    batch.update(booking, updateData);

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
  final bool isStillFinding;
  final bool isNoLaundryFound;
  final VoidCallback onTryAgainTap;
  final VoidCallback onSelectLaundryTap;

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
    required this.isStillFinding,
    required this.isNoLaundryFound,
    required this.onTryAgainTap,
    required this.onSelectLaundryTap,
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
    final screenHeight = MediaQuery.sizeOf(context).height;

    return ConstrainedBox(
      constraints: BoxConstraints(
        // Normal status/no-laundry states remain naturally compact.
        // Details can grow, but can never swallow the whole map.
        maxHeight: widget.isShowingDetails
            ? screenHeight * 0.72
            : screenHeight * 0.48,
      ),
      child: AnimatedSize(
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
                    onTap: widget.isShowingDetails
                        ? widget.onCollapseTap
                        : null,
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
                    isStillFinding: widget.isStillFinding,
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
                                      icon: Icons.store,
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
                        : widget.isNoLaundryFound
                        ? Row(
                            key: const ValueKey('no_laundry_found_actions'),
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.refresh_rounded,
                                  label: 'Try again',
                                  onTap: widget.onTryAgainTap,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.store,
                                  label: 'Select manually',
                                  onTap: widget.onSelectLaundryTap,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('default_actions'),
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

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

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
          // Soft contact shadow.
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

          // Thin orange pickup radar pulse.
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

          // Floating pin + label.
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

                  // Same scooter marker used on PickupPreviewScreen.
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

                  // Pin stem. No black ball under the stem.
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
