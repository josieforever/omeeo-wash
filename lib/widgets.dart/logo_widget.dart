import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';

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
    final burstSize = context.rw(180, min: 120, max: 220);
    final logoMarginTop = context.rh(40, min: 20, max: 56);
    final horizontalPadding = context.rw(40, min: 16, max: 40);

    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 0,
          child: Lottie.asset(
            'assets/animations/white_son.json',
            width: burstSize,
            height: burstSize,
            fit: BoxFit.contain,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: logoMarginTop),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
