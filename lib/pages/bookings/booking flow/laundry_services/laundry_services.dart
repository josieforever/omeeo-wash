import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'
    show
        FirebaseFirestore,
        FieldValue,
        SetOptions,
        QuerySnapshot,
        Timestamp,
        GeoPoint,
        DocumentSnapshot;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/location_picker.dart';
import 'package:omeeowash/pages/profile/profile_screen.dart';
import 'active_booking_screen.dart';
import 'active_laundry_order_stage.dart';
import 'closest_laundries_screen.dart';
import 'laundry_services_date_time.dart';
import 'package:geolocator/geolocator.dart';
import 'service_review.dart' show PickedLocationResult, PickupPreviewScreen;

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

  Future<void> _showLocationSheet() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.18),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> searchPlacesInSheet(String input) async {
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
              _locationController.clear();
              setModalState(() {
                _selectedPickupAddress = null;
                _predictions = [];
                _isSearchingLocations = false;
              });
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _locationFocusNode.requestFocus();
              }
            });

            return SafeArea(
              top: false,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.91,
                minChildSize: 0.91,
                maxChildSize: 0.91,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
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
                              const SizedBox(height: 10),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => Navigator.of(sheetContext).pop(),
                                child: Lottie.asset(
                                  'assets/animations/breathing_pill.json',
                                  width: 50,
                                  height: 30,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 50, 12, 24),
                          sliver: SliverToBoxAdapter(
                            child: _buildSearchSection(
                              sheetContext,
                              onSearchChanged: searchPlacesInSheet,
                              onClearSearch: clearSearchInSheet,
                              rebuildSheet: setModalState,
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
  }) {
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
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Pickup location',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: Transform.scale(
                            scale: 0.60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(1),
                              child: const Icon(
                                Icons.moped,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          suffixIcon: _isSearchingLocations
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
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
                      onTap: () => _openMapPicker(modalContext: modalContext),
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
                        onTap: () => _openPickupPreviewFromSuggestion(
                          place,
                          modalContext: modalContext,
                        ),
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
                        const CurrentUserLocationText(),
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

                ClosestLaundrySinglePreview(),
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
  const CurrentUserLocationText({super.key});

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

        String locationText = 'Getting your location...';

        if (lastLocation is Map) {
          final map = Map<String, dynamic>.from(lastLocation);
          final addressLine = map['addressLine']?.toString().trim();

          if (addressLine != null && addressLine.isNotEmpty) {
            locationText = addressLine;
          } else {
            locationText = 'Location unavailable';
          }
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 15,
              color: Color(0xFFE67E22),
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
          ],
        );
      },
    );
  }
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
          width: 170,
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
                  color: const Color(0xFFFFF4F7),
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
  const ClosestLaundrySinglePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<ClosestLaundryService?>(
      future: _loadClosestLaundryFromSavedUserLocation(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LaundryServiceCardShimmer();
        }

        final closestLaundry = snapshot.data;
        if (closestLaundry == null) return const SizedBox.shrink();

        return LaundryServiceCard(
          laundry: closestLaundry,
          onTap: () {
            // Route to the full closest laundries screen later if needed.
            debugPrint('Tapped closest laundry: ${closestLaundry.id}');
          },
        );
      },
    );
  }

  Future<ClosestLaundryService?> _loadClosestLaundryFromSavedUserLocation(
    String uid,
  ) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final userData = userDoc.data() ?? <String, dynamic>{};
    final lastLocation = userData['lastCurrentLocation'];

    GeoPoint? userGeoPoint;

    if (lastLocation is GeoPoint) {
      userGeoPoint = lastLocation;
    } else if (lastLocation is Map) {
      final map = Map<String, dynamic>.from(lastLocation);

      final geopoint = map['geopoint'];
      if (geopoint is GeoPoint) {
        userGeoPoint = geopoint;
      } else {
        final lat = map['latitude'];
        final lng = map['longitude'];

        if (lat is num && lng is num) {
          userGeoPoint = GeoPoint(lat.toDouble(), lng.toDouble());
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
