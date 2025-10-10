import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

// Google Places Autocomplete
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

// App imports
import 'package:omeeowash/pages/bookings/booking%20flow/common_widgets.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

const String kGoogleApiKey = 'AIzaSyAhUAyOfnZrilFp3OVqH1vEmpn0j5fL8SY';

class SelectVehicleAndLocationScreen extends StatefulWidget {
  final String? serviceType;
  const SelectVehicleAndLocationScreen({super.key, this.serviceType});

  @override
  State<SelectVehicleAndLocationScreen> createState() =>
      _SelectVehicleAndLocationScreenState();
}

class _SelectVehicleAndLocationScreenState
    extends State<SelectVehicleAndLocationScreen> {
  String placeSelected = "none"; // onSite | atHome | valet | none
  String carSelected = "none"; // hatchback | sedan | suv | truck | none

  // Saved addresses & coordinates for Mobile (atHome) and Valet
  String? atHomeAddress;
  String? valetAddress;
  LatLng? atHomeLatLng;
  LatLng? valetLatLng;

  @override
  void initState() {
    super.initState();
  }

  bool get _canContinue => placeSelected != 'none' && carSelected != 'none';

  @override
  Widget build(BuildContext context) {
    const List<double> progressIndicatorValues = [0.25, 0.5, 0.75, 1.0];

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RegularButton(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: 60,
        onPressed: () {
          if (!_canContinue) return;
          // TODO: proceed to next step with: placeSelected, atHome/valet address (+coords), carSelected
        },
        borderRadius: 8,
        textWidget: CustomText(
          text: 'Continue to Location',
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
                  Color.fromARGB(255, 73, 64, 241),
                  Color.fromARGB(255, 149, 60, 237),
                ]
              : const [
                  Color.fromARGB(97, 193, 193, 193),
                  Color.fromARGB(255, 193, 193, 193),
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
            LnProgressIndicator(value: progressIndicatorValues[0]),
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
            GestureDetector(
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
                subtitle:
                    'Bring your vehicle to one of our professional locations',
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
                title: 'Mobile Service',
                subtitle: atHomeAddress ?? "We'll come to your home or office",
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
      // Toggle on-site (no map needed)
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
      // Revert selection if there was no previously saved point
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
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _MapPickerBody(
          title: title,
          initialAddress: initialAddress,
          initialLatLng: initialLatLng,
        );
      },
    );
  }
}

// Map picker body

class _MapPickerBody extends StatefulWidget {
  final String title;
  final String? initialAddress;
  final LatLng? initialLatLng;

  const _MapPickerBody({
    required this.title,
    this.initialAddress,
    this.initialLatLng,
  });

  @override
  State<_MapPickerBody> createState() => _MapPickerBodyState();
}

class _MapPickerBodyState extends State<_MapPickerBody> {
  final TextEditingController _searchController = TextEditingController();
  LatLng? selectedLatLng;
  String currentAddress = '';
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    selectedLatLng = widget.initialLatLng;
    currentAddress = widget.initialAddress ?? '';

    if (currentAddress.isNotEmpty) {
      _searchController.text = currentAddress;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _moveTo(LatLng latLng) async {
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

    if (mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 16),
        ),
      );
    }
  }

  // 1. New method to zoom in
  void _zoomIn() {
    mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  // 2. New method to zoom out
  void _zoomOut() {
    mapController?.animateCamera(CameraUpdate.zoomOut());
  }

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

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xFFE8E3FF), Color(0xFFF1E1FF)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
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

              // Places search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      width: 1,
                    ),
                  ),
                  child: GooglePlaceAutoCompleteTextField(
                    // FIX 2: Pass the declared controller
                    textEditingController: _searchController,
                    googleAPIKey: kGoogleApiKey,

                    language: 'en',

                    // FIX 3: Use the correct 'countries' property
                    countries: const ["gh"],

                    // ESSENTIAL: Set to true to enable lat/lng retrieval
                    isLatLngRequired: true,

                    // This boxDecoration affects the autocomplete suggestion box, not the TextField.
                    boxDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),

                    inputDecoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      hintText: 'Search for a new location...',
                      border: InputBorder.none,
                      icon: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),

                    // FIX 4: Use getPlaceDetailWithLatLng for reliable coordinates
                    getPlaceDetailWithLatLng: (Prediction prediction) async {
                      final lat = double.tryParse(prediction.lat ?? '');
                      final lng = double.tryParse(prediction.lng ?? '');

                      if (lat != null && lng != null) {
                        final latLng = LatLng(lat, lng);
                        await _moveTo(latLng);
                        // Update the text field with the selected description
                        _searchController.text = prediction.description ?? '';
                        setState(() {});
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not get coordinates for selected place.',
                            ),
                          ),
                        );
                      }
                    },

                    // We also need to set the itemClick callback
                    itemClick: (Prediction prediction) {
                      // This runs first when an item is clicked. We use it to populate the text field.
                      _searchController.text = prediction.description ?? '';
                      _searchController.selection = TextSelection.fromPosition(
                        TextPosition(
                          offset: prediction.description?.length ?? 0,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Address display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).textTheme.headlineLarge?.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentAddress.isEmpty
                        ? 'Tap the map to drop a pin'
                        : currentAddress,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Use current location
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
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
              ),

              // Map
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    // 3. Use Stack to overlay buttons on the map
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target:
                                widget.initialLatLng ??
                                const LatLng(5.614818, -0.205874),
                            zoom: 14,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          // Keep zoom controls disabled for custom buttons
                          zoomControlsEnabled: false,
                          onMapCreated: (c) => mapController = c,
                          onTap: (latLng) async {
                            await _moveTo(latLng);
                            setState(() {});
                          },
                          markers: {if (selectedMarker != null) selectedMarker},
                          // 💡 THE FIX: Allow vertical drag gestures to be handled by the map
                          // even though a parent widget (DraggableScrollableSheet) also wants them.
                          gestureRecognizers:
                              <Factory<OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                                Factory<PanGestureRecognizer>(
                                  () => PanGestureRecognizer(),
                                ),
                                Factory<VerticalDragGestureRecognizer>(
                                  () => VerticalDragGestureRecognizer(),
                                ),
                              },
                        ),

                        // 4. Custom Zoom Buttons
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Column(
                            children: [
                              Transform.scale(
                                scale: 0.7,
                                child: FloatingActionButton.small(
                                  heroTag: 'zoom_in',
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
                                  heroTag: 'zoom_out',
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
              ),

              const SizedBox(height: 10),

              // Confirm
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: RegularButton(
                  onPressed: () {
                    if (selectedLatLng == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please drop a pin on the map.'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 10,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Color.fromARGB(255, 73, 64, 241),
                      Color.fromARGB(255, 149, 60, 237),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Simple holder for address + coordinates
class MapLocation {
  final String address;
  final double lat;
  final double lng;
  MapLocation({required this.address, required this.lat, required this.lng});
}

// Presentational tiles

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
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(26, 0, 0, 0),
            blurRadius: 12,
            spreadRadius: 2,
            offset: Offset(0, 6),
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
                  : Theme.of(context).colorScheme.secondary,
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
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(26, 0, 0, 0),
            blurRadius: 12,
            spreadRadius: 2,
            offset: Offset(0, 6),
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
                  : Theme.of(context).colorScheme.secondary,
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
