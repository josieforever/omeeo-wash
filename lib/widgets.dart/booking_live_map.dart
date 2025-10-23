import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BookingLiveMap extends StatefulWidget {
  final String bookingId;
  const BookingLiveMap({super.key, required this.bookingId});

  @override
  State<BookingLiveMap> createState() => _BookingLiveMapState();
}

class _BookingLiveMapState extends State<BookingLiveMap> {
  GoogleMapController? _map;
  Marker? _driverMarker;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    final liveRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .collection('runtime')
        .doc('live');

    _sub = liveRef.snapshots().listen((snap) {
      final d = snap.data();
      if (d == null) return;
      final lat = (d['lat'] as num?)?.toDouble();
      final lng = (d['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;

      final pos = LatLng(lat, lng);
      setState(() {
        _driverMarker = Marker(
          markerId: const MarkerId('driver'),
          position: pos,
          infoWindow: const InfoWindow(title: 'Valet driver'),
        );
      });
      _map?.animateCamera(CameraUpdate.newLatLng(pos));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(5.6037, -0.1870), // Accra default
          zoom: 13,
        ),
        markers: {if (_driverMarker != null) _driverMarker!},
        onMapCreated: (c) => _map = c,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
