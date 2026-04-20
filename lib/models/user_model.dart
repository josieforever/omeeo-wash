import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String accountType;
  final String status;

  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String photoUrl;

  final String? defaultAddressId;
  final String? defaultPaymentMethodId;

  final Map<String, bool> notificationSettings;
  final Map<String, dynamic> settings;

  final Map<String, dynamic> stats;
  final Map<String, dynamic> loyalty;

  final String? currentBookingId;
  final String? currentBookingStatus;

  final bool isOnline;
  final DateTime? lastLoginAt;
  final DateTime? lastSeen;

  final Map<String, bool> fcmTokens;
  final DateTime? fcmUpdatedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.accountType,
    required this.status,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.photoUrl,
    required this.defaultAddressId,
    required this.defaultPaymentMethodId,
    required this.notificationSettings,
    required this.settings,
    required this.stats,
    required this.loyalty,
    required this.currentBookingId,
    required this.currentBookingStatus,
    required this.isOnline,
    required this.lastLoginAt,
    required this.lastSeen,
    required this.fcmTokens,
    required this.fcmUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime? _toNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    try {
      return (value as dynamic).toDate();
    } catch (_) {
      return null;
    }
  }

  static Map<String, bool> _toBoolMap(
    dynamic value, {
    Map<String, bool> fallback = const {},
  }) {
    if (value is! Map) return Map<String, bool>.from(fallback);

    final out = <String, bool>{};
    value.forEach((key, val) {
      if (key != null && val is bool) {
        out[key.toString()] = val;
      }
    });

    if (out.isEmpty && fallback.isNotEmpty) {
      return Map<String, bool>.from(fallback);
    }

    return out;
  }

  static Map<String, dynamic> _toDynamicMap(
    dynamic value, {
    Map<String, dynamic> fallback = const {},
  }) {
    if (value is! Map) return Map<String, dynamic>.from(fallback);
    return Map<String, dynamic>.from(value);
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: (map['uid'] ?? '') as String,
      accountType: (map['accountType'] ?? 'customer') as String,
      status: (map['status'] ?? 'active') as String,

      name: (map['name'] ?? '') as String,
      firstName: (map['firstName'] ?? '') as String,
      lastName: (map['lastName'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phoneNumber: (map['phoneNumber'] ?? '') as String,
      photoUrl: (map['photoUrl'] ?? '') as String,

      defaultAddressId: map['defaultAddressId'] as String?,
      defaultPaymentMethodId: map['defaultPaymentMethodId'] as String?,

      notificationSettings: _toBoolMap(
        map['notificationSettings'],
        fallback: const {
          'push': true,
          'email': true,
          'bookingUpdates': true,
          'promoOffers': true,
        },
      ),

      settings: _toDynamicMap(
        map['settings'],
        fallback: const {
          'languageCode': 'en',
          'regionCode': 'GH',
          'darkMode': false,
        },
      ),

      stats: _toDynamicMap(
        map['stats'],
        fallback: const {
          'totalOrders': 0,
          'completedOrders': 0,
          'cancelledOrders': 0,
          'totalSpent': 0,
          'lastOrderAt': null,
          'memberSince': null,
        },
      ),

      loyalty: _toDynamicMap(
        map['loyalty'],
        fallback: const {'points': 0, 'tier': 'standard'},
      ),

      currentBookingId: map['currentBookingId'] as String?,
      currentBookingStatus: map['currentBookingStatus'] as String?,

      isOnline: (map['isOnline'] ?? false) as bool,
      lastLoginAt: _toNullableDateTime(map['lastLoginAt']),
      lastSeen: _toNullableDateTime(map['lastSeen']),

      fcmTokens: _toBoolMap(map['fcmTokens']),
      fcmUpdatedAt: _toNullableDateTime(map['fcmUpdatedAt']),

      createdAt: _toNullableDateTime(map['createdAt']),
      updatedAt: _toNullableDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'accountType': accountType,
      'status': status,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'defaultAddressId': defaultAddressId,
      'defaultPaymentMethodId': defaultPaymentMethodId,
      'notificationSettings': notificationSettings,
      'settings': settings,
      'stats': stats,
      'loyalty': loyalty,
      'currentBookingId': currentBookingId,
      'currentBookingStatus': currentBookingStatus,
      'isOnline': isOnline,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
      'fcmTokens': fcmTokens,
      'fcmUpdatedAt': fcmUpdatedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? accountType,
    String? status,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    String? defaultAddressId,
    String? defaultPaymentMethodId,
    Map<String, bool>? notificationSettings,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? loyalty,
    String? currentBookingId,
    String? currentBookingStatus,
    bool? isOnline,
    DateTime? lastLoginAt,
    DateTime? lastSeen,
    Map<String, bool>? fcmTokens,
    DateTime? fcmUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      accountType: accountType ?? this.accountType,
      status: status ?? this.status,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      defaultAddressId: defaultAddressId ?? this.defaultAddressId,
      defaultPaymentMethodId:
          defaultPaymentMethodId ?? this.defaultPaymentMethodId,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      loyalty: loyalty ?? this.loyalty,
      currentBookingId: currentBookingId ?? this.currentBookingId,
      currentBookingStatus: currentBookingStatus ?? this.currentBookingStatus,
      isOnline: isOnline ?? this.isOnline,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      fcmUpdatedAt: fcmUpdatedAt ?? this.fcmUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
