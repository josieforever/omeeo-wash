import 'package:flutter/material.dart';
import 'package:omeeowash/pages/home/booking%20flow/select_date_screen.dart';
import 'package:omeeowash/pages/home/booking%20flow/select_vehicle_size_screen.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class LnProgressIndicator extends StatelessWidget {
  final double value;
  const LnProgressIndicator({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: Color(0xFF9E9E9E),
        color: AppColors.pink,
        minHeight: 4,
      ),
    );
  }
}

class ContinueButton extends StatelessWidget {
  const ContinueButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: SizedBox(
        width: 200,
        child: RegularButton(
          borderRadius: 7,
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              Color.fromARGB(255, 73, 64, 241),
              Color.fromARGB(255, 149, 60, 237),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          textWidget: CustomText(
            text: 'Continue',
            textColor: Theme.of(context).textTheme.headlineLarge?.color,
            textSize: 16,
            textWeight: FontWeight.bold,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => const SelectDateScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
