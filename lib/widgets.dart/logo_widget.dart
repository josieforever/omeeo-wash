import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OmeeoLogoWidget extends StatelessWidget {
  final double size;
  final bool showTagline;

  const OmeeoLogoWidget({
    super.key,
    this.size = 120.0,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: Lottie.asset(
            'assets/animations/white_son.json',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 40),
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Image.asset(
            'assets/images/omeeo_wash_logo_white_stripes.png', // Replace with your actual logo path
            height: size,
            width: size,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
