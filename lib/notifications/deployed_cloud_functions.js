// const { onDocumentCreated } = require("firebase-functions/v2/firestore");
// const { initializeApp } = require("firebase-admin/app");
// const { getFirestore } = require("firebase-admin/firestore");
// const { getMessaging } = require("firebase-admin/messaging");

// initializeApp();
// const db = getFirestore();

// // 🔥 Trigger when a new help message is created
// exports.sendHelpMessageNotification = onDocumentCreated(
//   "users/{userId}/help_messages/{messageId}",
//   async (event) => {
//     const snapshot = event.data;
//     const { userId } = event.params;

//     if (!snapshot) {
//       console.log("⚠️ No snapshot found.");
//       return null;
//     }

//     const message = snapshot.data();
//     if (!message?.sender || !message?.text) {
//       console.log("⚠️ Missing fields in message data.");
//       return null;
//     }

//     console.log(`📩 New message from ${message.sender} in user ${userId}`);

//     let targetTokens = [];

//     try {
//       if (message.sender === "user") {
//         // 🧭 User sent a message → notify admins
//         const adminDoc = await db.collection("admin").doc("idforadminv1").get();
//         targetTokens = adminDoc.data()?.fcmTokens || [];
//         console.log("Sending notification to admins:", targetTokens.length);
//       } else if (message.sender === "ommeo") {
//         // 🧭 Admin sent a message → notify that user
//         const userDoc = await db.collection("users").doc(userId).get();
//         targetTokens = userDoc.data()?.fcmTokens || [];
//         console.log("Sending notification to user:", userId);
//       }

//       if (targetTokens.length === 0) {
//         console.log("⚠️ No FCM tokens found for this target.");
//         return null;
//       }

//       const payload = {
//         notification: {
//           title:
//             message.sender === "user"
//               ? "New Help Request 📩"
//               : "Message from Ommeo Support 💬",
//           body: message.text || "You have a new message",
//         },
//         data: {
//           userId,
//           sender: message.sender,
//           click_action: "FLUTTER_NOTIFICATION_CLICK",
//         },
//       };

//       // 🔥 Send to all tokens
//       const response = await getMessaging().sendEachForMulticast({
//         tokens: targetTokens,
//         ...payload,
//       });

//       console.log(
//         `✅ Notification sent: ${response.successCount} success, ${response.failureCount} failed`
//       );
//       console.log(`Message:.............. ${message.text}`);
//       return null;
//     } catch (err) {
//       console.error("❌ Error sending notification:", err);
//       return null;
//     }
//   }
// );
