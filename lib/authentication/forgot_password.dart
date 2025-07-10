import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/authentication/login_screen.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
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
                top: 140,
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
                          const SizedBox(height: 10),
                          CustomText(
                            text: 'Forgot Password?',
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.color,
                            textSize: TextSizes.heading2,
                            textWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 10),
                          CustomText(
                            text:
                                "Enter your email address and we'll send you a link to reset your password",
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            textSize: TextSizes.bodyText1,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),

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
                                  "Email Address",
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
                                      return 'Please enter your email address';
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
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          _isLoading
                              ? LoadingButton(height: 50, width: 50, scale: 1)
                              : RegularButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      final email = _emailController.text
                                          .trim();
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      try {
                                        await sendPasswordResetEmail(
                                          email: email,
                                        );
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                PasswordResetLinkConfirmation(
                                                  email: email,
                                                ),
                                          ),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Center(
                                              child: CustomText(
                                                text:
                                                    'Reset link sent successfully',
                                                textColor: AppColors.white,
                                              ),
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(
                                              seconds: 3,
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
                                                    'Error sending reset link',
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
                                    text: 'Send Reset Link',
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
                                text: "Remember your password?",
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
                                      builder: (_) => const LoginScreen(),
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
                              text: "By using our service, you agree to our",
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

Future<void> sendPasswordResetEmail({required String email}) async {
  try {
    final auth = FirebaseAuth.instance;
    await auth.sendPasswordResetEmail(email: email);
    debugPrint('Password reset email sent to $email');
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      debugPrint('No user found for that email.');
    } else {
      debugPrint('FirebaseAuth error: ${e.message}');
    }
  } catch (e) {
    debugPrint('General error: $e');
  }
}

class PasswordResetLinkConfirmation extends StatefulWidget {
  final String? email;
  const PasswordResetLinkConfirmation({super.key, this.email});

  @override
  State<PasswordResetLinkConfirmation> createState() =>
      _PasswordResetLinkConfirmationState();
}

class _PasswordResetLinkConfirmationState
    extends State<PasswordResetLinkConfirmation> {
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
                top: 140,
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
                          const SizedBox(height: 10),
                          Center(
                            child: Lottie.asset(
                              'assets/animations/email_sent.json',
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 10),
                          CustomText(
                            text: 'Check Your Email',
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.color,
                            textSize: TextSizes.heading2,
                            textWeight: FontWeight.bold,
                          ),
                          const SizedBox(height: 10),
                          CustomText(
                            text: "We've sent password reset instructions to",
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            textSize: TextSizes.bodyText1,
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 10),
                          CustomText(
                            text: widget.email!,
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            textSize: TextSizes.bodyText1,
                            textAlign: TextAlign.center,
                            textWeight: FontWeight.bold,
                          ),

                          const SizedBox(height: 10),
                          CustomText(
                            text:
                                "Didn't receive the email? Check your spam folder or try again.",
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            textSize: TextSizes.bodyText1,
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 20),

                          RegularButton(
                            onPressed: () async {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPassword(),
                                ),
                              );
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
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            textWidget: CustomText(
                              text: 'Try Again',
                              textColor: Theme.of(
                                context,
                              ).textTheme.headlineLarge?.color,
                              textSize: TextSizes.bodyText1,
                              textWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GradientText(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginScreen(),
                                ),
                              );
                            },
                            text: 'Back to Sign In',
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
