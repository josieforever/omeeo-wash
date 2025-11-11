// // Cloud Functions v2 (JavaScript / CommonJS)
// const { onDocumentCreated } = require("firebase-functions/v2/firestore");
// const logger = require("firebase-functions/logger");
// const admin = require("firebase-admin");

// admin.initializeApp();
// const db = admin.firestore();
// const messaging = admin.messaging();

// // Small helper to make a neat notification preview
// function preview(text, max = 120) {
//   if (!text || typeof text !== "string") return "New message";
//   const s = text.trim();
//   return s.length <= max ? s : `${s.slice(0, max)}…`;
// }

// // Remove invalid tokens from the user's doc
// async function pruneBadTokens(uid, tokens, batchResponse) {
//   const bad = [];
//   batchResponse.responses.forEach((r, i) => {
//     if (!r.success) {
//       const code = r.error && r.error.code;
//       if (
//         code === "messaging/registration-token-not-registered" ||
//         code === "messaging/invalid-registration-token"
//       ) {
//         bad.push(tokens[i]);
//       }
//     }
//   });

//   if (bad.length) {
//     await db
//       .collection("users")
//       .doc(uid)
//       .set(
//         {
//           fcmTokens: admin.firestore.FieldValue.arrayRemove(...bad),
//           fcmUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
//         },
//         { merge: true }
//       );
//     logger.info(`Pruned ${bad.length} invalid token(s) for ${uid}`);
//   }
// }

// console.log("Something...........................");
// exports.onBookingChatCreated = onDocumentCreated(
//   // Optional deploy settings
//   { region: "us-central1", memory: "256MiB", timeoutSeconds: 30 },
//   "bookings/{bookingId}/booking_chat/{messageId}",
//   async (event) => {
//     const snap = event.data;
//     if (!snap) return;

//     const { bookingId, messageId } = event.params || {};
//     const msg = snap.data() || {};

//     // Handle both spellings just in case: bookingRecieverId
//     const bookingRecieverId = msg.bookingRecieverId;
//     const bookingSenderId = msg.bookingSenderId;
//     const senderId = msg.senderId;
//     const text = msg.text;

//     // Basic guards
//     if (!bookingRecieverId || !bookingSenderId || !senderId) {
//       logger.warn("Missing required fields on chat doc", {
//         bookingId,
//         messageId,
//         hasReceiver: !!bookingRecieverId,
//         hasSender: !!bookingSenderId,
//         hasSenderId: !!senderId,
//       });
//       return;
//     }

//     // Decide the recipient: if the sender is the booking sender, notify the receiver; otherwise notify the booking sender.
//     const targetUid =
//       senderId === bookingSenderId ? bookingRecieverId : bookingSenderId;

//     // Load tokens (prefers array, falls back to a single token if you ever stored that)
//     const userDoc = await db.collection("users").doc(targetUid).get();
//     const tokens = Array.isArray(userDoc.get("fcmTokens"))
//       ? userDoc.get("fcmTokens")
//       : [];

//     if (!tokens.length) {
//       logger.info(
//         `No FCM tokens for user ${targetUid}; skipping notification.`,
//         { bookingId, messageId }
//       );
//       return;
//     }

//     // Build the notification
//     const payload = {
//       tokens,
//       notification: {
//         title: "New message",
//         body: preview(text),
//       },
//       data: {
//         type: "chat",
//         bookingId: bookingId || "",
//         messageId: messageId || "",
//         senderId: senderId || "",
//         click_action: "FLUTTER_NOTIFICATION_CLICK",
//       },
//       android: {
//         priority: "high",
//         notification: {
//           channelId: "chat_messages",
//           sound: "default",
//         },
//       },
//       apns: {
//         payload: {
//           aps: {
//             sound: "default",
//           },
//         },
//       },
//     };

//     // Send and prune invalid tokens
//     const resp = await messaging.sendEachForMulticast(payload);
//     logger.info(
//       `Chat push sent: ${resp.successCount}/${tokens.length} delivered`,
//       { bookingId, messageId, targetUid }
//     );

//     await pruneBadTokens(targetUid, tokens, resp);
//   }
// );
