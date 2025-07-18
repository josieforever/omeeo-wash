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
  final List<Map<String, dynamic>> locations; // New field

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
    required this.locations, // Required in constructor
  });

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
    );
  }
}
