import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:isar/isar.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/firebase_options.dart';
import 'package:omeeowash/helpers/network_listener.dart';
import 'package:omeeowash/l10n/app_localizations.dart';
import 'package:omeeowash/models/message.dart';
import 'package:omeeowash/notifications/local_notification_service.dart';
import 'package:omeeowash/notifications/notification_service.dart';
import 'package:omeeowash/onboarding/onboarding_screen.dart';
import 'package:omeeowash/pages/home_screen_with_nav.dart';
import 'package:omeeowash/pages/profile/help_and_support/live_chat/app.config.dart';
import 'package:omeeowash/providers/locale_provider.dart';
import 'package:omeeowash/providers/top_nav_provider.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/providers/theme_provider.dart';
import 'package:omeeowash/services/chat_sync_service.dart';
import 'package:omeeowash/services/local_chat_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔔 Background handler — must be top-level
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService.show(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Initialize local notifications (for background display)
  await LocalNotificationService.initialize();

  // ✅ Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 🧠 Load user prefs
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('seen_onboarding') ?? false;
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  Widget startScreen;
  if (!hasSeenOnboarding) {
    startScreen = const OnboardingScreen();
  } else if (!isLoggedIn) {
    startScreen = const LoginScreen();
  } else {
    startScreen = const HomeScreenWithNav(view: 'home');
  }

  // 🗃️ Initialize local DB (Isar)
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
        Provider<LocalChatStore>(create: (ctx) => LocalChatStore(isar)),
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
  final Widget? startScreen;
  const MyApp({super.key, this.startScreen});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final notificationService = NotificationService();

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
      // With Firestore offline persistence, this will queue and sync later.
      debugPrint('❌ Failed to update online status: $e');
    }
  }

  void listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        toggleIsOnline(true);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        notificationService.initFCM();
      }
    });
    WidgetsBinding.instance.addObserver(this);
    listenToAuthChanges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      toggleIsOnline(true);
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
      builder: (context, child) =>
          NetworkListener(child: child ?? const SizedBox()),
      title: 'Omeeo Wash',
      locale: localeProvider.locale, // from Provider or state
      supportedLocales: const [
        Locale('en'), // English
        Locale('fr'), // French (example)
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      home: widget.startScreen,
    );
  }
}
