import 'dart:async';
import 'dart:convert' show json;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart' show TypeAheadField;
import 'package:geocoding/geocoding.dart' as geo show placemarkFromCoordinates;
import 'package:geolocator/geolocator.dart'
    show LocationAccuracy, Geolocator, LocationPermission;
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show
        LatLng,
        CameraPosition,
        GoogleMapController,
        MarkerId,
        CameraUpdate,
        Marker,
        GoogleMap;
import 'package:http/http.dart' as http show get;
import 'package:intl/intl.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/auto_care/auto_care_review.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/common_widgets.dart'
    show LnProgressIndicator;
import 'package:omeeowash/pages/bookings/booking%20flow/confirm_booking.dart'
    show ConfirmBooking;
import 'package:omeeowash/widgets.dart/responsiveness.dart' show TextSizes;
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

// ✅ Autocomplete via REST + TypeAhead
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:omeeowash/pages/bookings/booking flow/confirm_booking.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

// App imports
import 'package:omeeowash/pages/bookings/booking flow/common_widgets.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';

const String kGoogleApiKey = 'AIzaSyAhUAyOfnZrilFp3OVqH1vEmpn0j5fL8SY';

/// ---- On-site (washing bay) constants ----
const String kOmeeoWashAddress = 'Israel Teikofio Street, Sowutuom, Accra';
const LatLng kOmeeoWashLatLng = LatLng(5.6288569, -0.2725429);

class _MapSearchBody extends StatefulWidget {
  final String title;
  final String? initialAddress;
  final LatLng? initialLatLng;

  const _MapSearchBody({
    required this.title,
    this.initialAddress,
    this.initialLatLng,
  });

  @override
  State<_MapSearchBody> createState() => _MapSearchBodyState();
}

class _MapSearchBodyState extends State<_MapSearchBody> {
  final TextEditingController _searchController = TextEditingController();

  // Places Autocomplete session
  final Uuid _uuid = const Uuid();
  String _sessionToken = const Uuid().v4();

