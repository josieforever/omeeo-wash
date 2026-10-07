import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/profile/help/live_chat/app.config.dart';

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
      print('✅ User granted notification permission');
      await _getAndSaveToken();
    } else {
      print('🚫 Notification permission denied or not accepted');
    }

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Only show notification if user is NOT on chat screen, for example
      print('📩 Foreground message received: ${message.notification?.title}');
      // You can integrate local notifications here (if you want)
    });

    // Handle when user taps a notification to open the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification clicked!');
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
        print('⚠️ No FCM token received.');
        return;
      }

      if (cachedToken != newToken) {
        print('🔄 Updating FCM token...');
        await _saveTokenIfNew(newToken);
        await prefs.setString('fcmToken', newToken);
      } else {
        print('✅ FCM token already cached and up-to-date.');
      }

      // Automatically handle token refresh events
      _messaging.onTokenRefresh.listen((refreshedToken) async {
        print('♻️ Token refreshed: $refreshedToken');
        await _saveTokenIfNew(refreshedToken);
        await prefs.setString('fcmToken', refreshedToken);
      });
    } catch (e) {
      print('❌ Error retrieving or saving FCM token: $e');
    }
  }

  /// Save the token in Firestore (for both admin & user)
  Future<void> _saveTokenIfNew(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ No logged-in user. Skipping token save.');
      return;
    }

    final isAdmin = AppConfig().isAdmin;
    print("isAdmin:''''''''''''''''''''''''''''''''''  $isAdmin");
    final ref = isAdmin
        ? FirebaseFirestore.instance.collection('admin').doc('idforadminv1')
        : FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snap = await ref.get();
    final existing = (snap.data()?['fcmTokens'] as List?)?.cast<String>() ?? [];

    if (existing.contains(token)) {
      print('✅ Token already exists in Firestore.');
      return;
    }

    await ref.set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('💾 Token saved successfully in Firestore for user: ${user.uid}');
  }

  /// Remove the token from both local storage & Firestore on logout
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedToken = prefs.getString('fcmToken');
    final user = FirebaseAuth.instance.currentUser;

    if (cachedToken == null) {
      print('⚠️ No cached FCM token found.');
      return;
    }

    if (user == null) {
      print('⚠️ No logged-in user. Cannot remove token.');
      return;
    }

    try {
      final isAdmin = AppConfig().isAdmin;
      final ref = isAdmin
          ? FirebaseFirestore.instance.collection('admin').doc('idforadminv1')
          : FirebaseFirestore.instance.collection('users').doc(user.uid);

      await ref.update({
        'fcmTokens': FieldValue.arrayRemove([cachedToken]),
      });

      await prefs.remove('fcmToken');
      print('🧹 Token removed successfully for user: ${user.uid}');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }
}
