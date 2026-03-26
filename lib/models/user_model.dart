import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for type casting Timestamp

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String emailAddress;
  final String phoneNumber;
  final String address;
  final String dateOfBirth;
  final String memberSince;
  final int totalWashes;
  final int washesThisMonth;
  final double rating;
  final int loyaltyPoints;
  final String photoUrl;

  final List<Map<String, dynamic>> locations;

  final Map<String, bool> notificationSettings;
  final Map<String, bool> settings;

  final bool? isOnline;
  final DateTime? lastSeen;
  final Map<String, dynamic>? fcmTokens;
  final DateTime? fcmUpdatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.emailAddress,
    required this.phoneNumber,
    required this.address,
    required this.dateOfBirth,
    required this.memberSince,
    required this.totalWashes,
    required this.washesThisMonth,
    required this.rating,
    required this.loyaltyPoints,
    required this.photoUrl,
    required this.locations,

    this.isOnline,
    this.lastSeen,

    this.fcmTokens,
    this.fcmUpdatedAt,

    Map<String, bool>? notificationSettings,
    Map<String, bool>? settings,
  }) : notificationSettings =
           notificationSettings ??
           {
             "push": true,
             "email": true,
             "bookingConfirmed": true,
             "washStarted": true,
             "washCompleted": true,
             "appUpdates": true,
           },
       settings =
           settings ??
           {"autoLock": false, "biometricAuth": false, "darkMode": false};

  // --- MODEL HELPER FUNCTIONS ---

  // 🛑 FIX: Made helper function STATIC so it can be called from the factory constructor.
  static DateTime? _toNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    // Safely convert Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }

    // Fallback if the runtime type check failed or it's another type
    try {
      // Tries to call .toDate() on the object if it looks like a Timestamp
      return (value as dynamic).toDate();
    } catch (_) {
      return null;
    }
  }

  // --- FROM MAP FACTORY (HARDENED AGAINST NULL CHECK CRASHES) ---
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // 🛑 FIX for Null Check Crash (locations): Filter out non-maps safely
    final List<Map<String, dynamic>> safeLocations = map['locations'] is List
        ? List<Map<String, dynamic>>.from(
            (map['locations'] as List)
                .where((item) => item is Map) // Filter nulls or non-maps
                .map((item) => Map<String, dynamic>.from(item as Map)),
          )
        : [];

    // 🛑 FIX for Null Check Crash (fcmTokens): Safely assign null if not a Map
    final Map<String, dynamic>? safeFcmTokens = map['fcmTokens'] is Map
        ? Map<String, dynamic>.from(map['fcmTokens'])
        : null;

    return UserModel(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      emailAddress: map['emailAddress'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      address: map['address'] as String? ?? '',
      dateOfBirth: map['dateOfBirth'] as String? ?? '',
      memberSince: map['memberSince'] as String? ?? '',
      totalWashes: map['totalWashes'] as int? ?? 0,
      washesThisMonth: map['washesThisMonth'] as int? ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      loyaltyPoints: map['loyaltyPoints'] as int? ?? 0,
      photoUrl: map['photoUrl'] as String? ?? '',

      locations: safeLocations,

      notificationSettings: Map<String, bool>.from(
        map['notificationSettings'] ??
            {
              "push": true,
              "email": true,
              "bookingConfirmed": true,
              "washStarted": true,
              "washCompleted": true,
              "appUpdates": true,
            },
      ),
      settings: Map<String, bool>.from(
        map['settings'] ??
            {"autoLock": false, "biometricAuth": false, "darkMode": false},
      ),

      isOnline: map['isOnline'] as bool?,
      // 🛑 FIX: Call static method on the class name
      lastSeen: UserModel._toNullableDateTime(map['lastSeen']),

      fcmTokens: safeFcmTokens,
      // 🛑 FIX: Call static method on the class name
      fcmUpdatedAt: UserModel._toNullableDateTime(map['fcmUpdatedAt']),
    );
  }

  // --- TO MAP METHOD (PREPARED FOR FIRESTORE) ---
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'uid': uid,
      'name': name,
      'email': email,
      'emailAddress': emailAddress,
      'phoneNumber': phoneNumber,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'memberSince': memberSince,
      'totalWashes': totalWashes,
      'washesThisMonth': washesThisMonth,
      'rating': rating,
      'loyaltyPoints': loyaltyPoints,
      'photoUrl': photoUrl,
      'locations': locations,
      'notificationSettings': notificationSettings,
      'settings': settings,
    };

    // Note: DateTime fields are intentionally omitted here to be replaced by
    // FieldValue.serverTimestamp() in the Service class.

    if (isOnline != null) map['isOnline'] = isOnline;

    if (fcmTokens != null && fcmTokens!.isNotEmpty) {
      map['fcmTokens'] = fcmTokens;
    }

    return map;
  }

  // --- COPYWITH METHOD ---
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? emailAddress,
    String? phoneNumber,
    String? address,
    String? dateOfBirth,
    String? memberSince,
    int? totalWashes,
    int? washesThisMonth,
    double? rating,
    int? loyaltyPoints,
    String? photoUrl,
    List<Map<String, dynamic>>? locations,
    Map<String, bool>? notificationSettings,
    Map<String, bool>? settings,

    bool? isOnline,
    DateTime? lastSeen,

    Map<String, dynamic>? fcmTokens,
    DateTime? fcmUpdatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      emailAddress: emailAddress ?? this.emailAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      memberSince: memberSince ?? this.memberSince,
      totalWashes: totalWashes ?? this.totalWashes,
      washesThisMonth: washesThisMonth ?? this.washesThisMonth,
      rating: rating ?? this.rating,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      photoUrl: photoUrl ?? this.photoUrl,
      locations: locations ?? this.locations,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      settings: settings ?? this.settings,

      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,

      fcmTokens: fcmTokens ?? this.fcmTokens,
      fcmUpdatedAt: fcmUpdatedAt ?? this.fcmUpdatedAt,
    );
  }
}
