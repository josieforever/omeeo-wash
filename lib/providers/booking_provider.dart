import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omeeowash/models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Booking? _booking; // single booking detail in memory
  List<Booking> _bookings = []; // last streamed list (optional cache)
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _bookingSubscription;

  Booking? get booking => _booking;
  List<Booking> get bookings => _bookings;

  // ------------------------
  // Creation
  // ------------------------

  /// Create a booking with an auto-generated Firestore ID.
  Future<String> createBooking(Booking booking) async {
    final docRef = _firestore.collection('bookings').doc(); // auto-id
    final toWrite = booking.copyWith(id: docRef.id).toMap();
    await docRef.set(toWrite);
    return docRef.id;
  }

  /// Create a booking using the given `booking.id` as the Firestore ID.
  Future<void> createBookingWithId(Booking booking) async {
    final docRef = _firestore.collection('bookings').doc(booking.id);
    await docRef.set(booking.toMap());
  }

  // ------------------------
  // Reads
  // ------------------------

  /// One-off read of a booking (no subscription).
  Future<Booking?> getBookingOnce(String bookingId) async {
    final snap = await _firestore.collection('bookings').doc(bookingId).get();
    if (!snap.exists || snap.data() == null) return null;
    return Booking.fromMap(snap.data()!, snap.id);
  }

  /// Stream all bookings for a user (ordered by scheduledTime desc).
  Stream<List<Booking>> listenToBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map(
                (d) => Booking.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList();
          _bookings = list;
          notifyListeners();
          return list;
        });
  }

  /// Stream a single booking by id.
  void listenToBooking(String bookingId) {
    _bookingSubscription?.cancel();
    _bookingSubscription = _firestore
        .collection('bookings')
        .doc(bookingId)
        .snapshots()
        .listen((doc) {
          if (doc.exists && doc.data() != null) {
            _booking = Booking.fromMap(doc.data()!, doc.id);
          } else {
            _booking = null;
          }
          notifyListeners();
        });
  }

  /// Stop live listeners (call in dispose / on screen exit).
  void cancelListeners() {
    _bookingSubscription?.cancel();
    _bookingSubscription = null;
  }

  // ------------------------
  // Pagination for lists
  // ------------------------

  /// Fetch a page of bookings for a user.
  /// Returns (bookings, lastDoc) where lastDoc can be passed back in for next page.
  Future<({List<Booking> items, DocumentSnapshot? lastDoc})>
  fetchUserBookingsPage({
    required String userId,
    int pageSize = 20,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('scheduledTime', descending: true)
        .limit(pageSize);

    if (startAfter != null) {
      query = (query as Query<Map<String, dynamic>>).startAfterDocument(
        startAfter,
      );
    }

    final snap = await query.get();
    final items = snap.docs
        .map((d) => Booking.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();

    final last = snap.docs.isNotEmpty ? snap.docs.last : null;
    return (items: items, lastDoc: last);
  }

  // ------------------------
  // Mutations / helpers
  // ------------------------

  Future<void> updateStatus(String bookingId, String status) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': status,
    });
  }

  Future<void> cancelBooking(String bookingId) async {
    await updateStatus(bookingId, 'canceled');
  }

  /// Assign or unassign a valet driver (pass null to unassign).
  Future<void> assignValet(String bookingId, {String? driverId}) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'valetDriverId': driverId,
    });
  }

  /// Update valet driver’s live location.
  Future<void> updateValetLocation({
    required String bookingId,
    required double lat,
    required double lng,
  }) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'valetLat': lat,
      'valetLng': lng,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// Update service location type: "washing_bay" | "mobile" | "valet".
  Future<void> updateServiceLocation(
    String bookingId,
    String? serviceLocation,
  ) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'serviceLocation': serviceLocation,
    });
  }

  /// Set payment method: "card" | "momo" | "cash".
  Future<void> setPaymentMethod(String bookingId, String method) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'paymentMethod': method,
    });
  }

  /// Link to a payment record (payments/{paymentId}); pass null to clear.
  Future<void> linkPaymentId(String bookingId, String? paymentId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'paymentId': paymentId,
    });
  }

  /// Generic safe partial update for any set of fields from the Booking model.
  Future<void> updateFields(
    String bookingId,
    Map<String, dynamic> fields,
  ) async {
    // You can add validation/whitelisting here if needed.
    await _firestore.collection('bookings').doc(bookingId).update(fields);
  }

  @override
  void dispose() {
    cancelListeners();
    super.dispose();
  }
}
