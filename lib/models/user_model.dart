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

  // ✅ NEW: App settings for Firestore syncing
  final Map<String, bool> settings;

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

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      emailAddress: map['emailAddress'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      memberSince: map['memberSince'] ?? '',
      totalWashes: map['totalWashes'] ?? 0,
      washesThisMonth: map['washesThisMonth'] ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      loyaltyPoints: map['loyaltyPoints'] ?? 0,
      photoUrl: map['photoUrl'] ?? '',
      locations: List<Map<String, dynamic>>.from(
        (map['locations'] ?? []).map((item) => Map<String, dynamic>.from(item)),
      ),
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
  }

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
    );
  }
}
