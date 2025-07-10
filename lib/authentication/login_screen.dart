import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/authentication/forgot_password.dart';
import 'package:omeeowash/authentication/signup_screen.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/pages/home_screen_with_nav.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
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
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromARGB(26, 7, 0, 133),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: Offset(0, 6),
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
                          ContinueSignInButton(
                            text: 'Continue with Google',
                            animation: 'assets/animations/google.json',
                            scale: 3,
                            onPressed: () async {
                              setState(() {
                                _isLoading = true;
                              });
                              final userCredential = await FirebaseService()
                                  .signInWithGoogle(context);
                              if (userCredential != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreenWithNav(),
                                  ),
                                );
                              } else {
                                setState(() {
                                  _isLoading = false;
                                });
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
                          Form(
                            key: _formKey,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Email
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
                                    }
                                    // CORRECTED REGEX: Removed the backslash before $
                                    else if (!RegExp(
                                      r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    // Moved generic border to the top to allow specific borders to override
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
                                // Password
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
                                    // Moved generic border to the top to allow specific borders to override
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
                          _isLoading
                              ? LoadingButton(height: 50, width: 50, scale: 1)
                              : RegularButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      final email = _emailController.text
                                          .trim();
                                      final password = _passwordController.text
                                          .trim();
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      try {
                                        await FirebaseService()
                                            .signInWithEmailAndPassword(
                                              email: email,
                                              password: password,
                                              context: context,
                                            );

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const HomeScreenWithNav(),
                                          ),
                                        );
                                      } catch (e) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Center(
                                              child: CustomText(
                                                text:
                                                    'Login failed: ${e.toString()}',
                                                textColor: AppColors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(
                                              seconds: 3,
                                            ),
                                          ),
                                        );
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class FirebaseService {
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

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null || user.email == null) return null;

      final userDoc = await firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        final now = DateTime.now();
        final memberSince = "${_monthName(now.month)} ${now.year}";

        final newUser = UserModel(
          uid: user.uid,
          name: user.displayName ?? user.email!.split('@')[0],
          email: user.email!,
          /* firstName: '',
          lastName: '', */
          emailAddress: user.email!,
          phoneNumber: user.phoneNumber ?? '',
          address: '',
          dateOfBirth: '',
          memberSince: memberSince,
          totalWashes: 0,
          washesThisMonth: 0,
          rating: 0.0,
          loyaltyPoints: 0,
          photoUrl: '',
        );

        await firestore.collection('users').doc(user.uid).set(newUser.toMap());

        // Save to Provider
        await context.read<UserProvider>().setUser(newUser);
      } else {
        // Existing user – load from Firestore
        final existingUser = UserModel.fromMap(userDoc.data()!);
        await context.read<UserProvider>().setUser(existingUser);
      }

      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signInWithEmailAndPassword({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // Sign in the user
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      final userRef = firestore.collection('users').doc(user.uid);
      final docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        final placeholderName = email.split('@').first;
        final now = DateTime.now();
        final memberSince = DateFormat('MMM yyyy').format(now);

        final userModel = UserModel(
          uid: user.uid,
          name: placeholderName,
          email: email,
          emailAddress: email,
          phoneNumber: user.phoneNumber ?? '',
          address: '',
          dateOfBirth: '',
          memberSince: memberSince,
          totalWashes: 0,
          washesThisMonth: 0,
          rating: 5.0,
          loyaltyPoints: 0,
          photoUrl: '',
        );

        await userRef.set(userModel.toMap());
        await context.read<UserProvider>().setUser(userModel);
      } else {
        final userModel = UserModel.fromMap(docSnapshot.data()!);
        await context.read<UserProvider>().setUser(userModel);

        // Optionally update last login
        await userRef.update({'lastLogin': FieldValue.serverTimestamp()});
      }

      debugPrint('Login successful');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        debugPrint('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        debugPrint('Wrong password provided.');
      } else {
        debugPrint('FirebaseAuth error: ${e.message}');
      }
    } catch (e) {
      debugPrint('General sign-in error: $e');
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      final auth = FirebaseAuth.instance;
      final googleSignIn = GoogleSignIn();

      // Sign out from Firebase Auth and Google
      await auth.signOut();
      await googleSignIn.signOut();

      // Clear user provider and cache
      await context.read<UserProvider>().clearCache();

      // Clear login state flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_logged_in');

      // Navigate to login screen
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error signing out: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
