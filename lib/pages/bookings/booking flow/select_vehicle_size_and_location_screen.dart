import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

// ⚠️ IMPORTANT: Ensure this key has Places API enabled.
const String kGoogleApiKey = 'AIzaSyAhUAyOfnZrilFp3OVqH1vEmpn0j5fL8SY';

/// ---- On-site (washing bay) constants ----
const String kOmeeoWashAddress = 'Israel Teikofio Street, Sowutuom, Accra';
const LatLng kOmeeoWashLatLng = LatLng(5.6288569, -0.2725429);

class SelectVehicleAndLocationScreen extends StatefulWidget {
  final int duration;
  final String? serviceType; // "express" | "standard" | "premium"
  final double? price;
  final DateTime scheduledTime; // from SelectDateScreen
  const SelectVehicleAndLocationScreen({
    super.key,
    this.serviceType,
    this.price,
    required this.scheduledTime,
    required this.duration,
  });

  @override
  State<SelectVehicleAndLocationScreen> createState() =>
      _SelectVehicleAndLocationScreenState();
}

class _SelectVehicleAndLocationScreenState
    extends State<SelectVehicleAndLocationScreen> {
  String placeSelected = "none"; // onSite | atHome | valet | none
  String carSelected = "none"; // hatchback | sedan | suv | truck | none

  // Saved addresses & coordinates for On-site, Mobile (atHome) and Valet
  String? onSiteAddress = kOmeeoWashAddress;
  String? atHomeAddress;
  String? valetAddress;

  LatLng? onSiteLatLng = kOmeeoWashLatLng;
  LatLng? atHomeLatLng;
  LatLng? valetLatLng;

  bool get _canContinue => placeSelected != 'none' && carSelected != 'none';

  // --- Helpers ---
  String _normalizeServiceLocation(String place) {
    switch (place) {
      case 'onSite':
        return 'washing_bay';
      case 'atHome':
        return 'mobile';
      case 'valet':
        return 'valet';
      default:
        return 'washing_bay';
    }
  }

  Future<void> _onContinue() async {
    if (!_canContinue) return;

    // Validate address when required
    if (placeSelected == 'atHome' && atHomeLatLng == null) {
      // prompt to pick address
      final res = await _showMapLocationPicker(
        context: context,
        title: 'Choose Mobile Service Location',
        initialAddress: atHomeAddress,
        initialLatLng: atHomeLatLng,
      );
      if (res == null) return;
      setState(() {
        atHomeAddress = res.address;
        atHomeLatLng = LatLng(res.lat, res.lng);
      });
    } else if (placeSelected == 'valet' && valetLatLng == null) {
      final res = await _showMapLocationPicker(
        context: context,
        title: 'Choose Valet Pickup Location',
        initialAddress: valetAddress,
        initialLatLng: valetLatLng,
      );
      if (res == null) return;
      setState(() {
        valetAddress = res.address;
        valetLatLng = LatLng(res.lat, res.lng);
      });
    }

    // Build location payload
    final serviceLocation = _normalizeServiceLocation(placeSelected);

    String? address;
    LatLng? coords;
    if (placeSelected == 'atHome') {
      address = atHomeAddress;
      coords = atHomeLatLng;
    } else if (placeSelected == 'valet') {
      address = valetAddress;
      coords = valetLatLng;
    } else {
      // ✅ onSite – use our washing bay constants
      address = onSiteAddress;
      coords = onSiteLatLng;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => ConfirmBooking(
          // Forward everything needed to create the Booking + booked_times later
          serviceType: widget.serviceType,
          price: widget.price,
          scheduledTime: widget.scheduledTime,
          serviceLocation:
              serviceLocation, // "washing_bay" | "mobile" | "valet"
          vehicleType: carSelected, // "hatchback" | "sedan" | "suv" | "truck"
          address: address,
          duration: widget.duration,
          latitude: coords?.latitude,
          longitude: coords?.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<double> progressIndicatorValues = [0.25, 0.5, 0.75, 1.0];
    debugPrint('service type  ======>>>>>>>>> ${widget.serviceType}');

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RegularButton(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: 60,
        onPressed: _canContinue ? _onContinue : null,
        borderRadius: 8,
        textWidget: CustomText(
          text: 'Continue to Review',
          textColor: Theme.of(context).colorScheme.inversePrimary,
          textSize: TextSizes.heading3,
          textWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: _canContinue
              ? const [
                  Color.fromARGB(255, 198, 198, 198),
                  Color.fromARGB(255, 44, 44, 44),
                ]
              : [
                  Color.fromARGB(184, 215, 215, 215),
                  Color.fromARGB(162, 65, 65, 65),
                ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            Align(
              alignment: Alignment.topRight,
              child: GoBack(
                bgColor: Theme.of(context).colorScheme.tertiary,
                onPressed: () => Navigator.pop(context),
              ),
            ),

            const SizedBox(height: 10),
            // step 3 of 4 in the flow
            LnProgressIndicator(value: progressIndicatorValues[2]),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: "Service Location",
                  textSize: TextSizes.subtitle1,
                  textWeight: FontWeight.w600,
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: "Choose where you'd like us to wash your vehicle",
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.normal,
                  textColor: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 1) On-site (Washing bay)
            widget.serviceType == 'express' || widget.serviceType == 'standard'
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
                          onSiteAddress ?? 'Omeeo Car Wash • Sowutuom, Accra',
                    ),
                  ),

            const SizedBox(height: 10),

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
                subtitle: atHomeAddress ?? "We'll come to your home or office",
                title: 'Mobile Service',
              ),
            ),

            const SizedBox(height: 10),

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

            const SizedBox(height: 15),
            widget.serviceType == 'express' || widget.serviceType == 'standard'
                ? const SizedBox(height: 40)
                : SizedBox(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: "Vehicle Type",
                  textSize: TextSizes.subtitle1,
                  textWeight: FontWeight.w600,
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: "Tell us about your vehicle for the best service",
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.normal,
                  textColor: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Hatchback
            GestureDetector(
              onTap: () => setState(() => carSelected = 'hatchback'),
              child: _CarTile(
                selected: carSelected == 'hatchback',
                borderColor: carSelected == 'hatchback'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.inversePrimary,
                fillColor: carSelected == 'hatchback'
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.inversePrimary,
                iconBgSelected: carSelected == "hatchback",
                imageAsset: 'assets/images/hatchback.png',
                imageScale: 1.5,
                title: 'Hatchback, Subcompact Hatchback',
              ),
            ),
            const SizedBox(height: 10),

            // Sedan
            GestureDetector(
              onTap: () => setState(() => carSelected = 'sedan'),
              child: _CarTile(
                selected: carSelected == 'sedan',
                borderColor: carSelected == 'sedan'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.inversePrimary,
                fillColor: carSelected == 'sedan'
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.inversePrimary,
                iconBgSelected: carSelected == "sedan",
                imageAsset: 'assets/images/sedan.png',
                imageScale: 1.7,
                title: 'Sedan, Saloon',
              ),
            ),
            const SizedBox(height: 10),

            // SUV
            GestureDetector(
              onTap: () => setState(() => carSelected = 'suv'),
              child: _CarTile(
                selected: carSelected == 'suv',
                borderColor: carSelected == 'suv'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.inversePrimary,
                fillColor: carSelected == 'suv'
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.inversePrimary,
                iconBgSelected: carSelected == "suv",
                imageAsset: 'assets/images/suv.png',
                imageScale: 1.5,
                title: 'SUV, Off-Roader',
              ),
            ),
            const SizedBox(height: 10),

            // Truck
            GestureDetector(
              onTap: () => setState(() => carSelected = 'truck'),
              child: _CarTile(
                selected: carSelected == 'truck',
                borderColor: carSelected == 'truck'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.inversePrimary,
                fillColor: carSelected == 'truck'
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.inversePrimary,
                iconBgSelected: carSelected == "truck",
                imageAsset: 'assets/images/truck.png',
                imageScale: 1.6,
                title: 'Truck',
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
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

  // Map picker bottom sheet
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
}

// -----------------------------------------------------------------------------
// NEW: Map Picker Container (Search + Map View) with working TypeAhead
// -----------------------------------------------------------------------------
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
        borderRadius: BorderRadius.circular(20),
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
              scale: 1.4,
              child: SvgPicture.asset(
                iconAsset,
                height: 30,
                width: 24,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
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
