import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String serviceType; // e.g., "Basic Wash", "Premium Detail"
  final DateTime scheduledTime;
  final String status; // pending, confirmed, in_progress, completed, canceled

  // Location details
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? serviceLocation; // "washing_bay" | "mobile" | "valet"

  // Valet driver details
  final String? valetDriverId;
  final double? valetLat;
  final double? valetLng;
  final DateTime? lastLocationUpdate;

  // Pricing & extras
  final double? price;
  final String? vehicleType;
  final String? notes;

  // Payment (step 1: just capture choice + optional link to a Payment doc)
  final String? paymentMethod; // "card" | "momo" | "cash"
  final String? paymentId; // payments/{paymentId} if/when created

  Booking({
    required this.id,
    required this.userId,
    required this.serviceType,
    required this.scheduledTime,
    required this.status,
    this.latitude,
    this.longitude,
    this.address,
    this.serviceLocation,
    this.valetDriverId,
    this.valetLat,
    this.valetLng,
    this.lastLocationUpdate,
    this.price,
    this.vehicleType,
    this.notes,
    this.paymentMethod,
    this.paymentId,
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
      address: map['address'],
      serviceLocation: map['serviceLocation'],
      valetDriverId: map['valetDriverId'],
      valetLat: (map['valetLat'] as num?)?.toDouble(),
      valetLng: (map['valetLng'] as num?)?.toDouble(),
      lastLocationUpdate: map['lastLocationUpdate'] != null
          ? (map['lastLocationUpdate'] as Timestamp).toDate()
          : null,
      price: (map['price'] as num?)?.toDouble(),
      vehicleType: map['vehicleType'],
      notes: map['notes'],
      paymentMethod: map['paymentMethod'],
      paymentId: map['paymentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'serviceType': serviceType,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'serviceLocation': serviceLocation,
      'valetDriverId': valetDriverId,
      'valetLat': valetLat,
      'valetLng': valetLng,
      'lastLocationUpdate': lastLocationUpdate != null
          ? Timestamp.fromDate(lastLocationUpdate!)
          : null,
      'price': price,
      'vehicleType': vehicleType,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
    };
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? serviceType,
    DateTime? scheduledTime,
    String? status,
    double? latitude,
    double? longitude,
    String? address,
    String? serviceLocation,
    String? valetDriverId,
    double? valetLat,
    double? valetLng,
    DateTime? lastLocationUpdate,
    double? price,
    String? vehicleType,
    String? notes,
    String? paymentMethod,
    String? paymentId,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceType: serviceType ?? this.serviceType,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      serviceLocation: serviceLocation ?? this.serviceLocation,
      valetDriverId: valetDriverId ?? this.valetDriverId,
      valetLat: valetLat ?? this.valetLat,
      valetLng: valetLng ?? this.valetLng,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      price: price ?? this.price,
      vehicleType: vehicleType ?? this.vehicleType,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
    );
  }
}