  // local selected location (from search)
  MapLocation? _searchResult;
  bool _showMapView = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _searchController.text = widget.initialAddress!;
    }
  }

  Future<List<_PlaceSuggestion>> _fetchSuggestions(String input) async {
    if (input.trim().isEmpty) return [];
    String? locationBias;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        );
        locationBias = "${pos.latitude},${pos.longitude}";
      }
    } catch (_) {}

    final params = <String, String>{
      'input': input,
      'key': kGoogleApiKey,
      'sessiontoken': _sessionToken,
      'language': 'en',
      'components': 'country:gh',
      if (locationBias != null) 'location': locationBias,
      if (locationBias != null) 'radius': '30000',
    };

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      params,
    );
    final res = await http.get(uri);

    if (res.statusCode != 200) return [];
    final data = json.decode(res.body);
    if ((data['status'] ?? '') != 'OK') {
      // fallback without country filter
      final fallback = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {...params..remove('components')},
      );
      final res2 = await http.get(fallback);
      if (res2.statusCode != 200) return [];
      final data2 = json.decode(res2.body);
      if ((data2['status'] ?? '') != 'OK') return [];
      final List preds2 = data2['predictions'] ?? [];
      return preds2
          .map<_PlaceSuggestion>(
            (p) => _PlaceSuggestion(
              description: p['description'] ?? '',
              placeId: p['place_id'] ?? '',
            ),
          )
          .where((s) => s.placeId.isNotEmpty)
          .toList();
    }

    final List preds = data['predictions'] ?? [];
    return preds
        .map<_PlaceSuggestion>(
          (p) => _PlaceSuggestion(
            description: p['description'] ?? '',
            placeId: p['place_id'] ?? '',
          ),
        )
        .where((s) => s.placeId.isNotEmpty)
        .toList();
  }

  Future<_PlaceDetails?> _fetchPlaceDetail(String placeId) async {
    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
          'place_id': placeId,
          'fields': 'geometry,formatted_address,name',
          'key': kGoogleApiKey,
          'sessiontoken': _sessionToken,
        });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final data = json.decode(res.body);
    if ((data['status'] ?? '') != 'OK') return null;

    final result = data['result'];
    final loc = result['geometry']?['location'];
    if (loc == null) return null;

    final lat = (loc['lat'] as num).toDouble();
    final lng = (loc['lng'] as num).toDouble();
    final addr =
        (result['formatted_address'] ?? result['name'] ?? '') as String;

    return _PlaceDetails(latLng: LatLng(lat, lng), address: addr);
  }

  void _openMapView({LatLng? latLng, String? address}) {
    setState(() {
      _showMapView = true;
      if (latLng != null && address != null) {
        _searchResult = MapLocation(
          address: address,
          lat: latLng.latitude,
          lng: latLng.longitude,
        );
        _searchController.text = address;
      }
    });
  }

  void _confirmAndPop(MapLocation result) {
    Navigator.pop(context, result);
  }

  void _goBackToSearch() {
    setState(() {
      _showMapView = false;
      _searchResult = null;
      _searchController.text = widget.initialAddress ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      expand: true,
      builder: (context, scrollController) {
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    if (_showMapView)
                      IconButton(
                        onPressed: _goBackToSearch,
                        icon: const Icon(Icons.arrow_back),
                      ),
                    Expanded(
                      child: CustomText(
                        text: widget.title,
                        textColor: Theme.of(context).textTheme.bodyLarge?.color,
                        textSize: TextSizes.subtitle1,
                        textWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Search Bar with suggestions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Theme.of(context).colorScheme.secondary,
                        elevation: 1,
                        borderRadius: BorderRadius.circular(8),
                        child: TypeAheadField<_PlaceSuggestion>(
                          suggestionsCallback: (pattern) async {
                            if (pattern.length == 1) {
                              // new session when user starts fresh
                              _sessionToken = _uuid.v4();
                            }
                            return _fetchSuggestions(pattern);
                          },
                          builder: (context, controller, focusNode) =>
                              TextField(
                                controller: _searchController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Search for a new location...',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 12,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                onChanged: (val) {
                                  controller.text = val;
                                  controller.selection =
                                      TextSelection.fromPosition(
                                        TextPosition(offset: val.length),
                                      );
                                },
                              ),
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              dense: true,
                              title: Text(
                                suggestion.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                          emptyBuilder: (context) => const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('No places found'),
                          ),
                          onSelected: (suggestion) async {
                            _searchController.text = suggestion.description;
                            FocusScope.of(context).unfocus();

                            final details = await _fetchPlaceDetail(
                              suggestion.placeId,
                            );
                            if (details == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not get coordinates.'),
                                ),
                              );
                              return;
                            }

                            if (_showMapView) {
                              await _searchResultMapKey.currentState?._moveTo(
                                details.latLng,
                              );
                            } else {
                              _openMapView(
                                latLng: details.latLng,
                                address: details.address,
                              );
                            }
                          },
                          decorationBuilder: (context, child) => Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(.2),
                              ),
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _openMapView(
                        latLng: widget.initialLatLng,
                        address: _searchController.text.isNotEmpty
                            ? _searchController.text
                            : widget.initialAddress,
                      ),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: Transform.scale(
                            scale: 2,
                            child: Image.asset(
                              'assets/images/pick_location.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Map or Search placeholder
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showMapView
                        ? _MapPickerMapBody(
                            key: _searchResultMapKey,
                            initialLatLng:
                                _searchResult?.toLatLng() ??
                                widget.initialLatLng,
                            initialAddress:
                                _searchResult?.address ?? widget.initialAddress,
                            onConfirm: _confirmAndPop,
                          )
                        : _buildInitialSearchUI(scrollController),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInitialSearchUI(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            CustomText(
              text: "Search a place or tap the map icon to drop a pin.",
              textSize: TextSizes.bodyText1,
              textColor: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ],
        ),
      ),
    );
  }
}

final GlobalKey<_MapPickerMapBodyState> _searchResultMapKey = GlobalKey();

// -----------------------------------------------------------------------------
// Map View
// -----------------------------------------------------------------------------
class _MapPickerMapBody extends StatefulWidget {
  final LatLng? initialLatLng;
  final String? initialAddress;
  final Function(MapLocation) onConfirm;

  const _MapPickerMapBody({
    super.key,
    this.initialLatLng,
    this.initialAddress,
    required this.onConfirm,
  });

  @override
  State<_MapPickerMapBody> createState() => _MapPickerMapBodyState();
}

class _MapPickerMapBodyState extends State<_MapPickerMapBody> {
  LatLng? selectedLatLng;
  String currentAddress = '';
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    selectedLatLng = widget.initialLatLng;
    currentAddress = widget.initialAddress ?? '';
    if (selectedLatLng != null && currentAddress.isEmpty) {
      _moveTo(selectedLatLng!, animate: false);
    }
  }

  Future<void> _moveTo(LatLng latLng, {bool animate = true}) async {
    selectedLatLng = latLng;
    String newAddress = '';
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        newAddress = [
          p.name,
          p.street,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((e) => e != null && e.trim().isNotEmpty).join(', ');
      } else {
        newAddress =
            'Dropped Pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
      }
    } catch (_) {
      newAddress =
          'Dropped Pin (${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)})';
    }

    setState(() {
      currentAddress = newAddress;
    });

    if (mapController != null && animate) {
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16),
        ),
      );
    }
  }

  void _zoomIn() => mapController?.animateCamera(CameraUpdate.zoomIn());
  void _zoomOut() => mapController?.animateCamera(CameraUpdate.zoomOut());

  Future<void> _useCurrentLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching current location...')),
    );

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _moveTo(LatLng(pos.latitude, pos.longitude));
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMarker = (selectedLatLng != null)
        ? Marker(
            markerId: const MarkerId('selected'),
            position: selectedLatLng!,
          )
        : null;

    return Column(
      children: [
        // Address display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).textTheme.headlineLarge?.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            currentAddress.isEmpty
                ? 'Tap on the map or search above'
                : currentAddress,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),

        // Use current location
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _useCurrentLocation,
            icon: Icon(
              Icons.my_location,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: const Text('Use current location'),
          ),
        ),
        const SizedBox(height: 10),

        // Map
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    // ✅ default to the washing bay if nothing provided
                    target: widget.initialLatLng ?? kOmeeoWashLatLng,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  onMapCreated: (c) => mapController = c,
                  onTap: (latLng) async {
                    await _moveTo(latLng);
                    setState(() {});
                  },
                  markers: {if (selectedMarker != null) selectedMarker},
                  // Allow map gestures inside bottom sheet
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                    Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                    Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                    ),
                  },
                ),

                // Custom Zoom Buttons
                Positioned(
                  top: 10,
                  right: 10,
                  child: Column(
                    children: [
                      Transform.scale(
                        scale: 0.7,
                        child: FloatingActionButton.small(
                          heroTag: 'zoom_in_map',
                          onPressed: _zoomIn,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: const Icon(Icons.add),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.7,
                        child: FloatingActionButton.small(
                          heroTag: 'zoom_out_map',
                          onPressed: _zoomOut,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: const Icon(Icons.remove),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Confirm Button
        RegularButton(
          onPressed: () {
            if (selectedLatLng == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please drop a pin on the map.')),
              );
              return;
            }
            widget.onConfirm(
              MapLocation(
                address: currentAddress.isEmpty
                    ? 'Dropped Pin'
                    : currentAddress,
                lat: selectedLatLng!.latitude,
                lng: selectedLatLng!.longitude,
              ),
            );
          },
          borderRadius: 8,
          textWidget: CustomText(
            text: 'Confirm Location',
            textColor: Theme.of(context).textTheme.headlineLarge?.color,
            textSize: TextSizes.heading3,
            textWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              Color.fromARGB(255, 198, 198, 198),
              Color.fromARGB(255, 44, 44, 44),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// Simple holder for address + coordinates
class MapLocation {
  final String address;
  final double lat;
  final double lng;
  MapLocation({required this.address, required this.lat, required this.lng});

  LatLng toLatLng() => LatLng(lat, lng);
}

// Suggestion + Details models (for TypeAhead + Details)
class _PlaceSuggestion {
  final String description;
  final String placeId;
  _PlaceSuggestion({required this.description, required this.placeId});
}

class _PlaceDetails {
  final LatLng latLng;
  final String address;
  _PlaceDetails({required this.latLng, required this.address});
}

// Presentational tiles (unchanged)
class _PlaceTile extends StatelessWidget {
  final bool selected;
  final Color borderColor;
  final Color? fillColor;
  final bool iconBgSelected;
  final String iconAsset;
  final String title;
  final String subtitle;

  const _PlaceTile({
    required this.selected,
    required this.borderColor,
    required this.fillColor,
    required this.iconBgSelected,
    required this.iconAsset,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 2, color: borderColor),
        color: fillColor,
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 167, 189, 187),
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon block
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Color(0xFFE2F3ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Transform.scale(
              scale: 1.4,
              child: SvgPicture.asset(
                iconAsset,
                height: 30,
                width: 24,
                colorFilter: ColorFilter.mode(
                  Color(0xFF45A182),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
                CustomText(
                  text: subtitle,
                  textColor: Theme.of(context).textTheme.bodyMedium?.color,
                  textSize: TextSizes.bodyText1,
                  textMaxLines: null,
                  textOverflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarTile extends StatelessWidget {
  final bool selected;
  final Color borderColor;
  final Color? fillColor;
  final bool iconBgSelected;
  final String imageAsset;
  final double imageScale;
  final String title;

  const _CarTile({
    required this.selected,
    required this.borderColor,
    required this.fillColor,
    required this.iconBgSelected,
    required this.imageAsset,
    required this.imageScale,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(width: 2, color: borderColor),
        color: fillColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow,
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon block
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: iconBgSelected
                  ? Theme.of(context).colorScheme.inversePrimary
                  : Theme.of(context).colorScheme.onSecondary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Transform.scale(
              scale: imageScale,
              child: Image.asset(
                imageAsset,
                width: 40,
                height: 21,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AutoCareSelectDateScreen extends StatefulWidget {
  final String carType;
  final int duration;
  final String? serviceType; // express | standard | premium
  final double? price;
  final String serviceLocation; // washing_bay | mobile | valet

  const AutoCareSelectDateScreen({
    super.key,
    required this.carType,
    required this.duration,
    this.serviceType,
    this.price,
    this.serviceLocation = 'washing_bay',
  });

  @override
  State<AutoCareSelectDateScreen> createState() =>
      _AutoCareSelectDateScreenState();
}

class _AutoCareSelectDateScreenState extends State<AutoCareSelectDateScreen> {
  late final String serviceType;
  double? price;

  // Date & time selections
  DateTime? pickedDate;
  String? selectedTimeLabel;
  String? _selectedHhmm;

  // ================= LOCATION STATE =================
  String placeSelected = 'none';

  String? onSiteAddress = kOmeeoWashAddress;
  String? atHomeAddress;
  String? valetAddress;

  LatLng? atHomeLatLng;
  LatLng? valetLatLng;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookedSub;

  List<_SlotVM> _slots = [];
  bool _loadingSlots = false;

  static const int _startMin = 8 * 60; // 08:00
  static const int _endMin = 15 * 60; // 18:00
  static const int _stepMin = 30;

  bool get hasPickedDate => pickedDate != null;

  static const Color _deepTeal = Color.fromARGB(255, 11, 85, 73);
  static const Color _teal = Color.fromARGB(255, 75, 161, 140);
  static const Color _mintBg = Color(0xFFE2F3ED);
  static const Color _accent = Color(0xFF45A182);
  static const Color _shadow = Color.fromARGB(255, 167, 189, 187);

  @override
  void initState() {
    super.initState();

    serviceType =
        (widget.serviceType != null && widget.serviceType!.trim().isNotEmpty)
        ? widget.serviceType!
        : "none";

    price = widget.price;
  }

  @override
  void dispose() {
    _bookedSub?.cancel();
    super.dispose();
  }

  // ================= VALIDATION =================

  bool get hasValidLocation {
    switch (placeSelected) {
      case 'onSite':
        return true;

      case 'atHome':
        return atHomeAddress != null &&
            atHomeAddress!.trim().isNotEmpty &&
            atHomeLatLng != null;

      case 'valet':
        return valetAddress != null &&
            valetAddress!.trim().isNotEmpty &&
            valetLatLng != null;

      default:
        return false;
    }
  }

  bool get canContinue {
    /* return pickedDate != null && selectedTimeLabel != null && hasValidLocation; */
    return pickedDate != null && selectedTimeLabel != null;
  }

  // ================= DATE & TIME =================

  DateTime? _composeScheduledDateTime() {
    if (pickedDate == null || selectedTimeLabel == null) return null;
    final t = DateFormat('hh:mm a').parse(selectedTimeLabel!);
    return DateTime(
      pickedDate!.year,
      pickedDate!.month,
      pickedDate!.day,
      t.hour,
      t.minute,
    );
  }

  DateTime _dateTimeFromHhmm(DateTime date, String hhmm) {
    final h = int.parse(hhmm.substring(0, 2));
    final m = int.parse(hhmm.substring(2, 4));
    return DateTime(date.year, date.month, date.day, h, m);
  }

  bool _isPastSlot(DateTime date, String hhmm) {
    final slotTime = _dateTimeFromHhmm(date, hhmm);
    return slotTime.isBefore(DateTime.now());
  }

  List<String> _generateHhmmKeysForDate(DateTime forDate) {
    final keys = <String>[];
    for (int m = _startMin; m <= _endMin; m += _stepMin) {
      final h = (m ~/ 60).toString().padLeft(2, '0');
      final mm = (m % 60).toString().padLeft(2, '0');
      final k = '$h$mm';

      if (DateUtils.isSameDay(forDate, DateTime.now()) &&
          _isPastSlot(forDate, k)) {
        continue;
      }

      keys.add(k);
    }
    return keys;
  }

  // ================= NAVIGATION =================

  void _goNext() {
    if (pickedDate == null) {
      _showError('Please select a pickup date.');
      return;
    }

    if (selectedTimeLabel == null) {
      _showError('Please select a time slot.');
      return;
    }

    /* if (!hasValidLocation) {
      _showError('Please select a service location.');
      return;
    } */

    final scheduled = _composeScheduledDateTime();
    if (scheduled == null) return;

    if (scheduled.isBefore(DateTime.now())) {
      _showError('Please select a future time.');
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ReviewAutoCareScreen()));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ================= DATE PICK =================

  Future<void> _onPickDate(DateTime? date) async {
    _bookedSub?.cancel();

    setState(() {
      pickedDate = date;
      selectedTimeLabel = null;
      _selectedHhmm = null;
      _slots = [];
      _loadingSlots = date != null;
    });

    if (date == null) return;

    final dateKey = DateFormat('yyyy-MM-dd').format(date);

    final q = FirebaseFirestore.instance
        .collection('booked_times')
        .where('date', isEqualTo: dateKey);

    _bookedSub = q.snapshots().listen(
      (snap) {
        final booked = snap.docs
            .where(
              (d) =>
                  (d.data()['location'] as String?) == widget.serviceLocation,
            )
            .map((d) => (d.data()['hhmm'] as String?) ?? '')
            .where((s) => s.isNotEmpty)
            .toSet();

        final keys = _generateHhmmKeysForDate(date);

        setState(() {
          _slots = keys
              .map(
                (k) => _SlotVM(
                  hhmm: k,
                  label: DateFormat(
                    'hh:mm a',
                  ).format(_dateTimeFromHhmm(date, k)),
                  isBooked: booked.contains(k),
                ),
              )
              .toList();
          _loadingSlots = false;
        });
      },
      onError: (_) {
        setState(() {
          _slots = _generateHhmmKeysForDate(date)
              .map(
                (k) => _SlotVM(
                  hhmm: k,
                  label: DateFormat(
                    'hh:mm a',
                  ).format(_dateTimeFromHhmm(date, k)),
                  isBooked: false,
                ),
              )
              .toList();
          _loadingSlots = false;
        });
      },
    );
  }

  /// Handle selecting a place. For 'atHome' and 'valet' we open the Map picker.
  Future<void> _handleSelectPlace(String target) async {
    if (target == 'onSite') {
      setState(() {
        placeSelected = (placeSelected == 'onSite') ? 'none' : 'onSite';
      });
      return;
    }

    final previous = placeSelected;
    setState(() => placeSelected = target);

    final result = await _showMapLocationPicker(
      context: context,
      title: target == 'atHome'
          ? 'Choose Mobile Service Location'
          : 'Choose Valet Pickup Location',
      initialAddress: target == 'atHome' ? atHomeAddress : valetAddress,
      initialLatLng: target == 'atHome' ? atHomeLatLng : valetLatLng,
    );

    if (result == null) {
      final hadExisting = target == 'atHome'
          ? (atHomeAddress != null && atHomeAddress!.trim().isNotEmpty)
          : (valetAddress != null && valetAddress!.trim().isNotEmpty);
      if (!hadExisting) {
        setState(() => placeSelected = previous);
      }
      return;
    }

    setState(() {
      if (target == 'atHome') {
        atHomeAddress = result.address;
        atHomeLatLng = LatLng(result.lat, result.lng);
      } else {
        valetAddress = result.address;
        valetLatLng = LatLng(result.lat, result.lng);
      }
    });
  }

  Future<MapLocation?> _showMapLocationPicker({
    required BuildContext context,
    required String title,
    String? initialAddress,
    LatLng? initialLatLng,
  }) {
    return showModalBottomSheet<MapLocation?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15), // 👈 smooth rounded corners
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: _MapSearchBody(
              title: title,
              initialAddress: initialAddress,
              initialLatLng: initialLatLng,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = !canContinue;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RegularButton(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: 50,
        onPressed: disabled ? null : _goNext,
        borderRadius: 8,
        textWidget: CustomText(
          text: 'Continue to Review',
          textColor: Theme.of(context).textTheme.headlineLarge?.color,
          textSize: TextSizes.heading3,
          textWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            disabled
                ? Color.fromARGB(130, 11, 85, 73)
                : Color.fromARGB(255, 11, 85, 73),

            disabled
                ? Color.fromARGB(130, 75, 161, 140)
                : Color.fromARGB(255, 75, 161, 140),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 5,
                right: 5,
                top: 30,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color.fromARGB(255, 75, 161, 140), // left (teal)
                    Color.fromARGB(
                      255,
                      30,
                      122,
                      107,
                    ), // right (slightly bluer teal)
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GoBack(
                    bgColor: Colors.white.withOpacity(0.18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: "Schedule Pickup",
                        textSize: TextSizes.heading1,
                        textWeight: FontWeight.w700,
                        textColor: Colors.white,
                      ),
                      CustomText(
                        text: "Choose when & where we collect your laundry",
                        textSize: TextSizes.bodyText1,
                        textWeight: FontWeight.normal,
                        textColor: Colors.white.withOpacity(0.85),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ✅ Date picker (NOW calls _onPickDate)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  PickupDateSection(onSelected: _onPickDate),
                  const SizedBox(height: 10),

                  // Times after date picked
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .04),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: hasPickedDate
                        ? Column(
                            key: const ValueKey('times-section'),
                            children: [
                              const SizedBox(height: 10),
                              if (_loadingSlots)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    const double spacing = 10.0;
                                    const double runSpacing = 10.0;
                                    const double targetTileWidth = 120;

                                    int columns =
                                        (constraints.maxWidth / targetTileWidth)
                                            .floor()
                                            .clamp(2, 4);
                                    final double totalSpacing =
                                        spacing * (columns - 1);
                                    final double itemWidth =
                                        (constraints.maxWidth - totalSpacing) /
                                        columns;

                                    return Wrap(
                                      spacing: spacing,
                                      runSpacing: runSpacing,
                                      children: [
                                        for (final slot in _slots)
                                          SizedBox(
                                            width: itemWidth,
                                            child: GestureDetector(
                                              onTap: () {
                                                if (slot.isBooked) return;
                                                if (pickedDate != null &&
                                                    _isPastSlot(
                                                      pickedDate!,
                                                      slot.hhmm,
                                                    )) {
                                                  return;
                                                }
                                                setState(() {
                                                  _selectedHhmm = slot.hhmm;
                                                  selectedTimeLabel =
                                                      slot.label;
                                                });
                                              },
                                              child: _TimeTile(
                                                label: slot.label,
                                                isSelected:
                                                    _selectedHhmm == slot.hhmm,
                                                isBooked: slot.isBooked,
                                                selectedFill: Color.fromARGB(
                                                  255,
                                                  30,
                                                  122,
                                                  107,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),

                  const SizedBox(height: 50),

                  Row(
                    children: const [
                      Icon(
                        Icons.location_on,
                        color: Color.fromARGB(255, 75, 161, 140),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Service Location",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                  // 1) On-site (Washing bay)
                  widget.serviceType == 'express' ||
                          widget.serviceType == 'standard'
                      ? SizedBox()
                      : GestureDetector(
                          onTap: () => _handleSelectPlace('onSite'),
                          child: _PlaceTile(
                            selected: placeSelected == 'onSite',
                            borderColor: placeSelected == 'onSite'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.inversePrimary,
                            fillColor: placeSelected == 'onSite'
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.inversePrimary,
                            iconBgSelected: placeSelected == "onSite",
                            iconAsset: 'assets/icons/emoji_transportation.svg',
                            title: 'Visit Our Washing Bay',
                            // ✅ show the fixed on-site address
                            subtitle:
                                onSiteAddress ??
                                'Omeeo Car Wash • Sowutuom, Accra',
                          ),
                        ),

                  const SizedBox(height: 20),

                  // 2) Mobile Service (tap to pick location)
                  GestureDetector(
                    onTap: () => _handleSelectPlace('atHome'),
                    child: _PlaceTile(
                      selected: placeSelected == 'atHome',
                      borderColor: placeSelected == 'atHome'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.inversePrimary,
                      fillColor: placeSelected == 'atHome'
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.inversePrimary,
                      iconBgSelected: placeSelected == "atHome",
                      iconAsset: 'assets/icons/family_group.svg',
                      subtitle:
                          atHomeAddress ?? "We'll come to your home or office",
                      title: 'Mobile Service',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3) Valet Service (tap to pick pickup location)
                  GestureDetector(
                    onTap: () => _handleSelectPlace('valet'),
                    child: _PlaceTile(
                      selected: placeSelected == 'valet',
                      borderColor: placeSelected == 'valet'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.inversePrimary,
                      fillColor: placeSelected == 'valet'
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.inversePrimary,
                      iconBgSelected: placeSelected == "valet",
                      iconAsset: 'assets/icons/parking_valet.svg',
                      title: 'Valet Service',
                      subtitle:
                          valetAddress ??
                          "We’ll pick up, clean, and return your car.",
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context, {
    required String left,
    required String right,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: left,
          textColor: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        CustomText(text: right, textWeight: FontWeight.bold),
      ],
    );
  }
}

class _SlotVM {
  final String hhmm;
  final String label;
  final bool isBooked;
  const _SlotVM({
    required this.hhmm,
    required this.label,
    required this.isBooked,
  });
}

class _TimeTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isBooked;
  final Color selectedFill;

  const _TimeTile({
    required this.label,
    required this.isSelected,
    required this.isBooked,
    required this.selectedFill,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? Color.fromARGB(255, 30, 122, 107)
        : Color.fromARGB(255, 214, 216, 216);

    final bgColor = isSelected ? selectedFill : Colors.white;

    final textColor = isSelected
        ? Theme.of(context).textTheme.headlineLarge?.color
        : Theme.of(context).textTheme.labelSmall?.color;

    return Opacity(
      opacity: isBooked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(width: 1.5, color: borderColor),
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(94, 71, 111, 104),
              blurRadius: 30,
              spreadRadius: 1,
              offset: const Offset(0, 13),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBooked) ...[
              Icon(
                Icons.lock,
                size: 16,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: CustomText(
                text: label,
                textColor: textColor,
                textSize: TextSizes.subtitle2,
                textWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// PickupDateSection (Horizontal scroll + tap selects date)
/// ===============================================================
class PickupDateSection extends StatefulWidget {
  const PickupDateSection({
    super.key,
    this.initialDays = 7,
    this.onSelected,
    this.initialSelectedIndex = 0,
  });

  final int initialDays;
  final int initialSelectedIndex;
  final ValueChanged<DateTime?>? onSelected;

  @override
  State<PickupDateSection> createState() => _PickupDateSectionState();
}

class _PickupDateSectionState extends State<PickupDateSection> {
  late final List<DateTime> _days;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.initialSelectedIndex.clamp(
      0,
      widget.initialDays - 1,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _days = List.generate(
      widget.initialDays,
      (i) => today.add(Duration(days: i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.calendar_month_rounded,
              color: Color.fromARGB(255, 75, 161, 140),
              size: 18,
            ),
            SizedBox(width: 10),
            Text(
              "Pickup Date & Time",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Container(
          height: 80,
          child: ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final date = _days[index];
                final isSelected = index == _selectedIndex;

                final topLabel = _topLabelFor(date, index);
                final dayNum = DateFormat('d').format(date);
                final month = DateFormat('MMM').format(date);

                return _DayCard(
                  topLabel: topLabel,
                  dayNumber: dayNum,
                  month: month,
                  selected: isSelected,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    widget.onSelected?.call(date); // ✅ triggers time section
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _topLabelFor(DateTime d, int index) {
    if (index == 0) return "Today";
    if (index == 1) return "Tomorrow";
    return DateFormat('EEE').format(d);
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.topLabel,
    required this.dayNumber,
    required this.month,
    required this.selected,
    required this.onTap,
  });

  final String topLabel;
  final String dayNumber;
  final String month;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color.fromARGB(255, 75, 161, 140)
        : const Color.fromARGB(255, 212, 226, 226);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 2.5 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                topLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color.fromARGB(255, 75, 161, 140)
                      : const Color(0xFF5E5E5E),
                ),
              ),

              Text(
                dayNumber,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F1F1F),
                ),
              ),

              Text(
                month,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color.fromARGB(255, 75, 161, 140)
                      : const Color(0xFF7A7A7A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
