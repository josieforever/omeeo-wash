import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String serviceType;
  final DateTime scheduledTime;
  final String status; // pending, confirmed, in_progress, completed, canceled

  // Location fields
  final double? latitude;
  final double? longitude;

  // Valet driver fields
  final String? valetDriverId;
  final double? valetLat;
  final double? valetLng;
  final DateTime? lastLocationUpdate;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.scheduledTime,
    required this.status,
    this.latitude,
    this.longitude,
    this.valetDriverId,
    this.valetLat,
    this.valetLng,
    this.lastLocationUpdate,
  });

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      userId: map['userId'] ?? '',
      serviceType: map['serviceType'] ?? '',
      scheduledTime: (map['scheduledTime'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      valetDriverId: map['valetDriverId'],
      valetLat: (map['valetLat'] as num?)?.toDouble(),
      valetLng: (map['valetLng'] as num?)?.toDouble(),
      lastLocationUpdate: map['lastLocationUpdate'] != null
          ? (map['lastLocationUpdate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'serviceType': serviceType,
      'scheduledTime': scheduledTime,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'valetDriverId': valetDriverId,
      'valetLat': valetLat,
      'valetLng': valetLng,
      'lastLocationUpdate': lastLocationUpdate,
    };
  }
}
