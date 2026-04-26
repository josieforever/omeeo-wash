import 'dart:async';
import 'dart:convert' as json;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/confirm_booking.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

const String kGoogleApiKey = 'AIzaSyBVg_L9lz2x5IdK9yvuNkVYfpDYVyy6zbA';
const LatLng kDefaultMapCenter = LatLng(5.6288569, -0.2725429);

class LaundryServicestDateScreen extends StatefulWidget {
  final int duration;
  final String? serviceType;
  final Set<String>? addOns;

  const LaundryServicestDateScreen({
    super.key,
    required this.duration,
    this.serviceType,
    this.addOns,
  });

  @override
  State<LaundryServicestDateScreen> createState() =>
      _LaundryServicestDateScreenState();
}

class _LaundryServicestDateScreenState
    extends State<LaundryServicestDateScreen> {
  late final String serviceType;

  DateTime? pickedDate;
  String? selectedTimeLabel;
  String? _selectedHhmm;

  String? pickupAddress;
  LatLng? pickupLatLng;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookedSub;

  List<_SlotVM> _slots = [];
  bool _loadingSlots = false;

  static const int _startMin = 8 * 60; // 08:00
  static const int _endMin = 15 * 60; // 15:00
  static const int _stepMin = 30;

  bool get hasPickedDate => pickedDate != null;

  bool get hasValidLocation {
    final address = pickupAddress;
    return address != null && address.trim().isNotEmpty && pickupLatLng != null;
  }

  bool get canContinue {
    return pickedDate != null && selectedTimeLabel != null && hasValidLocation;
  }

  String get selectedServiceLocation => pickupAddress ?? '';

  @override
  void initState() {
    super.initState();
    serviceType =
        (widget.serviceType != null && widget.serviceType!.trim().isNotEmpty)
        ? widget.serviceType!
        : 'laundry';
  }

  @override
  void dispose() {
    _bookedSub?.cancel();
    super.dispose();
  }

  DateTime? _composeScheduledDateTime() {
    final date = pickedDate;
    final label = selectedTimeLabel;

    if (date == null || label == null) return null;

    final t = DateFormat('hh:mm a').parse(label);
    return DateTime(date.year, date.month, date.day, t.hour, t.minute);
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

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goNext() {
    if (pickedDate == null) {
      _showError('Please select a pickup date.');
      return;
    }

    if (selectedTimeLabel == null) {
      _showError('Please select a time slot.');
      return;
    }

    if (!hasValidLocation) {
      _showError('Please choose your pickup location.');
      return;
    }

    final scheduled = _composeScheduledDateTime();
    if (scheduled == null) {
      _showError('Please select a valid schedule.');
      return;
    }

    if (scheduled.isBefore(DateTime.now())) {
      _showError('Please select a future time.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmBooking(
          scheduledTime: scheduled,
          serviceLocation: selectedServiceLocation,
          vehicleType: widget.serviceType ?? 'laundry',
          duration: widget.duration,
        ),
      ),
    );
  }

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
        final currentLocation = selectedServiceLocation;

        final booked = snap.docs
            .where((d) => (d.data()['location'] as String?) == currentLocation)
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

  Future<void> _pickValetLocation() async {
    final result = await _showMapLocationPicker(
      context: context,
      title: 'Choose Pickup Location',
      initialAddress: pickupAddress,
      initialLatLng: pickupLatLng,
    );

    if (result == null) return;

    setState(() {
      pickupAddress = result.address;
      pickupLatLng = LatLng(result.lat, result.lng);
    });

    if (pickedDate != null) {
      await _onPickDate(pickedDate);
    }
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
      builder: (_) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
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
    final disabled = !canContinue;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RegularButton(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        height: 50,
        onPressed: () {
          if (disabled) return;
          _goNext();
        },
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
                ? const Color.fromARGB(130, 85, 11, 79)
                : const Color.fromARGB(255, 85, 11, 79),
            disabled
                ? const Color.fromARGB(130, 161, 75, 154)
                : const Color.fromARGB(255, 161, 75, 154),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    Color.fromARGB(255, 202, 88, 176),
                    Color.fromARGB(255, 139, 97, 198),
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
                        text: 'Schedule Pickup',
                        textSize: TextSizes.heading1,
                        textWeight: FontWeight.w700,
                        textColor: Colors.white,
                      ),
                      CustomText(
                        text: 'Choose when & where we collect your laundry',
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
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  PickupDateSection(onSelected: _onPickDate),
                  const SizedBox(height: 10),
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
                                    const double targetTileWidth = 120.0;

                                    final columns =
                                        (constraints.maxWidth / targetTileWidth)
                                            .floor()
                                            .clamp(2, 4);
                                    final totalSpacing =
                                        spacing * (columns - 1);
                                    final itemWidth =
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
                                                selectedFill:
                                                    const Color.fromARGB(
                                                      255,
                                                      145,
                                                      38,
                                                      152,
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
                        color: Color(0xFF912698),
                        size: 18,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Pickup Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickValetLocation,
                    child: _PlaceTile(
                      selected: hasValidLocation,
                      borderColor: hasValidLocation
                          ? const Color(0xFF912698)
                          : Theme.of(context).colorScheme.inversePrimary,
                      fillColor: Theme.of(context).colorScheme.inversePrimary,
                      iconBgSelected: hasValidLocation,
                      iconAsset: 'assets/icons/moped_package.svg',
                      title: 'Pickup Location',
                      subtitle:
                          pickupAddress ??
                          'Choose where we should pick up your laundry.',
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
}

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
  final Uuid _uuid = const Uuid();
  String _sessionToken = const Uuid().v4();

  MapLocation? _searchResult;
  bool _showMapView = false;

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
                              _sessionToken = _uuid.v4();
                            }
                            return _fetchSuggestions(pattern);
                          },
                          builder: (context, controller, focusNode) {
                            if (widget.initialAddress != null &&
                                widget.initialAddress!.trim().isNotEmpty &&
                                controller.text.isEmpty) {
                              controller.text = widget.initialAddress!;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length),
                              );
                            }

                            return TextField(
                              controller: controller,
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          },
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
                            FocusScope.of(context).unfocus();

                            final details = await _fetchPlaceDetail(
                              suggestion.placeId,
                            );

                            if (details == null) {
                              if (!mounted) return;
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
                        address: widget.initialAddress,
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
        locationBias = '${pos.latitude},${pos.longitude}';
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

    final data = json.jsonDecode(res.body);
    if ((data['status'] ?? '') != 'OK') {
      final fallback = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {...params..remove('components')},
      );
      final res2 = await http.get(fallback);
      if (res2.statusCode != 200) return [];

      final data2 = json.jsonDecode(res2.body);
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

    final data = json.jsonDecode(res.body);
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
    });
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
              text: 'Search a place or tap the map icon to drop a pin.',
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fetching current location...')),
    );

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _moveTo(LatLng(pos.latitude, pos.longitude));
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMarker = selectedLatLng != null
        ? Marker(
            markerId: const MarkerId('selected'),
            position: selectedLatLng!,
          )
        : null;

    return Column(
      children: [
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
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.initialLatLng ?? kDefaultMapCenter,
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  onMapCreated: (c) => mapController = c,
                  onTap: (latLng) async {
                    await _moveTo(latLng);
                  },
                  markers: {if (selectedMarker != null) selectedMarker},
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
        RegularButton(
          onPressed: () {
            final latLng = selectedLatLng;
            if (latLng == null) {
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
                lat: latLng.latitude,
                lng: latLng.longitude,
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

class MapLocation {
  final String address;
  final double lat;
  final double lng;

  MapLocation({required this.address, required this.lat, required this.lng});

  LatLng toLatLng() => LatLng(lat, lng);
}

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
        ? const Color.fromARGB(255, 145, 38, 152)
        : const Color.fromARGB(255, 214, 216, 216);

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
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(94, 111, 71, 110),
              blurRadius: 30,
              spreadRadius: 1,
              offset: Offset(0, 13),
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
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(255, 188, 167, 189),
            blurRadius: 30,
            spreadRadius: 1,
            offset: Offset(0, 13),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 242, 226, 243),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Transform.scale(
              scale: 1.4,
              child: SvgPicture.asset(
                iconAsset,
                height: 30,
                width: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF912698),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
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
              color: Color.fromARGB(255, 145, 38, 152),
              size: 18,
            ),
            SizedBox(width: 10),
            Text(
              'Pickup Date & Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
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
                    widget.onSelected?.call(date);
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
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    return DateFormat('EEE').format(d);
  }
}

class _DayCard extends StatelessWidget {
  final String topLabel;
  final String dayNumber;
  final String month;
  final bool selected;
  final VoidCallback onTap;

  const _DayCard({
    required this.topLabel,
    required this.dayNumber,
    required this.month,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color.fromARGB(255, 145, 38, 152)
        : const Color.fromARGB(255, 222, 212, 226);

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
                      ? const Color.fromARGB(255, 126, 61, 131)
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
                      ? const Color.fromARGB(255, 126, 61, 131)
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
