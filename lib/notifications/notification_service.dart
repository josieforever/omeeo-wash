import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/profile/help_and_support/live_chat/app.config.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;

  /// Call this once after Firebase.initializeApp()
  Future<void> initFCM() async {
    // Request notification permission from the user
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
      await _getAndSaveToken();
    } else {
      debugPrint('🚫 Notification permission denied or not accepted');
    }

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Only show notification if user is NOT on chat screen, for example
      debugPrint(
        '📩 Foreground message received: ${message.notification?.title}',
      );
      // You can integrate local notifications here (if you want)
    });

    // Handle when user taps a notification to open the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification clicked!');
      // Navigate or handle deep link here
    });
  }

  // 🔍 Determine user role
  Future<void> checkUserRole(String uid) async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    bool isAdmin = userSnapshot.data()?['isAdmin'] ?? false;
    AppConfig().setAdmin(isAdmin);
  }

  Future<void> _getAndSaveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedToken = prefs.getString('fcmToken');
      final newToken = await _messaging.getToken();

      await checkUserRole(user.uid);

      if (newToken == null) {
        debugPrint('⚠️ No FCM token received.');
        return;
      }

      if (cachedToken != newToken) {
        debugPrint('🔄 Updating FCM token...');
        await _saveTokenIfNew(newToken);
        await prefs.setString('fcmToken', newToken);
      } else {
        debugPrint('✅ FCM token already cached and up-to-date.');
      }

      // Automatically handle token refresh events
      _messaging.onTokenRefresh.listen((refreshedToken) async {
        debugPrint('♻️ Token refreshed: $refreshedToken');
        await _saveTokenIfNew(refreshedToken);
        await prefs.setString('fcmToken', refreshedToken);
      });
    } catch (e) {
      debugPrint('❌ Error retrieving or saving FCM token: $e');
    }
  }

  /// Save the token in Firestore (for both admin & user)
  Future<void> _saveTokenIfNew(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ No logged-in user. Skipping token save.');
      return;
    }

    final isAdmin = AppConfig().isAdmin;
    debugPrint("isAdmin: $isAdmin");

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);
    final adminRef = firestore.collection('admin').doc('idforadminv1');

    try {
      // Always save token in the user doc
      await userRef.set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // If admin, also save token in admin doc
      if (isAdmin) {
        await adminRef.set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      debugPrint(
        '💾 Token saved successfully for ${isAdmin ? "admin & user" : "user"}: ${user.uid}',
      );
    } catch (e, st) {
      debugPrint('❌ Failed to save token: $e');
    }
  }

  /// Remove the token from both local storage & Firestore on logout
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedToken = prefs.getString('fcmToken');
    final user = FirebaseAuth.instance.currentUser;

    if (cachedToken == null) {
      debugPrint('⚠️ No cached FCM token found.');
      return;
    }

    if (user == null) {
      debugPrint('⚠️ No logged-in user. Cannot remove token.');
      return;
    }

    try {
      final isAdmin = AppConfig().isAdmin;
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final adminRef = FirebaseFirestore.instance
          .collection('admin')
          .doc('idforadminv1');

      await userRef.update({
        'fcmTokens': FieldValue.arrayRemove([cachedToken]),
      });

      if (isAdmin) {
        await adminRef.update({
          'fcmTokens': FieldValue.arrayRemove([cachedToken]),
        });
      }

      await prefs.remove('fcmToken');
      debugPrint('🧹 Token removed successfully for user: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error removing FCM token: $e');
    }
  }
}
