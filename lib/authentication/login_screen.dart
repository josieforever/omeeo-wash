import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'
    show FirebaseMessaging;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:omeeowash/authentication/forgot_password.dart';
import 'package:omeeowash/authentication/signup_screen.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/laundry_services/laundry_services.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _orange = Color(0xFFE67E22);
  static const Color _orangeSoft = Color(0xFFFFF0E4);
  static const Color _ink = Color(0xFF111111);
  static const Color _field = Color(0xFFF6F6F6);
  static const Color _muted = Color(0xFF7A7A7A);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString('remembered_login_email') ?? '';
    final remember = prefs.getBool('remember_login_email') ?? true;

    if (!mounted) return;

    setState(() {
      _rememberMe = remember;
      if (rememberedEmail.trim().isNotEmpty) {
        _emailController.text = rememberedEmail.trim();
      }
    });
  }

  Future<void> _saveRememberPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_login_email', _rememberMe);

    if (_rememberMe) {
      await prefs.setString(
        'remembered_login_email',
        _emailController.text.trim(),
      );
    } else {
      await prefs.remove('remembered_login_email');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

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
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      await FirebaseService().signInWithEmailAndPassword(
        email: email,
        password: password,
        context: context,
      );

      await _saveRememberPreference();

      if (!mounted) return;

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

      if (mounted) _showError(displayMessage);
    } catch (_) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
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

  Widget _rememberRow() {
    return Row(
      children: [
        InkWell(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _rememberMe ? _orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _rememberMe ? _orange : const Color(0xFFD6D6D6),
                  ),
                ),
                child: _rememberMe
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              const Text(
                'Remember me',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPassword()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: _orange,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text(
            'Forgot password?',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleEmailLogin,
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
                      'Sign in',
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
                                  'Welcome ',
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
                                onFieldSubmitted: (_) =>
                                    _passwordFocusNode.requestFocus(),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty)
                                    return 'Please enter your email';
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
                                textInputAction: TextInputAction.done,
                                cursorColor: _orange,
                                onFieldSubmitted: (_) => _handleEmailLogin(),
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
                                  hint: 'Enter your password',
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () {
                                      setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      );
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
                              const SizedBox(height: 6),
                              _rememberRow(),
                              const SizedBox(height: 12),
                              _loginButton(),
                              const SizedBox(height: 24),
                              const Row(
                                children: [
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
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'New to Lundri?',
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
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _orange,
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'By continuing, you agree to Lundri’s Terms of Service and Privacy Policy.',
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
