import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/laundry_services.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const Color _orange = Color(0xFFE67E22);
  static const Color _orangeSoft = Color(0xFFFFF0E4);
  static const Color _ink = Color(0xFF111111);
  static const Color _field = Color(0xFFF6F6F6);
  static const Color _muted = Color(0xFF7A7A7A);

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_refreshPasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_refreshPasswordStrength);

    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  void _refreshPasswordStrength() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleEmailSignup() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      _showMessage(
        'Please correct the highlighted fields.',
        backgroundColor: Colors.orange.shade800,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      await signUpWithEmail(email: email, password: password, context: context);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LaundryServicesScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Please choose a stronger password.';
          break;
        case 'operation-not-allowed':
          message = 'Email sign-up is currently unavailable.';
          break;
        default:
          message = e.message ?? 'Could not create your account.';
      }

      _showMessage(message, backgroundColor: Colors.red.shade700);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not create your account. Please try again.',
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFA7A7A7),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: Colors.black45, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: _field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _orange, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: _ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _brandHeader() {
    return Column(
      children: [
        SizedBox(
          width: 132,
          height: 96,
          child: Image.asset(
            'assets/images/lundri_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: _ink,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.local_laundry_service_rounded,
                  color: _orange,
                  size: 40,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fresh laundry, one tap away.',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  int get _passwordScore {
    final password = _passwordController.text;

    if (password.isEmpty) return 0;

    int score = 0;

    if (password.length >= 6) score++;
    if (password.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password) ||
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score++;
    }

    return score.clamp(0, 4);
  }

  String get _passwordStrengthLabel {
    switch (_passwordScore) {
      case 0:
        return 'Use at least 6 characters';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  Widget _passwordStrengthIndicator() {
    final score = _passwordScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 4,
                margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
                decoration: BoxDecoration(
                  color: index < score ? _orange : const Color(0xFFE7E7E7),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _passwordStrengthLabel,
          style: TextStyle(
            color: score >= 3 ? _orange : Colors.black45,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _createAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleEmailSignup,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _orange,
          disabledBackgroundColor: _orange.withOpacity(0.65),
          foregroundColor: _ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: _ink,
                  ),
                )
              : const Row(
                  key: ValueKey('text'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 19),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required Widget icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: SizedBox(
        height: 52,
        child: OutlinedButton(
          onPressed: _isLoading ? null : onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: _ink,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE8E8E8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF7F3EE),
      body: Stack(
        children: [
          Positioned(
            left: -90,
            top: -120,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -65,
            top: 115,
            child: Container(
              width: 175,
              height: 175,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.045),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                16,
                24,
                16,
                media.viewInsets.bottom + 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      _brandHeader(),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'Create your account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 27,
                                    letterSpacing: -0.7,
                                    fontWeight: FontWeight.w900,
                                    color: _ink,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),
                              _fieldLabel('Email'),
                              TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocusNode,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                cursorColor: _orange,
                                onFieldSubmitted: (_) {
                                  _passwordFocusNode.requestFocus();
                                },
                                validator: (value) {
                                  final email = value?.trim() ?? '';

                                  if (email.isEmpty) {
                                    return 'Please enter your email';
                                  }

                                  if (!RegExp(
                                    r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$',
                                  ).hasMatch(email)) {
                                    return 'Enter a valid email address';
                                  }

                                  return null;
                                },
                                decoration: _inputDecoration(
                                  hint: 'you@example.com',
                                  icon: Icons.mail_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _fieldLabel('Password'),
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                cursorColor: _orange,
                                onFieldSubmitted: (_) {
                                  _confirmPasswordFocusNode.requestFocus();
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
                                decoration: _inputDecoration(
                                  hint: 'Create a password',
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 19,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 9),
                              _passwordStrengthIndicator(),
                              const SizedBox(height: 18),
                              _fieldLabel('Confirm password'),
                              TextFormField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocusNode,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                cursorColor: _orange,
                                onFieldSubmitted: (_) {
                                  _handleEmailSignup();
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
                                decoration: _inputDecoration(
                                  hint: 'Re-enter your password',
                                  icon: Icons.lock_reset_rounded,
                                  suffix: IconButton(
                                    tooltip: _obscureConfirmPassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 19,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _createAccountButton(),
                              const SizedBox(height: 24),
                              Row(
                                children: const [
                                  Expanded(
                                    child: Divider(color: Color(0xFFE7E7E7)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'or continue with',
                                      style: TextStyle(
                                        color: Colors.black38,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: Color(0xFFE7E7E7)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  _socialButton(
                                    icon: Container(
                                      width: 22,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _orangeSoft,
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: const Text(
                                        'G',
                                        style: TextStyle(
                                          color: _orange,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    text: 'Google',
                                    onTap: _handleGoogleSignIn,
                                  ),
                                  const SizedBox(width: 10),
                                  _socialButton(
                                    icon: const Icon(
                                      Icons.apple,
                                      size: 22,
                                      color: _ink,
                                    ),
                                    text: 'Apple',
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Apple sign-in is coming soon.',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _orange,
                            ),
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'By creating an account, you agree to Lundri’s Terms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.4,
                          color: Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
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
