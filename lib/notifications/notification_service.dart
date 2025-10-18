import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  Future<void> _getAndSaveToken() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) return;

      try {
        final prefs = await SharedPreferences.getInstance();
        String? cachedToken = prefs.getString('fcmToken');
        final newToken = await _messaging.getToken();

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
    });
  }

  /// Save the token in Firestore (for both admin & user)
  Future<void> _saveTokenIfNew(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('⚠️ No logged-in user. Skipping token save.');
      return;
    }

    final isAdmin = AppConfig().isAdmin;

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

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../pages/profile/help_and_support/live_chat/app.config.dart';

// class NotificationService {
//   Future<void> requestNotificationPermission() async {
//     final NotificationSettings notificationSettings = await FirebaseMessaging
//         .instance
//         .requestPermission(provisional: true, sound: true);
//     if (notificationSettings.authorizationStatus ==
//         AuthorizationStatus.authorized) {
//       print('User granted permission 👏');
//       _getTokenAndSave();
//     } else {
//       print('User declined or has not accepted permission');
//     }
//   }

//   Future<void> _getTokenAndSave() async {
//     FirebaseAuth.instance.authStateChanges().listen((User? user) async {
//       if (user != null) {
//         try {
//           final prefs = await SharedPreferences.getInstance();
//           final cachedToken = prefs.getString('fcmToken');
//           print('PREF DATA: $cachedToken');
//           if (cachedToken != null) return;
//           String? token = await FirebaseMessaging.instance.getToken();
//           print("FCM Token: $token");
//           if (token != null) {
//             await _saveTokenIfNew(token);
//             FirebaseMessaging.instance.onTokenRefresh.listen((
//               refreshedToken,
//             ) async {
//               await _saveTokenIfNew(refreshedToken);
//             });
//             await prefs.setString('fcmToken', token);
//           }
//         } catch (e) {
//           print('Error getting FCM token: $e');
//         }
//       } else {}
//     });
//   }

//   // Save the FCM token in Firestore
//   Future<void> _saveTokenIfNew(String token) async {
//     bool isAdmin = AppConfig().isAdmin;
//     User? user = FirebaseAuth.instance.currentUser;

//     if (user != null) {
//       final ref = isAdmin
//           ? FirebaseFirestore.instance.collection('admin').doc("idforadminv1")
//           : FirebaseFirestore.instance.collection('users').doc(user.uid);

//       // Read once to avoid a no-op write if already present
//       final snap = await ref.get();
//       final existing =
//           (snap.data()?['fcmTokens'] as List?)?.cast<String>() ?? const [];
//       if (existing.contains(token)) return; // already saved, do nothing

//       await ref.set({
//         'fcmTokens': FieldValue.arrayUnion([token]), // de-dupes server-side
//         'fcmUpdatedAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//       print('Notification Enabled');
//     } else {
//       print('User not logged in');
//     }
//   }

//   //FUNCTIONS FOR LOGOUT
//   Future<void> removeToken() async {
//   final prefs = await SharedPreferences.getInstance();
//   final cachedToken = prefs.getString('fcmToken');
//   if (cachedToken == null) {
//     print('No cached FCM token found.');
//     return;
//   }

//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) {
//     print('No logged-in user. Cannot remove token.');
//     return;
//   }

//   try {
//     final isAdmin = AppConfig().isAdmin;

//     final ref = isAdmin
//         ? FirebaseFirestore.instance.collection('admin').doc("idforadminv1")
//         : FirebaseFirestore.instance.collection('users').doc(user.uid);

//     // Remove token from Firestore array
//     await ref.update({
//       'fcmTokens': FieldValue.arrayRemove([cachedToken]),
//     });

//     // Remove cached token locally
//     await prefs.remove('fcmToken');

//     print('✅ FCM token removed successfully for user: ${user.uid}');
//   } catch (e) {
//     print('⚠️ Error removing FCM token: $e');
//   }
// }

// }
