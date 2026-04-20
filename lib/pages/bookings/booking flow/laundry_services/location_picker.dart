import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/service_review.dart';
import 'package:omeeowash/pages/profile/addresses.dart'
    hide PickedLocationResult;
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class GoogleMapLocationPickerScreen extends StatefulWidget {
  final String serviceType;

  const GoogleMapLocationPickerScreen({super.key, required this.serviceType});

  @override
  State<GoogleMapLocationPickerScreen> createState() =>
      _GoogleMapLocationPickerScreenState();
}

class _GoogleMapLocationPickerScreenState
    extends State<GoogleMapLocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(5.6037, -0.1870); // Accra

  GoogleMapController? _mapController;
  LatLng _mapCenter = _defaultCenter;

  bool _isMapReady = false;
  bool _isResolvingAddress = true;
  bool _isFetchingCurrentLocation = false;

  String _title = 'Fetching address...';
  String _subtitle = '';
  Placemark? _placemark;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _reverseGeocode(_mapCenter);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocode(LatLng target) async {
    setState(() {
      _isResolvingAddress = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );

      if (!mounted) return;

      if (placemarks.isEmpty) {
        setState(() {
          _placemark = null;
          _title = 'Selected location';
          _subtitle =
              '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
          _isResolvingAddress = false;
        });
        return;
      }

      final p = placemarks.first;

      final titleParts = <String>[
        if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
        if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
      ];

      final subtitleParts = <String>[
        if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
        if ((p.administrativeArea ?? '').trim().isNotEmpty)
          p.administrativeArea!.trim(),
        if ((p.country ?? '').trim().isNotEmpty) p.country!.trim(),
      ];

      setState(() {
        _placemark = p;
        _title = titleParts.isNotEmpty
            ? titleParts.join(', ')
            : 'Selected location';
        _subtitle = subtitleParts.isNotEmpty
            ? subtitleParts.join(', ')
            : '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
        _isResolvingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _placemark = null;
        _title = 'Selected location';
        _subtitle =
            '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
        _isResolvingAddress = false;
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isFetchingCurrentLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        setState(() {
          _isFetchingCurrentLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission was not granted.')),
        );
        setState(() {
          _isFetchingCurrentLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      final target = LatLng(position.latitude, position.longitude);

      _mapCenter = target;

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 17),
        ),
      );

      await _reverseGeocode(target);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
  }

  void _onDone() {
    final result = PickedLocationResult(
      latitude: _mapCenter.latitude,
      longitude: _mapCenter.longitude,
      addressLine: _title,
      subtitle: _subtitle,
      serviceType: widget.serviceType,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PickupPreviewScreen(pickupLocation: result, selectedService: ''),
      ),
    );
  }

  void _onDoneAddressDetails() {
    final result = PickedLocationResult(
      latitude: _mapCenter.latitude,
      longitude: _mapCenter.longitude,
      addressLine: _title,
      subtitle: _subtitle,
      serviceType: widget.serviceType,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddressDetailsScreen(
          addressType: AddressType.other,
          initialName: '',
          initialLocation: result.addressLine,
          initialInstructions: '',
          initialLatitude: result.latitude,
          initialLongitude: result.longitude,
          initialSubtitle: result.subtitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _defaultCenter,
                zoom: 16,
              ),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                setState(() {
                  _isMapReady = true;
                });
              },
              onCameraMove: (position) {
                _mapCenter = position.target;
              },
              onCameraIdle: () {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 250), () {
                  _reverseGeocode(_mapCenter);
                });
              },
            ),
          ),

          Center(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE67E22),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.moped,
                        size: 26,
                        color: Color(0xFF000000),
                      ),
                    ),
                    Container(width: 3, height: 16, color: Colors.black87),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            top: 40,
            child: _RoundMapButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),

          Positioned(
            right: 16,
            bottom: 230,
            child: _RoundMapButton(
              icon: _isFetchingCurrentLocation
                  ? Icons.more_horiz_rounded
                  : Icons.navigation_outlined,
              onTap: _isFetchingCurrentLocation ? null : _goToCurrentLocation,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomAddressCard(
              title: 'Destination address',
              areaText: _subtitle,
              streetText: _title,
              isLoading: _isResolvingAddress || !_isMapReady,
              onDoneTap: (_isResolvingAddress || !_isMapReady) ? null : _onDone,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAddressCard extends StatelessWidget {
  final String title;
  final String areaText;
  final String streetText;
  final bool isLoading;
  final VoidCallback? onDoneTap;

  const _BottomAddressCard({
    required this.title,
    required this.areaText,
    required this.streetText,
    required this.isLoading,
    this.onDoneTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 25),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.location_on,
                  size: 20,
                  color: Color(0xFFE67E22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: LinearProgressIndicator(minHeight: 3),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            areaText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            streetText,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: onDoneTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 33, 33, 33),
                disabledBackgroundColor: const Color.fromARGB(255, 33, 33, 33),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE67E22),
                ),
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

  const _RoundMapButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(0xFFFFF9FB),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: const Color.fromARGB(255, 0, 0, 0),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _RoundMapButton2 extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundMapButton2({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color(0xFFFFF9FB),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: const Color.fromARGB(255, 0, 0, 0),
            size: 22,
          ),
        ),
      ),
    );
  }
}
