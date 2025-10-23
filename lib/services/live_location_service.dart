import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocationService {
  final FirebaseFirestore db;
  StreamSubscription<Position>? _sub;
  double? _lastLat, _lastLng;
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);

  LiveLocationService(this.db);

  Future<void> start({
    required String driverId,
    required String bookingId,
    Duration minWriteGap = const Duration(seconds: 5),
    int minMoveMeters = 50,
  }) async {
    // 1) Permission
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are disabled.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      throw Exception('Location permission not granted.');
    }

    // 2) Stream settings
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    );

    await _sub?.cancel();
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) async {
        final now = DateTime.now();
        final movedEnough = _lastLat == null
            ? true
            : Geolocator.distanceBetween(
                    _lastLat!,
                    _lastLng!,
                    pos.latitude,
                    pos.longitude,
                  ) >=
                  minMoveMeters;
        final spacedEnough = now.difference(_lastWrite) >= minWriteGap;
        if (!movedEnough && !spacedEnough) return;

        _lastWrite = now;
        _lastLat = pos.latitude;
        _lastLng = pos.longitude;

        // Write to the booking's live doc (what the customer watches)
        final liveRef = db
            .collection('bookings')
            .doc(bookingId)
            .collection('runtime')
            .doc('live');
        await liveRef.set({
          'driverId': driverId,
          'lat': pos.latitude,
          'lng': pos.longitude,
          'speed': pos.speed,
          'heading': pos.heading,
          'accuracy': pos.accuracy,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      },
      onError: (e) => print('Location stream error: $e'),
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
