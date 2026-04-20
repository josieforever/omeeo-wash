import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/laundry_services.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final focusColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;

    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 14,
        color: const Color.fromARGB(255, 91, 91, 91),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color.fromARGB(255, 127, 127, 127),
        size: 20,
      ),
      suffixIcon: suffixIcon,
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

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, label),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          cursorColor: Theme.of(context).textTheme.bodyLarge?.color,
          obscureText: obscureText,
          validator: validator,
          decoration: _inputDecoration(
            context: context,
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color.fromARGB(255, 127, 127, 127),
                      size: 18,
                    ),
                    onPressed: onToggleObscure,
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final userCredential = await signInWithGoogle(context);

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

  Future<void> _handleEmailSignup() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: CustomText(
              text: 'Please correct the errors in the form.',
              textColor: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      await signUpWithEmail(email: email, password: password, context: context);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: CustomText(
              text: 'Account created successfully!',
              textColor: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LaundryServicesScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: CustomText(
              text: 'Sign up failed: $e',
              textColor: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              padding: EdgeInsets.only(
                left: 15,
                right: 15,
                top: 30,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 10,
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
                              text: 'Create your account to get started',
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
                                  _buildTextField(
                                    context: context,
                                    label: 'Email',
                                    controller: _emailController,
                                    hintText: 'Enter your email',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      final email = value?.trim() ?? '';
                                      if (email.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(
                                        r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      ).hasMatch(email)) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  _buildTextField(
                                    context: context,
                                    label: 'Password',
                                    controller: _passwordController,
                                    hintText: 'Create a password',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    onToggleObscure: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  _buildTextField(
                                    context: context,
                                    label: 'Confirmed Password',
                                    controller: _confirmPasswordController,
                                    hintText: 'Confirm your password',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscureConfirmPassword,
                                    onToggleObscure: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 30),

                                  RegularButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleEmailSignup,
                                    borderRadius: 7,
                                    gradient: _brandGradient,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    textWidget: CustomText(
                                      text: _isLoading
                                          ? 'Creating Account...'
                                          : 'Create Account',
                                      textColor: Theme.of(
                                        context,
                                      ).textTheme.headlineLarge?.color,
                                      textSize: 14,
                                      textWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomText(
                                  text: 'Already have an account?',
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
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                  text: 'Sign In',
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
                              Flexible(
                                child: CustomText(
                                  text:
                                      'By creating an account, you agree to our',
                                  textColor: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  textSize: 11,
                                ),
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

String _monthName(int month) {
  const months = [
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
  return months[month - 1];
}

UserModel _buildNewUser({
  required User user,
  required DateTime now,
  required Map<String, bool> fcmTokensMap,
}) {
  final memberSince = "${_monthName(now.month)} ${now.year}";

  return UserModel(
    uid: user.uid,
    accountType: 'customer',
    status: 'active',

    name: user.displayName ?? user.email!.split('@').first,
    firstName: '',
    lastName: '',
    email: user.email ?? '',
    phoneNumber: user.phoneNumber ?? '',
    photoUrl: user.photoURL ?? '',

    defaultAddressId: null,
    defaultPaymentMethodId: null,

    notificationSettings: const {
      'push': true,
      'email': true,
      'bookingUpdates': true,
      'promoOffers': true,
    },

    settings: const {
      'languageCode': 'en',
      'regionCode': 'GH',
      'darkMode': false,
    },

    stats: {
      'totalOrders': 0,
      'completedOrders': 0,
      'cancelledOrders': 0,
      'totalSpent': 0,
      'lastOrderAt': null,
      'memberSince': memberSince,
    },

    loyalty: const {'points': 0, 'tier': 'standard'},

    currentBookingId: null,
    currentBookingStatus: null,

    isOnline: true,
    lastLoginAt: now,
    lastSeen: now,

    fcmTokens: fcmTokensMap,
    fcmUpdatedAt: now,

    createdAt: now,
    updatedAt: now,
  );
}

Future<UserCredential?> signInWithGoogle(BuildContext context) async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final fcm = FirebaseMessaging.instance;

  try {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null || user.email == null) return null;

    final userRef = firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    final now = DateTime.now();
    final fcmToken = await fcm.getToken();
    final fcmTokensMap = (fcmToken != null && fcmToken.isNotEmpty)
        ? <String, bool>{fcmToken: true}
        : <String, bool>{};

    if (!userDoc.exists || userDoc.data() == null) {
      final newUser = _buildNewUser(
        user: user,
        now: now,
        fcmTokensMap: fcmTokensMap,
      );

      await userRef.set(newUser.toMap());
      await context.read<UserProvider>().setUser(newUser);
    } else {
      final existingUser = UserModel.fromMap(userDoc.data()!);
      final updatedTokens = Map<String, bool>.from(existingUser.fcmTokens);

      if (fcmToken != null && fcmToken.isNotEmpty) {
        updatedTokens[fcmToken] = true;
      }

      final updatedUser = existingUser.copyWith(
        isOnline: true,
        lastLoginAt: now,
        lastSeen: now,
        fcmTokens: updatedTokens,
        fcmUpdatedAt: now,
        updatedAt: now,
      );

      await userRef.set(updatedUser.toMap(), SetOptions(merge: true));
      await context.read<UserProvider>().setUser(updatedUser);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);

    return userCredential;
  } catch (e) {
    debugPrint('Google Sign-In Error: $e');
    return null;
  }
}

Future<void> signUpWithEmail({
  required BuildContext context,
  required String email,
  required String password,
}) async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final fcm = FirebaseMessaging.instance;

  final userCredential = await auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  final user = userCredential.user!;
  final placeholderName = email.split('@').first;

  await user.updateDisplayName(placeholderName);

  final userRef = firestore.collection('users').doc(user.uid);
  final doc = await userRef.get();

  if (!doc.exists || doc.data() == null) {
    final now = DateTime.now();
    final fcmToken = await fcm.getToken();
    final fcmTokensMap = (fcmToken != null && fcmToken.isNotEmpty)
        ? <String, bool>{fcmToken: true}
        : <String, bool>{};

    final refreshedUser = auth.currentUser;
    final newUser = _buildNewUser(
      user: refreshedUser ?? user,
      now: now,
      fcmTokensMap: fcmTokensMap,
    );

    await userRef.set(newUser.toMap());
    await context.read<UserProvider>().setUser(newUser);
  } else {
    final existingUser = UserModel.fromMap(doc.data()!);
    await context.read<UserProvider>().setUser(existingUser);
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_logged_in', true);
}
