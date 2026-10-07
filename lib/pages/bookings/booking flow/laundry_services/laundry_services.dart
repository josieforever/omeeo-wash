import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart'
    show
        FirebaseFirestore,
        FieldValue,
        SetOptions,
        CollectionReference,
        QuerySnapshot,
        Timestamp,
        GeoPoint,
        DocumentSnapshot;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' hide Marker;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/location_picker.dart';
import 'package:omeeowash/pages/profile/profile_screen.dart';
import 'active_booking_screen.dart';
import 'active_laundry_order_stage.dart';
import 'closest_laundries_screen.dart';
import 'laundry_services_date_time.dart';
import 'manual_laundry_details_request_screen.dart';
import 'service_review.dart' show PickedLocationResult, PickupPreviewScreen;

enum _LocationSheetMode { pickup, changeCurrentLocation }

class LaundryServicesScreen extends StatefulWidget {
  final String? serviceType;

  const LaundryServicesScreen({super.key, this.serviceType});

  @override
  State<LaundryServicesScreen> createState() => _LaundryServicesScreenState();
}

class _LaundryServicesScreenState extends State<LaundryServicesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String serviceType = 'none';
  int? duration;
  String? expandedService;
  Set<String> selectedAddOns = {};

  static const String washFold = ' Wash & Fold  ';
  static const String ironingPressing = ' Wash & Iron  ';

  static const String _googleApiKey = 'AIzaSyABK1eJNZmo0VNvGabx4JZDTQvPppSpnA0';

  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();

  bool _isSearchingLocations = false;
  bool _isApplyingCurrentLocation = false;
  String? _selectedPickupAddress;

  List<PlaceSuggestion> _predictions = [];

  @override
  void initState() {
    super.initState();

    final initialType = widget.serviceType;
    if (initialType != null && initialType.trim().isNotEmpty) {
      serviceType = initialType;
      duration = _durationForService(initialType);
      expandedService = initialType;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      serviceType != 'none' &&
      duration != null &&
      (_selectedPickupAddress?.trim().isNotEmpty ?? false);

  int? _durationForService(String type) {
    switch (type) {
      case washFold:
        return 30;
      case ironingPressing:
        return 120;
      default:
        return null;
    }
  }

  Future<void> _onSelect(String type) async {
    setState(() {
      serviceType = type;
      duration = _durationForService(type);
      expandedService = type;
    });

    await _showLocationSheet();
  }

  void _goNext() {
    final selectedDuration = duration;

    if (!_canContinue || selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a service and choose a pickup location.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LaundryServicestDateScreen(
          serviceType: serviceType,
          duration: selectedDuration,
          addOns: selectedAddOns,
        ),
      ),
    );
  }

  Future<void> _openClosestLaundriesScreen() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data() ?? <String, dynamic>{};
    final lastLocation = userData['lastCurrentLocation'];

    double? latitude;
    double? longitude;

    if (lastLocation is Map) {
      final map = Map<String, dynamic>.from(lastLocation);

      final lat = map['latitude'];
      final lng = map['longitude'];

      if (lat is num && lng is num) {
        latitude = lat.toDouble();
        longitude = lng.toDouble();
      } else {
        final geopoint = map['geopoint'];
        if (geopoint is GeoPoint) {
          latitude = geopoint.latitude;
          longitude = geopoint.longitude;
        }
      }
    }

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your current location.')),
      );
      return;
    }

    final selectedServiceType = _normalizeServiceType(serviceType);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClosestLaundriesScreen(
          bookingId: '',
          pickupTitle: _selectedPickupAddress ?? 'Current location',
          pickupLatitude: latitude!,
          pickupLongitude: longitude!,
          selectedServiceType: selectedServiceType,
          selectedAddOns: selectedAddOns.toList(),
        ),
      ),
    );
  }

  String _normalizeServiceType(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized.contains('iron')) return 'wash_iron';
    if (normalized.contains('fold')) return 'wash_fold';

    return 'wash_fold';
  }

  Future<void> _showLocationSheet({
    _LocationSheetMode mode = _LocationSheetMode.pickup,
    _ResolvedMapLocation? currentLocation,
  }) async {
    if (!mounted) return;

    final isChangingCurrentLocation =
        mode == _LocationSheetMode.changeCurrentLocation;

    final previousSearchText = _locationController.text;
    final previousSelectedPickupAddress = _selectedPickupAddress;

    bool hasEditedChangeQuery = false;

    if (isChangingCurrentLocation && currentLocation != null) {
      _locationController.text = currentLocation.addressLine;
      _locationController.selection = TextSelection.collapsed(
        offset: _locationController.text.length,
      );
      _predictions = [];
      _isSearchingLocations = false;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.18),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> searchPlacesInSheet(String input) async {
              hasEditedChangeQuery = true;

              final query = input.trim();

              if (query.isEmpty) {
                setModalState(() {
                  _predictions = [];
                  _isSearchingLocations = false;
                });
                return;
              }

              setModalState(() {
                _isSearchingLocations = true;
              });

              try {
                final uri = Uri.parse(
                  'https://maps.googleapis.com/maps/api/place/autocomplete/json'
                  '?input=${Uri.encodeQueryComponent(query)}'
                  '&key=$_googleApiKey'
                  '&components=country:gh',
                );

                final response = await http.get(uri);
                final data = jsonDecode(response.body) as Map<String, dynamic>;

                debugPrint('Places response: $data');

                final status = (data['status'] ?? '').toString();
                final errorMessage = (data['error_message'] ?? '').toString();

                if (response.statusCode != 200) {
                  throw Exception('HTTP ${response.statusCode}');
                }

                if (status != 'OK' && status != 'ZERO_RESULTS') {
                  throw Exception(
                    errorMessage.isNotEmpty ? '$status: $errorMessage' : status,
                  );
                }

                final predictions =
                    (data['predictions'] as List<dynamic>? ?? [])
                        .map(
                          (e) => PlaceSuggestion.fromJson(
                            e as Map<String, dynamic>,
                          ),
                        )
                        .toList();

                if (!mounted) return;

                setModalState(() {
                  _predictions = predictions;
                  _isSearchingLocations = false;
                });
              } catch (e) {
                debugPrint('Places autocomplete failed: $e');

                if (!mounted) return;

                setModalState(() {
                  _predictions = [];
                  _isSearchingLocations = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not fetch locations: $e')),
                );
              }
            }

            void clearSearchInSheet() {
              hasEditedChangeQuery = true;
              _locationController.clear();

              setModalState(() {
                if (!isChangingCurrentLocation) {
                  _selectedPickupAddress = null;
                }

                _predictions = [];
                _isSearchingLocations = false;
              });
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _locationFocusNode.requestFocus();
              }
            });

            final savedLocationsQuery =
                isChangingCurrentLocation && !hasEditedChangeQuery
                ? ''
                : _locationController.text;

            return SafeArea(
              top: false,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.95,
                minChildSize: 0.95,
                maxChildSize: 0.95,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 24,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    child: CustomScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              const SizedBox(height: 0),
                              /*  GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => Navigator.of(sheetContext).pop(),
                                child: Lottie.asset(
                                  'assets/animations/breathing_pill.json',
                                  width: 50,
                                  height: 30,
                                  fit: BoxFit.contain,
                                ),
                              ), */
                            ],
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 24),
                          sliver: SliverToBoxAdapter(
                            child: _buildSearchSection(
                              sheetContext,
                              onSearchChanged: searchPlacesInSheet,
                              onClearSearch: clearSearchInSheet,
                              rebuildSheet: setModalState,
                              mode: mode,
                              savedLocationsQuery: savedLocationsQuery,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );

    if (isChangingCurrentLocation && mounted) {
      setState(() {
        _locationController.text = previousSearchText;
        _selectedPickupAddress = previousSelectedPickupAddress;
        _predictions = [];
        _isSearchingLocations = false;
        _isApplyingCurrentLocation = false;
      });
    }
  }

  Future<void> _searchPlaces(String input) async {
    final query = input.trim();

    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearchingLocations = false;
      });
      return;
    }

    setState(() {
      _isSearchingLocations = true;
    });

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeQueryComponent(query)}'
        '&key=$_googleApiKey'
        '&components=country:gh',
      );

      final response = await http.get(uri);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint('Places response: $data');

      final status = (data['status'] ?? '').toString();
      final errorMessage = (data['error_message'] ?? '').toString();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        throw Exception(
          errorMessage.isNotEmpty ? '$status: $errorMessage' : status,
        );
      }

      final predictions = (data['predictions'] as List<dynamic>? ?? [])
          .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      setState(() {
        _predictions = predictions;
        _isSearchingLocations = false;
      });
    } catch (e) {
      debugPrint('Places autocomplete failed: $e');

      if (!mounted) return;

      setState(() {
        _predictions = [];
        _isSearchingLocations = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not fetch locations: $e')));
    }
  }

  void _selectPrediction(PlaceSuggestion place, {BuildContext? modalContext}) {
    setState(() {
      _selectedPickupAddress = place.description;
      _locationController.text = place.description;
      _predictions = [];
    });

    _locationFocusNode.unfocus();

    if (modalContext != null && Navigator.of(modalContext).canPop()) {
      Navigator.of(modalContext).pop();
    }
  }

  Future<void> _openPickupPreviewFromSuggestion(
    PlaceSuggestion place, {
    BuildContext? modalContext,
  }) async {
    try {
      final detailsUri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${Uri.encodeQueryComponent(place.placeId)}'
        '&fields=formatted_address,geometry,name'
        '&key=$_googleApiKey',
      );

      final response = await http.get(detailsUri);
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      debugPrint('Place details response: $data');

      final status = (data['status'] ?? '').toString();
      final errorMessage = (data['error_message'] ?? '').toString();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      if (status != 'OK') {
        throw Exception(
          errorMessage.isNotEmpty ? '$status: $errorMessage' : status,
        );
      }

      final result = data['result'] as Map<String, dynamic>? ?? {};
      final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
      final location = geometry['location'] as Map<String, dynamic>? ?? {};

      final double latitude = (location['lat'] as num?)?.toDouble() ?? 0.0;
      final double longitude = (location['lng'] as num?)?.toDouble() ?? 0.0;
      final String addressLine =
          (result['formatted_address'] ?? place.description).toString();

      if (latitude == 0.0 && longitude == 0.0) {
        throw Exception('Could not resolve coordinates for this location.');
      }

      setState(() {
        _selectedPickupAddress = addressLine;
        _locationController.clear();
        _predictions = [];
      });

      _locationFocusNode.unfocus();

      if (modalContext != null && Navigator.of(modalContext).canPop()) {
        Navigator.of(modalContext).pop();
      }

      if (!mounted) return;

      final pickedLocation = PickedLocationResult(
        addressLine: addressLine,
        latitude: latitude,
        longitude: longitude,
        subtitle: place.secondaryText,
        serviceType: '',
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PickupPreviewScreen(
            pickupLocation: pickedLocation,
            selectedService: serviceType,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Failed to open pickup preview from suggestion: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open selected location: $e')),
      );
    }
  }

  Future<void> _openPickupPreviewFromSavedLocation(
    _SavedLocation place, {
    BuildContext? modalContext,
  }) async {
    setState(() {
      _selectedPickupAddress = place.addressLine;
      _locationController.clear();
      _predictions = [];
    });

    _locationFocusNode.unfocus();

    if (modalContext != null && Navigator.of(modalContext).canPop()) {
      Navigator.of(modalContext).pop();
    }

    if (!mounted) return;

    final pickedLocation = PickedLocationResult(
      addressLine: place.addressLine,
      latitude: place.latitude,
      longitude: place.longitude,
      subtitle: place.name,
      serviceType: '',
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PickupPreviewScreen(
          pickupLocation: pickedLocation,
          selectedService: serviceType,
        ),
      ),
    );
  }

  Future<void> _changeCurrentLocation(
    _ResolvedMapLocation currentLocation,
  ) async {
    await _showLocationSheet(
      mode: _LocationSheetMode.changeCurrentLocation,
      currentLocation: currentLocation,
    );
  }

  Future<_ResolvedMapLocation> _resolveSuggestionToLocation(
    PlaceSuggestion place,
  ) async {
    final detailsUri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=${Uri.encodeQueryComponent(place.placeId)}'
      '&fields=formatted_address,geometry,name'
      '&key=$_googleApiKey',
    );

    final response = await http.get(detailsUri);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final status = (data['status'] ?? '').toString();
    final errorMessage = (data['error_message'] ?? '').toString();

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    if (status != 'OK') {
      throw Exception(
        errorMessage.isNotEmpty ? '$status: $errorMessage' : status,
      );
    }

    final result = data['result'] as Map<String, dynamic>? ?? {};
    final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
    final location = geometry['location'] as Map<String, dynamic>? ?? {};

    final latitude = (location['lat'] as num?)?.toDouble();
    final longitude = (location['lng'] as num?)?.toDouble();

    if (latitude == null || longitude == null) {
      throw Exception('Selected location has no coordinates.');
    }

    final addressLine = (result['formatted_address'] ?? place.description)
        .toString()
        .trim();

    final locationName = (result['name'] ?? place.mainText).toString().trim();

    return _ResolvedMapLocation(
      latitude: latitude,
      longitude: longitude,
      addressLine: addressLine.isEmpty ? place.description : addressLine,
      locationName: locationName.isEmpty
          ? _locationNameFromAddress(place.description)
          : locationName,
    );
  }

  Future<void> _applySuggestionAsCurrentLocation(
    PlaceSuggestion place, {
    required BuildContext modalContext,
    required void Function(VoidCallback fn) rebuildSheet,
  }) async {
    if (_isApplyingCurrentLocation) return;

    _locationFocusNode.unfocus();

    rebuildSheet(() {
      _isApplyingCurrentLocation = true;
    });

    try {
      final resolved = await _resolveSuggestionToLocation(place);

      await _commitCurrentLocation(resolved, source: 'google_places');

      if (!mounted || !modalContext.mounted) return;

      Navigator.of(modalContext).pop();
    } catch (e) {
      debugPrint('Failed to change current location from search: $e');

      if (!mounted || !modalContext.mounted) return;

      rebuildSheet(() {
        _isApplyingCurrentLocation = false;
      });

      ScaffoldMessenger.of(modalContext).showSnackBar(
        const SnackBar(
          content: Text('Could not update your location. Please try again.'),
        ),
      );
    }
  }

  Future<void> _applySavedPlaceAsCurrentLocation(
    _SavedLocation place, {
    required BuildContext modalContext,
    required void Function(VoidCallback fn) rebuildSheet,
  }) async {
    if (_isApplyingCurrentLocation) return;

    _locationFocusNode.unfocus();

    rebuildSheet(() {
      _isApplyingCurrentLocation = true;
    });

    try {
      await _commitCurrentLocation(
        _ResolvedMapLocation(
          latitude: place.latitude,
          longitude: place.longitude,
          addressLine: place.addressLine,
          locationName: place.name,
        ),
        source: 'saved_place',
      );

      if (!mounted || !modalContext.mounted) return;

      Navigator.of(modalContext).pop();
    } catch (e) {
      debugPrint('Failed to change current location from saved place: $e');

      if (!mounted || !modalContext.mounted) return;

      rebuildSheet(() {
        _isApplyingCurrentLocation = false;
      });

      ScaffoldMessenger.of(modalContext).showSnackBar(
        const SnackBar(
          content: Text('Could not update your location. Please try again.'),
        ),
      );
    }
  }

  Future<void> _useDeviceLocationAsCurrentLocation({
    required BuildContext modalContext,
    required void Function(VoidCallback fn) rebuildSheet,
  }) async {
    if (_isApplyingCurrentLocation) return;

    _locationFocusNode.unfocus();

    rebuildSheet(() {
      _isApplyingCurrentLocation = true;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is unavailable.');
      }

      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        throw Exception('Could not get your current location.');
      }

      final resolved = await _reverseGeocodeLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await _commitCurrentLocation(resolved, source: 'device_gps');

      if (!mounted || !modalContext.mounted) return;

      Navigator.of(modalContext).pop();
    } catch (e) {
      debugPrint('Failed to use device location: $e');

      if (!mounted || !modalContext.mounted) return;

      rebuildSheet(() {
        _isApplyingCurrentLocation = false;
      });

      ScaffoldMessenger.of(modalContext).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openMapForCurrentLocationChange({
    required BuildContext modalContext,
    required void Function(VoidCallback fn) rebuildSheet,
  }) async {
    if (_isApplyingCurrentLocation) return;

    _locationFocusNode.unfocus();

    final result = await Navigator.of(context).push<PickedLocationResult>(
      MaterialPageRoute(
        builder: (_) => GoogleMapLocationPickerScreen(serviceType: serviceType),
      ),
    );

    if (!mounted || result == null || !modalContext.mounted) {
      if (mounted && modalContext.mounted) {
        _locationFocusNode.requestFocus();
      }
      return;
    }

    rebuildSheet(() {
      _isApplyingCurrentLocation = true;
    });

    try {
      await _commitCurrentLocation(
        _ResolvedMapLocation(
          latitude: result.latitude,
          longitude: result.longitude,
          addressLine: result.addressLine,
          locationName: result.subtitle.trim().isNotEmpty
              ? result.subtitle.trim()
              : _locationNameFromAddress(result.addressLine),
        ),
        source: 'map_picker',
      );

      if (!mounted || !modalContext.mounted) return;

      Navigator.of(modalContext).pop();
    } catch (e) {
      debugPrint('Failed to change current location from map: $e');

      if (!mounted || !modalContext.mounted) return;

      rebuildSheet(() {
        _isApplyingCurrentLocation = false;
      });

      ScaffoldMessenger.of(modalContext).showSnackBar(
        const SnackBar(
          content: Text('Could not update your location. Please try again.'),
        ),
      );
    }
  }

  Future<void> _commitCurrentLocation(
    _ResolvedMapLocation location, {
    required String source,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please sign in first.');
    }

    final now = DateTime.now();

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final writeFuture = userRef.set({
      'lastCurrentLocation': {
        'addressLine': location.addressLine,
        'name': location.locationName,
        'placeName': location.locationName,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'geopoint': GeoPoint(location.latitude, location.longitude),
        'source': source,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Firestore applies the mutation to its local cache immediately. That is
    // what makes CurrentUserLocationText under "Hello, Chris" update at once.
    // Do not keep the UI stuck if the remote acknowledgement is slow/offline.
    try {
      await writeFuture.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      debugPrint(
        'ℹ️ Current-location write queued locally; remote sync is pending.',
      );
    }

    // Keep the startup fallback in main.dart synchronized with the manually
    // selected location. A local-storage problem must not undo a successful
    // current-location change.
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'last_current_location_${user.uid}';

      await Future.wait([
        prefs.setString('${prefix}_addressLine', location.addressLine),
        prefs.setString('${prefix}_placeName', location.locationName),
        prefs.setString('${prefix}_locality', ''),
        prefs.setDouble('${prefix}_latitude', location.latitude),
        prefs.setDouble('${prefix}_longitude', location.longitude),
        prefs.setInt('${prefix}_updatedAtMs', now.millisecondsSinceEpoch),
      ]);
    } catch (e) {
      debugPrint('⚠️ Could not update local location fallback: $e');
    }

    debugPrint('✅ Current location changed to: ${location.addressLine}');
  }

  String _locationNameFromAddress(String address) {
    final clean = address.trim();

    if (clean.isEmpty) return 'Selected location';

    final first = clean.split(',').first.trim();
    return first.isEmpty ? 'Selected location' : first;
  }

  Future<void> _openMapPicker({BuildContext? modalContext}) async {
    if (modalContext != null && Navigator.of(modalContext).canPop()) {
      Navigator.of(modalContext).pop();
    }

    final result = await Navigator.of(context).push<PickedLocationResult>(
      MaterialPageRoute(
        builder: (_) => GoogleMapLocationPickerScreen(serviceType: serviceType),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _selectedPickupAddress = result.addressLine;
        _locationController.text = result.addressLine;
        _predictions = [];
      });
    }
  }

  Widget _buildSearchSection(
    BuildContext modalContext, {
    required ValueChanged<String> onSearchChanged,
    required VoidCallback onClearSearch,
    required void Function(VoidCallback fn) rebuildSheet,
    required _LocationSheetMode mode,
    required String savedLocationsQuery,
  }) {
    final isChangingCurrentLocation =
        mode == _LocationSheetMode.changeCurrentLocation;

    final isBusy = _isSearchingLocations || _isApplyingCurrentLocation;

    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            child: Lottie.asset(
              'assets/animations/washing_machine_icon.json',
              width: 400,
              height: MediaQuery.of(context).size.height * 0.7,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.7,
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(40, 0, 0, 0),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _locationController,
                        focusNode: _locationFocusNode,
                        enabled: !_isApplyingCurrentLocation,
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: isChangingCurrentLocation
                              ? 'Search for a location'
                              : 'Pickup location',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: Transform.scale(
                            scale: 0.60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(1),
                              child: Icon(
                                isChangingCurrentLocation
                                    ? Icons.location_on_rounded
                                    : Icons.moped,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          suffixIcon: isBusy
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFE67E22),
                                    ),
                                  ),
                                )
                              : (_locationController.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: onClearSearch,
                                        icon: const Icon(Icons.close_rounded),
                                      )
                                    : null),
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFFFF4F8),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: _isApplyingCurrentLocation
                          ? null
                          : () {
                              if (isChangingCurrentLocation) {
                                _openMapForCurrentLocationChange(
                                  modalContext: modalContext,
                                  rebuildSheet: rebuildSheet,
                                );
                              } else {
                                _openMapPicker(modalContext: modalContext);
                              }
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(40, 0, 0, 0),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(
                            child: Icon(Icons.map, color: Color(0xFFE67E22)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (isChangingCurrentLocation) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    enabled: !_isApplyingCurrentLocation,
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECDB),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: Color(0xFFE67E22),
                      ),
                    ),
                    title: const Text(
                      'Your location',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Pickup at your GPS location',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.black38,
                    ),
                    onTap: _isApplyingCurrentLocation
                        ? null
                        : () => _useDeviceLocationAsCurrentLocation(
                            modalContext: modalContext,
                            rebuildSheet: rebuildSheet,
                          ),
                  ),
                ),
              ],

              _SavedLocationsSearchSuggestions(
                query: savedLocationsQuery,
                onTap: (place) {
                  if (isChangingCurrentLocation) {
                    _applySavedPlaceAsCurrentLocation(
                      place,
                      modalContext: modalContext,
                      rebuildSheet: rebuildSheet,
                    );
                  } else {
                    _openPickupPreviewFromSavedLocation(
                      place,
                      modalContext: modalContext,
                    );
                  }
                },
              ),
              if (_predictions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _predictions.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 0.5,
                      endIndent: 20,
                      indent: 20,
                      color: Color.fromARGB(255, 211, 211, 211),
                    ),
                    itemBuilder: (context, index) {
                      final place = _predictions[index];

                      return ListTile(
                        enabled: !_isApplyingCurrentLocation,
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFE67E22),
                        ),
                        title: Text(
                          place.mainText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          place.secondaryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: _isApplyingCurrentLocation
                            ? null
                            : () {
                                if (isChangingCurrentLocation) {
                                  _applySuggestionAsCurrentLocation(
                                    place,
                                    modalContext: modalContext,
                                    rebuildSheet: rebuildSheet,
                                  );
                                } else {
                                  _openPickupPreviewFromSuggestion(
                                    place,
                                    modalContext: modalContext,
                                  );
                                }
                              },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _shouldExit = false;

  Future<void> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exit App',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Are you sure you want to close the app?",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "No",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              "Yes",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    setState(() {
      _shouldExit = result ?? false;
    });

    if (_shouldExit) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, result) {
        if (!didPop) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        key: _scaffoldKey,
        endDrawerEnableOpenDragGesture: false,
        backgroundColor: Colors.white,
        endDrawer: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: const Drawer(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: ProfileScreen(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              'Hello, ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Chris',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: Color.fromARGB(255, 188, 113, 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        CurrentUserLocationText(
                          onChangeLocation: (currentLocation) async {
                            await _changeCurrentLocation(currentLocation);
                          },
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECDB),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.sort,
                          color: Color.fromARGB(255, 0, 0, 0),
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                SearchEventsBar(
                  controller: _locationController,
                  onTap: _showLocationSheet,
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ServiceTile(
                      title: 'Wash & Fold',
                      imageAsset: 'assets/images/wash_foldd.png',
                      onTap: () => _onSelect(washFold),
                    ),
                    ServiceTile(
                      title: 'Wash & Iron',
                      imageAsset: 'assets/images/wash_ironn.png',
                      onTap: () => _onSelect(ironingPressing),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const CustomerActiveBookingsPreview(),

                const SizedBox(height: 20),

                PromoImageCarousel(
                  imagePaths: const [
                    'assets/images/promo_banner.png',
                    'assets/images/promo_banner_inverse.png',
                  ],
                  height: 140,
                  onTap: (index) {
                    debugPrint('Tapped banner $index');
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _openClosestLaundriesScreen,
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),

                const SizedBox(height: 20),

                CurrentLocationClosestLaundryPreview(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CurrentUserLocationText extends StatelessWidget {
  final Future<void> Function(_ResolvedMapLocation location)? onChangeLocation;

  const CurrentUserLocationText({super.key, this.onChangeLocation});

  static const Color primaryOrange = Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final lastLocationRaw = data['lastCurrentLocation'];
        final lastLocation = lastLocationRaw is Map
            ? Map<String, dynamic>.from(lastLocationRaw)
            : <String, dynamic>{};

        final addressLine =
            lastLocation['addressLine']?.toString().trim() ?? '';

        final latitude = _readDouble(
          lastLocation['latitude'] ?? lastLocation['lat'],
        );

        final longitude = _readDouble(
          lastLocation['longitude'] ??
              lastLocation['lng'] ??
              lastLocation['lon'],
        );

        final locationName = _firstNonEmpty([
          lastLocation['name']?.toString() ?? '',
          lastLocation['title']?.toString() ?? '',
          lastLocation['placeName']?.toString() ?? '',
          _shortAddress(addressLine),
        ]);

        String locationText = 'Getting your location...';

        if (snapshot.hasError) {
          locationText = 'Location unavailable';
        } else if (snapshot.hasData) {
          locationText = addressLine.isNotEmpty
              ? addressLine
              : 'Location unavailable';
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (addressLine.isEmpty &&
                (latitude == null || longitude == null)) {
              return;
            }

            _showLocationBottomSheet(
              context: context,
              userId: user.uid,
              locationName: locationName,
              addressLine: addressLine,
              latitude: latitude,
              longitude: longitude,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 15,
                  color: primaryOrange,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 230),
                  child: Text(
                    locationText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 17,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLocationBottomSheet({
    required BuildContext context,
    required String userId,
    required String locationName,
    required String addressLine,
    required double? latitude,
    required double? longitude,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.48),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      isDismissible: true,
      builder: (sheetContext) {
        return _CurrentLocationBottomSheet(
          locationName: locationName,
          addressLine: addressLine,
          latitude: latitude,
          longitude: longitude,
          onSaveCurrentLocation: (resolvedLocation) async {
            // resolvedLocation is the same Firestore-backed location currently
            // displayed in the header. No second GPS request happens here.
            Navigator.of(sheetContext).pop();

            await Future<void>.delayed(const Duration(milliseconds: 180));

            if (!context.mounted) return;

            await _openSaveLocationFlow(
              context: context,
              userId: userId,
              locationName: resolvedLocation.locationName,
              addressLine: resolvedLocation.addressLine,
              latitude: resolvedLocation.latitude,
              longitude: resolvedLocation.longitude,
            );
          },
          onChangeLocation: () {
            Navigator.of(sheetContext).pop();

            Future<void>.delayed(const Duration(milliseconds: 150), () async {
              if (!context.mounted) return;

              if (latitude == null || longitude == null) return;

              await onChangeLocation?.call(
                _ResolvedMapLocation(
                  latitude: latitude,
                  longitude: longitude,
                  addressLine: addressLine,
                  locationName: locationName,
                ),
              );
            });
          },
        );
      },
    );
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) return clean;
    }
    return 'Your location';
  }

  static String _shortAddress(String address) {
    if (address.trim().isEmpty) return '';
    final parts = address.split(',');
    return parts.isEmpty ? address : parts.first.trim();
  }
}

/* -------------------------------------------------------------------------- */
/*                         CURRENT LOCATION BOTTOM SHEET                       */
/* -------------------------------------------------------------------------- */

class _CurrentLocationBottomSheet extends StatefulWidget {
  final String locationName;
  final String addressLine;
  final double? latitude;
  final double? longitude;
  final Future<void> Function(_ResolvedMapLocation location)
  onSaveCurrentLocation;
  final VoidCallback onChangeLocation;

  const _CurrentLocationBottomSheet({
    required this.locationName,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    required this.onSaveCurrentLocation,
    required this.onChangeLocation,
  });

  @override
  State<_CurrentLocationBottomSheet> createState() =>
      _CurrentLocationBottomSheetState();
}

class _CurrentLocationBottomSheetState
    extends State<_CurrentLocationBottomSheet> {
  static const Color primaryOrange = Color(0xFFE67E22);
  static const Color softGrey = Color(0xFFF5F5F5);

  bool get _hasCoordinates =>
      widget.latitude != null && widget.longitude != null;

  LatLng? get _position {
    if (!_hasCoordinates) return null;
    return LatLng(widget.latitude!, widget.longitude!);
  }

  Future<void> _handleSaveLocation() async {
    // IMPORTANT:
    // Do NOT request the phone's GPS again here. The location displayed at the
    // top of LaundryServicesScreen already comes from users/{uid}.lastCurrentLocation.
    // Reuse that exact address + coordinates so opening the save flow is instant.
    if (!_hasCoordinates) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Current location coordinates are unavailable.'),
          ),
        );
      return;
    }

    final latitude = widget.latitude!;
    final longitude = widget.longitude!;
    final addressLine = widget.addressLine.trim().isNotEmpty
        ? widget.addressLine.trim()
        : '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    final locationName = widget.locationName.trim().isNotEmpty
        ? widget.locationName.trim()
        : _fallbackLocationName(addressLine);

    await widget.onSaveCurrentLocation(
      _ResolvedMapLocation(
        latitude: latitude,
        longitude: longitude,
        addressLine: addressLine,
        locationName: locationName,
      ),
    );
  }

  String _fallbackLocationName(String addressLine) {
    final parts = addressLine.split(',');
    if (parts.isEmpty) return 'Your location';

    final first = parts.first.trim();
    return first.isEmpty ? 'Your location' : first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8D8D8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'YOUR LOCATION',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMap(),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.locationName.isEmpty
                            ? 'Your location'
                            : widget.locationName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.addressLine.isEmpty
                            ? 'Location address unavailable'
                            : widget.addressLine,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                _LocationActionTile(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Save location for future use',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black54,
                  ),
                  onTap: _hasCoordinates ? _handleSaveLocation : null,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                _LocationActionTile(
                  icon: Icons.edit_outlined,
                  title: 'Change location',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black54,
                  ),
                  onTap: widget.onChangeLocation,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (!_hasCoordinates) {
      return Container(
        height: 145,
        width: double.infinity,
        decoration: BoxDecoration(
          color: softGrey,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_outlined,
                color: Colors.black45,
                size: 32,
              ),
              SizedBox(height: 6),
              Text(
                'Map location unavailable',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final position = _position!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 145,
        width: double.infinity,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: position,
                zoom: 15.5,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('current_user_location'),
                  position: position,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
                ),
              },
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              liteModeEnabled: true,
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  size: 18,
                  color: primaryOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         SAVE LOCATION FOR FUTURE USE                        */
/* -------------------------------------------------------------------------- */

Future<void> _openSaveLocationFlow({
  required BuildContext context,
  required String userId,
  required String locationName,
  required String addressLine,
  required double latitude,
  required double longitude,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,

    // Important: the map on the save-place flow must own vertical drags.
    // If the modal itself is draggable, a vertical swipe can move the sheet
    // instead of moving the Google Map. The back button still closes it.
    enableDrag: false,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.48),
    builder: (_) {
      return _SaveLocationFlowSheet(
        userId: userId,
        locationName: locationName,
        addressLine: addressLine,
        latitude: latitude,
        longitude: longitude,
      );
    },
  );
}

enum _SaveLocationStage { checking, nearbyPlace, createNew }

class _SaveLocationFlowSheet extends StatefulWidget {
  final String userId;
  final String locationName;
  final String addressLine;
  final double latitude;
  final double longitude;

  const _SaveLocationFlowSheet({
    required this.userId,
    required this.locationName,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<_SaveLocationFlowSheet> createState() => _SaveLocationFlowSheetState();
}

class _SaveLocationFlowSheetState extends State<_SaveLocationFlowSheet> {
  static const Color primaryOrange = Color(0xFFE67E22);
  static const double nearbyThresholdMeters = 300;

  _SaveLocationStage _stage = _SaveLocationStage.checking;
  _SavedLocation? _nearbySavedLocation;
  bool _savingMerge = false;
  bool _resolvingPinnedAddress = false;
  bool _forceCreateNew = false;

  late double _selectedLatitude;
  late double _selectedLongitude;
  late String _selectedAddressLine;
  late String _selectedLocationName;

  int _pinRevision = 0;
  int _nearbyRevision = 0;

  CollectionReference<Map<String, dynamic>> get _savedLocationsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('savedLocations');

  @override
  void initState() {
    super.initState();

    _selectedLatitude = widget.latitude;
    _selectedLongitude = widget.longitude;
    _selectedAddressLine = widget.addressLine;
    _selectedLocationName = widget.locationName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNearbyLocationState(showChecking: true);
    });
  }

  Future<void> _refreshNearbyLocationState({bool showChecking = false}) async {
    final revision = ++_nearbyRevision;
    final latitude = _selectedLatitude;
    final longitude = _selectedLongitude;

    if (showChecking && mounted && !_forceCreateNew) {
      setState(() {
        _stage = _SaveLocationStage.checking;
      });
    }

    try {
      final snapshot = await _savedLocationsRef.limit(100).get();

      _SavedLocation? closest;
      double? closestDistance;

      for (final doc in snapshot.docs) {
        final saved = _SavedLocation.fromFirestore(doc.id, doc.data());
        if (saved == null) continue;

        final distance = _distanceMeters(
          latitude,
          longitude,
          saved.latitude,
          saved.longitude,
        );

        if (distance > nearbyThresholdMeters) continue;

        if (closestDistance == null || distance < closestDistance) {
          closestDistance = distance;
          closest = saved;
        }
      }

      if (!mounted || revision != _nearbyRevision) return;

      setState(() {
        _nearbySavedLocation = closest;

        if (!_forceCreateNew) {
          _stage = closest == null
              ? _SaveLocationStage.createNew
              : _SaveLocationStage.nearbyPlace;
        }
      });
    } catch (e) {
      debugPrint('Nearby saved location check failed: $e');

      if (!mounted || revision != _nearbyRevision) return;

      setState(() {
        _nearbySavedLocation = null;
        if (!_forceCreateNew) {
          _stage = _SaveLocationStage.createNew;
        }
      });
    }
  }

  Future<void> _handlePinDropped(LatLng target) async {
    final revision = ++_pinRevision;

    setState(() {
      _selectedLatitude = target.latitude;
      _selectedLongitude = target.longitude;
      _resolvingPinnedAddress = true;
    });

    final resolved = await _reverseGeocodeLocation(
      latitude: target.latitude,
      longitude: target.longitude,
    );

    if (!mounted || revision != _pinRevision) return;

    setState(() {
      _selectedLatitude = resolved.latitude;
      _selectedLongitude = resolved.longitude;
      _selectedAddressLine = resolved.addressLine;
      _selectedLocationName = resolved.locationName;
      _resolvingPinnedAddress = false;
    });

    await _refreshNearbyLocationState();
  }

  void _goBack() {
    if (_stage == _SaveLocationStage.createNew &&
        _nearbySavedLocation != null) {
      FocusScope.of(context).unfocus();

      setState(() {
        _forceCreateNew = false;
        _stage = _SaveLocationStage.nearbyPlace;
      });
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _mergeWithNearbyLocation() async {
    final nearby = _nearbySavedLocation;
    if (nearby == null || _savingMerge || _resolvingPinnedAddress) return;

    setState(() {
      _savingMerge = true;
    });

    try {
      await _savedLocationsRef.doc(nearby.id).update({
        'addressLine': _selectedAddressLine,
        'locationName': _selectedLocationName,
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'geopoint': GeoPoint(_selectedLatitude, _selectedLongitude),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showPlaceSavedToast(
        context,
        title: 'Place updated',
        subtitle: 'Your nearby saved place has been merged.',
      );

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Saved location merge failed: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not merge this location. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _savingMerge = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.96,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              flex: 45,
              child: _SaveLocationMapHeader(
                initialLatitude: widget.latitude,
                initialLongitude: widget.longitude,
                selectedAddressLine: _selectedAddressLine,
                isResolvingAddress: _resolvingPinnedAddress,
                onBack: _goBack,
                onPinDropped: _handlePinDropped,
              ),
            ),
            Expanded(
              flex: 55,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildStage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case _SaveLocationStage.checking:
        return const _CheckingSavedLocationView(key: ValueKey('checking'));

      case _SaveLocationStage.nearbyPlace:
        return _NearbySavedPlaceView(
          key: ValueKey('nearby-${_nearbySavedLocation?.id ?? 'none'}'),
          place: _nearbySavedLocation!,
          selectedAddressLine: _selectedAddressLine,
          isSaving: _savingMerge,
          isResolvingAddress: _resolvingPinnedAddress,
          onSaveNewPlace: () {
            FocusScope.of(context).unfocus();

            setState(() {
              _forceCreateNew = true;
              _stage = _SaveLocationStage.createNew;
            });
          },
          onMerge: _mergeWithNearbyLocation,
        );

      case _SaveLocationStage.createNew:
        return _CreateSavedPlaceView(
          key: const ValueKey('create'),
          userId: widget.userId,
          locationName: _selectedLocationName,
          addressLine: _selectedAddressLine,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          isResolvingAddress: _resolvingPinnedAddress,
          onSaved: () {
            _showPlaceSavedToast(
              context,
              title: 'Place saved',
              subtitle: 'Now shown in search suggestions',
            );

            Navigator.of(context).pop();
          },
        );
    }
  }
}

class _SaveLocationMapHeader extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final String selectedAddressLine;
  final bool isResolvingAddress;
  final VoidCallback onBack;
  final ValueChanged<LatLng> onPinDropped;

  const _SaveLocationMapHeader({
    required this.initialLatitude,
    required this.initialLongitude,
    required this.selectedAddressLine,
    required this.isResolvingAddress,
    required this.onBack,
    required this.onPinDropped,
  });

  @override
  State<_SaveLocationMapHeader> createState() => _SaveLocationMapHeaderState();
}

class _SaveLocationMapHeaderState extends State<_SaveLocationMapHeader> {
  static const Color primaryOrange = Color(0xFFE67E22);

  late LatLng _cameraTarget;
  bool _cameraMoving = false;
  bool _mapWasMovedByUser = false;

  @override
  void initState() {
    super.initState();
    _cameraTarget = LatLng(widget.initialLatitude, widget.initialLongitude);
  }

  void _handleCameraMove(CameraPosition position) {
    _cameraTarget = position.target;

    if (!_cameraMoving && mounted) {
      setState(() {
        _cameraMoving = true;
      });
    }
  }

  void _handleCameraIdle() {
    final shouldDropPin = _mapWasMovedByUser;

    if (mounted) {
      setState(() {
        _cameraMoving = false;
        _mapWasMovedByUser = false;
      });
    }

    // The pin is only re-dropped after the user has actually moved the map.
    // This prevents the initial Google Map camera idle event from replacing
    // the current-location selection unnecessarily.
    if (shouldDropPin) {
      widget.onPinDropped(_cameraTarget);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = LatLng(
      widget.initialLatitude,
      widget.initialLongitude,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 17,
          ),
          onCameraMoveStarted: () {
            if (mounted) {
              setState(() {
                _cameraMoving = true;
                _mapWasMovedByUser = true;
              });
            }
          },
          onCameraMove: _handleCameraMove,
          onCameraIdle: _handleCameraIdle,

          // A GoogleMap inside a modal/bottom sheet can lose vertical drag
          // gestures to the parent scroll/drag recognizer. Eagerly claiming
          // the gesture makes the map reliably pannable in every direction.
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
          },

          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: false,
        ),
        Positioned(
          left: 14,
          top: 14,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              onTap: widget.onBack,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 21,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
        Center(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                0,
                _cameraMoving ? -31 : -22,
                0,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 54,
                color: primaryOrange,
                shadows: [
                  Shadow(
                    color: Color(0x55000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: IgnorePointer(
            child: Container(
              margin: const EdgeInsets.only(top: 22),
              width: 10,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (widget.isResolvingAddress)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryOrange,
                      ),
                    )
                  else
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: primaryOrange,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cameraMoving
                          ? 'Move the map to place the pin'
                          : widget.isResolvingAddress
                          ? 'Finding address for this pin...'
                          : widget.selectedAddressLine.trim().isEmpty
                          ? 'Pin dropped here'
                          : widget.selectedAddressLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckingSavedLocationView extends StatelessWidget {
  const _CheckingSavedLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFFE67E22)),
          SizedBox(height: 14),
          Text(
            'Checking saved places...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _NearbySavedPlaceView extends StatelessWidget {
  final _SavedLocation place;
  final String selectedAddressLine;
  final bool isSaving;
  final bool isResolvingAddress;
  final VoidCallback onSaveNewPlace;
  final VoidCallback onMerge;

  const _NearbySavedPlaceView({
    super.key,
    required this.place,
    required this.selectedAddressLine,
    required this.isSaving,
    required this.isResolvingAddress,
    required this.onSaveNewPlace,
    required this.onMerge,
  });

  static const Color primaryOrange = Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have another saved\nplace nearby',
              style: TextStyle(
                fontSize: 23,
                height: 1.08,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Move the map if you want to adjust the pin. Then keep this as a separate place or merge it with the nearby saved place.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Colors.black54,
              ),
            ),
            if (selectedAddressLine.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _PinnedAddressPreview(
                addressLine: selectedAddressLine,
                loading: isResolvingAddress,
              ),
            ],
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F4F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      place.type.toLowerCase() == 'home'
                          ? Icons.home_rounded
                          : Icons.bookmark_rounded,
                      size: 19,
                      color: primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          place.addressLine.isEmpty
                              ? 'Saved location'
                              : place.addressLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            height: 1.35,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving || isResolvingAddress
                          ? null
                          : onSaveNewPlace,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFF0F0F0),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text(
                        'Save new place',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving || isResolvingAddress
                          ? null
                          : onMerge,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Merge',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
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

class _CreateSavedPlaceView extends StatefulWidget {
  final String userId;
  final String locationName;
  final String addressLine;
  final double latitude;
  final double longitude;
  final bool isResolvingAddress;
  final VoidCallback onSaved;

  const _CreateSavedPlaceView({
    super.key,
    required this.userId,
    required this.locationName,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    required this.isResolvingAddress,
    required this.onSaved,
  });

  @override
  State<_CreateSavedPlaceView> createState() => _CreateSavedPlaceViewState();
}

class _CreateSavedPlaceViewState extends State<_CreateSavedPlaceView> {
  static const Color primaryOrange = Color(0xFFE67E22);

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  String _selectedType = 'home';
  bool _saving = false;

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      !_saving &&
      !widget.isResolvingAddress;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _savePlace() async {
    if (!_canSave) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('savedLocations')
          .doc();

      await docRef.set({
        'id': docRef.id,
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'addressLine': widget.addressLine,
        'locationName': widget.locationName,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'geopoint': GeoPoint(widget.latitude, widget.longitude),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      widget.onSaved();
    } catch (e) {
      debugPrint('Save place failed: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not save this place. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _addCustomType() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New location type'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'e.g. Work, School'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Add', style: TextStyle(color: primaryOrange)),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || result == null || result.trim().isEmpty) return;

    setState(() {
      _selectedType = result.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customTypeSelected = _selectedType.toLowerCase() != 'home';

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Save place',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Move the map to position the pin exactly where you want, then give the place a name.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            _PinnedAddressPreview(
              addressLine: widget.addressLine,
              loading: widget.isResolvingAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              maxLength: 40,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_canSave) _savePlace();
              },
              decoration: InputDecoration(
                hintText: 'Address name...',
                counterText: '${_nameController.text.length}/40',
                prefixIcon: const Icon(
                  Icons.bookmark_border_rounded,
                  color: Colors.black38,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD7D7D7)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: primaryOrange,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PlaceTypeChip(
                  icon: Icons.home_rounded,
                  text: 'Home',
                  selected: _selectedType.toLowerCase() == 'home',
                  onTap: () {
                    setState(() {
                      _selectedType = 'home';
                    });
                  },
                ),
                _PlaceTypeChip(
                  icon: customTypeSelected
                      ? Icons.bookmark_rounded
                      : Icons.add_rounded,
                  text: customTypeSelected ? _selectedType : 'New',
                  selected: customTypeSelected,
                  onTap: _addCustomType,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canSave ? _savePlace : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  disabledBackgroundColor: const Color(0xFFF0F0F0),
                  disabledForegroundColor: Colors.black38,
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : widget.isResolvingAddress
                    ? const Text(
                        'Finding pinned address...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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

class _PinnedAddressPreview extends StatelessWidget {
  final String addressLine;
  final bool loading;

  const _PinnedAddressPreview({
    required this.addressLine,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFE67E22),
              ),
            )
          else
            const Icon(
              Icons.location_on_outlined,
              color: Color(0xFFE67E22),
              size: 21,
            ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              loading
                  ? 'Finding the address for this pin...'
                  : addressLine.trim().isEmpty
                  ? 'Pinned location'
                  : addressLine,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceTypeChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _PlaceTypeChip({
    required this.icon,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF202020) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF202020) : const Color(0xFFE1E1E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolvedMapLocation {
  final double latitude;
  final double longitude;
  final String addressLine;
  final String locationName;

  const _ResolvedMapLocation({
    required this.latitude,
    required this.longitude,
    required this.addressLine,
    required this.locationName,
  });
}

Future<_ResolvedMapLocation> _reverseGeocodeLocation({
  required double latitude,
  required double longitude,
}) async {
  final fallbackAddress =
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  try {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      <String, String>{
        'latlng': '$latitude,$longitude',
        'key': 'AIzaSyABK1eJNZmo0VNvGabx4JZDTQvPppSpnA0',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = (data['status'] ?? '').toString();

    if (status != 'OK') {
      throw Exception(status);
    }

    final results = data['results'] as List<dynamic>? ?? const [];

    if (results.isEmpty) {
      throw Exception('No reverse geocoding result');
    }

    final first = results.first as Map<String, dynamic>? ?? <String, dynamic>{};
    final formattedAddress = (first['formatted_address'] ?? '')
        .toString()
        .trim();

    final addressLine = formattedAddress.isEmpty
        ? fallbackAddress
        : formattedAddress;

    final firstPart = addressLine.split(',').first.trim();

    return _ResolvedMapLocation(
      latitude: latitude,
      longitude: longitude,
      addressLine: addressLine,
      locationName: firstPart.isEmpty ? 'Pinned location' : firstPart,
    );
  } catch (e) {
    debugPrint('Reverse geocoding failed: $e');

    return _ResolvedMapLocation(
      latitude: latitude,
      longitude: longitude,
      addressLine: fallbackAddress,
      locationName: 'Pinned location',
    );
  }
}

class _SavedLocation {
  final String id;
  final String name;
  final String type;
  final String addressLine;
  final double latitude;
  final double longitude;
  final DateTime? updatedAt;

  const _SavedLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  static _SavedLocation? fromFirestore(String id, Map<String, dynamic> data) {
    final latitude = _readDouble(data['latitude']);
    final longitude = _readDouble(data['longitude']);

    if (latitude == null || longitude == null) {
      final geopoint = data['geopoint'];
      if (geopoint is! GeoPoint) return null;

      return _SavedLocation(
        id: id,
        name: _safeName(data['name']),
        type: (data['type'] ?? '').toString().trim(),
        addressLine: (data['addressLine'] ?? '').toString().trim(),
        latitude: geopoint.latitude,
        longitude: geopoint.longitude,
        updatedAt: _dateFromTimestamp(data['updatedAt']),
      );
    }

    return _SavedLocation(
      id: id,
      name: _safeName(data['name']),
      type: (data['type'] ?? '').toString().trim(),
      addressLine: (data['addressLine'] ?? '').toString().trim(),
      latitude: latitude,
      longitude: longitude,
      updatedAt: _dateFromTimestamp(data['updatedAt']),
    );
  }

  static double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  static DateTime? _dateFromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static String _safeName(dynamic value) {
    final name = value?.toString().trim() ?? '';
    return name.isEmpty ? 'Saved place' : name;
  }
}

class _SavedLocationsSearchSuggestions extends StatelessWidget {
  final String query;
  final ValueChanged<_SavedLocation> onTap;

  const _SavedLocationsSearchSuggestions({
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedLocations')
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final normalizedQuery = query.trim().toLowerCase();

        final saved = snapshot.data!.docs
            .map((doc) => _SavedLocation.fromFirestore(doc.id, doc.data()))
            .whereType<_SavedLocation>()
            .where((place) {
              if (normalizedQuery.isEmpty) return true;

              return place.name.toLowerCase().contains(normalizedQuery) ||
                  place.addressLine.toLowerCase().contains(normalizedQuery) ||
                  place.type.toLowerCase().contains(normalizedQuery);
            })
            .toList();

        saved.sort((a, b) {
          final aDate = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

        final visible = saved.take(5).toList();
        if (visible.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.97),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  'Saved places',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ),
              ...visible.map(
                (place) => ListTile(
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECDB),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      place.type.toLowerCase() == 'home'
                          ? Icons.home_rounded
                          : Icons.bookmark_rounded,
                      size: 18,
                      color: const Color(0xFFE67E22),
                    ),
                  ),
                  title: Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    place.addressLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black38,
                  ),
                  onTap: () => onTap(place),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showPlaceSavedToast(
  BuildContext context, {
  required String title,
  required String subtitle,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);

  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (overlayContext) {
      return Positioned(
        top: MediaQuery.of(overlayContext).padding.top + 10,
        left: 14,
        right: 14,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16B364),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 19,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);

  Future<void>.delayed(const Duration(seconds: 3), () {
    if (entry.mounted) entry.remove();
  });
}

double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusMeters = 6371000.0;

  double toRadians(double degrees) => degrees * math.pi / 180.0;

  final dLat = toRadians(lat2 - lat1);
  final dLng = toRadians(lng2 - lng1);

  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRadians(lat1)) *
          math.cos(toRadians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMeters * c;
}

class PlaceSuggestion {
  final String description;
  final String mainText;
  final String secondaryText;
  final String placeId;

  const PlaceSuggestion({
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.placeId,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final formatting =
        json['structured_formatting'] as Map<String, dynamic>? ?? {};

    return PlaceSuggestion(
      description: (json['description'] ?? '') as String,
      mainText: (formatting['main_text'] ?? '') as String,
      secondaryText: (formatting['secondary_text'] ?? '') as String,
      placeId: (json['place_id'] ?? '') as String,
    );
  }
}

class ServiceMiniChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconCircleColor;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;

  const ServiceMiniChip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.backgroundColor = const Color(0xFF1F1F1F),
    this.iconCircleColor = const Color(0xFFD7EA6A),
    this.iconColor = const Color(0xFF4A4A2A),
    this.titleColor = Colors.white,
    this.subtitleColor = const Color(0xFFB9B9B9),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 18, bottom: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 255, 255, 255),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: iconCircleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 5),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SearchEventsBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const SearchEventsBar({
    super.key,
    this.hintText = 'Pickup location...',
    this.controller,
    this.onFilterTap,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = controller?.text.trim() ?? '';
    final hasValue = text.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(50, 230, 125, 34),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.moped, size: 25),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? text : hintText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue ? Colors.black : Colors.black54,
                ),
              ),
            ),
            const Icon(Icons.search, size: 25, color: Color(0xFFE67E22)),
          ],
        ),
      ),
    );
  }
}

class ServiceTile extends StatelessWidget {
  final String title;
  final String imageAsset;
  final VoidCallback? onTap;

  const ServiceTile({
    super.key,
    required this.title,
    required this.imageAsset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F1F1), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 160,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(imageAsset, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A2A2A),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PromoImageCarousel extends StatefulWidget {
  final List<String> imagePaths;
  final double height;
  final Duration autoPlayDuration;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final ValueChanged<int>? onTap;

  const PromoImageCarousel({
    super.key,
    required this.imagePaths,
    this.height = 180,
    this.autoPlayDuration = const Duration(seconds: 4),
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.onTap,
  });

  @override
  State<PromoImageCarousel> createState() => _PromoImageCarouselState();
}

class _PromoImageCarouselState extends State<PromoImageCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    if (widget.imagePaths.length <= 1) return;

    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayDuration, (_) {
      if (!_pageController.hasClients) return;

      int nextPage = _currentIndex + 1;
      if (nextPage >= widget.imagePaths.length) {
        nextPage = 0;
      }

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(22);

    if (widget.imagePaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => widget.onTap?.call(index),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: radius),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: Image.asset(
                        widget.imagePaths[index],
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.imagePaths.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? const Color.fromARGB(255, 227, 166, 108)
                    : const Color.fromARGB(255, 216, 207, 197),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LaundryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double distanceKm;
  final double? rating;
  final String availabilityStatus;
  final bool isOpenNow;
  final List<String> supportedServices;
  final int basePricePerKg;
  final int washIronExtraPerKg;
  final String turnaroundText;
  final VoidCallback? onTap;

  const LaundryCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.distanceKm,
    required this.rating,
    required this.availabilityStatus,
    required this.isOpenNow,
    required this.supportedServices,
    required this.basePricePerKg,
    required this.washIronExtraPerKg,
    required this.turnaroundText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusData(availabilityStatus, isOpenNow);

    final darkOrange = const Color(0xFFE67E22);
    final softOrange = const Color(0xFFFFECDB);
    final white = Colors.white;
    final black = Colors.black;
    final borderColor = const Color(0xFFEAEAEA);
    final subtitleColor = Colors.black54;
    final closedColor = Colors.black45;
    final shadowColor = Colors.black.withOpacity(0.06);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 140,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.trim().isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: softOrange,
                              child: Icon(
                                Icons.local_laundry_service_outlined,
                                size: 40,
                                color: darkOrange,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: softOrange,
                          child: Icon(
                            Icons.local_laundry_service_outlined,
                            size: 40,
                            color: darkOrange,
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.18),
                          Colors.black.withOpacity(0.45),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _StatusBadge(
                      label: status.label,
                      textColor: status.textColor,
                      bgColor: status.bgColor,
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: supportedServices
                            .map(
                              (service) => _ServiceChip(
                                label: _serviceLabel(service),
                                bgColor: softOrange,
                                textColor: darkOrange,
                              ),
                            )
                            .toList(),
                      ),
                      _MetaItem(
                        title: 'From',
                        value: 'GH₵$basePricePerKg/kg',
                        titleColor: subtitleColor,
                        valueColor: black,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isOpenNow ? 'Open now' : 'Currently closed',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: isOpenNow ? darkOrange : closedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 16,
                                  color: subtitleColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${distanceKm.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: darkOrange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating == null || rating == 0
                                      ? 'New'
                                      : rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  _StatusData _statusData(String availabilityStatus, bool isOpenNow) {
    if (!isOpenNow) {
      return const _StatusData(
        label: 'Closed',
        textColor: Color(0xFF6D6D6D),
        bgColor: Color(0xFFEEEEEE),
      );
    }

    switch (availabilityStatus.toLowerCase()) {
      case 'available':
        return const _StatusData(
          label: 'Available',
          textColor: Color(0xFFE67E22),
          bgColor: Color(0xFFFFE8D6),
        );
      case 'busy':
        return const _StatusData(
          label: 'Busy',
          textColor: Colors.black,
          bgColor: Color(0xFFFFD6A5),
        );
      default:
        return const _StatusData(
          label: 'Offline',
          textColor: Color(0xFF6D6D6D),
          bgColor: Color(0xFFEEEEEE),
        );
    }
  }

  String _serviceLabel(String key) {
    switch (key) {
      case 'wash_fold':
        return 'Wash & Fold';
      case 'wash_iron':
        return 'Wash & Iron';
      default:
        return key;
    }
  }
}

class _StatusData {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _StatusData({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });
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

class _ServiceChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _ServiceChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String title;
  final String value;
  final Color titleColor;
  final Color valueColor;

  const _MetaItem({
    required this.title,
    required this.value,
    required this.titleColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Text(
        value,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: valueColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ActiveLaundryOrderCard extends StatelessWidget {
  final String laundryName;
  final String dateText;
  final String currentStage;
  final String nextStage;
  final String currentTimeText;
  final String nextTimeText;
  final String durationText;
  final double progress;
  final VoidCallback? onTap;

  const ActiveLaundryOrderCard({
    super.key,
    required this.laundryName,
    required this.dateText,
    required this.currentStage,
    required this.nextStage,
    required this.currentTimeText,
    required this.nextTimeText,
    required this.durationText,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 255, 248, 240),
              Color.fromARGB(255, 255, 222, 195),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE67E22).withOpacity(0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopRow(dateText: dateText),
            const SizedBox(height: 10),
            Text(
              laundryName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 25,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2E7),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE67E22).withOpacity(0.18),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _StageText(
                        title: currentStage,
                        time: currentTimeText,
                        alignRight: false,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Column(
                            children: [
                              Text(
                                durationText,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7A4A24),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ProgressLine(progress: safeProgress),
                            ],
                          ),
                        ),
                      ),
                      _StageText(
                        title: nextStage,
                        time: nextTimeText,
                        alignRight: true,
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

class _TopRow extends StatelessWidget {
  final String dateText;

  const _TopRow({required this.dateText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          dateText,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9A7153),
          ),
        ),
        const Spacer(),
        _CircleIconButton(
          icon: Icons.local_laundry_service_outlined,
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _CircleIconButton(icon: Icons.delivery_dining_rounded, onTap: () {}),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFECDB),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: Color(0xFFE67E22)),
        ),
      ),
    );
  }
}

class _StageText extends StatelessWidget {
  final String title;
  final String time;
  final bool alignRight;

  const _StageText({
    required this.title,
    required this.time,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          time,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9A7153),
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final double progress;

  const _ProgressLine({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFE8C9AA),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFE67E22),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ],
    );
  }
}

class ActiveLaundryOrderStackPreview extends StatelessWidget {
  final ActiveLaundryOrderCardData cardData;
  final int bookingCount;
  final VoidCallback? onTap;

  const ActiveLaundryOrderStackPreview({
    super.key,
    required this.cardData,
    required this.bookingCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasMultiple = bookingCount > 1;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          if (hasMultiple)
            Positioned(
              left: 18,
              right: 18,
              top: 22,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDCC3),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          if (hasMultiple)
            Positioned(
              left: 9,
              right: 9,
              top: 11,
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D6),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(bottom: hasMultiple ? 18 : 0),
            child: ActiveLaundryOrderCard(
              dateText: cardData.dateText,
              laundryName: cardData.laundryName,
              currentStage: cardData.currentStage,
              currentTimeText: cardData.currentTimeText,
              nextStage: cardData.nextStage,
              nextTimeText: cardData.nextTimeText,
              durationText: cardData.durationText,
              progress: cardData.progress,
            ),
          ),
          if (hasMultiple)
            Positioned(
              top: 70,
              right: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE67E22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$bookingCount active',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ActiveLaundryOrderCardData {
  final String laundryName;
  final String dateText;
  final String currentStage;
  final String nextStage;
  final String currentTimeText;
  final String nextTimeText;
  final String durationText;
  final double progress;

  const ActiveLaundryOrderCardData({
    required this.laundryName,
    required this.dateText,
    required this.currentStage,
    required this.nextStage,
    required this.currentTimeText,
    required this.nextTimeText,
    required this.durationText,
    required this.progress,
  });

  factory ActiveLaundryOrderCardData.fromBooking(Map<String, dynamic> booking) {
    final status = (booking['status'] ?? '').toString();
    final laundrySnapshot =
        booking['laundrySnapshot'] as Map<String, dynamic>? ?? {};

    final laundryName = (laundrySnapshot['name'] ?? 'Finding laundry')
        .toString();

    final createdAt = booking['createdAt'];
    final date = createdAt is Timestamp ? createdAt.toDate() : DateTime.now();

    final stage = _stageForStatus(status);

    return ActiveLaundryOrderCardData(
      laundryName: laundryName,
      dateText: _formatDate(date),
      currentStage: stage.currentStage,
      nextStage: stage.nextStage,
      currentTimeText: stage.currentTimeText,
      nextTimeText: stage.nextTimeText,
      durationText: stage.durationText,
      progress: stage.progress,
    );
  }

  static _OrderStageData _stageForStatus(String status) {
    switch (status) {
      case 'awaiting_laundry_assignment':
        return const _OrderStageData(
          currentStage: 'Finding',
          nextStage: 'Laundry',
          currentTimeText: 'Now',
          nextTimeText: 'Soon',
          durationText: 'Searching',
          progress: 0.08,
        );

      case 'offered_to_laundry':
        return const _OrderStageData(
          currentStage: 'Offer sent',
          nextStage: 'Accepted',
          currentTimeText: 'Now',
          nextTimeText: 'Soon',
          durationText: 'Waiting',
          progress: 0.15,
        );

      case 'pending':
        return const _OrderStageData(
          currentStage: 'Accepted',
          nextStage: 'Pickup',
          currentTimeText: 'Now',
          nextTimeText: 'Soon',
          durationText: 'Preparing',
          progress: 0.25,
        );

      case 'looking_for_pickup_rider':
        return const _OrderStageData(
          currentStage: 'Finding rider',
          nextStage: 'Pickup',
          currentTimeText: 'Now',
          nextTimeText: 'Soon',
          durationText: 'Searching',
          progress: 0.35,
        );

      case 'pickup_rider_assigned':
      case 'pickup_started':
      case 'arrived_at_pickup':
        return const _OrderStageData(
          currentStage: 'Pickup',
          nextStage: 'Laundry',
          currentTimeText: 'Now',
          nextTimeText: 'Soon',
          durationText: 'In progress',
          progress: 0.48,
        );

      case 'arrived_at_laundry':
        return const _OrderStageData(
          currentStage: 'Arrived',
          nextStage: 'Washing',
          currentTimeText: 'Now',
          nextTimeText: 'Soon',
          durationText: 'Queued',
          progress: 0.58,
        );

      case 'processing':
        return const _OrderStageData(
          currentStage: 'Washing',
          nextStage: 'Delivery',
          currentTimeText: 'Now',
          nextTimeText: 'Soon',
          durationText: 'In progress',
          progress: 0.72,
        );

      case 'ready_for_dropoff':
        return const _OrderStageData(
          currentStage: 'Ready',
          nextStage: 'Delivery',
          currentTimeText: 'Now',
          nextTimeText: 'Soon',
          durationText: 'Waiting rider',
          progress: 0.82,
        );
      case 'no_laundry_found':
        return const _OrderStageData(
          currentStage: 'No laundry',
          nextStage: 'Retry',
          currentTimeText: 'Now',
          nextTimeText: 'Tap',
          durationText: 'Not found',
          progress: 0.12,
        );

      case 'delivery_in_progress':
        return const _OrderStageData(
          currentStage: 'Delivery',
          nextStage: 'Complete',
          currentTimeText: 'Now',
          nextTimeText: 'Soon',
          durationText: 'On the way',
          progress: 0.92,
        );

      default:
        return const _OrderStageData(
          currentStage: 'Active',
          nextStage: 'Next',
          currentTimeText: 'Now',
          nextTimeText: 'Soon',
          durationText: 'In progress',
          progress: 0.3,
        );
    }
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'June',
      'July',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];

    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isToday) return 'Today, ${date.day} ${months[date.month - 1]}';

    return '${date.day} ${months[date.month - 1]}';
  }
}

class _OrderStageData {
  final String currentStage;
  final String nextStage;
  final String currentTimeText;
  final String nextTimeText;
  final String durationText;
  final double progress;

  const _OrderStageData({
    required this.currentStage,
    required this.nextStage,
    required this.currentTimeText,
    required this.nextTimeText,
    required this.durationText,
    required this.progress,
  });
}

class CustomerActiveBookingsPreview extends StatelessWidget {
  const CustomerActiveBookingsPreview({super.key});

  static const List<String> activeStatuses = [
    'awaiting_laundry_assignment',
    'offered_to_laundry',
    'pending',
    'looking_for_pickup_rider',
    'pickup_rider_assigned',
    'pickup_started',
    'arrived_at_pickup',
    'arrived_at_laundry',
    'processing',
    'ready_for_dropoff',
    'delivery_in_progress',
    'no_laundry_found',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('customerSnapshot.customerId', isEqualTo: user.uid)
          .where('status', whereIn: activeStatuses)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Active bookings preview error: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs.toList();

        docs.sort((a, b) {
          final aCreatedAt = a.data()['createdAt'];
          final bCreatedAt = b.data()['createdAt'];

          final aDate = aCreatedAt is Timestamp
              ? aCreatedAt.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          final bDate = bCreatedAt is Timestamp
              ? bCreatedAt.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          return bDate.compareTo(aDate);
        });

        if (docs.isEmpty) return const SizedBox.shrink();

        final firstBooking = docs.first.data();
        final cardData = ActiveLaundryOrderCardData.fromBooking(firstBooking);

        return ActiveLaundryOrderStackPreview(
          cardData: cardData,
          bookingCount: docs.length,
          onTap: () {
            if (docs.length == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ActiveLaundryOrderScreen(bookingId: docs.first.id),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerActiveBookingsScreen(),
              ),
            );
          },
        );
      },
    );
  }
}

class ClosestLaundrySinglePreview extends StatelessWidget {
  final dynamic lastLocation;

  const ClosestLaundrySinglePreview({super.key, required this.lastLocation});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClosestLaundryService?>(
      future: _loadClosestLaundryFromLastLocation(lastLocation),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LaundryServiceCardShimmer();
        }

        final closestLaundry = snapshot.data;
        if (closestLaundry == null) return const SizedBox.shrink();
        debugPrint(
          ' closest laundries 1 ==============>>>>>>> $closestLaundry',
        );
        debugPrint(
          ' closest laundries 2 ==============>>>>>>> ${closestLaundry.geopoint.latitude}',
        );
        debugPrint(
          ' closest laundries 3 ==============>>>>>>> ${closestLaundry.geopoint.longitude}',
        );

        return LaundryServiceCard(
          laundry: closestLaundry,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                /* builder: (context) => ClosestLaundrySelectedScreen(
                  laundryId: closestLaundry.id,
                  lastLocation: lastLocation,
                ), */
                builder: (context) => MapPickupPickerScreen(
                  initialPickup: LatLng(
                    lastLocation['latitude'],
                    lastLocation['longitude'],
                  ),
                  fixedDropoff: LatLng(
                    closestLaundry.geopoint.latitude,
                    closestLaundry.geopoint.longitude,
                  ),
                  dropoffAddress: closestLaundry.addressLine,
                  googleMapsApiKey: 'AIzaSyABK1eJNZmo0VNvGabx4JZDTQvPppSpnA0',
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<ClosestLaundryService?> _loadClosestLaundryFromLastLocation(
    dynamic lastLocation,
  ) async {
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
        if (geopoint is GeoPoint) {
          userGeoPoint = geopoint;
        }
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
        final laundry = ClosestLaundryService.fromFirestore(
          id: doc.id,
          data: doc.data(),
          pickupGeopoint: userGeoPoint,
        );

        laundries.add(laundry);
      } catch (_) {
        continue;
      }
    }

    laundries.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return laundries.isEmpty ? null : laundries.first;
  }
}

class LaundryServiceCard extends StatelessWidget {
  final ClosestLaundryService laundry;
  final VoidCallback onTap;

  const LaundryServiceCard({
    super.key,
    required this.laundry,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _CardImageSection(laundry: laundry),
            _CardBodySection(laundry: laundry),
          ],
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
    required this.isLoading,
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

class CurrentLocationClosestLaundryPreview extends StatelessWidget {
  const CurrentLocationClosestLaundryPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final lastLocation = data['lastCurrentLocation'];

        if (lastLocation == null) {
          return const SizedBox.shrink();
        }

        return ClosestLaundrySinglePreview(lastLocation: lastLocation);
      },
    );
  }
}

class _LocationActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _LocationActionTile({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, size: 19, color: Colors.black87),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
