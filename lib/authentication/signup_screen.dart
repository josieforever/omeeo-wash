import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:omeeowash/pages/home_screen_with_nav.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                top: 30,
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
                            text: 'Create your account to get started',
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            textSize: TextSizes.bodyText1,
                          ),
                          const SizedBox(height: 10),
                          ContinueSignInButton(
                            text: 'Continue with Google',
                            animation:
                                'assets/animations/google.json', // Ensure this path is correct
                            scale: 3,
                            onPressed: () async {
                              setState(() {
                                _isLoading = true;
                              });
                              final userCredential = await signInWithGoogle(
                                context,
                              ); ///////////////////////////////////////////////////SIGN IN WITH GOOGLE///////////////////////////////////
                              if (userCredential != null) {
                                // Navigate to home screen
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const HomeScreenWithNav(view: 'home'),
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
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Apple sign-in not implemented yet",
                                  ),
                                ),
                              );
                            },
                            animation:
                                'assets/animations/apple.json', // Ensure this path is correct
                            scale: 1.5,
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
                                const SizedBox(height: 20),

                                // Confirm Password
                                Text(
                                  "Confirmed Password",
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
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your password';
                                    } else if (value !=
                                        _passwordController.text) {
                                      return 'Passwords do not match';
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
                                    hintText: 'Confirm your password',
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
                                        _obscureConfirmPassword
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
                                          () => _obscureConfirmPassword =
                                              !_obscureConfirmPassword,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                RegularButton(
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
                                        await signUpWithEmail(
                                          email: email,
                                          password: password,
                                          context: context,
                                        );

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Center(
                                              child: CustomText(
                                                text:
                                                    'Account created successfully!',
                                                textColor: AppColors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(
                                              seconds: 3,
                                            ),
                                          ),
                                        );

                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const HomeScreenWithNav(
                                                  view: 'home',
                                                ),
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
                                                    'Sign up failed: ${e.toString()}',
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
                                    } else {
                                      // show warning if form is invalid
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Center(
                                            child: CustomText(
                                              text:
                                                  'Please correct the errors in the form.',
                                              textColor: AppColors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
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
                                    text: 'Create Account',
                                    textColor: Theme.of(
                                      context,
                                    ).textTheme.headlineLarge?.color,
                                    textSize: TextSizes.bodyText1,
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
                                textSize: TextSizes.bodyText1,
                              ),
                              const SizedBox(width: 5),
                              GradientText(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoginScreen(),
                                    ),
                                  );
                                },
                                text: 'Sign In',
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
                              text: 'By creating an account, you agree to our',
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

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
        locations: [],
        notificationSettings: {
          "push": true,
          "email": true,
          "bookingConfirmed": true,
          "washStarted": true,
          "washCompleted": true,
          "appUpdates": true,
        },
        settings: {
          "autoLock": false,
          "biometricAuth": false,
          "darkMode": false,
        },
      );

      await firestore.collection('users').doc(user.uid).set(newUser.toMap());

      // Save to Provider
      await context.read<UserProvider>().setUser(newUser);
    } else {
      // Existing user – load from Firestore
      final existingUser = UserModel.fromMap(userDoc.data()!);
      await context.read<UserProvider>().setUser(existingUser);
    }
    // ✅ Save login status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);

    return userCredential;
  } catch (e) {
    debugPrint('Google Sign-In Error: $e');
    return null;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///
Future<void> signUpWithEmail({
  required BuildContext context,
  required String email,
  required String password,
}) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final userCredential = await auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  final user = userCredential.user!;
  final placeholderName = email.split('@').first;

  // Set display name in Firebase Auth
  await user.updateDisplayName(placeholderName);

  final userRef = firestore.collection('users').doc(user.uid);
  final docExists = (await userRef.get()).exists;

  if (!docExists) {
    final now = DateTime.now();
    final memberSince = "${_monthName(now.month)} ${now.year}";

    final newUser = UserModel(
      uid: user.uid,
      name: user.displayName ?? user.email!.split('@')[0],
      email: user.email!,
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
      locations: [],
      notificationSettings: {
        "push": true,
        "email": true,
        "bookingConfirmed": true,
        "washStarted": true,
        "washCompleted": true,
        "appUpdates": true,
      },
      settings: {"autoLock": false, "biometricAuth": false, "darkMode": false},
    );

    await userRef.set(newUser.toMap());

    // Save to Provider
    await context.read<UserProvider>().setUser(newUser);
    // ✅ Save login status
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
  } else {
    final existingUser = UserModel.fromMap((await userRef.get()).data()!);
    await context.read<UserProvider>().setUser(existingUser);
  }
}
