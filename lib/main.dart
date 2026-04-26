import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geocoding/geocoding.dart' show placemarkFromCoordinates;
import 'package:geolocator/geolocator.dart';
import 'package:isar/isar.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/helpers/network_listener.dart';
import 'package:omeeowash/l10n/app_localizations.dart';
import 'package:omeeowash/models/message.dart';
import 'package:omeeowash/notifications/local_notification_service.dart';
import 'package:omeeowash/notifications/notification_service.dart';
import 'package:omeeowash/onboarding/onboarding_screen.dart';
import 'package:omeeowash/pages/bookings/booking flow/laundry_services/laundry_services.dart';
import 'package:omeeowash/providers/locale_provider.dart';
import 'package:omeeowash/providers/theme_provider.dart';
import 'package:omeeowash/providers/top_nav_provider.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/services/chat_sync_service.dart';
import 'package:omeeowash/services/local_chat_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _ensureFirebaseInitialized() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      debugPrint('ℹ️ Firebase already initialized');
      return;
    }

    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized (native config)');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('ℹ️ Duplicate Firebase app ignored');
      return;
    }
    rethrow;
  }
}

Future<void> _activateAppCheckSafely() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.appAttest,
    );

    debugPrint('✅ Firebase App Check activated');
  } catch (e) {
    debugPrint('⚠️ Firebase App Check activation skipped: $e');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _ensureFirebaseInitialized();
  await LocalNotificationService.show(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _ensureFirebaseInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await _activateAppCheckSafely();

  await LocalNotificationService.initialize();

  final prefs = await SharedPreferences.getInstance();

  final hasSeenOnboarding = prefs.getBool('seen_onboarding') ?? false;
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  final Widget startScreen;

  if (!hasSeenOnboarding) {
    startScreen = const OnboardingScreen();
  } else if (!isLoggedIn) {
    startScreen = const LoginScreen();
  } else {
    startScreen = const LaundryServicesScreen();
  }

  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open([MessageSchema], directory: dir.path);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TopNavProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        Provider<Isar>.value(value: isar),
        Provider<LocalChatStore>(create: (_) => LocalChatStore(isar)),
        Provider<ChatSyncService>(
          create: (ctx) => ChatSyncService(
            FirebaseFirestore.instance,
            ctx.read<LocalChatStore>(),
          ),
        ),
      ],
      child: MyApp(startScreen: startScreen),
    ),
  );
}

class MyApp extends StatefulWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final NotificationService notificationService = NotificationService();

  Stream<User?>? _authStream;

  bool _isUpdatingLocation = false;

  Future<void> toggleIsOnline(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isOnline': value,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ User online status updated: $value');
    } catch (e) {
      debugPrint('❌ Failed to update online status: $e');
    }
  }

  Future<void> _updateUserLocationIfStale(String uid) async {
    if (_isUpdatingLocation) return;

    _isUpdatingLocation = true;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final userDoc = await userRef.get();

      final data = userDoc.data() ?? <String, dynamic>{};
      final lastLocation = data['lastCurrentLocation'];

      DateTime? updatedAt;

      if (lastLocation is Map) {
        final map = Map<String, dynamic>.from(lastLocation);
        final rawUpdatedAt = map['updatedAt'];

        if (rawUpdatedAt is Timestamp) {
          updatedAt = rawUpdatedAt.toDate();
        }
      }

      if (updatedAt != null) {
        final age = DateTime.now().difference(updatedAt);
        if (age.inMinutes < 15) {
          debugPrint('ℹ️ User location still fresh. Skipping update.');
          return;
        }
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied.');
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint('⚠️ Location service is disabled.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String addressLine = '';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          addressLine =
              [
                    place.street,
                    place.subLocality,
                    place.locality,
                    place.administrativeArea,
                    place.country,
                  ]
                  .where((value) => value != null && value.trim().isNotEmpty)
                  .map((value) => value!.trim())
                  .join(', ');
        }
      } catch (e) {
        debugPrint('⚠️ Reverse geocoding failed: $e');
      }

      await userRef.set({
        'lastCurrentLocation': {
          'addressLine': addressLine,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'geopoint': GeoPoint(position.latitude, position.longitude),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      debugPrint('✅ User location updated with address: $addressLine');
    } catch (e) {
      debugPrint('⚠️ User location update skipped: $e');
    } finally {
      _isUpdatingLocation = false;
    }
  }

  void _handleLoggedInUser(User user) {
    toggleIsOnline(true);
    notificationService.initFCM();
    _updateUserLocationIfStale(user.uid);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _authStream = FirebaseAuth.instance.authStateChanges();

    _authStream?.listen((User? user) {
      if (user != null) {
        _handleLoggedInUser(user);
      }
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Future.microtask(() => _handleLoggedInUser(currentUser));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;

    if (state == AppLifecycleState.resumed) {
      toggleIsOnline(true);

      if (user != null) {
        _updateUserLocationIfStale(user.uid);
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      toggleIsOnline(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Omeeo Wash',
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        final clampedTextScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.2,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedTextScaler),
          child: NetworkListener(child: child ?? const SizedBox()),
        );
      },
      home: widget.startScreen,
    );
  }
}
