import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ ADD: connectivity_plus in pubspec.yaml: connectivity_plus: ^6.0.0
import 'package:connectivity_plus/connectivity_plus.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 248, 255),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              color: const Color.fromARGB(213, 255, 255, 255),
            ),
          ),
          Positioned.fill(
            child: Lottie.asset(
              'assets/animations/background_animation_light.json',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              color: const Color.fromARGB(100, 255, 255, 255),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 15,
                right: 15,
                top: 70,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).textTheme.headlineLarge?.color,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.shadow,
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 10,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GradientText(
                            text: 'omeeo wash',
                            style: TextStyle(
                              fontSize: TextSizes.heading1,
                              fontWeight: FontWeight.w900,
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
                            ),
                          ),
                          const SizedBox(height: 10),
                          CustomText(
                            text: 'Sign in to your omeeo wash account',
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            textSize: TextSizes.bodyText1,
                          ),
                          const SizedBox(height: 10),

                          // GOOGLE SIGN IN
                          ContinueSignInButton(
                            text: 'Continue with Google',
                            animation: 'assets/animations/google.json',
                            scale: 3,
                            onPressed: () async {
                              setState(() => _isLoading = true);

                              final userCredential = await FirebaseService()
                                  .signInWithGoogle(context);

                              if (!mounted) return;

                              if (userCredential != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LaundryServicesScreen(),
                                  ),
                                );
                              } else {
                                setState(() => _isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Google sign-in failed"),
                                  ),
                                );
                              }
                            },
                          ),

                          ContinueSignInButton(
                            text: 'Continue with Apple',
                            animation: 'assets/animations/apple.json',
                            scale: 1.5,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Apple sign-in not implemented yet",
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
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text("or"),
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

                          // EMAIL/PASSWORD FORM
                          Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Email",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  cursorColor: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  controller: _emailController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    } else if (!RegExp(
                                      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                      horizontal: 0,
                                    ),
                                    hintText: 'Enter your email',
                                    hintStyle: TextStyle(
                                      fontSize: TextSizes.bodyText1,
                                      color: const Color.fromARGB(
                                        255,
                                        91,
                                        91,
                                        91,
                                      ),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color.fromARGB(255, 127, 127, 127),
                                      size: IconSizes.midSmall,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      gapPadding: 10,
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            AppColors.textPrimary,
                                        width: 2.0,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                Text(
                                  "Password",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                  ),
                                ),
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
                                    } else if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                      horizontal: 0,
                                    ),
                                    hintText: 'Create a password',
                                    hintStyle: TextStyle(
                                      fontSize: TextSizes.bodyText1,
                                      color: const Color.fromARGB(
                                        255,
                                        91,
                                        91,
                                        91,
                                      ),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Color.fromARGB(255, 127, 127, 127),
                                      size: IconSizes.midSmall,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      gapPadding: 10,
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            AppColors.textPrimary,
                                        width: 2.0,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2.0,
                                      ),
                                    ),
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
                                        setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        );
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
                                style: TextStyle(
                                  fontSize: TextSizes.bodyText1,
                                  fontWeight: FontWeight.bold,
                                ),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Color.fromARGB(255, 73, 64, 241),
                                    Color.fromARGB(255, 149, 60, 237),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // EMAIL/PASSWORD SIGN IN
                          _isLoading
                              ? LoadingButton(height: 50, width: 50, scale: 1)
                              : RegularButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      final email = _emailController.text
                                          .trim();
                                      final password = _passwordController.text
                                          .trim();

                                      setState(() => _isLoading = true);

                                      try {
                                        await FirebaseService()
                                            .signInWithEmailAndPassword(
                                              email: email,
                                              password: password,
                                              context: context,
                                            );

                                        if (!mounted) return;

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Login successful! 🎉",
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const LaundryServicesScreen(),
                                          ),
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
                                            displayMessage =
                                                'invalid email or password.';
                                            break;
                                          case 'user-disabled':
                                            displayMessage =
                                                'This user account has been disabled.';
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
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Center(
                                                child: Text(
                                                  displayMessage,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
                                                  ),
                                                ),
                                              ),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(
                                                seconds: 4,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Center(
                                                child: Text(
                                                  'An unexpected error occurred: ${e.toString()}',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
                                                  ),
                                                ),
                                              ),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(
                                                seconds: 4,
                                              ),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      }
                                    }
                                  },
                                  borderRadius: 7,
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                    colors: [
                                      Color.fromARGB(255, 73, 64, 241),
                                      Color.fromARGB(255, 149, 60, 237),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  textWidget: CustomText(
                                    text: 'Sign In',
                                    textColor: Theme.of(
                                      context,
                                    ).textTheme.headlineLarge?.color,
                                    textSize: TextSizes.bodyText1,
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
                                textSize: TextSizes.bodyText1,
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
                                style: TextStyle(
                                  fontSize: TextSizes.bodyText1,
                                  fontWeight: FontWeight.bold,
                                ),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Color.fromARGB(255, 73, 64, 241),
                                    Color.fromARGB(255, 149, 60, 237),
                                  ],
                                ),
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
                              textSize: 9,
                            ),
                            const SizedBox(width: 5),
                            GradientText(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              gradient: const LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Color.fromARGB(255, 73, 64, 241),
                                  Color.fromARGB(255, 149, 60, 237),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            CustomText(
                              text: 'and',
                              textColor: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              textSize: 9,
                            ),
                          ],
                        ),
                        GradientText(
                          text: 'Privacy Policy',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          gradient: const LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              Color.fromARGB(255, 73, 64, 241),
                              Color.fromARGB(255, 149, 60, 237),
                            ],
                          ),
                        ),
                      ],
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

