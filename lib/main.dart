import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:geocoding/geocoding.dart'
    show Placemark, placemarkFromCoordinates;
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
    debugPrint('✅ Firebase initialized');
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

class _CurrentLocationBootstrap {
  _CurrentLocationBootstrap._();

  static bool _isRunning = false;

  static const Duration _resumeFreshness = Duration(minutes: 15);
  static const Duration _freshLocationTimeout = Duration(seconds: 10);
  static const Duration _firestoreWriteWait = Duration(seconds: 2);

  /// Called on every full/cold app launch.
  ///
  /// The order is:
  /// 1. Load the previously saved location as a fallback.
  /// 2. Try to obtain a NEW device location.
  /// 3. If that succeeds, save it to Firestore + local storage.
  /// 4. If anything prevents that, restore/use the last saved location.
  /// 5. Only after this method finishes does LaundryServicesScreen load.
  static Future<void> refreshOnColdLaunch(String uid) async {
    await _refresh(uid: uid, forceFreshGps: true);
  }

  /// Called when the existing app process resumes from the background.
  ///
  /// We keep the 15-minute freshness rule here so the GPS is not unnecessarily
  /// started every time the user briefly leaves and returns to the app.
  static Future<void> refreshOnResume(String uid) async {
    await _refresh(uid: uid, forceFreshGps: false);
  }

  static Future<void> _refresh({
    required String uid,
    required bool forceFreshGps,
  }) async {
    if (_isRunning) {
      debugPrint('ℹ️ Location refresh already running.');
      return;
    }

    _isRunning = true;

    try {
      final fallback = await _loadLastSavedLocation(uid);

      if (!forceFreshGps &&
          fallback != null &&
          fallback.updatedAt != null &&
          DateTime.now().difference(fallback.updatedAt!) < _resumeFreshness) {
        debugPrint(
          'ℹ️ Existing location is still fresh. '
          'Using saved location without starting GPS.',
        );

        await _makeLocationAvailableToLaundryScreen(
          uid: uid,
          location: fallback,
        );

        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await _useFallback(
          uid: uid,
          fallback: fallback,
          reason: 'Device location service is disabled.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _useFallback(
          uid: uid,
          fallback: fallback,
          reason: 'Location permission is unavailable.',
        );
        return;
      }

      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: _freshLocationTimeout,
          ),
        );

