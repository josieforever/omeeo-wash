import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:omeeowash/models/booking_model.dart';

class BookingProvider with ChangeNotifier {
  BookingProvider({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  BookingModel? _booking;
  List<BookingModel> _bookings = [];

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _bookingSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _bookingsSubscription;

  BookingModel? get booking => _booking;
  List<BookingModel> get bookings => List.unmodifiable(_bookings);

  CollectionReference<Map<String, dynamic>> get _bookingsRef =>
      _firestore.collection('bookings');

  Future<String> createBooking(BookingModel booking) async {
    final docRef = _bookingsRef.doc();
    final toWrite = booking.copyWith(id: docRef.id).toMap();

    await docRef.set({
      ...toWrite,
      'id': docRef.id,
      'createdAt': toWrite['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> createBookingWithId(BookingModel booking) async {
    if (booking.id.trim().isEmpty) {
      throw ArgumentError('booking.id cannot be empty.');
    }

    final toWrite = booking.toMap();

    await _bookingsRef.doc(booking.id).set({
      ...toWrite,
      'id': booking.id,
      'createdAt': toWrite['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<BookingModel?> getBookingOnce(String bookingId) async {
    final snap = await _bookingsRef.doc(bookingId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return BookingModel.fromMap(data, snap.id);
  }

  Stream<List<BookingModel>> bookingsStream(String userId) {
    return _bookingsRef
        .where('userId', isEqualTo: userId)
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => BookingModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  void listenToBookings(String userId) {
    _bookingsSubscription?.cancel();

    _bookingsSubscription = _bookingsRef
        .where('userId', isEqualTo: userId)
        .orderBy('scheduledTime', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _bookings = snapshot.docs
                .map((d) => BookingModel.fromMap(d.data(), d.id))
                .toList();
            notifyListeners();
          },
          onError: (error, stackTrace) {
            debugPrint('listenToBookings error: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  void listenToBooking(String bookingId) {
    _bookingSubscription?.cancel();

    _bookingSubscription = _bookingsRef
        .doc(bookingId)
        .snapshots()
        .listen(
          (doc) {
            final data = doc.data();
            if (doc.exists && data != null) {
              _booking = BookingModel.fromMap(data, doc.id);
            } else {
              _booking = null;
            }
            notifyListeners();
          },
          onError: (error, stackTrace) {
            debugPrint('listenToBooking error: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  void cancelListeners() {
    _bookingSubscription?.cancel();
    _bookingSubscription = null;

    _bookingsSubscription?.cancel();
    _bookingsSubscription = null;
  }

  Future<
    ({
      List<BookingModel> items,
      DocumentSnapshot<Map<String, dynamic>>? lastDoc,
    })
  >
  fetchUserBookingsPage({
    required String userId,
    int pageSize = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _bookingsRef
        .where('userId', isEqualTo: userId)
        .orderBy('scheduledTime', descending: true)
        .limit(pageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.get();

    final items = snap.docs
        .map((d) => BookingModel.fromMap(d.data(), d.id))
        .toList();

    final last = snap.docs.isNotEmpty ? snap.docs.last : null;

    return (items: items, lastDoc: last);
  }

  Future<void> updateStatus(
    String bookingId,
    String status, {
    String? title,
    String? description,
    bool writeHistory = false,
  }) async {
    final bookingRef = _bookingsRef.doc(bookingId);

    final batch = _firestore.batch();

    batch.update(bookingRef, {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'cancelled')
        'timeline.cancelledAt': FieldValue.serverTimestamp(),
    });

    if (writeHistory) {
      batch.set(bookingRef.collection('status_history').doc(), {
        'status': status,
        'title': title ?? _defaultTitleForStatus(status),
        'description': description ?? _defaultDescriptionForStatus(status),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> cancelBooking(
    String bookingId, {
    String reason = 'Cancelled by customer',
    String cancelledBy = 'customer',
  }) async {
    final bookingRef = _bookingsRef.doc(bookingId);

    final batch = _firestore.batch();

    batch.update(bookingRef, {
      'status': 'cancelled',
      'cancellation': {
        'reason': reason,
        'cancelledBy': cancelledBy,
        'cancelledAt': FieldValue.serverTimestamp(),
      },
      'timeline.cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(bookingRef.collection('status_history').doc(), {
      'status': 'cancelled',
      'title': 'Booking Cancelled',
      'description': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> assignValet(String bookingId, {String? driverId}) async {
    await _bookingsRef.doc(bookingId).update({
      'valetDriverId': driverId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateValetLocation({
    required String bookingId,
    required double lat,
    required double lng,
  }) async {
    await _bookingsRef.doc(bookingId).update({
      'valetLat': lat,
      'valetLng': lng,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateServiceLocation(
    String bookingId,
    String? serviceLocation,
  ) async {
    await _bookingsRef.doc(bookingId).update({
      'serviceLocation': serviceLocation,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setPaymentMethod(String bookingId, String method) async {
    await _bookingsRef.doc(bookingId).update({
      'paymentMethod': method,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> linkPaymentId(String bookingId, String? paymentId) async {
    await _bookingsRef.doc(bookingId).update({
      'paymentId': paymentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFields(
    String bookingId,
    Map<String, dynamic> fields, {
    bool touchUpdatedAt = true,
  }) async {
    final payload = <String, dynamic>{...fields};
    if (touchUpdatedAt) {
      payload['updatedAt'] = FieldValue.serverTimestamp();
    }

    await _bookingsRef.doc(bookingId).update(payload);
  }

  Future<void> offerToLaundry({
    required String bookingId,
    required String laundryId,
    required String laundryName,
    String? laundryPhone,
    String? laundryPhotoUrl,
  }) async {
    final bookingRef = _bookingsRef.doc(bookingId);
    final batch = _firestore.batch();

    batch.update(bookingRef, {
      'status': 'awaiting_laundry_acceptance',
      'laundryId': laundryId,
      'laundryName': laundryName,
      'laundryPhone': laundryPhone,
      'laundryPhotoUrl': laundryPhotoUrl,
      'laundryOffer.offeredLaundryId': laundryId,
      'laundryOffer.offeredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'timeline.offeredToLaundryAt': FieldValue.serverTimestamp(),
    });

    batch.set(bookingRef.collection('status_history').doc(), {
      'status': 'awaiting_laundry_acceptance',
      'title': 'Offer sent to laundry',
      'description': 'Booking offered to $laundryName.',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> markLaundryAccepted(String bookingId) async {
    await updateStatus(
      bookingId,
      'looking_for_pickup_rider',
      title: 'Laundry accepted',
      description: 'Laundry accepted the request and rider search has started.',
      writeHistory: true,
    );
  }

  String _defaultTitleForStatus(String status) {
    switch (status) {
      case 'offered_to_laundry':
        return 'Offer sent to laundry';
      case 'awaiting_laundry_acceptance':
        return 'Waiting for laundry';
      case 'pending':
        return 'Pending';
      case 'looking_for_pickup_rider':
        return 'Laundry accepted';
      case 'pickup_rider_assigned':
        return 'Pickup rider assigned';
      case 'pickup_started':
        return 'Pickup started';
      case 'arrived_at_pickup':
        return 'Arrived at pickup';
      case 'arrived_at_laundry':
        return 'Arrived at laundry';
      case 'processing':
        return 'Processing';
      case 'ready_for_dropoff':
        return 'Ready for dropoff';
      case 'delivery_in_progress':
        return 'Delivery in progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Booking Cancelled';
      default:
        return 'Booking Updated';
    }
  }

  String _defaultDescriptionForStatus(String status) {
    switch (status) {
      case 'offered_to_laundry':
        return 'The booking has been offered to a laundry.';
      case 'awaiting_laundry_acceptance':
        return 'Waiting for the laundry to accept the booking.';
      case 'pending':
        return 'The booking is pending.';
      case 'looking_for_pickup_rider':
        return 'A pickup rider is being assigned.';
      case 'pickup_rider_assigned':
        return 'A pickup rider has been assigned.';
      case 'pickup_started':
        return 'Pickup is in progress.';
      case 'arrived_at_pickup':
        return 'The rider has arrived at pickup.';
      case 'arrived_at_laundry':
        return 'Items have arrived at the laundry.';
      case 'processing':
        return 'Laundry processing is in progress.';
      case 'ready_for_dropoff':
        return 'The order is ready for delivery.';
      case 'delivery_in_progress':
        return 'Delivery is in progress.';
      case 'completed':
        return 'The booking has been completed.';
      case 'cancelled':
        return 'The booking has been cancelled.';
      default:
        return 'The booking status was updated.';
    }
  }

  @override
  void dispose() {
    cancelListeners();
    super.dispose();
  }
}