////////////////////////////////////////////////////////////////////////////////////////////////////

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
      return await ref.get(const GetOptions(source: Source.cache));
    }

    try {
      return await ref
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      return await ref.get(const GetOptions(source: Source.cache));
    }
  }

  Map<String, dynamic> _readMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _mergeFcmToken(
    Map<String, dynamic>? existing,
    String? token,
  ) {
    final updated = Map<String, dynamic>.from(existing ?? {});
    if (token != null && token.isNotEmpty) {
      updated[token] = true;
    }
    return updated;
  }

  Map<String, dynamic> _sanitizeUserMap(Map<String, dynamic> data) {
    data['notificationSettings'] ??= {
      "push": true,
      "email": true,
      "bookingConfirmed": true,
      "washStarted": true,
      "washCompleted": true,
      "appUpdates": true,
    };
    data['settings'] ??= {
      "autoLock": false,
      "biometricAuth": false,
      "darkMode": false,
    };
    data['locations'] ??= [];
    data['fcmTokens'] ??= <String, dynamic>{};

    final nowUtcTs = Timestamp.fromDate(DateTime.now().toUtc());
    data['createdAt'] ??= nowUtcTs;
    data['updatedAt'] ??= nowUtcTs;
    data['lastLoginAt'] ??= nowUtcTs;
    data['lastSeen'] ??= nowUtcTs;
    data['fcmUpdatedAt'] ??= nowUtcTs;

    data['uid'] ??= '';
    data['email'] ??= data['emailAddress'] ?? '';
    data['emailAddress'] ??= data['email'] ?? '';
    data['name'] ??= '';

    return data;
  }

  Future<void> _saveLoggedInFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
  }

  Future<void> _loadUserIntoProvider(BuildContext context, String uid) async {
    final doc = await _getUserDocResolved(uid);
    final data = doc.data();
    if (data == null) throw Exception('User document has no data for uid=$uid');

    final safe = _sanitizeUserMap(data);
    final userModel = UserModel.fromMap(safe);

    if (context.mounted) {
      await context.read<UserProvider>().setUser(userModel);
    }
  }

  // ✅ NEW: ensure full user profile exists even if doc already exists partially
  Future<void> _ensureUserProfile({
    required User user,
    required String? fcmToken,
  }) async {
    final uid = user.uid;
    final ref = _userRef(uid);

    final snap = await ref.get().timeout(const Duration(seconds: 8));
    final existing = snap.data() ?? <String, dynamic>{};

    String pickString(String key, String fallback) {
      final v = existing[key];
      if (v is String && v.trim().isNotEmpty) return v;
      return fallback;
    }

    final nowUtc = DateTime.now().toUtc();
    final memberSinceDefault = "${_monthName(nowUtc.month)} ${nowUtc.year}";

    final safeName = pickString(
      'name',
      user.displayName ?? user.email?.split('@').first ?? '',
    );
    final safeEmail = pickString('email', user.email ?? '');
    final safeEmailAddress = pickString('emailAddress', user.email ?? '');
    final safePhone = pickString('phoneNumber', user.phoneNumber ?? '');
    final safePhoto = pickString('photoUrl', user.photoURL ?? '');
    final safeMemberSince = pickString('memberSince', memberSinceDefault);

    final existingTokens = _readMap(existing['fcmTokens']);
    final updatedTokens = _mergeFcmToken(existingTokens, fcmToken);

    final notificationDefaults = <String, dynamic>{
      "push": true,
      "email": true,
      "bookingConfirmed": true,
      "washStarted": true,
      "washCompleted": true,
      "appUpdates": true,
    };

    final settingsDefaults = <String, dynamic>{
      "autoLock": false,
      "biometricAuth": false,
      "darkMode": false,
    };

    final data = <String, dynamic>{
      // identity
      'uid': uid,
      'name': safeName,
      'email': safeEmail,
      'emailAddress': safeEmailAddress,
      'phoneNumber': safePhone,
      'photoUrl': safePhoto,
      'memberSince': safeMemberSince,

      // keep existing if present else default
      'address': existing['address'] ?? '',
      'dateOfBirth': existing['dateOfBirth'] ?? '',
      'locations': existing['locations'] ?? [],
      'totalWashes': existing['totalWashes'] ?? 0,
      'washesThisMonth': existing['washesThisMonth'] ?? 0,
      'rating': existing['rating'] ?? 0.0,
      'loyaltyPoints': existing['loyaltyPoints'] ?? 0,

      // merge nested maps (don’t lose old settings)
      'notificationSettings': {
        ...notificationDefaults,
        ..._readMap(existing['notificationSettings']),
      },
      'settings': {...settingsDefaults, ..._readMap(existing['settings'])},

      // session + times (server authoritative)
      'isOnline': true,
      'updatedAt': _serverNow(),
      'lastLoginAt': _serverNow(),
      'lastSeen': _serverNow(),
    };

    // tokens
    if (fcmToken != null && fcmToken.isNotEmpty) {
      data['fcmTokens'] = updatedTokens;
      data['fcmUpdatedAt'] = _serverNow();
    } else {
      data['fcmTokens'] = existing['fcmTokens'] ?? <String, dynamic>{};
      data['fcmUpdatedAt'] =
          existing['fcmUpdatedAt'] ?? Timestamp.fromDate(nowUtc);
    }

    // createdAt once
    if (!snap.exists) {
      data['createdAt'] = _serverNow();
    } else {
      data['createdAt'] = existing['createdAt'] ?? _serverNow();
    }

    // ✅ merge so we never wipe any user-entered info
    await ref.set(data, SetOptions(merge: true));
  }

  // --- SIGN IN WITH GOOGLE (now guarantees full profile) ---------------------
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      debugPrint('🟦 GS1: open Google sign-in');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('🟨 GS cancelled (googleUser == null)');
        return null;
      }

      debugPrint('🟦 GS2: get auth tokens');
      final googleAuth = await googleUser.authentication;

      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        debugPrint('❌ GS tokens empty (idToken/accessToken both null/empty)');
        try {
          await googleSignIn.signOut();
        } catch (_) {}
        return null;
      }

      debugPrint('🟦 GS3: Firebase signInWithCredential');
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        debugPrint('❌ GS userCredential.user is null');
        try {
          await googleSignIn.signOut();
        } catch (_) {}
        return null;
      }

      debugPrint('🟦 GS4: ensureUserProfile');
      final fcmToken = await fcm.getToken();
      await _ensureUserProfile(user: user, fcmToken: fcmToken);

      debugPrint('🟦 GS5: load user into provider');
      await _loadUserIntoProvider(context, user.uid);

      debugPrint('🟦 GS6: save logged-in flag');
      await _saveLoggedInFlag();

      debugPrint('✅ GS done');
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

  // --- SIGN IN WITH EMAIL/PASSWORD (optional: also ensure profile completeness)
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
      };

      if (fcmToken != null && fcmToken.isNotEmpty) {
        updateMap['fcmTokens'] = updatedTokens;
        updateMap['fcmUpdatedAt'] = _serverNow();
      }

      await _userRef(uid).set(updateMap, SetOptions(merge: true));

      // ✅ ensure old email users also get missing defaults/time fields filled
      await _ensureUserProfile(user: user, fcmToken: fcmToken);

      await _loadUserIntoProvider(context, uid);
      await _saveLoggedInFlag();
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // --- TOGGLE IS ONLINE ------------------------------------------------------
  Future<void> toggleIsOnline(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _userRef(user.uid).set({
        'isOnline': value,
        'updatedAt': _serverNow(),
        'lastSeen': _serverNow(),
      }, SetOptions(merge: true));

      debugPrint('✅ User online status updated: $value');
    } catch (e) {
      debugPrint('❌ Failed to update online status: $e');
    }
  }

  // --- SIGN OUT --------------------------------------------------------------
  Future<void> signOut(BuildContext context) async {
    try {
      await toggleIsOnline(false);
      await auth.signOut();

      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      if (context.mounted) {
        await context.read<UserProvider>().clearCache();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}
