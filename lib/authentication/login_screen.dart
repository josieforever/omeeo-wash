import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    show FirebaseMessaging;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/authentication/forgot_password.dart';
import 'package:omeeowash/authentication/signup_screen.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/laundry_services.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const _brandGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required BuildContext context,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final focusColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 14,
        color: Color.fromARGB(255, 91, 91, 91),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color.fromARGB(255, 127, 127, 127),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        gapPadding: 10,
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: focusColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final userCredential = await FirebaseService().signInWithGoogle(context);

    if (!mounted) return;

    if (userCredential != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LaundryServicesScreen()),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google sign-in failed')));
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      await FirebaseService().signInWithEmailAndPassword(
        email: email,
        password: password,
        context: context,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful! 🎉'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LaundryServicesScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String displayMessage;

      switch (e.code) {
        case 'user-data-not-found':
          displayMessage =
              'Account not found. Please register or check your credentials.';
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          displayMessage = 'Invalid email or password.';
          break;
        case 'user-disabled':
          displayMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          displayMessage =
              'Too many failed login attempts. Please try again later.';
          break;
        default:
          displayMessage =
              'Login failed: ${e.message ?? 'An unknown error occurred.'}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                displayMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                'An unexpected error occurred: $e',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 360;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color.fromARGB(255, 244, 248, 255),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: _brandGradient)),
          Positioned.fill(
            child: Container(color: const Color.fromARGB(213, 255, 255, 255)),
          ),
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/background_animation_light.json',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: const Color.fromARGB(100, 255, 255, 255)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: 15,
                right: 15,
                top: isSmallScreen ? 24 : 48,
                bottom: mediaQuery.viewInsets.bottom + 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 16 : 20,
                          horizontal: isSmallScreen ? 8 : 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.color,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow,
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GradientText(
                              text: 'omeeo wash',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                              gradient: _brandGradient,
                            ),
                            const SizedBox(height: 10),
                            CustomText(
                              text: 'Sign in to your omeeo wash account',
                              textColor: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              textSize: 14,
                            ),
                            const SizedBox(height: 10),

                            ContinueSignInButton(
                              text: 'Continue with Google',
                              animation: 'assets/animations/google.json',
                              scale: 3,
                              onPressed: _handleGoogleSignIn,
                            ),

                            ContinueSignInButton(
                              text: 'Continue with Apple',
                              animation: 'assets/animations/apple.json',
                              scale: 1.5,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Apple sign-in not implemented yet',
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    thickness: 0.5,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('or'),
                                ),
                                Expanded(
                                  child: Divider(
                                    thickness: 0.5,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(context, 'Email'),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    cursorColor: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                    controller: _emailController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(
                                        r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      ).hasMatch(value)) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                    decoration: _fieldDecoration(
                                      context: context,
                                      hintText: 'Enter your email',
                                      prefixIcon: Icons.email_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _fieldLabel(context, 'Password'),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    cursorColor: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    decoration: _fieldDecoration(
                                      context: context,
                                      hintText: 'Enter your password',
                                      prefixIcon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color.fromARGB(
                                            255,
                                            127,
                                            127,
                                            127,
                                          ),
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GradientText(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ForgotPassword(),
                                      ),
                                    );
                                  },
                                  text: 'Forgot password?',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  gradient: _brandGradient,
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            _isLoading
                                ? LoadingButton(height: 50, width: 50, scale: 1)
                                : RegularButton(
                                    onPressed: _handleEmailLogin,
                                    borderRadius: 7,
                                    gradient: _brandGradient,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    textWidget: CustomText(
                                      text: 'Sign In',
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.headlineLarge?.color,
                                      textSize: 14,
                                      textWeight: FontWeight.bold,
                                    ),
                                  ),

                            const SizedBox(height: 30),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomText(
                                  text: "Don't have an account?",
                                  textColor: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  textSize: 14,
                                ),
                                const SizedBox(width: 5),
                                GradientText(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignupScreen(),
                                      ),
                                    );
                                  },
                                  text: 'Sign Up',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  gradient: _brandGradient,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                text: 'By signing in, you agree to our',
                                textColor: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                textSize: 11,
                              ),
                              const SizedBox(width: 5),
                              GradientText(
                                text: 'Terms of Service',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                gradient: _brandGradient,
                              ),
                              const SizedBox(width: 5),
                              CustomText(
                                text: 'and',
                                textColor: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                textSize: 11,
                              ),
                            ],
                          ),
                          GradientText(
                            text: 'Privacy Policy',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            gradient: _brandGradient,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FirebaseService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseMessaging fcm = FirebaseMessaging.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: const ['email']);

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _monthName(int month) => _months[month - 1];
  FieldValue _serverNow() => FieldValue.serverTimestamp();

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      firestore.collection('users').doc(uid);

  void _logError(String title, Object e, StackTrace st) {
    debugPrint('❌ $title: $e\n$st');
  }

  Future<bool> _hasInternet() async {
    final res = await Connectivity().checkConnectivity();
    return res != ConnectivityResult.none;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDocResolved(
    String uid,
  ) async {
    final ref = _userRef(uid);

    final online = await _hasInternet();
    if (!online) {
      return ref.get(const GetOptions(source: Source.cache));
    }

    try {
      return await ref
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      return ref.get(const GetOptions(source: Source.cache));
    }
  }

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, bool> _mergeFcmToken(
    Map<String, dynamic>? existing,
    String? token,
  ) {
    final updated = <String, bool>{};

    existing?.forEach((key, value) {
      updated[key] = value == true;
    });

    if (token != null && token.isNotEmpty) {
      updated[token] = true;
    }

    return updated;
  }

  Map<String, dynamic> _sanitizeUserMap(Map<String, dynamic> data) {
    final now = Timestamp.fromDate(DateTime.now());

    data['uid'] ??= '';
    data['accountType'] ??= 'customer';
    data['status'] ??= 'active';

    data['name'] ??= '';
    data['firstName'] ??= '';
    data['lastName'] ??= '';
    data['email'] ??= '';
    data['phoneNumber'] ??= '';
    data['photoUrl'] ??= '';

    data['defaultAddressId'] ??= null;
    data['defaultPaymentMethodId'] ??= null;
    data['savedAddresses'] ??= [];

    data['notificationSettings'] ??= {
      'push': true,
      'email': true,
      'bookingUpdates': true,
      'promoOffers': true,
    };

    data['settings'] ??= {
      'languageCode': 'en',
      'regionCode': 'GH',
      'darkMode': false,
    };

    data['stats'] ??= {
      'totalOrders': 0,
      'completedOrders': 0,
      'cancelledOrders': 0,
      'totalSpent': 0,
      'lastOrderAt': null,
      'memberSince': 'Apr 2026',
    };

    data['loyalty'] ??= {'points': 0, 'tier': 'standard'};

    data['currentBookingId'] ??= null;
    data['currentBookingStatus'] ??= null;

    data['fcmTokens'] ??= <String, bool>{};
    data['fcmUpdatedAt'] ??= now;

    data['isOnline'] ??= false;
    data['lastLoginAt'] ??= now;
    data['lastSeen'] ??= now;

    data['createdAt'] ??= now;
    data['updatedAt'] ??= now;

    return data;
  }

  Future<void> _saveLoggedInFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
  }

  Future<void> _loadUserIntoProvider(BuildContext context, String uid) async {
    final doc = await _getUserDocResolved(uid);
    final data = doc.data();
    if (data == null) {
      throw Exception('User document has no data for uid=$uid');
    }

    final safe = _sanitizeUserMap(data);
    final userModel = UserModel.fromMap(safe);

    if (context.mounted) {
      await context.read<UserProvider>().setUser(userModel);
    }
  }

  Future<void> _ensureUserProfile({
    required User user,
    required String? fcmToken,
  }) async {
    final ref = _userRef(user.uid);
    final snapshot = await ref.get();

    final existing = snapshot.data() ?? {};
    final now = DateTime.now();
    final memberSince = '${_monthName(now.month)} ${now.year}';

    final existingTokens = _readMap(existing['fcmTokens']);
    final updatedTokens = _mergeFcmToken(existingTokens, fcmToken);

    final update = <String, dynamic>{
      'uid': user.uid,
      'accountType': existing['accountType'] ?? 'customer',
      'status': existing['status'] ?? 'active',

      'name':
          existing['name'] ??
          user.displayName ??
          user.email?.split('@').first ??
          '',
      'firstName': existing['firstName'] ?? '',
      'lastName': existing['lastName'] ?? '',
      'email': existing['email'] ?? user.email ?? '',
      'phoneNumber': existing['phoneNumber'] ?? user.phoneNumber ?? '',
      'photoUrl': existing['photoUrl'] ?? user.photoURL ?? '',

      'defaultAddressId': existing['defaultAddressId'],
      'defaultPaymentMethodId': existing['defaultPaymentMethodId'],
      'savedAddresses': existing['savedAddresses'] ?? [],

      'notificationSettings': {
        'push': true,
        'email': true,
        'bookingUpdates': true,
        'promoOffers': true,
        ..._readMap(existing['notificationSettings']),
      },

      'settings': {
        'languageCode': 'en',
        'regionCode': 'GH',
        'darkMode': false,
        ..._readMap(existing['settings']),
      },

      'stats': {
        'totalOrders': 0,
        'completedOrders': 0,
        'cancelledOrders': 0,
        'totalSpent': 0,
        'lastOrderAt': null,
        'memberSince': memberSince,
        ..._readMap(existing['stats']),
      },

      'loyalty': {
        'points': 0,
        'tier': 'standard',
        ..._readMap(existing['loyalty']),
      },

      'currentBookingId': existing['currentBookingId'],
      'currentBookingStatus': existing['currentBookingStatus'],

      'fcmTokens': updatedTokens,
      'fcmUpdatedAt': _serverNow(),

      'isOnline': true,
      'lastLoginAt': _serverNow(),
      'lastSeen': _serverNow(),
      'updatedAt': _serverNow(),
    };

    if (!snapshot.exists) {
      update['createdAt'] = _serverNow();
    }

    await ref.set(update, SetOptions(merge: true));
  }

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        try {
          await googleSignIn.signOut();
        } catch (_) {}
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        try {
          await googleSignIn.signOut();
        } catch (_) {}
        return null;
      }

      final fcmToken = await fcm.getToken();
      await _ensureUserProfile(user: user, fcmToken: fcmToken);
      await _loadUserIntoProvider(context, user.uid);
      await _saveLoggedInFlag();

      return userCredential;
    } catch (e, st) {
      _logError('Google Sign-In Error', e, st);

      try {
        await auth.signOut();
      } catch (_) {}
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      return null;
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'invalid-user',
          message: 'Login failed: user is null.',
        );
      }

      final uid = user.uid;
      final docSnapshot = await _userRef(
        uid,
      ).get().timeout(const Duration(seconds: 8));

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        await auth.signOut();
        throw FirebaseAuthException(
          code: 'user-data-not-found',
          message: 'User profile not found. Please register before logging in.',
        );
      }

      final existingData = docSnapshot.data()!;
      final existingTokens = _readMap(existingData['fcmTokens']);
      final fcmToken = await fcm.getToken();
      final updatedTokens = _mergeFcmToken(existingTokens, fcmToken);

      final updateMap = <String, dynamic>{
        'isOnline': true,
        'updatedAt': _serverNow(),
        'lastLoginAt': _serverNow(),
        'lastSeen': _serverNow(),
        'fcmTokens': updatedTokens,
        'fcmUpdatedAt': _serverNow(),
      };

      await _userRef(uid).set(updateMap, SetOptions(merge: true));
      await _ensureUserProfile(user: user, fcmToken: fcmToken);

      await _loadUserIntoProvider(context, uid);
      await _saveLoggedInFlag();
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> toggleIsOnline(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _userRef(user.uid).set({
        'isOnline': value,
        'updatedAt': _serverNow(),
        'lastSeen': _serverNow(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Failed to update online status: $e');
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await toggleIsOnline(false);

      final wasGoogleSignedIn = await googleSignIn.isSignedIn();
      if (wasGoogleSignedIn) {
        await googleSignIn.signOut();
      }

      await auth.signOut();

      if (context.mounted) {
        await context.read<UserProvider>().clearCache();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
