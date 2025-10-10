import 'package:flutter/material.dart';
import 'package:omeeowash/pages/bookings/booking%20flow/select_date_screen.dart';
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
