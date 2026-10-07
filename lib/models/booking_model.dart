import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String bookingCode;

  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerPhotoUrl;

  final String? laundrySnapshotId;
  final String? laundrySnapshotName;
  final String? laundrySnapshotPhone;
  final String? laundrySnapshotPhotoUrl;
  final String? laundrySnapshotAddressLine;
  final double? laundrySnapshotLatitude;
  final double? laundrySnapshotLongitude;
  final double? laundrySnapshotRating;
  final int? laundrySnapshotTotalRatings;

  final String serviceType;
  final List<String> selectedAddOns;

  final int estimatedWeightKg;
  final int? actualWeightKg;

  final String pickupAddress;
  final String pickupSubtitle;
  final double? pickupLatitude;
  final double? pickupLongitude;

  final String customerAddress;
  final String deliverySubtitle;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final bool isSameAsPickup;

  final int basePrice;
  final int addOnsPrice;
  final int pickupFee;
  final int deliveryFee;
  final int totalPrice;
  final String currency;

  final String status;

  final String paymentMethod;
  final String paymentStatus;
  final String? paymentTransactionRef;
  final DateTime? paidAt;

  final String? pickupRiderId;
  final String? pickupRiderName;
  final String? pickupRiderPhone;
  final String? pickupRiderPhotoUrl;
  final String? pickupRiderVehicleType;
  final String? pickupRiderPlateNumber;
  final DateTime? pickupRiderAssignedAt;
  final DateTime? pickupRiderPickedUpAt;

  final String? deliveryRiderId;
  final String? deliveryRiderName;
  final String? deliveryRiderPhone;
  final String? deliveryRiderPhotoUrl;
  final String? deliveryRiderVehicleType;
  final String? deliveryRiderPlateNumber;
  final DateTime? deliveryRiderAssignedAt;
  final DateTime? deliveryRiderDeliveredAt;

  final bool hasUnreadForCustomer;
  final bool hasUnreadForLaundry;
  final String lastMessage;
  final DateTime? lastMessageAt;

  final bool assignedAutomatically;
  final DateTime? assignedAt;

  final String? offeredLaundryId;
  final DateTime? offeredAt;
  final DateTime? offerExpiresAt;

  final List<String> rejectedLaundryIds;
  final int assignmentAttempts;
  final DateTime? lastAssignmentAttemptAt;
  final int maxSearchRadiusKm;

  final DateTime? requestedAt;
  final DateTime? acceptedAt;
  final DateTime? pickupStartedAt;
  final DateTime? arrivedAtPickupAt;
  final DateTime? arrivedAtLaundryAt;
  final DateTime? processingStartedAt;
  final DateTime? readyForDropoffAt;
  final DateTime? deliveryStartedAt;
  final DateTime? arrivedAtCustomerAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  final String customerNotes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    required this.id,
    required this.bookingCode,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerPhotoUrl,
    required this.laundrySnapshotId,
    required this.laundrySnapshotName,
    required this.laundrySnapshotPhone,
    required this.laundrySnapshotPhotoUrl,
    required this.laundrySnapshotAddressLine,
    required this.laundrySnapshotLatitude,
    required this.laundrySnapshotLongitude,
    required this.laundrySnapshotRating,
    required this.laundrySnapshotTotalRatings,
    required this.serviceType,
    required this.selectedAddOns,
    required this.estimatedWeightKg,
    required this.actualWeightKg,
    required this.pickupAddress,
    required this.pickupSubtitle,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.customerAddress,
    required this.deliverySubtitle,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.isSameAsPickup,
    required this.basePrice,
    required this.addOnsPrice,
    required this.pickupFee,
    required this.deliveryFee,
    required this.totalPrice,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentTransactionRef,
    required this.paidAt,
    required this.pickupRiderId,
    required this.pickupRiderName,
    required this.pickupRiderPhone,
    required this.pickupRiderPhotoUrl,
    required this.pickupRiderVehicleType,
    required this.pickupRiderPlateNumber,
    required this.pickupRiderAssignedAt,
    required this.pickupRiderPickedUpAt,
    required this.deliveryRiderId,
    required this.deliveryRiderName,
    required this.deliveryRiderPhone,
    required this.deliveryRiderPhotoUrl,
    required this.deliveryRiderVehicleType,
    required this.deliveryRiderPlateNumber,
    required this.deliveryRiderAssignedAt,
    required this.deliveryRiderDeliveredAt,
    required this.hasUnreadForCustomer,
    required this.hasUnreadForLaundry,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.assignedAutomatically,
    required this.assignedAt,
    required this.offeredLaundryId,
    required this.offeredAt,
    required this.offerExpiresAt,
    required this.rejectedLaundryIds,
    required this.assignmentAttempts,
    required this.lastAssignmentAttemptAt,
    required this.maxSearchRadiusKm,
    required this.requestedAt,
    required this.acceptedAt,
    required this.pickupStartedAt,
    required this.arrivedAtPickupAt,
    required this.arrivedAtLaundryAt,
    required this.processingStartedAt,
    required this.readyForDropoffAt,
    required this.deliveryStartedAt,
    required this.arrivedAtCustomerAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.customerNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    final pickupAddressMap = _asMap(map['pickupAddress']);
    final customerAddressMap = _asMap(map['customerAddress']);
    final pricingMap = _asMap(map['pricing']);
    final paymentMap = _asMap(map['payment']);
    final pickupRiderMap = _asMap(map['pickupRider']);
    final deliveryRiderMap = _asMap(map['deliveryRider']);
    final chatMap = _asMap(map['chat']);
    final laundryAssignmentMap = _asMap(map['laundryAssignment']);
    final laundryOfferMap = _asMap(map['laundryOffer']);
    final laundrySnapshotMap = _asMap(map['laundrySnapshot']);
    final customerSnapshotMap = _asMap(map['customerSnapshot']);
    final searchMetaMap = _asMap(map['searchMeta']);
    final timelineMap = _asMap(map['timeline']);

    final items = map['items'] is List ? map['items'] as List : <dynamic>[];
    final firstItem = items.isNotEmpty && items.first is Map
        ? _asMap(items.first)
        : <String, dynamic>{};

    return BookingModel(
      id: docId,
      bookingCode: _readString(map['bookingCode']),

      customerId: _readString(
        customerSnapshotMap['customerId'],
        fallback: _readString(map['customerId']),
      ),
      customerName: _readString(
        customerSnapshotMap['customerName'],
        fallback: _readString(map['customerName']),
      ),
      customerPhone: _readString(
        customerSnapshotMap['customerPhone'],
        fallback: _readString(map['customerPhone']),
      ),
      customerPhotoUrl: _readString(
        customerSnapshotMap['customerPhotoUrl'],
        fallback: _readString(map['customerPhotoUrl']),
      ),

      laundrySnapshotId: _readNullableString(laundrySnapshotMap['id']),
      laundrySnapshotName: _readNullableString(laundrySnapshotMap['name']),
      laundrySnapshotPhone: _readNullableString(
        laundrySnapshotMap['phoneNumber'],
      ),
      laundrySnapshotPhotoUrl: _readNullableString(
        laundrySnapshotMap['photoUrl'],
      ),
      laundrySnapshotAddressLine: _readNullableString(
        laundrySnapshotMap['addressLine'],
      ),
      laundrySnapshotLatitude: _readNullableDouble(
        laundrySnapshotMap['latitude'],
      ),
      laundrySnapshotLongitude: _readNullableDouble(
        laundrySnapshotMap['longitude'],
      ),
      laundrySnapshotRating: _readNullableDouble(laundrySnapshotMap['rating']),
      laundrySnapshotTotalRatings: _readNullableInt(
        laundrySnapshotMap['totalRatings'],
      ),

      serviceType: _readString(map['serviceType']),
      selectedAddOns: _readStringList(map['selectedAddOns']),

      estimatedWeightKg: _readInt(firstItem['estimatedWeightKg']),
      actualWeightKg: _readNullableInt(firstItem['actualWeightKg']),

      pickupAddress: _readString(pickupAddressMap['address']),
      pickupSubtitle: _readString(pickupAddressMap['subtitle']),
      pickupLatitude: _readNullableDouble(pickupAddressMap['latitude']),
      pickupLongitude: _readNullableDouble(pickupAddressMap['longitude']),

      customerAddress: _readString(customerAddressMap['address']),
      deliverySubtitle: _readString(customerAddressMap['subtitle']),
      deliveryLatitude: _readNullableDouble(customerAddressMap['latitude']),
      deliveryLongitude: _readNullableDouble(customerAddressMap['longitude']),
      isSameAsPickup: _readBool(customerAddressMap['isSameAsPickup']),

      basePrice: _readInt(pricingMap['basePrice']),
      addOnsPrice: _readInt(pricingMap['addOnsPrice']),
      pickupFee: _readInt(pricingMap['pickupFee']),
      deliveryFee: _readInt(pricingMap['deliveryFee']),
      totalPrice: _readInt(pricingMap['totalPrice']),
      currency: _readString(pricingMap['currency'], fallback: 'GHS'),

      status: _readString(map['status']),

      paymentMethod: _readString(paymentMap['method']),
      paymentStatus: _readString(paymentMap['status']),
      paymentTransactionRef: _readNullableString(paymentMap['transactionRef']),
      paidAt: _parseTimestamp(paymentMap['paidAt']),

      pickupRiderId: _readNullableString(pickupRiderMap['riderId']),
      pickupRiderName: _readNullableString(pickupRiderMap['fullName']),
      pickupRiderPhone: _readNullableString(pickupRiderMap['phoneNumber']),
      pickupRiderPhotoUrl: _readNullableString(pickupRiderMap['photoUrl']),
      pickupRiderVehicleType: _readNullableString(
        pickupRiderMap['vehicleType'],
      ),
      pickupRiderPlateNumber: _readNullableString(
        pickupRiderMap['plateNumber'],
      ),
      pickupRiderAssignedAt: _parseTimestamp(pickupRiderMap['assignedAt']),
      pickupRiderPickedUpAt: _parseTimestamp(pickupRiderMap['pickedUpAt']),

      deliveryRiderId: _readNullableString(deliveryRiderMap['riderId']),
      deliveryRiderName: _readNullableString(deliveryRiderMap['fullName']),
      deliveryRiderPhone: _readNullableString(deliveryRiderMap['phoneNumber']),
      deliveryRiderPhotoUrl: _readNullableString(deliveryRiderMap['photoUrl']),
      deliveryRiderVehicleType: _readNullableString(
        deliveryRiderMap['vehicleType'],
      ),
      deliveryRiderPlateNumber: _readNullableString(
        deliveryRiderMap['plateNumber'],
      ),
      deliveryRiderAssignedAt: _parseTimestamp(deliveryRiderMap['assignedAt']),
      deliveryRiderDeliveredAt: _parseTimestamp(
        deliveryRiderMap['deliveredAt'],
      ),

      hasUnreadForCustomer: _readBool(chatMap['hasUnreadForCustomer']),
      hasUnreadForLaundry: _readBool(chatMap['hasUnreadForLaundry']),
      lastMessage: _readString(chatMap['lastMessage']),
      lastMessageAt: _parseTimestamp(chatMap['lastMessageAt']),

      assignedAutomatically: _readBool(
        laundryAssignmentMap['assignedAutomatically'],
      ),
      assignedAt: _parseTimestamp(laundryAssignmentMap['assignedAt']),

      offeredLaundryId: _readNullableString(
        laundryOfferMap['offeredLaundryId'],
      ),
      offeredAt: _parseTimestamp(laundryOfferMap['offeredAt']),
      offerExpiresAt: _parseTimestamp(laundryOfferMap['offerExpiresAt']),

      rejectedLaundryIds: _readStringList(map['rejectedLaundryIds']),
      assignmentAttempts: _readInt(searchMetaMap['assignmentAttempts']),
      lastAssignmentAttemptAt: _parseTimestamp(
        searchMetaMap['lastAssignmentAttemptAt'],
      ),
      maxSearchRadiusKm: _readInt(searchMetaMap['maxSearchRadiusKm']),

      requestedAt: _parseTimestamp(timelineMap['requestedAt']),
      acceptedAt: _parseTimestamp(timelineMap['acceptedAt']),
      pickupStartedAt: _parseTimestamp(timelineMap['pickupStartedAt']),
      arrivedAtPickupAt: _parseTimestamp(timelineMap['arrivedAtPickupAt']),
      arrivedAtLaundryAt: _parseTimestamp(timelineMap['arrivedAtLaundryAt']),
      processingStartedAt: _parseTimestamp(timelineMap['processingStartedAt']),
      readyForDropoffAt: _parseTimestamp(timelineMap['readyForDropoffAt']),
      deliveryStartedAt: _parseTimestamp(timelineMap['deliveryStartedAt']),
      arrivedAtCustomerAt: _parseTimestamp(timelineMap['arrivedAtCustomerAt']),
      completedAt: _parseTimestamp(timelineMap['completedAt']),
      cancelledAt: _parseTimestamp(timelineMap['cancelledAt']),

      customerNotes: _readString(map['customerNotes']),

      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  String get laundryId => laundrySnapshotId ?? '';
  String get laundryName => laundrySnapshotName ?? '';
  String get laundryPhone => laundrySnapshotPhone ?? '';
  String get laundryPhotoUrl => laundrySnapshotPhotoUrl ?? '';

  bool get hasLaundryAssigned {
    return laundrySnapshotId != null && laundrySnapshotId!.trim().isNotEmpty;
  }

  bool get isIncomingOffer => status == 'offered_to_laundry';

  bool get isActiveLaundryOrder {
    switch (status) {
      case 'pending':
      case 'looking_for_pickup_rider':
      case 'pickup_rider_assigned':
      case 'pickup_started':
      case 'arrived_at_pickup':
      case 'arrived_at_laundry':
      case 'processing':
      case 'ready_for_dropoff':
      case 'delivery_in_progress':
      case 'arrived_at_customer':
      case 'completed':
        return true;
      default:
        return false;
    }
  }

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isNoLaundryFound => status == 'no_laundry_found';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingCode': bookingCode,

      'customerSnapshot': {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerPhotoUrl': customerPhotoUrl,
      },

      'laundrySnapshot': {
        'id': laundrySnapshotId,
        'name': laundrySnapshotName,
        'phoneNumber': laundrySnapshotPhone,
        'photoUrl': laundrySnapshotPhotoUrl,
        'addressLine': laundrySnapshotAddressLine,
        'latitude': laundrySnapshotLatitude,
        'longitude': laundrySnapshotLongitude,
        'rating': laundrySnapshotRating,
        'totalRatings': laundrySnapshotTotalRatings,
      },

      'serviceType': serviceType,
      'selectedAddOns': selectedAddOns,

      'items': [
        {
          'name': 'Laundry Load',
          'estimatedWeightKg': estimatedWeightKg,
          'actualWeightKg': actualWeightKg,
        },
      ],

      'customerNotes': customerNotes,

      'pickupAddress': {
        'address': pickupAddress,
        'subtitle': pickupSubtitle,
        'latitude': pickupLatitude,
        'longitude': pickupLongitude,
      },

      'customerAddress': {
        'address': customerAddress,
        'subtitle': deliverySubtitle,
        'latitude': deliveryLatitude,
        'longitude': deliveryLongitude,
        'isSameAsPickup': isSameAsPickup,
      },

      'pricing': {
        'basePrice': basePrice,
        'addOnsPrice': addOnsPrice,
        'pickupFee': pickupFee,
        'deliveryFee': deliveryFee,
        'totalPrice': totalPrice,
        'currency': currency,
      },

      'status': status,

      'pickupRider': {
        'riderId': pickupRiderId,
        'fullName': pickupRiderName,
        'phoneNumber': pickupRiderPhone,
        'photoUrl': pickupRiderPhotoUrl,
        'vehicleType': pickupRiderVehicleType,
        'plateNumber': pickupRiderPlateNumber,
        'assignedAt': _dateToTimestamp(pickupRiderAssignedAt),
        'pickedUpAt': _dateToTimestamp(pickupRiderPickedUpAt),
      },

      'deliveryRider': {
        'riderId': deliveryRiderId,
        'fullName': deliveryRiderName,
        'phoneNumber': deliveryRiderPhone,
        'photoUrl': deliveryRiderPhotoUrl,
        'vehicleType': deliveryRiderVehicleType,
        'plateNumber': deliveryRiderPlateNumber,
        'assignedAt': _dateToTimestamp(deliveryRiderAssignedAt),
        'deliveredAt': _dateToTimestamp(deliveryRiderDeliveredAt),
      },

      'payment': {
        'method': paymentMethod,
        'status': paymentStatus,
        'transactionRef': paymentTransactionRef,
        'paidAt': _dateToTimestamp(paidAt),
      },

      'chat': {
        'hasUnreadForCustomer': hasUnreadForCustomer,
        'hasUnreadForLaundry': hasUnreadForLaundry,
        'lastMessage': lastMessage,
        'lastMessageAt': _dateToTimestamp(lastMessageAt),
      },

      'laundryAssignment': {
        'assignedAutomatically': assignedAutomatically,
        'assignedAt': _dateToTimestamp(assignedAt),
      },

      'laundryOffer': {
        'offeredLaundryId': offeredLaundryId,
        'offeredAt': _dateToTimestamp(offeredAt),
        'offerExpiresAt': _dateToTimestamp(offerExpiresAt),
      },

      'rejectedLaundryIds': rejectedLaundryIds,

      'searchMeta': {
        'assignmentAttempts': assignmentAttempts,
        'lastAssignmentAttemptAt': _dateToTimestamp(lastAssignmentAttemptAt),
        'maxSearchRadiusKm': maxSearchRadiusKm,
      },

      'timeline': {
        'requestedAt': _dateToTimestamp(requestedAt),
        'acceptedAt': _dateToTimestamp(acceptedAt),
        'pickupStartedAt': _dateToTimestamp(pickupStartedAt),
        'arrivedAtPickupAt': _dateToTimestamp(arrivedAtPickupAt),
        'arrivedAtLaundryAt': _dateToTimestamp(arrivedAtLaundryAt),
        'processingStartedAt': _dateToTimestamp(processingStartedAt),
        'readyForDropoffAt': _dateToTimestamp(readyForDropoffAt),
        'deliveryStartedAt': _dateToTimestamp(deliveryStartedAt),
        'arrivedAtCustomerAt': _dateToTimestamp(arrivedAtCustomerAt),
        'completedAt': _dateToTimestamp(completedAt),
        'cancelledAt': _dateToTimestamp(cancelledAt),
      },

      'createdAt': _dateToTimestamp(createdAt),
      'updatedAt': _dateToTimestamp(updatedAt),
    };
  }

  BookingModel copyWith({
    String? id,
    String? bookingCode,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerPhotoUrl,
    String? laundrySnapshotId,
    String? laundrySnapshotName,
    String? laundrySnapshotPhone,
    String? laundrySnapshotPhotoUrl,
    String? laundrySnapshotAddressLine,
    double? laundrySnapshotLatitude,
    double? laundrySnapshotLongitude,
    double? laundrySnapshotRating,
    int? laundrySnapshotTotalRatings,
    String? serviceType,
    List<String>? selectedAddOns,
    int? estimatedWeightKg,
    int? actualWeightKg,
    String? pickupAddress,
    String? pickupSubtitle,
    double? pickupLatitude,
    double? pickupLongitude,
    String? customerAddress,
    String? deliverySubtitle,
    double? deliveryLatitude,
    double? deliveryLongitude,
    bool? isSameAsPickup,
    int? basePrice,
    int? addOnsPrice,
    int? pickupFee,
    int? deliveryFee,
    int? totalPrice,
    String? currency,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentTransactionRef,
    DateTime? paidAt,
    String? pickupRiderId,
    String? pickupRiderName,
    String? pickupRiderPhone,
    String? pickupRiderPhotoUrl,
    String? pickupRiderVehicleType,
    String? pickupRiderPlateNumber,
    DateTime? pickupRiderAssignedAt,
    DateTime? pickupRiderPickedUpAt,
    String? deliveryRiderId,
    String? deliveryRiderName,
    String? deliveryRiderPhone,
    String? deliveryRiderPhotoUrl,
    String? deliveryRiderVehicleType,
    String? deliveryRiderPlateNumber,
    DateTime? deliveryRiderAssignedAt,
    DateTime? deliveryRiderDeliveredAt,
    bool? hasUnreadForCustomer,
    bool? hasUnreadForLaundry,
    String? lastMessage,
    DateTime? lastMessageAt,
    bool? assignedAutomatically,
    DateTime? assignedAt,
    String? offeredLaundryId,
    DateTime? offeredAt,
    DateTime? offerExpiresAt,
    List<String>? rejectedLaundryIds,
    int? assignmentAttempts,
    DateTime? lastAssignmentAttemptAt,
    int? maxSearchRadiusKm,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? pickupStartedAt,
    DateTime? arrivedAtPickupAt,
    DateTime? arrivedAtLaundryAt,
    DateTime? processingStartedAt,
    DateTime? readyForDropoffAt,
    DateTime? deliveryStartedAt,
    DateTime? arrivedAtCustomerAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? customerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      bookingCode: bookingCode ?? this.bookingCode,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
      laundrySnapshotId: laundrySnapshotId ?? this.laundrySnapshotId,
      laundrySnapshotName: laundrySnapshotName ?? this.laundrySnapshotName,
      laundrySnapshotPhone: laundrySnapshotPhone ?? this.laundrySnapshotPhone,
      laundrySnapshotPhotoUrl:
          laundrySnapshotPhotoUrl ?? this.laundrySnapshotPhotoUrl,
      laundrySnapshotAddressLine:
          laundrySnapshotAddressLine ?? this.laundrySnapshotAddressLine,
      laundrySnapshotLatitude:
          laundrySnapshotLatitude ?? this.laundrySnapshotLatitude,
      laundrySnapshotLongitude:
          laundrySnapshotLongitude ?? this.laundrySnapshotLongitude,
      laundrySnapshotRating:
          laundrySnapshotRating ?? this.laundrySnapshotRating,
      laundrySnapshotTotalRatings:
          laundrySnapshotTotalRatings ?? this.laundrySnapshotTotalRatings,
      serviceType: serviceType ?? this.serviceType,
      selectedAddOns: selectedAddOns ?? this.selectedAddOns,
      estimatedWeightKg: estimatedWeightKg ?? this.estimatedWeightKg,
      actualWeightKg: actualWeightKg ?? this.actualWeightKg,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupSubtitle: pickupSubtitle ?? this.pickupSubtitle,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      customerAddress: customerAddress ?? this.customerAddress,
      deliverySubtitle: deliverySubtitle ?? this.deliverySubtitle,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      isSameAsPickup: isSameAsPickup ?? this.isSameAsPickup,
      basePrice: basePrice ?? this.basePrice,
      addOnsPrice: addOnsPrice ?? this.addOnsPrice,
      pickupFee: pickupFee ?? this.pickupFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalPrice: totalPrice ?? this.totalPrice,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentTransactionRef:
          paymentTransactionRef ?? this.paymentTransactionRef,
      paidAt: paidAt ?? this.paidAt,
      pickupRiderId: pickupRiderId ?? this.pickupRiderId,
      pickupRiderName: pickupRiderName ?? this.pickupRiderName,
      pickupRiderPhone: pickupRiderPhone ?? this.pickupRiderPhone,
      pickupRiderPhotoUrl: pickupRiderPhotoUrl ?? this.pickupRiderPhotoUrl,
      pickupRiderVehicleType:
          pickupRiderVehicleType ?? this.pickupRiderVehicleType,
      pickupRiderPlateNumber:
          pickupRiderPlateNumber ?? this.pickupRiderPlateNumber,
      pickupRiderAssignedAt:
          pickupRiderAssignedAt ?? this.pickupRiderAssignedAt,
      pickupRiderPickedUpAt:
          pickupRiderPickedUpAt ?? this.pickupRiderPickedUpAt,
      deliveryRiderId: deliveryRiderId ?? this.deliveryRiderId,
      deliveryRiderName: deliveryRiderName ?? this.deliveryRiderName,
      deliveryRiderPhone: deliveryRiderPhone ?? this.deliveryRiderPhone,
      deliveryRiderPhotoUrl:
          deliveryRiderPhotoUrl ?? this.deliveryRiderPhotoUrl,
      deliveryRiderVehicleType:
          deliveryRiderVehicleType ?? this.deliveryRiderVehicleType,
      deliveryRiderPlateNumber:
          deliveryRiderPlateNumber ?? this.deliveryRiderPlateNumber,
      deliveryRiderAssignedAt:
          deliveryRiderAssignedAt ?? this.deliveryRiderAssignedAt,
      deliveryRiderDeliveredAt:
          deliveryRiderDeliveredAt ?? this.deliveryRiderDeliveredAt,
      hasUnreadForCustomer: hasUnreadForCustomer ?? this.hasUnreadForCustomer,
      hasUnreadForLaundry: hasUnreadForLaundry ?? this.hasUnreadForLaundry,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      assignedAutomatically:
          assignedAutomatically ?? this.assignedAutomatically,
      assignedAt: assignedAt ?? this.assignedAt,
      offeredLaundryId: offeredLaundryId ?? this.offeredLaundryId,
      offeredAt: offeredAt ?? this.offeredAt,
      offerExpiresAt: offerExpiresAt ?? this.offerExpiresAt,
      rejectedLaundryIds: rejectedLaundryIds ?? this.rejectedLaundryIds,
      assignmentAttempts: assignmentAttempts ?? this.assignmentAttempts,
      lastAssignmentAttemptAt:
          lastAssignmentAttemptAt ?? this.lastAssignmentAttemptAt,
      maxSearchRadiusKm: maxSearchRadiusKm ?? this.maxSearchRadiusKm,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickupStartedAt: pickupStartedAt ?? this.pickupStartedAt,
      arrivedAtPickupAt: arrivedAtPickupAt ?? this.arrivedAtPickupAt,
      arrivedAtLaundryAt: arrivedAtLaundryAt ?? this.arrivedAtLaundryAt,
      processingStartedAt: processingStartedAt ?? this.processingStartedAt,
      readyForDropoffAt: readyForDropoffAt ?? this.readyForDropoffAt,
      deliveryStartedAt: deliveryStartedAt ?? this.deliveryStartedAt,
      arrivedAtCustomerAt: arrivedAtCustomerAt ?? this.arrivedAtCustomerAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      customerNotes: customerNotes ?? this.customerNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _readNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    return fallback;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Timestamp? _dateToTimestamp(DateTime? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value);
  }
}
