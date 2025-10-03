import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omeeowash/models/booking_model.dart';
import 'package:provider/provider.dart';

class BookingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Booking? _booking; // For a single booking detail screen
  List<Booking> _bookings = []; // For a user’s full booking list

  StreamSubscription<DocumentSnapshot>? _bookingSubscription;
  StreamSubscription<QuerySnapshot>? _bookingsSubscription;

  Booking? get booking => _booking;
  List<Booking> get bookings => _bookings;

  /// 🔹 Listen to all bookings for a specific user in real-time
  Stream<List<Booking>> listenToBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          _bookings = snapshot.docs
              .map((doc) => Booking.fromMap(doc.data(), doc.id))
              .toList();
          notifyListeners();
          return _bookings;
        });
  }

  /// 🔹 Listen to a single booking in real-time
  void listenToBooking(String bookingId) {
    _bookingSubscription?.cancel();
    _bookingSubscription = _firestore
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            _booking = Booking.fromMap(doc.data()!, doc.id);
            notifyListeners();
          }
        });
  }

  /// 🔹 Stop listeners (call when leaving screen)
  void cancelListeners() {
    _bookingSubscription?.cancel();
    _bookingsSubscription?.cancel();
    _bookingSubscription = null;
    _bookingsSubscription = null;
  }

  /// 🔹 Update booking status
  Future<void> updateStatus(String bookingId, String status) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': status,
      'updatedAt': DateTime.now(),
    });
  }

  /// 🔹 Assign valet driver to a booking
  Future<void> assignValet(String bookingId, String driverId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'valetDriverId': driverId,
      'updatedAt': DateTime.now(),
    });
  }

  /// 🔹 Update valet driver’s live location
  Future<void> updateValetLocation({
    required String bookingId,
    required double lat,
    required double lng,
  }) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'valetLat': lat,
      'valetLng': lng,
      'lastLocationUpdate': DateTime.now(),
    });
  }

  @override
  void dispose() {
    cancelListeners();
    super.dispose();
  }
}

class BookingScreen extends StatelessWidget {
  final String userId;
  const BookingScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    return StreamBuilder<List<Booking>>(
      stream: bookingProvider.listenToBookings(userId), // ✅ Stream of bookings
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No bookings found."));
        }

        final bookings = snapshot.data!;

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: ListTile(
                title: Text("Service: ${booking.serviceType}"),
                subtitle: Text("Status: ${booking.status}"),
                trailing: DropdownButton<String>(
                  value: booking.status,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'confirmed',
                      child: Text('Confirmed'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In Progress'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(
                      value: 'canceled',
                      child: Text('Canceled'),
                    ),
                  ],
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      bookingProvider.updateStatus(booking.id, newStatus);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
