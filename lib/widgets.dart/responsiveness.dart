import 'package:flutter/material.dart';

class Responsiveness {
  static late double screenWidth;
  static late double screenHeight;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height;
  }
}

class TextSizes {
  static const double heading1 = 25.0;
  static const double heading2 = 20.0;
  static const double heading3 = 18.0;

  static const double subtitle1 = 18.0;
  static const double subtitle2 = 16.0;

  static const double bodyText1 = 14.0;
  static const double bodyText2 = 12.0;

  static const double caption = 11.0;
  static const double overline = 10.0;
}

class IconSizes {
  static const double tiny = 12.0;
  static const double small = 16.0;
  static const double midSmall = 20.0;
  static const double medium = 24.0;
  static const double large = 32.0;
  static const double extraLarge = 48.0;
  static const double jumbo = 64.0;
}
