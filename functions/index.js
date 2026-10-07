const { initializeApp } = require("firebase-admin/app");
const {
  getFirestore,
  FieldValue,
  Timestamp,
} = require("firebase-admin/firestore");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getFunctions } = require("firebase-admin/functions");
const { logger } = require("firebase-functions");

initializeApp();

const db = getFirestore();

const MAX_MATCH_DISTANCE_KM = 8;
const MAX_RIDER_MATCH_DISTANCE_KM = 10;
const OFFER_EXPIRY_MINUTES = 2;
const MAX_LAUNDRY_ASSIGNMENT_ATTEMPTS = 3;
const MAX_RIDER_RETRY_ATTEMPTS = 3;

/* -------------------------------------------------------------------------- */
/*                              LAUNDRY MATCHING                              */
/* -------------------------------------------------------------------------- */

exports.offerLaundryOnBookingCreate = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const bookingId = event.params.bookingId;
    const booking = snapshot.data();

    if (booking.status !== "awaiting_laundry_assignment") {
      logger.info("Skipping create trigger. Booking not awaiting assignment.", {
        bookingId,
        status: booking.status,
      });
      return;
    }

    await offerLaundryForBooking(bookingId);
  },
);

exports.reofferLaundryOnBookingUpdate = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    // Only trigger when status transitions INTO awaiting_laundry_assignment
    const statusChanged =
      before.status !== after.status &&
      after.status === "awaiting_laundry_assignment";

    if (!statusChanged) return;

    const laundrySnapshot = getLaundrySnapshot(after);

    if (laundrySnapshot.id) {
      logger.info("Skipping re-offer because laundrySnapshot still exists.", {
        bookingId,
        laundryId: laundrySnapshot.id,
      });
      return;
    }

    await offerLaundryForBooking(bookingId);
  },
);

/**
 * Scheduled job that runs every minute to expire stale laundry offers.
 * This replaces the unreliable document-update-based expiry approach.
 */
exports.expireLaundryOffersScheduled = onSchedule(
  "every 1 minutes",
  async () => {
    const now = Timestamp.now();

    const expiredOffersSnap = await db
      .collection("bookings")
      .where("status", "==", "offered_to_laundry")
      .where("laundryOffer.offerExpiresAt", "<=", now)
      .get();

    if (expiredOffersSnap.empty) {
      return;
    }

    logger.info(
      `Found ${expiredOffersSnap.size} expired laundry offer(s) to process.`,
    );

    const jobs = expiredOffersSnap.docs.map((doc) =>
      expireSingleLaundryOffer(doc.id, doc.data()),
    );

    await Promise.allSettled(jobs);
  },
);

