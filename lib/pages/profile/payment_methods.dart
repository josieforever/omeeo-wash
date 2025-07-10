import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/authentication/signup_screen.dart';
import 'package:omeeowash/providers/user_provider.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';
import 'package:provider/provider.dart';

class PaymentMethods extends StatelessWidget {
  const PaymentMethods({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    userProvider.loadUser(uid: FirebaseAuth.instance.currentUser!.uid);
    final user = userProvider.user;
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
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PaymentMethodTopBar(),
                  PaymentMethodMiddleBar(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodTopBar extends StatelessWidget {
  const PaymentMethodTopBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFF6D66F6), Color(0xFFA558F2)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'Payment Methods',
                    textColor: Theme.of(context).textTheme.headlineLarge?.color,
                    textSize: TextSizes.heading2,
                    textWeight: FontWeight.w900,
                  ),
                  CustomText(
                    text: 'Manage cards & payments',
                    textColor: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.color,
                    textSize: TextSizes.subtitle2,
                  ),
                ],
              ),
              GoBack(
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class PaymentMethodMiddleBar extends StatelessWidget {
  const PaymentMethodMiddleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      margin: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: 'Add Credit/Debit Card',
            textSize: TextSizes.bodyText1,
            textColor: Theme.of(context).textTheme.bodyLarge?.color,
            textWeight: FontWeight.bold,
          ),

          Row(
            children: [
              Expanded(
                child: PaymentIconStackTextButton(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  borderRadius: 7,
                  scale: 1.5,
                  imagePath: 'assets/images/credit_card.png',
                  imageHeight: 50,
                  imageWidth: 50,
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: const [
                      Color.fromARGB(
                        207,
                        109,
                        102,
                        246,
                      ), // Right (periwinkle blue-purple)
                      Color.fromARGB(
                        202,
                        165,
                        88,
                        242,
                      ), // Left (light pink-purple)
                    ],
                  ),
                  onPressed: () {
                    showAddCreditCardDialog(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CustomText(
            text: 'Add Mobile Money',
            textSize: TextSizes.bodyText1,
            textColor: Theme.of(context).textTheme.bodyLarge?.color,
            textWeight: FontWeight.bold,
          ),
          Row(
            children: [
              Expanded(
                child: PaymentIconStackTextButton(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  borderRadius: 7,
                  scale: 1.5,
                  imagePath: 'assets/images/mtn_logo.png',
                  imageHeight: 50,
                  imageWidth: 50,
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.fromARGB(
                        195,
                        255,
                        140,
                        0,
                      ), // A vibrant orange (e.g., DarkOrange)
                      Color.fromARGB(
                        186,
                        255,
                        217,
                        0,
                      ), // A golden yellow (e.g., Gold)
                    ],
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: PaymentIconStackTextButton(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  borderRadius: 7,
                  scale: 2.5,
                  imagePath: 'assets/images/at_logo.png',
                  imageHeight: 50,
                  imageWidth: 50,
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.fromARGB(200, 0, 123, 255), // A standard blue
                      Color.fromARGB(198, 0, 200, 255), // A lighter, sky blue
                    ],
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: PaymentIconStackTextButton(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  borderRadius: 7,
                  scale: 1.3,
                  imagePath: 'assets/images/telecel_logo.png',
                  imageHeight: 50,
                  imageWidth: 50,
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color.fromARGB(212, 220, 20, 60), // Crimson red
                      Color.fromARGB(220, 255, 99, 71), // Tomato red
                    ],
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void showAddCreditCardDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      final formKey = GlobalKey<FormState>();
      final cardholderName = TextEditingController();
      final cardNumber = TextEditingController();
      final month = TextEditingController();
      final year = TextEditingController();
      final cvv = TextEditingController();

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  CustomText(
                    text: 'Add Credit/Debit Card',
                    textSize: TextSizes.bodyText1,
                    textColor: Theme.of(context).textTheme.bodyLarge?.color,
                    textWeight: FontWeight.w900,
                  ),
                  const SizedBox(height: 10),
                  Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        TextFormField(
                          cursorColor: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color,
                          controller: cardholderName,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter cardholder name';
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
                              horizontal: 10,
                            ),
                            hintText: 'Cardholder Name (eg: John Doe)',
                            hintStyle: TextStyle(
                              fontSize: TextSizes.caption,
                              color: const Color.fromARGB(255, 91, 91, 91),
                              fontWeight: FontWeight.bold,
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
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
                              borderSide: const BorderSide(color: Colors.red),
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
                        const SizedBox(height: 10),
                        // Password
                        TextFormField(
                          cursorColor: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color,
                          controller: cardNumber,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your card number';
                            } else if (value.length > 13) {
                              return 'Enter a valid card number';
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
                              horizontal: 10,
                            ),
                            hintText: 'Card Number (eg: 1234 5678 9012 3456)',
                            hintStyle: TextStyle(
                              fontSize: TextSizes.caption,
                              color: const Color.fromARGB(255, 91, 91, 91),
                              fontWeight: FontWeight.bold,
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
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
                              borderSide: const BorderSide(color: Colors.red),
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
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          cursorColor: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color,
                          controller: month,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '';
                            } else if (value.length > 2) {
                              return '';
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
                              horizontal: 10,
                            ),
                            hintText: 'Month',
                            hintStyle: TextStyle(
                              fontSize: TextSizes.caption,
                              color: const Color.fromARGB(255, 91, 91, 91),
                              fontWeight: FontWeight.bold,
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
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
                              borderSide: const BorderSide(color: Colors.red),
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
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TextFormField(
                          cursorColor: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color,
                          controller: year,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '';
                            } else if (value.length > 3) {
                              return '';
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
                              horizontal: 10,
                            ),
                            hintText: 'Year',
                            hintStyle: TextStyle(
                              fontSize: TextSizes.caption,
                              color: const Color.fromARGB(255, 91, 91, 91),
                              fontWeight: FontWeight.bold,
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
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
                              borderSide: const BorderSide(color: Colors.red),
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
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TextFormField(
                          cursorColor: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.color,
                          controller: cvv,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '';
                            } else if (value.length > 2) {
                              return '';
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
                              horizontal: 10,
                            ),
                            hintText: 'CVV',
                            hintStyle: TextStyle(
                              fontSize: TextSizes.caption,
                              color: const Color.fromARGB(255, 91, 91, 91),
                              fontWeight: FontWeight.bold,
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
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
                              borderSide: const BorderSide(color: Colors.red),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: RegularButton(
                          onPressed: () async {
                            Navigator.pop(context);
                          },
                          borderRadius: 7,
                          gradient: const LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              Color.fromARGB(104, 102, 102, 102),
                              Color.fromARGB(104, 102, 102, 102),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textWidget: CustomText(
                            text: 'Cancel',
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.color,
                            textSize: TextSizes.caption,
                            textWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RegularButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final name = cardholderName.text.trim();
                              final number = cardNumber.text.trim();
                              final mm = month.text.trim();
                              final yy = year.text.trim();
                              final code = cvv.text.trim();

                              Navigator.pop(context);
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
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textWidget: CustomText(
                            text: 'Add Card',
                            textColor: Theme.of(
                              context,
                            ).textTheme.headlineLarge?.color,
                            textSize: TextSizes.caption,
                            textWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