        debugPrint(
          '✅ Fresh location obtained: '
          '${position.latitude}, ${position.longitude}',
        );
      } catch (e) {
        debugPrint('⚠️ Could not obtain a fresh location: $e');
      }

      if (position == null) {
        await _useFallback(
          uid: uid,
          fallback: fallback,
          reason: 'A fresh GPS/network location could not be obtained.',
        );
        return;
      }

      final resolved = await _reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      /// If coordinates were obtained but reverse-geocoding failed (for
      /// example because internet is unavailable), prefer the previously saved
      /// complete location so the Laundry Services screen still has a useful
      /// address to display.
      if (resolved.addressLine.isEmpty && fallback != null) {
        await _useFallback(
          uid: uid,
          fallback: fallback,
          reason:
              'Current coordinates were found, but the current address '
              'could not be resolved.',
        );
        return;
      }

      final addressLine = resolved.addressLine.isNotEmpty
          ? resolved.addressLine
          : '${position.latitude.toStringAsFixed(6)}, '
                '${position.longitude.toStringAsFixed(6)}';

      final currentLocation = _SavedStartupLocation(
        addressLine: addressLine,
        placeName: resolved.placeName,
        locality: resolved.locality,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        updatedAt: DateTime.now(),
      );

      /// Save locally FIRST. This gives us a reliable fallback even if the
      /// Firestore network write cannot be acknowledged right now.
      await _saveLocationLocally(uid: uid, location: currentLocation);

      await _writeLocationToFirestore(
        uid: uid,
        location: currentLocation,
        source: 'device',
      );

      debugPrint('✅ Current location prepared before LaundryServicesScreen.');
    } catch (e, stackTrace) {
      debugPrint('❌ Location bootstrap failed unexpectedly: $e');
      debugPrint('$stackTrace');

      /// One final fallback attempt in case an unexpected exception occurred.
      try {
        final fallback = await _loadLastSavedLocation(uid);

        if (fallback != null) {
          await _makeLocationAvailableToLaundryScreen(
            uid: uid,
            location: fallback,
          );

          debugPrint('✅ Recovered using last saved location.');
        }
      } catch (fallbackError) {
        debugPrint('⚠️ Final fallback also failed: $fallbackError');
      }
    } finally {
      _isRunning = false;
    }
  }

  static Future<void> _useFallback({
    required String uid,
    required _SavedStartupLocation? fallback,
    required String reason,
  }) async {
    debugPrint('⚠️ $reason');

    if (fallback == null) {
      debugPrint(
        '⚠️ There is no previously saved location available to fall back to.',
      );
      return;
    }

    await _makeLocationAvailableToLaundryScreen(uid: uid, location: fallback);

    debugPrint(
      '✅ Falling back to last saved location: '
      '${fallback.addressLine}',
    );
  }

  /// Reads the most recent usable location.
  ///
  /// We keep a small SharedPreferences copy in addition to Firestore. This is
  /// useful when the phone has no internet and Firestore does not yet have a
  /// readable cached document during startup.
  static Future<_SavedStartupLocation?> _loadLastSavedLocation(
    String uid,
  ) async {
    final local = await _loadLocationLocally(uid);

    _SavedStartupLocation? firestoreLocation;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    /// Try Firestore's local cache first so this does not wait for the network.
    try {
      final cachedDoc = await userRef.get(
        const GetOptions(source: Source.cache),
      );

      firestoreLocation = _SavedStartupLocation.fromFirestoreMap(
        cachedDoc.data()?['lastCurrentLocation'],
      );
    } catch (e) {
      debugPrint('ℹ️ No usable Firestore location cache: $e');
    }

    /// If the Firestore cache did not contain it, make a normal read attempt.
    if (firestoreLocation == null) {
      try {
        final doc = await userRef.get();

        firestoreLocation = _SavedStartupLocation.fromFirestoreMap(
          doc.data()?['lastCurrentLocation'],
        );
      } catch (e) {
        debugPrint('ℹ️ Could not read lastCurrentLocation from Firestore: $e');
      }
    }

    final selected = _newerLocation(local, firestoreLocation);

    if (selected != null) {
      /// Keep SharedPreferences synchronized with whichever fallback is newer.
      await _saveLocationLocally(uid: uid, location: selected);
    }

    return selected;
  }

  static _SavedStartupLocation? _newerLocation(
    _SavedStartupLocation? first,
    _SavedStartupLocation? second,
  ) {
    if (first == null) return second;
    if (second == null) return first;

    final firstDate = first.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final secondDate =
        second.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    return secondDate.isAfter(firstDate) ? second : first;
  }

  /// Ensures LaundryServicesScreen can read the fallback from the exact same
  /// Firestore field it already listens to.
  ///
  /// Firestore writes update its local cache immediately. If the phone is
  /// offline, the remote write can remain queued while the next screen still
  /// reads the local value.
  static Future<void> _makeLocationAvailableToLaundryScreen({
    required String uid,
    required _SavedStartupLocation location,
  }) async {
    await _saveLocationLocally(uid: uid, location: location);

    await _writeLocationToFirestore(
      uid: uid,
      location: location,
      source: 'fallback',
      preserveSavedTime: true,
    );
  }

  static Future<void> _writeLocationToFirestore({
    required String uid,
    required _SavedStartupLocation location,
    required String source,
    bool preserveSavedTime = false,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final writeFuture = userRef.set({
      'lastCurrentLocation': {
        'addressLine': location.addressLine,
        'name': location.placeName,
        'placeName': location.placeName,
        'locality': location.locality,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'geopoint': GeoPoint(location.latitude, location.longitude),
        if (location.accuracyMeters != null)
          'accuracyMeters': location.accuracyMeters,
        'source': source,

        /// Do not make an old fallback look like a newly captured GPS fix.
        'updatedAt': preserveSavedTime && location.updatedAt != null
            ? Timestamp.fromDate(location.updatedAt!)
            : FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    try {
      await writeFuture.timeout(_firestoreWriteWait);
    } on TimeoutException {
      /// The local Firestore mutation has already been queued. Do not delay
      /// navigation just because the remote server cannot acknowledge it yet.
      debugPrint('ℹ️ Firestore location write is queued; continuing startup.');
    } catch (e) {
      debugPrint('⚠️ Firestore location write failed: $e');
    }
  }

  static Future<void> _saveLocationLocally({
    required String uid,
    required _SavedStartupLocation location,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'last_current_location_$uid';

    await Future.wait([
      prefs.setString('${prefix}_addressLine', location.addressLine),
      prefs.setString('${prefix}_placeName', location.placeName),
      prefs.setString('${prefix}_locality', location.locality),
      prefs.setDouble('${prefix}_latitude', location.latitude),
      prefs.setDouble('${prefix}_longitude', location.longitude),
      if (location.accuracyMeters != null)
        prefs.setDouble('${prefix}_accuracyMeters', location.accuracyMeters!),
      prefs.setInt(
        '${prefix}_updatedAtMs',
        (location.updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
      ),
    ]);
  }

  static Future<_SavedStartupLocation?> _loadLocationLocally(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'last_current_location_$uid';

    final latitude = prefs.getDouble('${prefix}_latitude');
    final longitude = prefs.getDouble('${prefix}_longitude');

    if (latitude == null || longitude == null) {
      return null;
    }

    final updatedAtMs = prefs.getInt('${prefix}_updatedAtMs');

    return _SavedStartupLocation(
      addressLine: prefs.getString('${prefix}_addressLine') ?? '',
      placeName: prefs.getString('${prefix}_placeName') ?? '',
      locality: prefs.getString('${prefix}_locality') ?? '',
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: prefs.getDouble('${prefix}_accuracyMeters'),
      updatedAt: updatedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
    );
  }

  static Future<_ResolvedLocationAddress> _reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isEmpty) {
        return const _ResolvedLocationAddress();
      }

      return _ResolvedLocationAddress.fromPlacemark(placemarks.first);
    } catch (e) {
      debugPrint('⚠️ Reverse geocoding failed: $e');
      return const _ResolvedLocationAddress();
    }
  }
}

class _SavedStartupLocation {
  final String addressLine;
  final String placeName;
  final String locality;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime? updatedAt;

  const _SavedStartupLocation({
    required this.addressLine,
    required this.placeName,
    required this.locality,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.updatedAt,
  });

  factory _SavedStartupLocation.fromFirestoreMap(dynamic raw) {
    if (raw is! Map) {
      throw const FormatException('Location is not a map.');
    }

    final map = Map<String, dynamic>.from(raw);

    final latitude = _readDouble(map['latitude'] ?? map['lat']);

    final longitude = _readDouble(map['longitude'] ?? map['lng'] ?? map['lon']);

    if (latitude == null || longitude == null) {
      final geopoint = map['geopoint'];

      if (geopoint is GeoPoint) {
        return _SavedStartupLocation(
          addressLine: _readString(map['addressLine']),
          placeName: _firstNonEmpty([
            _readString(map['placeName']),
            _readString(map['name']),
            _readString(map['title']),
          ]),
          locality: _readString(map['locality']),
          latitude: geopoint.latitude,
          longitude: geopoint.longitude,
          accuracyMeters: _readDouble(map['accuracyMeters']),
          updatedAt: _readDate(map['updatedAt']),
        );
      }

      throw const FormatException('Saved location has no coordinates.');
    }

    return _SavedStartupLocation(
      addressLine: _readString(map['addressLine']),
      placeName: _firstNonEmpty([
        _readString(map['placeName']),
        _readString(map['name']),
        _readString(map['title']),
      ]),
      locality: _readString(map['locality']),
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: _readDouble(map['accuracyMeters']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class _ResolvedLocationAddress {
  final String addressLine;
  final String placeName;
  final String locality;

  const _ResolvedLocationAddress({
    this.addressLine = '',
    this.placeName = '',
    this.locality = '',
  });

  factory _ResolvedLocationAddress.fromPlacemark(Placemark place) {
    String clean(String? value) => value?.trim() ?? '';

    final parts = <String>[
      clean(place.street),
      clean(place.subLocality),
      clean(place.locality),
      clean(place.administrativeArea),
      clean(place.country),
    ];

    final addressParts = <String>[];

    for (final part in parts) {
      if (part.isEmpty) continue;

      final alreadyExists = addressParts.any(
        (existing) => existing.toLowerCase() == part.toLowerCase(),
      );

      if (!alreadyExists) {
        addressParts.add(part);
      }
    }

    final candidates = <String>[
      clean(place.name),
      clean(place.street),
      clean(place.subLocality),
      clean(place.locality),
    ];

    String placeName = '';

    for (final candidate in candidates) {
      if (candidate.isNotEmpty) {
        placeName = candidate;
        break;
      }
    }

    return _ResolvedLocationAddress(
      addressLine: addressParts.join(', '),
      placeName: placeName,
      locality: clean(place.locality),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the background callback immediately. This call itself does not
  // need to hold the first Flutter frame.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // IMPORTANT:
  // Do not await Firebase, App Check, notifications, Isar, preferences,
  // location or any other service before runApp().
  //
  // Anything awaited here keeps Android/iOS on the native splash screen.
  runApp(const _LundriBootstrapApp());
}

class _LundriBootstrapApp extends StatefulWidget {
  const _LundriBootstrapApp();

  @override
  State<_LundriBootstrapApp> createState() => _LundriBootstrapAppState();
}

class _LundriBootstrapAppState extends State<_LundriBootstrapApp> {
  bool _isReady = false;
  bool _hasSeenOnboarding = false;

  Isar? _isar;

  @override
  void initState() {
    super.initState();
    _initializeFlutterServices();
  }

  Future<void> _initializeFlutterServices() async {
    try {
      // The Lundri Flutter splash is already visible now.
      //
      // Start non-Firebase work in parallel while Firebase Core initializes.
      final prefsFuture = SharedPreferences.getInstance();
      final directoryFuture = getApplicationDocumentsDirectory();

      await _ensureFirebaseInitialized();

      // System UI does not need to block startup.
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      );

      // App Check needs Firebase Core. Notifications can initialize alongside it.
      final appCheckFuture = _activateAppCheckSafely();
      final notificationFuture = LocalNotificationService.initialize();

      final prefs = await prefsFuture;
      final dir = await directoryFuture;

      final hasSeenOnboarding = prefs.getBool('seen_onboarding') ?? false;

      // Isar can open while App Check / notifications finish.
      final isarFuture = Isar.open([MessageSchema], directory: dir.path);

      final results = await Future.wait<dynamic>([
        appCheckFuture,
        notificationFuture,
        isarFuture,
      ]);

      final isar = results[2] as Isar;

      if (!mounted) {
        await isar.close();
        return;
      }

      setState(() {
        _hasSeenOnboarding = hasSeenOnboarding;
        _isar = isar;
        _isReady = true;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ App bootstrap failed: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _isReady = false;
      });
    }
  }

  @override
  void dispose() {
    // The app normally lives for the life of the process, so Isar remains open.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isar = _isar;

    if (!_isReady || isar == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _LundriStartupSplash(),
      );
    }

    return MultiProvider(
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
      child: MyApp(hasSeenOnboarding: _hasSeenOnboarding),
    );
  }
}

class _LundriStartupSplash extends StatefulWidget {
  const _LundriStartupSplash();

  @override
  State<_LundriStartupSplash> createState() => _LundriStartupSplashState();
}

class _LundriStartupSplashState extends State<_LundriStartupSplash>
    with SingleTickerProviderStateMixin {
  static const Color _background = Color(0xFFFFF7F0);
  static const Color _orange = Color(0xFFE67E22);
  static const Color _black = Color(0xFF111111);

  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _ambientScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _logoScale = Tween<double>(begin: 0.97, end: 1.02).animate(curve);

    _logoOpacity = Tween<double>(begin: 0.90, end: 1.0).animate(curve);

    _ambientScale = Tween<double>(begin: 0.94, end: 1.07).animate(curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -115,
            top: -125,
            child: ScaleTransition(
              scale: _ambientScale,
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _orange.withOpacity(0.12),
                ),
              ),
            ),
          ),
          Positioned(
            right: -95,
            bottom: -120,
            child: ScaleTransition(
              scale: _ambientScale,
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _black.withOpacity(0.045),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: SizedBox(
                          width: 190,
                          height: 140,
                          child: Image.asset(
                            'assets/images/lundri_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Fresh laundry, one tap away.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _black,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 118,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Color(0xFFFFE2CC),
                          valueColor: AlwaysStoppedAnimation<Color>(_orange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Getting things ready...',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final bool hasSeenOnboarding;

  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final NotificationService notificationService = NotificationService();

  StreamSubscription<User?>? _authSubscription;
  String? _initializedFcmForUid;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (user == null) {
        _initializedFcmForUid = null;
        return;
      }

      unawaited(_setOnlineStatus(user.uid, true));

      if (_initializedFcmForUid != user.uid) {
        _initializedFcmForUid = user.uid;
        unawaited(notificationService.initFCM());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setOnlineStatus(String uid, bool value) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'isOnline': value,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ User online status updated: $value');
    } catch (e) {
      debugPrint('⚠️ Online status update failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_setOnlineStatus(user.uid, true));
        unawaited(_CurrentLocationBootstrap.refreshOnResume(user.uid));
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_setOnlineStatus(user.uid, false));
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Lundri',
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
      home: widget.hasSeenOnboarding
          ? const _StartupGate()
          : const OnboardingScreen(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  Widget? _destination;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      try {
        user = await FirebaseAuth.instance.authStateChanges().first.timeout(
          const Duration(seconds: 5),
        );
      } catch (_) {
        user = FirebaseAuth.instance.currentUser;
      }
    }

    if (!mounted) return;

    if (user == null) {
      setState(() {
        _destination = const LoginScreen();
      });
      return;
    }

    await _CurrentLocationBootstrap.refreshOnColdLaunch(user.uid);

    if (!mounted) return;

    setState(() {
      _destination = const LaundryServicesScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destination;

    if (destination != null) {
      return destination;
    }

    return const _LundriStartupSplash();
  }
}