async function expireSingleLaundryOffer(bookingId, bookingData) {
  const offeredLaundryId = bookingData.laundryOffer?.offeredLaundryId;
  if (!offeredLaundryId) return;

  const bookingRef = db.collection("bookings").doc(bookingId);

  const currentAttempts = Number(
    bookingData.searchMeta?.assignmentAttempts ?? 0,
  );

  // If we've exhausted attempts, mark no laundry found instead of re-queuing
  if (currentAttempts >= MAX_LAUNDRY_ASSIGNMENT_ATTEMPTS) {
    logger.info(
      "Max laundry assignment attempts reached. Marking no laundry found.",
      {
        bookingId,
        attempts: currentAttempts,
      },
    );
    await markNoLaundryFound(bookingId);
    return;
  }

  await db.runTransaction(async (tx) => {
    const freshSnap = await tx.get(bookingRef);
    const fresh = freshSnap.data();

    if (!fresh) {
      throw new Error("Booking not found while expiring offer");
    }

    if (fresh.status !== "offered_to_laundry") return;

    const freshOfferExpiresAt = fresh.laundryOffer?.offerExpiresAt;

    if (
      !freshOfferExpiresAt ||
      typeof freshOfferExpiresAt.toDate !== "function" ||
      freshOfferExpiresAt.toDate() > new Date()
    ) {
      // Offer was refreshed or accepted — skip
      return;
    }

    const rejectedLaundryIds = Array.isArray(fresh.rejectedLaundryIds)
      ? fresh.rejectedLaundryIds
      : [];

    const updatedRejectedLaundryIds = rejectedLaundryIds.includes(
      offeredLaundryId,
    )
      ? rejectedLaundryIds
      : [...rejectedLaundryIds, offeredLaundryId];

    tx.update(bookingRef, {
      status: "awaiting_laundry_assignment",
      laundrySnapshot: null,
      rejectedLaundryIds: updatedRejectedLaundryIds,

      "laundryOffer.offeredLaundryId": null,
      "laundryOffer.offeredAt": null,
      "laundryOffer.offerExpiresAt": null,

      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.set(bookingRef.collection("status_history").doc(), {
      status: "awaiting_laundry_assignment",
      title: "Offer Expired",
      description:
        "Laundry did not respond in time. Looking for another laundry.",
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info("Expired laundry offer and reset booking for reassignment.", {
    bookingId,
    offeredLaundryId,
  });
}

exports.acceptLaundryOffer = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const acceptedNow =
      before.status === "offered_to_laundry" && after.status === "pending";

    if (!acceptedNow) return;

    const laundrySnapshot = getLaundrySnapshot(after);

    logger.info("Laundry accepted booking offer.", {
      bookingId,
      laundryId: laundrySnapshot.id || null,
      laundryName: laundrySnapshot.name || null,
    });
  },
);

async function offerLaundryForBooking(bookingId) {
  const bookingRef = db.collection("bookings").doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    logger.warn("Booking does not exist for offer flow.", { bookingId });
    return;
  }

  const booking = bookingSnap.data();

  if (!booking) {
    logger.warn("Booking data missing for offer flow.", { bookingId });
    return;
  }

  if (booking.status !== "awaiting_laundry_assignment") {
    logger.info("Skipping offer flow. Booking not awaiting assignment.", {
      bookingId,
      status: booking.status,
    });
    return;
  }

  const existingLaundrySnapshot = getLaundrySnapshot(booking);

  if (existingLaundrySnapshot.id) {
    logger.info("Skipping offer flow. Booking already has laundrySnapshot.", {
      bookingId,
      laundryId: existingLaundrySnapshot.id,
    });
    return;
  }

  // Enforce max attempts cap before even searching
  const currentAttempts = Number(booking.searchMeta?.assignmentAttempts ?? 0);

  if (currentAttempts >= MAX_LAUNDRY_ASSIGNMENT_ATTEMPTS) {
    logger.info(
      "Max laundry assignment attempts reached. Marking no laundry found.",
      {
        bookingId,
        attempts: currentAttempts,
      },
    );
    await markNoLaundryFound(bookingId);
    return;
  }

  const pickupLat = booking.pickupAddress?.latitude;
  const pickupLng = booking.pickupAddress?.longitude;

  if (pickupLat == null || pickupLng == null) {
    logger.warn("Booking missing pickup coordinates.", { bookingId });
    return;
  }

  const selectedAddOns = Array.isArray(booking.selectedAddOns)
    ? booking.selectedAddOns
    : [];

  const serviceType = booking.serviceType || "";

  const rejectedLaundryIds = Array.isArray(booking.rejectedLaundryIds)
    ? booking.rejectedLaundryIds
    : [];

  const laundriesSnap = await db
    .collection("laundries")
    .where("role", "==", "laundry")
    .where("business.isApproved", "==", true)
    .where("business.acceptingOrders", "==", true)
    .where("business.acceptingAutoAssignments", "==", true)
    .get();

  if (laundriesSnap.empty) {
    logger.info("No laundries available for matching.", { bookingId });
    await markNoLaundryFound(bookingId);
    return;
  }

  const eligible = [];

  for (const doc of laundriesSnap.docs) {
    const laundry = doc.data();

    if (rejectedLaundryIds.includes(doc.id)) continue;

    const lat = laundry.location?.latitude;
    const lng = laundry.location?.longitude;

    if (lat == null || lng == null) continue;

    const currentOrderCount = Number(laundry.business?.currentOrderCount ?? 0);
    const maxConcurrentOrders = Number(
      laundry.business?.maxConcurrentOrders ?? 0,
    );

    if (maxConcurrentOrders > 0 && currentOrderCount >= maxConcurrentOrders) {
      continue;
    }

    if (!isLaundryOpenNow(laundry.openingHours)) continue;
    if (!supportsRequestedService(laundry, serviceType)) continue;
    if (!supportsRequestedAddOns(laundry, selectedAddOns)) continue;

    const distanceKm = haversineKm(pickupLat, pickupLng, lat, lng);

    if (distanceKm > MAX_MATCH_DISTANCE_KM) continue;

    const rating = Number(laundry.ratings?.rating ?? 0);

    eligible.push({
      id: doc.id,
      distanceKm,
      rating,
      score: distanceKm - rating * 0.05,
      data: laundry,
    });
  }

  if (eligible.length === 0) {
    logger.info("No eligible laundries matched booking.", {
      bookingId,
      serviceType,
      selectedAddOns,
      rejectedLaundryIds,
    });
    await markNoLaundryFound(bookingId);
    return;
  }

  eligible.sort((a, b) => a.score - b.score);
  const best = eligible[0];

  const offerExpiresAt = Timestamp.fromDate(
    new Date(Date.now() + OFFER_EXPIRY_MINUTES * 60 * 1000),
  );

  const selectedLaundrySnapshot = buildLaundrySnapshot(best.id, best.data);

  await db.runTransaction(async (tx) => {
    const freshSnap = await tx.get(bookingRef);
    const fresh = freshSnap.data();

    if (!fresh) {
      throw new Error("Booking disappeared before laundry offer");
    }

    if (fresh.status !== "awaiting_laundry_assignment") {
      logger.info("Booking status changed before offer transaction.", {
        bookingId,
        status: fresh.status,
      });
      return;
    }

    const freshLaundrySnapshot = getLaundrySnapshot(fresh);

    if (freshLaundrySnapshot.id) {
      logger.info("Booking already has laundrySnapshot before transaction.", {
        bookingId,
        laundryId: freshLaundrySnapshot.id,
      });
      return;
    }

    const nextAttempts = Number(fresh.searchMeta?.assignmentAttempts ?? 0) + 1;

    tx.update(bookingRef, {
      laundrySnapshot: selectedLaundrySnapshot,

      status: "offered_to_laundry",
      updatedAt: FieldValue.serverTimestamp(),

      "laundryOffer.offeredLaundryId": best.id,
      "laundryOffer.offeredAt": FieldValue.serverTimestamp(),
      "laundryOffer.offerExpiresAt": offerExpiresAt,

      "searchMeta.assignmentAttempts": nextAttempts,
      "searchMeta.lastAssignmentAttemptAt": FieldValue.serverTimestamp(),
    });

    tx.set(bookingRef.collection("status_history").doc(), {
      status: "offered_to_laundry",
      title: "Offer Sent To Laundry",
      description: `${selectedLaundrySnapshot.name || "A laundry"} received this order offer.`,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info("Laundry offer created successfully.", {
    bookingId,
    laundryId: selectedLaundrySnapshot.id,
    laundryName: selectedLaundrySnapshot.name || "",
    distanceKm: best.distanceKm,
    rating: best.rating,
  });
}

async function markNoLaundryFound(bookingId) {
  const bookingRef = db.collection("bookings").doc(bookingId);

  await db.runTransaction(async (tx) => {
    const bookingSnap = await tx.get(bookingRef);
    const booking = bookingSnap.data();

    if (!booking) {
      throw new Error("Booking not found while marking no laundry found");
    }

    const laundrySnapshot = getLaundrySnapshot(booking);

    if (laundrySnapshot.id) return;

    const nextAttempts =
      Number(booking.searchMeta?.assignmentAttempts ?? 0) + 1;

    tx.update(bookingRef, {
      status: "no_laundry_found",
      updatedAt: FieldValue.serverTimestamp(),
      "searchMeta.assignmentAttempts": nextAttempts,
      "searchMeta.lastAssignmentAttemptAt": FieldValue.serverTimestamp(),
    });

    tx.set(bookingRef.collection("status_history").doc(), {
      status: "no_laundry_found",
      title: "No Laundry Found",
      description: "No suitable laundry was found for this booking.",
      createdAt: FieldValue.serverTimestamp(),
    });
  });
}

/* -------------------------------------------------------------------------- */
/*                               RIDER MATCHING                               */
/* -------------------------------------------------------------------------- */

exports.offerPickupRiderOnBookingUpdate = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const changedToLookingForPickupRider =
      before.status !== after.status &&
      after.status === "looking_for_pickup_rider";

    if (!changedToLookingForPickupRider) return;

    await assignPickupRiderForBooking(bookingId);
  },
);

exports.offerDeliveryRiderOnBookingUpdate = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const changedToReadyForDropoff =
      before.status !== after.status && after.status === "ready_for_dropoff";

    if (!changedToReadyForDropoff) return;

    await assignDeliveryRiderForBooking(bookingId);
  },
);

/**
 * Scheduled job that retries rider assignment for bookings stuck waiting.
 * Handles the case where no rider was available at the time of status change.
 */
exports.retryStuckRiderAssignments = onSchedule("every 2 minutes", async () => {
  const now = new Date();

  // Retry pickup rider assignments stuck for more than 90 seconds
  const stuckPickupSnap = await db
    .collection("bookings")
    .where("status", "==", "looking_for_pickup_rider")
    .get();

  const stuckDeliverySnap = await db
    .collection("bookings")
    .where("status", "==", "ready_for_dropoff")
    .get();

  const pickupJobs = stuckPickupSnap.docs
    .filter((doc) => {
      const data = doc.data();
      // Only retry if no rider is assigned and booking has been waiting
      if (data.pickupRider?.riderId) return false;
      const updatedAt = data.updatedAt?.toDate?.();
      if (!updatedAt) return false;
      const waitSeconds = (now - updatedAt) / 1000;
      return waitSeconds > 90;
    })
    .map((doc) => assignPickupRiderForBooking(doc.id));

  const deliveryJobs = stuckDeliverySnap.docs
    .filter((doc) => {
      const data = doc.data();
      if (data.deliveryRider?.riderId) return false;
      const updatedAt = data.updatedAt?.toDate?.();
      if (!updatedAt) return false;
      const waitSeconds = (now - updatedAt) / 1000;
      return waitSeconds > 90;
    })
    .map((doc) => assignDeliveryRiderForBooking(doc.id));

  if (pickupJobs.length > 0 || deliveryJobs.length > 0) {
    logger.info("Retrying stuck rider assignments.", {
      pickupCount: pickupJobs.length,
      deliveryCount: deliveryJobs.length,
    });
  }

  await Promise.allSettled([...pickupJobs, ...deliveryJobs]);
});

async function assignPickupRiderForBooking(bookingId) {
  const bookingRef = db.collection("bookings").doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    logger.warn("Booking does not exist for pickup rider flow.", { bookingId });
    return;
  }

  const booking = bookingSnap.data();

  if (!booking) {
    logger.warn("Booking data missing for pickup rider flow.", { bookingId });
    return;
  }

  if (booking.status !== "looking_for_pickup_rider") {
    logger.info("Skipping pickup rider assignment. Wrong booking status.", {
      bookingId,
      status: booking.status,
    });
    return;
  }

  if (booking.pickupRider?.riderId) {
    logger.info("Skipping pickup rider assignment. Rider already assigned.", {
      bookingId,
      riderId: booking.pickupRider?.riderId,
    });
    return;
  }

  // Match pickup rider to pickup location (where they need to go pick up clothes)
  const pickupLat = booking.pickupAddress?.latitude;
  const pickupLng = booking.pickupAddress?.longitude;

  if (pickupLat == null || pickupLng == null) {
    logger.warn("Booking missing pickup coordinates for pickup rider flow.", {
      bookingId,
    });
    return;
  }

  const ridersSnap = await db
    .collection("riders")
    .where("role", "==", "rider")
    .where("business.isApproved", "==", true)
    .where("business.isOnline", "==", true)
    .where("business.acceptingAssignments", "==", true)
    .get();

  if (ridersSnap.empty) {
    logger.info("No riders available for pickup assignment.", { bookingId });
    return;
  }

  const eligible = [];

  for (const doc of ridersSnap.docs) {
    const rider = doc.data();

    const lat = rider.location?.latitude;
    const lng = rider.location?.longitude;

    if (lat == null || lng == null) continue;

    const currentActiveRequestCount = Number(
      rider.business?.currentActiveRequestCount ?? 0,
    );

    const maxActiveRequests = Number(rider.business?.maxActiveRequests ?? 0);

    if (
      maxActiveRequests > 0 &&
      currentActiveRequestCount >= maxActiveRequests
    ) {
      continue;
    }

    const distanceKm = haversineKm(pickupLat, pickupLng, lat, lng);

    if (distanceKm > MAX_RIDER_MATCH_DISTANCE_KM) continue;

    const rating = Number(rider.ratings?.rating ?? 0);

    eligible.push({
      id: doc.id,
      distanceKm,
      rating,
      score: distanceKm - rating * 0.05,
      data: rider,
    });
  }

  if (eligible.length === 0) {
    logger.info("No eligible riders matched booking for pickup.", {
      bookingId,
    });
    return;
  }

  eligible.sort((a, b) => a.score - b.score);
  const best = eligible[0];

  await db.runTransaction(async (tx) => {
    const freshBookingSnap = await tx.get(bookingRef);
    const freshBooking = freshBookingSnap.data();

    if (!freshBooking) {
      throw new Error("Booking disappeared before pickup rider assignment");
    }

    if (freshBooking.status !== "looking_for_pickup_rider") {
      logger.info("Booking status changed before pickup rider transaction.", {
        bookingId,
        status: freshBooking.status,
      });
      return;
    }

    if (freshBooking.pickupRider?.riderId) {
      logger.info("Pickup rider already assigned before transaction.", {
        bookingId,
        riderId: freshBooking.pickupRider?.riderId,
      });
      return;
    }

    const riderRef = db.collection("riders").doc(best.id);
    const riderSnap = await tx.get(riderRef);
    const riderData = riderSnap.data();

    if (!riderData) {
      throw new Error("Matched rider disappeared before assignment");
    }

    const currentActiveRequestCount = Number(
      riderData.business?.currentActiveRequestCount ?? 0,
    );

    const maxActiveRequests = Number(
      riderData.business?.maxActiveRequests ?? 0,
    );

    if (
      maxActiveRequests > 0 &&
      currentActiveRequestCount >= maxActiveRequests
    ) {
      logger.info("Matched rider became unavailable before transaction.", {
        bookingId,
        riderId: best.id,
      });
      return;
    }

    const existingActiveRequestIds = Array.isArray(
      riderData.business?.activeRequestIds,
    )
      ? riderData.business.activeRequestIds
      : [];

    const existingLaundryIds = Array.isArray(
      riderData.business?.currentLaundryIds,
    )
      ? riderData.business.currentLaundryIds
      : [];

    const existingCustomerIds = Array.isArray(
      riderData.business?.currentCustomerIds,
    )
      ? riderData.business.currentCustomerIds
      : [];

    const laundrySnapshot = getLaundrySnapshot(freshBooking);
    const laundryId = laundrySnapshot.id || null;

    const newActiveRequestIds = existingActiveRequestIds.includes(bookingId)
      ? existingActiveRequestIds
      : [...existingActiveRequestIds, bookingId];

    const newCurrentLaundryIds =
      laundryId && !existingLaundryIds.includes(laundryId)
        ? [...existingLaundryIds, laundryId]
        : existingLaundryIds;

    const newCurrentCustomerIds =
      freshBooking.customerId &&
      !existingCustomerIds.includes(freshBooking.customerId)
        ? [...existingCustomerIds, freshBooking.customerId]
        : existingCustomerIds;

    const nextActiveCount = currentActiveRequestCount + 1;

    tx.update(bookingRef, {
      status: "pickup_rider_assigned",
      "pickupRider.riderId": best.id,
      "pickupRider.fullName": best.data.profile?.fullName || "",
      "pickupRider.phoneNumber": best.data.contact?.phoneNumber || "",
      "pickupRider.photoUrl": best.data.profile?.photoUrl || "",
      "pickupRider.vehicleType": best.data.vehicle?.type || "",
      "pickupRider.plateNumber": best.data.vehicle?.plateNumber || "",
      "pickupRider.assignedAt": FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(riderRef, {
      "business.currentActiveRequestCount": nextActiveCount,
      "business.activeRequestIds": newActiveRequestIds,
      "business.currentLaundryIds": newCurrentLaundryIds,
      "business.currentCustomerIds": newCurrentCustomerIds,
      "business.availabilityStatus":
        maxActiveRequests > 0 && nextActiveCount >= maxActiveRequests
          ? "busy"
          : "available",
      "business.acceptingAssignments":
        maxActiveRequests > 0 ? nextActiveCount < maxActiveRequests : true,
      "timestamps.updatedAt": FieldValue.serverTimestamp(),
    });

    tx.set(bookingRef.collection("status_history").doc(), {
      status: "pickup_rider_assigned",
      title: "Pickup Rider Assigned",
      description: `${best.data.profile?.fullName || "A rider"} was assigned for pickup.`,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info("Pickup rider assigned successfully.", {
    bookingId,
    riderId: best.id,
    riderName: best.data.profile?.fullName || "",
    distanceKm: best.distanceKm,
    rating: best.rating,
  });
}

async function assignDeliveryRiderForBooking(bookingId) {
  const bookingRef = db.collection("bookings").doc(bookingId);
  const bookingSnap = await bookingRef.get();

  if (!bookingSnap.exists) {
    logger.warn("Booking does not exist for delivery rider flow.", {
      bookingId,
    });
    return;
  }

  const booking = bookingSnap.data();

  if (!booking) {
    logger.warn("Booking data missing for delivery rider flow.", { bookingId });
    return;
  }

  if (booking.status !== "ready_for_dropoff") {
    logger.info("Skipping delivery rider assignment. Wrong booking status.", {
      bookingId,
      status: booking.status,
    });
    return;
  }

  if (booking.deliveryRider?.riderId) {
    logger.info("Skipping delivery rider assignment. Rider already assigned.", {
      bookingId,
      riderId: booking.deliveryRider?.riderId,
    });
    return;
  }

  // Fix: match delivery rider to laundry location (where they pick up the order),
  // falling back to customer delivery address if laundry coordinates are unavailable.
  const laundrySnapshot = getLaundrySnapshot(booking);
  const matchLat =
    laundrySnapshot.latitude ?? booking.customerAddress?.latitude;
  const matchLng =
    laundrySnapshot.longitude ?? booking.customerAddress?.longitude;

  if (matchLat == null || matchLng == null) {
    logger.warn("Booking missing coordinates for delivery rider matching.", {
      bookingId,
    });
    return;
  }

  const ridersSnap = await db
    .collection("riders")
    .where("role", "==", "rider")
    .where("business.isApproved", "==", true)
    .where("business.isOnline", "==", true)
    .where("business.acceptingAssignments", "==", true)
    .get();

  if (ridersSnap.empty) {
    logger.info("No riders available for delivery assignment.", { bookingId });
    return;
  }

  const eligible = [];

  for (const doc of ridersSnap.docs) {
    const rider = doc.data();

    const lat = rider.location?.latitude;
    const lng = rider.location?.longitude;

    if (lat == null || lng == null) continue;

    const currentActiveRequestCount = Number(
      rider.business?.currentActiveRequestCount ?? 0,
    );

    const maxActiveRequests = Number(rider.business?.maxActiveRequests ?? 0);

    if (
      maxActiveRequests > 0 &&
      currentActiveRequestCount >= maxActiveRequests
    ) {
      continue;
    }

    const distanceKm = haversineKm(matchLat, matchLng, lat, lng);

    if (distanceKm > MAX_RIDER_MATCH_DISTANCE_KM) continue;

    const rating = Number(rider.ratings?.rating ?? 0);

    eligible.push({
      id: doc.id,
      distanceKm,
      rating,
      score: distanceKm - rating * 0.05,
      data: rider,
    });
  }

  if (eligible.length === 0) {
    logger.info("No eligible riders matched booking for delivery.", {
      bookingId,
    });
    return;
  }

  eligible.sort((a, b) => a.score - b.score);
  const best = eligible[0];

  await db.runTransaction(async (tx) => {
    const freshBookingSnap = await tx.get(bookingRef);
    const freshBooking = freshBookingSnap.data();

    if (!freshBooking) {
      throw new Error("Booking disappeared before delivery rider assignment");
    }

    if (freshBooking.status !== "ready_for_dropoff") {
      logger.info("Booking status changed before delivery rider transaction.", {
        bookingId,
        status: freshBooking.status,
      });
      return;
    }

    if (freshBooking.deliveryRider?.riderId) {
      logger.info("Delivery rider already assigned before transaction.", {
        bookingId,
        riderId: freshBooking.deliveryRider?.riderId,
      });
      return;
    }

    const riderRef = db.collection("riders").doc(best.id);
    const riderSnap = await tx.get(riderRef);
    const riderData = riderSnap.data();

    if (!riderData) {
      throw new Error("Matched rider disappeared before delivery assignment");
    }

    const currentActiveRequestCount = Number(
      riderData.business?.currentActiveRequestCount ?? 0,
    );

    const maxActiveRequests = Number(
      riderData.business?.maxActiveRequests ?? 0,
    );

    if (
      maxActiveRequests > 0 &&
      currentActiveRequestCount >= maxActiveRequests
    ) {
      logger.info(
        "Matched delivery rider became unavailable before transaction.",
        {
          bookingId,
          riderId: best.id,
        },
      );
      return;
    }

    const existingActiveRequestIds = Array.isArray(
      riderData.business?.activeRequestIds,
    )
      ? riderData.business.activeRequestIds
      : [];

    const existingLaundryIds = Array.isArray(
      riderData.business?.currentLaundryIds,
    )
      ? riderData.business.currentLaundryIds
      : [];

    const existingCustomerIds = Array.isArray(
      riderData.business?.currentCustomerIds,
    )
      ? riderData.business.currentCustomerIds
      : [];

    const freshLaundrySnapshot = getLaundrySnapshot(freshBooking);
    const laundryId = freshLaundrySnapshot.id || null;

    const newActiveRequestIds = existingActiveRequestIds.includes(bookingId)
      ? existingActiveRequestIds
      : [...existingActiveRequestIds, bookingId];

    const newCurrentLaundryIds =
      laundryId && !existingLaundryIds.includes(laundryId)
        ? [...existingLaundryIds, laundryId]
        : existingLaundryIds;

    const newCurrentCustomerIds =
      freshBooking.customerId &&
      !existingCustomerIds.includes(freshBooking.customerId)
        ? [...existingCustomerIds, freshBooking.customerId]
        : existingCustomerIds;

    const nextActiveCount = currentActiveRequestCount + 1;

    tx.update(bookingRef, {
      status: "delivery_rider_assigned",
      "deliveryRider.riderId": best.id,
      "deliveryRider.fullName": best.data.profile?.fullName || "",
      "deliveryRider.phoneNumber": best.data.contact?.phoneNumber || "",
      "deliveryRider.photoUrl": best.data.profile?.photoUrl || "",
      "deliveryRider.vehicleType": best.data.vehicle?.type || "",
      "deliveryRider.plateNumber": best.data.vehicle?.plateNumber || "",
      "deliveryRider.assignedAt": FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.update(riderRef, {
      "business.currentActiveRequestCount": nextActiveCount,
      "business.activeRequestIds": newActiveRequestIds,
      "business.currentLaundryIds": newCurrentLaundryIds,
      "business.currentCustomerIds": newCurrentCustomerIds,
      "business.availabilityStatus":
        maxActiveRequests > 0 && nextActiveCount >= maxActiveRequests
          ? "busy"
          : "available",
      "business.acceptingAssignments":
        maxActiveRequests > 0 ? nextActiveCount < maxActiveRequests : true,
      "timestamps.updatedAt": FieldValue.serverTimestamp(),
    });

    tx.set(bookingRef.collection("status_history").doc(), {
      status: "delivery_rider_assigned",
      title: "Delivery Rider Assigned",
      description: `${best.data.profile?.fullName || "A rider"} was assigned for delivery.`,
      createdAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info("Delivery rider assigned successfully.", {
    bookingId,
    riderId: best.id,
    riderName: best.data.profile?.fullName || "",
    distanceKm: best.distanceKm,
    rating: best.rating,
  });
}

/* -------------------------------------------------------------------------- */
/*                               RIDER CLEANUP                                */
/* -------------------------------------------------------------------------- */

exports.cleanupRejectedPickupRider = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const beforeRiderId = before.pickupRider?.riderId || null;
    const afterRiderId = after.pickupRider?.riderId || null;

    const riderWasRemoved = beforeRiderId && !afterRiderId;

    if (!riderWasRemoved) return;

    const laundrySnapshot = getLaundrySnapshot(before);

    await releaseRiderFromBooking({
      riderId: beforeRiderId,
      bookingId,
      laundryId: laundrySnapshot.id || null,
      customerId: before.customerId || null,
    });
  },
);

exports.cleanupRejectedDeliveryRider = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const beforeRiderId = before.deliveryRider?.riderId || null;
    const afterRiderId = after.deliveryRider?.riderId || null;

    const riderWasRemoved = beforeRiderId && !afterRiderId;

    if (!riderWasRemoved) return;

    const laundrySnapshot = getLaundrySnapshot(before);

    await releaseRiderFromBooking({
      riderId: beforeRiderId,
      bookingId,
      laundryId: laundrySnapshot.id || null,
      customerId: before.customerId || null,
    });
  },
);

exports.cleanupRidersOnBookingClosed = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const bookingId = event.params.bookingId;

    if (!before || !after) return;

    const wasOpen = !isBookingClosed(before.status);
    const isNowClosed = isBookingClosed(after.status);

    if (!wasOpen || !isNowClosed) return;

    const pickupRiderId =
      after.pickupRider?.riderId || before.pickupRider?.riderId || null;

    const deliveryRiderId =
      after.deliveryRider?.riderId || before.deliveryRider?.riderId || null;

    const afterLaundrySnapshot = getLaundrySnapshot(after);
    const beforeLaundrySnapshot = getLaundrySnapshot(before);

    const laundryId =
      afterLaundrySnapshot.id || beforeLaundrySnapshot.id || null;

    const customerId = after.customerId || before.customerId || null;

    const jobs = [];

    if (pickupRiderId) {
      jobs.push(
        releaseRiderFromBooking({
          riderId: pickupRiderId,
          bookingId,
          laundryId,
          customerId,
        }),
      );
    }

    if (deliveryRiderId && deliveryRiderId !== pickupRiderId) {
      jobs.push(
        releaseRiderFromBooking({
          riderId: deliveryRiderId,
          bookingId,
          laundryId,
          customerId,
        }),
      );
    }

    await Promise.all(jobs);
  },
);

async function releaseRiderFromBooking({
  riderId,
  bookingId,
  laundryId,
  customerId,
}) {
  if (!riderId) return;

  const riderRef = db.collection("riders").doc(riderId);

  await db.runTransaction(async (tx) => {
    const riderSnap = await tx.get(riderRef);
    const rider = riderSnap.data();

    if (!rider) return;

    const business = rider.business || {};

    const currentActiveRequestCount = Number(
      business.currentActiveRequestCount ?? 0,
    );

    const maxActiveRequests = Number(business.maxActiveRequests ?? 0);

    const activeRequestIds = Array.isArray(business.activeRequestIds)
      ? business.activeRequestIds.filter((id) => id !== bookingId)
      : [];

    const currentLaundryIds = Array.isArray(business.currentLaundryIds)
      ? laundryId
        ? business.currentLaundryIds.filter((id) => id !== laundryId)
        : business.currentLaundryIds
      : [];

    const currentCustomerIds = Array.isArray(business.currentCustomerIds)
      ? customerId
        ? business.currentCustomerIds.filter((id) => id !== customerId)
        : business.currentCustomerIds
      : [];

    const nextCount = Math.max(0, currentActiveRequestCount - 1);

    tx.update(riderRef, {
      "business.currentActiveRequestCount": nextCount,
      "business.activeRequestIds": activeRequestIds,
      "business.currentLaundryIds": currentLaundryIds,
      "business.currentCustomerIds": currentCustomerIds,
      "business.availabilityStatus":
        nextCount <= 0
          ? rider.business?.isOnline
            ? "available"
            : "offline"
          : maxActiveRequests > 0 && nextCount >= maxActiveRequests
            ? "busy"
            : "available",
      "business.acceptingAssignments":
        rider.business?.isOnline === true &&
        (maxActiveRequests <= 0 || nextCount < maxActiveRequests),
      "timestamps.updatedAt": FieldValue.serverTimestamp(),
    });
  });
}

function isBookingClosed(status) {
  return status === "completed" || status === "cancelled";
}

/* -------------------------------------------------------------------------- */
/*                                   HELPERS                                  */
/* -------------------------------------------------------------------------- */

function buildLaundrySnapshot(laundryId, laundry) {
  return {
    id: laundryId,
    name: laundry.profile?.name || "",
    phoneNumber: laundry.contact?.phoneNumber || "",
    whatsappNumber: laundry.contact?.whatsappNumber || "",
    photoUrl: laundry.profile?.photoUrl || laundry.profile?.logoUrl || "",
    addressLine: laundry.location?.addressLine || "",
    latitude: laundry.location?.latitude ?? null,
    longitude: laundry.location?.longitude ?? null,
    rating: Number(laundry.ratings?.rating ?? 0),
    totalRatings: Number(laundry.ratings?.totalRatings ?? 0),
    capturedAt: FieldValue.serverTimestamp(),
  };
}

function getLaundrySnapshot(booking) {
  const snapshot =
    booking && typeof booking.laundrySnapshot === "object"
      ? booking.laundrySnapshot
      : {};

  return {
    id: snapshot.id || snapshot.laundryId || "",
    name: snapshot.name || snapshot.laundryName || "",
    phoneNumber: snapshot.phoneNumber || snapshot.phone || "",
    whatsappNumber: snapshot.whatsappNumber || "",
    photoUrl: snapshot.photoUrl || snapshot.logoUrl || "",
    addressLine: snapshot.addressLine || "",
    latitude: snapshot.latitude ?? null,
    longitude: snapshot.longitude ?? null,
    rating: Number(snapshot.rating ?? 0),
    totalRatings: Number(snapshot.totalRatings ?? 0),
  };
}

function supportsRequestedService(laundry, serviceType) {
  if (!serviceType) return true;

  const services = laundry.services || {};

  if (serviceType === "wash_fold") {
    return services.washFold === true || services.wash_fold === true;
  }

  if (serviceType === "wash_iron") {
    if (services.washIron === true || services.wash_iron === true) {
      return true;
    }

    const washIronExtraPerKg = laundry.pricing?.washIronExtraPerKg;
    return typeof washIronExtraPerKg === "number";
  }

  return true;
}

function supportsRequestedAddOns(laundry, selectedAddOns) {
  if (!Array.isArray(selectedAddOns) || selectedAddOns.length === 0) {
    return true;
  }

  const supportedAddOns = Array.isArray(laundry.supportedAddOns)
    ? laundry.supportedAddOns
    : [];

  if (supportedAddOns.length === 0) {
    return true;
  }

  return selectedAddOns.every((addOn) => supportedAddOns.includes(addOn));
}

function isLaundryOpenNow(openingHours) {
  if (!openingHours || typeof openingHours !== "object") {
    return true;
  }

  const dayKeys = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];
  const now = new Date();
  const todayKey = dayKeys[now.getDay()];
  const today = openingHours[todayKey];

  if (!today) return true;

  if (today.isOpen !== true) return false;

  const open = today.open;
  const close = today.close;

  if (!open || !close) return true;

  const currentMinutes = now.getHours() * 60 + now.getMinutes();
  const openMinutes = parseTimeToMinutes(open);
  const closeMinutes = parseTimeToMinutes(close);

  if (openMinutes == null || closeMinutes == null) return true;

  return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
}

function parseTimeToMinutes(time) {
  if (typeof time !== "string" || !time.includes(":")) {
    return null;
  }

  const parts = time.split(":");

  if (parts.length !== 2) return null;

  const hours = Number(parts[0]);
  const minutes = Number(parts[1]);

  if (Number.isNaN(hours) || Number.isNaN(minutes)) return null;

  return hours * 60 + minutes;
}

function haversineKm(lat1, lng1, lat2, lng2) {
  const toRad = (value) => (value * Math.PI) / 180;
  const earthRadiusKm = 6371;

  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLng / 2) *
      Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return earthRadiusKm * c;
}
