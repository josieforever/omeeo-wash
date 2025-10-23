//WELCOM EMAIL----------------------------------------
// const functions = require("firebase-functions/v1");
// const admin = require("firebase-admin");
// const nodemailer = require("nodemailer");

// admin.initializeApp();

// const gmailUser = "omeeogh@gmail.com";
// const gmailPass = "yxmvgrglaxouwphh";

// if (!gmailUser || !gmailPass) {
//   console.warn(
//     "Missing Gmail creds. Set GMAIL_USER/GMAIL_PASS env vars or use functions:config:set gmail.user / gmail.pass"
//   );
// }

// const transporter = nodemailer.createTransport({
//   service: "gmail",
//   auth: { user: gmailUser, pass: gmailPass },
// });

// // 3) v1 Auth trigger — fires after account creation
// exports.sendWelcomeEmail = functions
//   .region("us-central1")
//   .auth.user()
//   .onCreate(async (user) => {
//     const email = user.email;
//     if (!email) {
//       console.log("New auth user has no email; skipping.");
//       return;
//     }

//     const firstName =
//       (user.displayName && user.displayName.split(" ")[0]) ||
//       (email.includes("@") ? email.split("@")[0] : "there");
//     console.error("First name:..........", firstName);

//     const mailOptions = {
//       from: `"Omeeo Wash Support" <${gmailUser}>`,
//       to: email,
//       subject: "🎉 Welcome to Omeeo Wash!",
//       text: [
//         `Hi ${firstName},`,
//         `You've successfully signed up for Omeeo Wash.`,
//         `You can now book washes, track your car’s progress, and enjoy a cleaner ride anytime.`,
//         `Need help? Just reply to this email — we’re here for you.`,
//         `— The Omeeo Wash Team`,
//       ].join("\n\n"),
//       html: `
//         <div style="font-family:Arial,Helvetica,sans-serif;line-height:1.6">
//           <h2 style="margin:0 0 12px 0;">Welcome to
//             <span style="color:#3E00A1;">Omeeo Wash</span>!
//           </h2>
//           <p>Hi ${firstName},</p>
//           <p>You’ve <strong>successfully signed up</strong> for Omeeo Wash 🚗✨</p>
//           <p>Book washes, track your car’s progress, and enjoy a cleaner ride anytime.</p>
//           <p>Need help? Just reply to this email — we’re here for you.</p>
//           <br>
//           <p style="font-weight:bold;margin:0;">— The Omeeo Wash Team</p>
//         </div>
//       `,
//       replyTo: gmailUser,
//       headers: { "X-Entity-Ref-ID": user.uid },
//     };

//     try {
//       await transporter.sendMail(mailOptions);
//       console.log(`✅ Welcome email sent to ${email}`);
//     } catch (err) {
//       console.error("❌ Error sending welcome email:..........", err);
//     }
//     return null;
//   });

//ONSEND MESSAGE NOTIFICATION----------------------
// const { onDocumentCreated } = require("firebase-functions/v2/firestore");
// const { initializeApp } = require("firebase-admin/app");
// const { getFirestore } = require("firebase-admin/firestore");
// const { getMessaging } = require("firebase-admin/messaging");

// initializeApp();
// const db = getFirestore();

// // 🔥 Trigger when a new help message is created
// exports.sendHelpMessageNotification = onDocumentCreated(
//   {
//     document: "users/{userId}/help_messages/{messageId}",
//     region: "us-central1",
//   },
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
//               : "Message from Omeeo Support 💬",
//           body: message.text || "You have a new message",
//         },
//         data: {
//           userId,
//           sender: message.sender,
//           click_action: "FLUTTER_NOTIFICATION_CLICK",
//         },
//       };

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

//ONSEND MESSAGE NOTIFICATION V2, THE DEPLOYED ONE----------------------
