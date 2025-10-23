// functions/index.js
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

// --- Tiny in-memory cache for admin tokens (refreshes every 60s) ---
let adminCache = { tokens: null, expiresAt: 0 };
async function getAdminTokens() {
  if (adminCache.tokens && adminCache.expiresAt > Date.now()) {
    return adminCache.tokens;
  }
  const snap = await db.collection("admin").doc("idforadminv1").get();
  const tokens = (snap.data()?.fcmTokens || []).filter(Boolean);
  adminCache = { tokens, expiresAt: Date.now() + 60_000 };
  return tokens;
}

function chunk(arr, size = 500) {
  if (!arr?.length) return [];
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

// 🔥 Trigger when a new help message is created
exports.sendHelpMessageNotification = onDocumentCreated(
  {
    document: "users/{userId}/help_messages/{messageId}",
    region: "us-central1",
    memory: "256MiB",
    cpu: 1,
    timeoutSeconds: 30,
    minInstances: 1, // keep warm to avoid cold-start latency
    maxInstances: 10,
  },
  async (event) => {
    const t0 = Date.now();

    const snapshot = event.data;
    const { userId } = event.params;

    if (!snapshot) {
      console.log("⚠️ No snapshot found.");
      return null;
    }

    const message = snapshot.data();
    if (!message?.sender || !message?.text) {
      console.log("⚠️ Missing fields in message data.");
      return null;
    }

    console.log(`📩 New message from ${message.sender} in user ${userId}`);

    // --- Resolve target tokens ---
    let targetTokens = [];
    if (message.sender === "user") {
      // User → notify admins
      targetTokens = await getAdminTokens();
      console.log("Sending notification to admins:", targetTokens.length);
    } else if (message.sender === "ommeo") {
      // Admin → notify that user
      const userDoc = await db.collection("users").doc(userId).get();
      targetTokens = userDoc.data()?.fcmTokens || [];
      console.log("Sending notification to user:", userId);
    }

    const t1 = Date.now();

    if (targetTokens.length === 0) {
      console.log("⚠️ No FCM tokens found for this target.");
      return null;
    }

    // --- High-priority, immediate delivery ---
    const payload = {
      notification: {
        title:
          message.sender === "user"
            ? "New Help Request 📩"
            : "Message from Omeeo Support 💬",
        body: message.text || "You have a new message",
      },
      data: {
        userId,
        sender: message.sender,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        ttl: 0, // deliver now, don't queue
        notification: {
          channelId: "help_messages", // make sure your app created this channel
        },
      },
      apns: {
        headers: { "apns-priority": "10" }, // immediate on iOS
      },
    };

    // --- Send in batches; prune dead tokens ---
    let success = 0;
    let failure = 0;

    for (const tokens of chunk(targetTokens, 500)) {
      const res = await getMessaging().sendEachForMulticast({
        tokens,
        ...payload,
      });

      success += res.successCount;
      failure += res.failureCount;

      // Remove invalid/stale tokens from Firestore
      const toRemove = [];
      res.responses.forEach((r, i) => {
        if (!r.success) {
          const code = r.error?.code || "";
          if (
            code.includes("registration-token-not-registered") ||
            code.includes("invalid-registration-token")
          ) {
            toRemove.push(tokens[i]);
          }
        }
      });

      if (toRemove.length) {
        const ref =
          message.sender === "user"
            ? db.collection("admin").doc("idforadminv1")
            : db.collection("users").doc(userId);
        await ref
          .update({ fcmTokens: FieldValue.arrayRemove(...toRemove) })
          .catch(() => {});
      }
    }

    const t2 = Date.now();
    console.log(
      `✅ Notification sent: ${success} success, ${failure} failed. timing reads=${
        t1 - t0
      }ms send=${t2 - t1}ms total=${t2 - t0}ms`
    );
    console.log(`Message:......... ${message.text}`);

    return null;
  }
);
