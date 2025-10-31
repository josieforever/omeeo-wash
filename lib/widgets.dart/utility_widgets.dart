import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lottie/lottie.dart';
import 'package:omeeowash/pages/bookings/bookings_chat/bookings_chat.dart';
import 'package:omeeowash/providers/top_nav_provider.dart';
import 'package:omeeowash/widgets.dart/colors.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:provider/provider.dart';

class ServiceButton extends StatelessWidget {
  final String textWidget1;
  final String? animation;
  final String? textWidget2;
  final String textWidget3;
  final String? price;
  final String? stars;
  final Icon? icon;
  final SvgPicture? svg;
  final double? scale;
  final VoidCallback onPressed;
  final VoidCallback modalSheet;
  final bool isSelected;
  final List<String>? serviceItems;
  const ServiceButton({
    super.key,
    required this.textWidget1,
    this.textWidget2,
    required this.textWidget3,
    this.price,
    this.icon,
    required this.onPressed,
    this.stars,
    this.animation,
    this.scale,
    this.svg,
    this.isSelected = false,
    this.serviceItems,
    required this.modalSheet,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: isSelected
              ? AppColors.pink
              : Theme.of(context).colorScheme.inversePrimary,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow,
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 6), // x, y
            ),
          ],
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromARGB(196, 235, 204, 255)
                            : Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Transform.scale(
                        scale: scale,
                        child: Center(child: icon ?? svg),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: textWidget1,
                      textColor: isSelected
                          ? Theme.of(context).colorScheme.inversePrimary
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      textSize: TextSizes.bodyText1,
                      textWeight: FontWeight.bold,
                    ),
                    textWidget2 == null
                        ? SizedBox()
                        : CustomText(
                            text: textWidget2!,
                            textColor: isSelected
                                ? Theme.of(context).colorScheme.inversePrimary
                                : Theme.of(context).textTheme.bodyMedium?.color,
                            textSize: TextSizes.bodyText1,
                          ),
                    CustomText(
                      text: textWidget3,
                      textColor: isSelected
                          ? Theme.of(context).colorScheme.inversePrimary
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      textSize: TextSizes.bodyText1,
                    ),
                  ],
                ),
                Expanded(child: SizedBox()),

                GestureDetector(
                  onTap: modalSheet,
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    radius: 15,
                    child: Icon(
                      FontAwesomeIcons.question,
                      size: 18,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ),
                SizedBox(width: 10),
              ],
            ),
            /* Column(
              children: [
                Row(
                  children: [
                    CustomText(
                      text: "Includes :",
                      textSize: TextSizes.bodyText1,
                      textWeight: FontWeight.bold,
                      textColor: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ],
                ),

                for (var service in serviceItems!)
                  Row(
                    children: [
                      Icon(Icons.do_not_disturb_on_sharp, size: 8),
                      const SizedBox(width: 5),
                      CustomText(
                        text: service,
                        textColor: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color,
                        textSize: TextSizes.bodyText3,
                      ),
                    ],
                  ),
              ],
            ), */
          ],
        ),
      ),
    );
  }
}

class CustomText extends StatelessWidget {
  final String text;
  final Color? textColor;
  final double? textSize;
  final FontWeight? textWeight;
  final TextAlign? textAlign;
  final int? textMaxLines;
  final TextOverflow? textOverflow;

  const CustomText({
    super.key,
    required this.text,
    this.textColor,
    this.textSize,
    this.textWeight,
    this.textAlign,
    this.textMaxLines,
    this.textOverflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.start,
      softWrap: true,
      maxLines: textMaxLines,
      overflow: textMaxLines != null
          ? (textOverflow ?? TextOverflow.ellipsis)
          : null,
      style: TextStyle(
        color: textColor ?? Colors.black,
        fontSize: textSize ?? 16,
        fontWeight: textWeight ?? FontWeight.normal,
      ),
    );
  }
}

class RegularButton extends StatefulWidget {
  final dynamic textWidget;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final double borderRadius;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const RegularButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.textWidget,
    this.border,
    required this.borderRadius,
    this.gradient,
    this.height,
  });

  @override
  State<RegularButton> createState() => _RegularButtonState();
}

class _RegularButtonState extends State<RegularButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border,
          gradient: widget.gradient,
        ),
        // fixed height
        padding: widget.padding,
        margin: widget.margin,
        child: Center(child: widget.textWidget),
      ),
    );
  }
}

class IconStackTextButton extends StatelessWidget {
  final Widget textWidget;
  final Widget? numberWidget;
  final Icon icon;
  final VoidCallback onPressed;
  final String? lottieAsset; // 👈 background animation file
  final BoxBorder? border;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const IconStackTextButton({
    super.key,
    required this.icon,
    required this.textWidget,
    this.numberWidget,
    required this.onPressed,
    this.lottieAsset,
    this.border,
    required this.borderRadius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          border: border,
          borderRadius: BorderRadius.circular(borderRadius),
          color: const Color.fromARGB(80, 117, 117, 117),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 🔥 Background Lottie (fills button perfectly)
              if (lottieAsset != null)
                Positioned.fill(
                  child: Transform.rotate(
                    angle: 90,
                    child: Transform.scale(
                      scale: 0.4,
                      child: Lottie.asset(
                        lottieAsset!,
                        fit: BoxFit.cover, // 👈 fills perfectly inside button
                        repeat: true,
                      ),
                    ),
                  ),
                ),
              if (lottieAsset != null)
                Positioned.fill(
                  left: 100,
                  child: Transform.rotate(
                    angle: 270,
                    child: Transform.scale(
                      scale: 0.4,
                      child: Lottie.asset(
                        lottieAsset!,
                        fit: BoxFit.cover, // 👈 fills perfectly inside button
                        repeat: true,
                      ),
                    ),
                  ),
                ),

              // 🔥 Foreground content
              Padding(
                padding: padding ?? const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        icon,
                        const SizedBox(width: 10),
                        if (numberWidget != null) numberWidget!,
                      ],
                    ),

                    const SizedBox(height: 2),
                    textWidget,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceButtonExpanded extends StatelessWidget {
  final String textWidget1;
  final String? animation;
  final String? textWidget2;
  final String textWidget3;
  final String? price;
  final String? stars;
  final Icon? icon;
  final SvgPicture? svg;
  final double? scale;
  final VoidCallback onPressed;
  final bool isSelected;
  final List<String>? serviceItems;
  const ServiceButtonExpanded({
    super.key,
    required this.textWidget1,
    this.textWidget2,
    required this.textWidget3,
    this.price,
    this.icon,
    required this.onPressed,
    this.stars,
    this.animation,
    this.scale,
    this.svg,
    this.isSelected = false,
    this.serviceItems,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            width: 2.5,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.inversePrimary,
          ),
          color: isSelected
              ? Theme.of(context).colorScheme.onSecondary
              : Theme.of(context).colorScheme.inversePrimary,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow,
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 6), // x, y
            ),
          ],
        ),
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.inversePrimary
                            : Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Transform.scale(
                        scale: scale,
                        child: Center(child: icon ?? svg),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: textWidget1,
                      textColor: Theme.of(context).textTheme.bodyLarge?.color,
                      textSize: TextSizes.bodyText1,
                      textWeight: FontWeight.bold,
                    ),
                    textWidget2 == null
                        ? SizedBox()
                        : CustomText(
                            text: textWidget2!,
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            textSize: TextSizes.bodyText1,
                          ),
                    CustomText(
                      text: textWidget3,
                      textColor: Theme.of(context).textTheme.bodyMedium?.color,
                      textSize: TextSizes.bodyText1,
                    ),
                  ],
                ),
                Expanded(child: SizedBox()),
                price == null
                    ? Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.solidStar,
                            size: IconSizes.midSmall,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 5),
                          CustomText(
                            text: stars!,
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.color,
                            textSize: TextSizes.subtitle1,
                            textWeight: FontWeight.bold,
                          ),
                        ],
                      )
                    : SizedBox(),
              ],
            ),

            Row(
              children: [
                CustomText(
                  text: "Includes :",
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ],
            ),

            for (var service in serviceItems!)
              Row(
                children: [
                  Icon(Icons.do_not_disturb_on_sharp, size: 8),
                  const SizedBox(width: 5),
                  CustomText(
                    text: service,
                    textColor: Theme.of(context).textTheme.bodyMedium?.color,
                    textSize: TextSizes.bodyText3,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class PromoButtom extends StatefulWidget {
  final dynamic textWidget1;
  final dynamic textWidget2;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final BoxBorder? border;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const PromoButtom({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.textWidget1,
    this.textWidget2,
    this.border,
    required this.borderRadius,
  });

  @override
  State<PromoButtom> createState() => _PromoButtomState();
}

class _PromoButtomState extends State<PromoButtom> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: const [
              /* Color.fromARGB(
                255,
                245,
                245,
                245,
              ),  */
              // Right (periwinkle blue-purple)
              Color.fromARGB(255, 193, 193, 193),
              Color.fromARGB(255, 52, 52, 52),
            ], // Left (light pink-purple)
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border,
        ),
        // fixed height
        padding: widget.padding,
        margin: widget.margin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: 'First Wash Free!',
                  textColor: Theme.of(context).colorScheme.inversePrimary,
                  textSize: TextSizes.subtitle2,
                  textWeight: FontWeight.bold,
                ),
                RegularButton(
                  onPressed: () {},

                  borderRadius: 15,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  textWidget: CustomText(
                    text: 'Claim Now',
                    textColor: Theme.of(context).colorScheme.inversePrimary,
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            CustomText(
              text: 'New customers get their first basic wash on us',
              textColor: Theme.of(context).colorScheme.inversePrimary,
              textSize: TextSizes.bodyText1,
              textWeight: FontWeight.normal,
            ),
          ],
        ),
      ),
    );
  }
}

class TopNavBarTab extends StatefulWidget {
  final dynamic textWidget;
  final dynamic numberWidget;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final BoxBorder? border;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const TopNavBarTab({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.textWidget,
    this.border,
    required this.borderRadius,
    this.numberWidget,
  });

  @override
  State<TopNavBarTab> createState() => _TopNavBarTabState();
}

class _TopNavBarTabState extends State<TopNavBarTab> {
  @override
  Widget build(BuildContext context) {
    final topNavProvider = Provider.of<TopNavProvider>(context);
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: topNavProvider.isTabSelected(widget.textWidget)
              ? Theme.of(context).colorScheme.inversePrimary
              : Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border,
        ),
        // fixed height
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        margin: widget.margin,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                text: widget.textWidget,
                textColor: Theme.of(context).colorScheme.primary,
                textSize: TextSizes.bodyText1,
                textWeight: FontWeight.bold,
              ),
              const SizedBox(width: 5),
              CircleAvatar(
                backgroundColor: topNavProvider.isTabSelected(widget.textWidget)
                    ? Theme.of(context).colorScheme.secondary
                    : const Color.fromARGB(43, 255, 255, 255),
                radius: 12,
                child: CustomText(
                  text: widget.numberWidget,
                  textColor: Theme.of(context).colorScheme.primary,
                  textSize: TextSizes.subtitle2,
                  textWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ManageBookingsTopNavBarTab extends StatefulWidget {
  final dynamic textWidget;
  final dynamic numberWidget;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final BoxBorder? border;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ManageBookingsTopNavBarTab({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.textWidget,
    this.border,
    required this.borderRadius,
    this.numberWidget,
  });

  @override
  State<ManageBookingsTopNavBarTab> createState() =>
      _ManageBookingsTopNavBarTabState();
}

class _ManageBookingsTopNavBarTabState
    extends State<ManageBookingsTopNavBarTab> {
  @override
  Widget build(BuildContext context) {
    final topNavProvider = Provider.of<TopNavProvider>(context);
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: topNavProvider.isTabSelected(widget.textWidget)
              ? Theme.of(context).colorScheme.inversePrimary
              : Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border,
        ),
        // fixed height
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        margin: widget.margin,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                text: widget.textWidget,
                textColor: Theme.of(context).colorScheme.primary,
                textSize: TextSizes.bodyText1,
                textWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileButton extends StatelessWidget {
  final String? textWidget1;
  final String? animation;
  final String? textWidget2;
  final String? textWidget3;
  final String? price;
  final String? stars;
  final Icon? icon;
  final SvgPicture? svg;
  final double? scale;
  final VoidCallback onPressed;
  const ProfileButton({
    super.key,
    this.textWidget1,
    this.textWidget2,
    this.textWidget3,
    this.price,
    this.icon,
    required this.onPressed,
    this.stars,
    this.animation,
    this.scale,
    this.svg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Theme.of(context).colorScheme.inversePrimary,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow,
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 6), // x, y
            ),
          ],
        ),
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Transform.scale(
                    scale: scale,
                    child: Center(child: icon ?? svg),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: textWidget1!,
                  textColor: Theme.of(context).textTheme.bodyLarge?.color,
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
                SizedBox(height: 1),
                CustomText(
                  text: textWidget2!,
                  textColor: Theme.of(context).textTheme.bodyMedium?.color,
                  textSize: TextSizes.bodyText1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SignOut extends StatelessWidget {
  final String? textWidget1;
  final String? animation;
  final String? textWidget2;
  final String? textWidget3;
  final String? price;
  final String? stars;
  final Icon? icon;
  final SvgPicture? svg;
  final double? scale;
  final VoidCallback onPressed;
  const SignOut({
    super.key,
    this.textWidget1,
    this.textWidget2,
    this.textWidget3,
    this.price,
    this.icon,
    required this.onPressed,
    this.stars,
    this.animation,
    this.scale,
    this.svg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color.fromARGB(154, 255, 145, 145)),
          color: Theme.of(context).colorScheme.inversePrimary,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow,
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 6), // x, y
            ),
          ],
        ),
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(31, 220, 22, 22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Transform.scale(
                    scale: scale,
                    child: Center(child: icon ?? svg),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: textWidget1!,
                  textColor: const Color.fromARGB(255, 178, 0, 0),
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
                SizedBox(height: 1),
                CustomText(
                  text: textWidget2!,
                  textColor: const Color.fromARGB(255, 0, 0, 0),
                  textSize: TextSizes.bodyText1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LoyaltyPointsBar extends StatefulWidget {
  final dynamic textWidget1;
  final dynamic textWidget2;
  final dynamic textWidget3;
  final String point;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final BoxBorder? border;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const LoyaltyPointsBar({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.textWidget1,
    this.textWidget2,
    this.border,
    required this.borderRadius,
    this.textWidget3,
    required this.point,
  });

  @override
  State<LoyaltyPointsBar> createState() => _LoyaltyPointsBarState();
}

class _LoyaltyPointsBarState extends State<LoyaltyPointsBar> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: const [
              Color(0xFF6D66F6), // Right (periwinkle blue-purple)
              Color(0xFFA558F2),
            ], // Left (light pink-purple)
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border,
        ),
        // fixed height
        padding: widget.padding,
        margin: EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.textWidget1,
                const SizedBox(height: 5),
                widget.textWidget2,
                const SizedBox(height: 5),
                widget.textWidget3,
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CustomText(
                  text: widget.point,
                  textColor: Theme.of(context).colorScheme.inversePrimary,
                  textSize: TextSizes.heading1,
                  textWeight: FontWeight.bold,
                ),

                CustomText(
                  text: 'points',
                  textColor: Theme.of(context).colorScheme.inversePrimary,
                  textSize: TextSizes.caption,
                  textWeight: FontWeight.normal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const GradientText({
    super.key,
    required this.text,
    required this.gradient,
    this.style,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: ShaderMask(
        shaderCallback: (bounds) => gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        ),
        blendMode: BlendMode.srcIn,
        child: Text(text, style: style),
      ),
    );
  }
}

class ContinueSignInButton extends StatelessWidget {
  final String text;
  final String animation;
  final double scale;
  final VoidCallback onPressed;

  const ContinueSignInButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.animation,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 7),
        padding: EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Color.fromARGB(102, 91, 91, 91), width: 1),
          borderRadius: BorderRadius.circular(5),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Lottie.asset(
                animation,
                fit: BoxFit.contain,
                height: MediaQuery.of(context).size.height * 0.02,
                width: MediaQuery.of(context).size.width * 0.08,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: Colors.black87,
                fontSize: TextSizes.bodyText2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingButton extends StatelessWidget {
  final double? containerHeight;
  final double? containerWidth;
  final double? width;
  final double? height;
  final double? scale;
  const LoadingButton({
    super.key,
    this.width,
    this.height,
    this.scale,
    this.containerHeight,
    this.containerWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: containerHeight,
      width: containerWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Color.fromARGB(255, 73, 64, 241),
            Color.fromARGB(255, 149, 60, 237),
          ],
        ),
      ),
      child: Center(
        child: Transform.scale(
          scale: scale ?? 1,
          child: Lottie.asset(
            'assets/animations/omeeo_loading_white.json',
            width: width ?? 100,
            height: height ?? 100,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class GoBack extends StatelessWidget {
  final Color? bgColor;
  final VoidCallback onPressed;
  const GoBack({super.key, required this.onPressed, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: EdgeInsets.all(10),
        child: CircleAvatar(
          backgroundColor: bgColor ?? Theme.of(context).colorScheme.surface,
          // backgroundColor: Colors.red,
          child: Center(
            child: Transform.scale(
              scale: 1.2,
              child: Icon(
                Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentIconStackTextButton extends StatelessWidget {
  final double? imageWidth;
  final double? imageHeight;
  final double? scale;
  final String imagePath;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final double borderRadius;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const PaymentIconStackTextButton({
    super.key,
    required this.imagePath,
    required this.onPressed,
    this.backgroundColor,
    this.border,
    required this.borderRadius,
    this.padding,
    this.margin,
    this.gradient,
    this.width,
    this.imageWidth,
    this.imageHeight,
    this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          gradient: gradient,
          border: border,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Transform.scale(
            scale: scale ?? 1,
            child: Image.asset(
              imagePath,
              width: imageWidth,
              height: imageHeight,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class RegularIconButton extends StatefulWidget {
  final dynamic textWidget;
  final Icon? icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const RegularIconButton({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.textWidget,
    this.border,
    required this.borderRadius,
    this.gradient,
    this.icon,
  });

  @override
  State<RegularIconButton> createState() => _RegularIconButtonState();
}

class _RegularIconButtonState extends State<RegularIconButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border,
          gradient: widget.gradient,
        ),
        // fixed height
        padding: widget.padding,
        margin: widget.margin,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.icon!,
              const SizedBox(width: 10),
              widget.textWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class LiveLocationProgressBar extends StatefulWidget {
  const LiveLocationProgressBar({super.key});

  @override
  State<LiveLocationProgressBar> createState() =>
      _LiveLocationProgressBarState();
}

class _LiveLocationProgressBarState extends State<LiveLocationProgressBar> {
  // Initial progress value. This will increase over time.
  double _progressValue = 0.0;
  // A timer to simulate the driver's progress.
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Start a timer to update the progress bar every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Increase the progress value by 0.1 each second.
        _progressValue += 0.1;
        // Stop the timer when the progress reaches 1.0 (100%).
        if (_progressValue >= 1.0) {
          _progressValue = 1.0;
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    // Cancel the timer to avoid memory leaks.
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: const Color.fromARGB(255, 0, 116, 0),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    backgroundColor: const Color(0xFFE5F1E5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF2ECC71),
                    ),
                    minHeight: 3,
                  ),
                ),
              ),
              Icon(
                Icons.circle,
                size: 8,
                color: const Color.fromARGB(255, 0, 116, 0),
              ),
            ],
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}

class WashStageVM {
  final String key; // e.g. "pre_rinse"
  final String label; // e.g. "Pre-rinse"
  final String status; // "pending" | "in_progress" | "done"
  const WashStageVM(this.key, this.label, this.status);

  // ✅ add this
  WashStageVM copyWith({String? key, String? label, String? status}) {
    return WashStageVM(
      key ?? this.key,
      label ?? this.label,
      status ?? this.status,
    );
  }
}

/// Default order used everywhere
const List<String> _kStageOrder = [
  'pre_rinse',
  'washing',
  'rinsing',
  'cleaning',
];

String _normalizeStageStatus(String? s) {
  final v = (s ?? '').trim().toLowerCase();
  if (v == 'done' || v == 'completed') return 'done';
  if (v == 'in_progress' ||
      v == 'in_progress' ||
      v == 'in-progress' ||
      v == 'active' ||
      v == 'processing') {
    return 'in_progress';
  }
  return 'pending';
}

String _labelFromKey(String k) {
  switch (k) {
    case 'pre_rinse':
      return 'Pre-rinse';
    case 'washing':
      return 'Washing';
    case 'rinsing':
      return 'Rinsing';
    case 'cleaning':
      return 'Cleaning';
    default:
      final pretty = k.replaceAll('_', ' ').trim();
      if (pretty.isEmpty) return 'Stage';
      return pretty[0].toUpperCase() + pretty.substring(1);
  }
}

List<WashStageVM> _vmFromFirestoreList(
  List<dynamic>? raw, {
  List<String> defaultOrder = const [
    'pre_rinse',
    'washing',
    'rinsing',
    'cleaning',
  ],
}) {
  if (raw == null || raw.isEmpty) {
    return defaultOrder
        .map((k) => WashStageVM(k, _labelFromKey(k), 'pending'))
        .toList();
  }

  final out = <WashStageVM>[];
  for (final item in raw) {
    if (item is String) {
      final key = item.trim();
      if (key.isNotEmpty)
        out.add(WashStageVM(key, _labelFromKey(key), 'pending'));
      continue;
    }
    if (item is Map) {
      final key = (item['key'] ?? item['stage'] ?? item['name'] ?? '')
          .toString()
          .trim();
      if (key.isEmpty) continue;
      final status = _normalizeStageStatus(item['status']?.toString());
      final label = (item['label'] ?? _labelFromKey(key)).toString();
      out.add(WashStageVM(key, label, status));
    }
  }

  if (out.isEmpty) {
    return defaultOrder
        .map((k) => WashStageVM(k, _labelFromKey(k), 'pending'))
        .toList();
  }

  final orderIndex = {
    for (var i = 0; i < defaultOrder.length; i++) defaultOrder[i]: i,
  };
  out.sort(
    (a, b) => (orderIndex[a.key] ?? 9999).compareTo(orderIndex[b.key] ?? 9999),
  );
  return out;
}

class StatusTabScreen extends StatelessWidget {
  const StatusTabScreen({super.key});

  // Canonical status mapping
  String _canonicalStatus(dynamic s) {
    final v = '${s ?? ''}'.trim().toLowerCase();
    if (v == 'pending' ||
        v == 'pending_cash' ||
        v == 'pending-card' ||
        v == 'awaiting_payment') {
      return 'pending';
    }
    if (v == 'in_progress' ||
        v == 'in_progress' ||
        v == 'in-progress' ||
        v == 'processing') {
      return 'in_progress';
    }
    if (v == 'confirmed' || v == 'booked') {
      return 'confirmed';
    }
    if (v == 'completed' || v == 'done' || v == 'finished') {
      return 'completed';
    }
    if (v == 'cancelled' || v == 'canceled') {
      return 'cancelled';
    }
    return v;
  }

  DateTime? _extractDate(dynamic tsOrIso) {
    if (tsOrIso == null) return null;
    try {
      if (tsOrIso is Timestamp) return tsOrIso.toDate();
      if (tsOrIso is String) return DateTime.tryParse(tsOrIso);
    } catch (_) {}
    return null;
  }

  String _serviceLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'express':
        return 'Express Wash';
      case 'standard':
        return 'Standard Wash';
      case 'premium':
      default:
        return 'Premium Detail';
    }
  }

  String _dayLabel(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(dt);
    if (day == now) return 'Today';
    if (day == now.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('MMM d').format(day).toLowerCase(); // dec 10
  }

  String _format12h(int hour24, int minute) {
    final h12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final mm = minute.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    return '$h12:$mm $ampm';
  }

  String? _convertDbLabelTo12h(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    final re = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?$');
    final m = re.firstMatch(s);
    if (m == null) return null;

    var h = int.tryParse(m.group(1)!) ?? 0;
    final min = int.tryParse(m.group(2)!) ?? 0;
    final ampmRaw = m.group(3);
    if (ampmRaw != null) {
      final ampm = ampmRaw.toUpperCase();
      if (ampm == 'PM' && h != 12) h += 12;
      if (ampm == 'AM' && h == 12) h = 0;
    } else {
      h = h.clamp(0, 23);
    }
    return _format12h(h, min);
  }

  String _timeLabel(DateTime? dt, dynamic labelFromDb) {
    final fromDb = _convertDbLabelTo12h(labelFromDb?.toString());
    if (fromDb != null) return fromDb;
    if (dt == null) return '—';
    return _format12h(dt.hour, dt.minute);
  }

  int? _durationForService(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'express':
        return 10;
      case 'standard':
        return 30;
      case 'premium':
        return 120;
      default:
        return null;
    }
  }

  String _locationLabel(Map<String, dynamic> b) {
    final addr =
        '${b['address'] ?? b['location'] ?? b['serviceLocation'] ?? ''}'.trim();
    if (addr.isEmpty) return '—';
    return '📍 $addr';
  }

  Stream<List<Map<String, dynamic>>> _userBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) => {
                  '__id': d.id, // keep id for live panel
                  ...d.data(),
                },
              )
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _NoGlowScroll(),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _userBookings(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _ListLoading();
          }
          if (snap.hasError) {
            return const _ErrorState(message: 'Could not load bookings.');
          }

          final raw = snap.data ?? const [];
          final items = raw.where((b) {
            final s = _canonicalStatus(b['status']);
            return s == 'pending' || s == 'in_progress' || s == 'confirmed';
          }).toList();

          // sort
          items.sort((a, b) {
            final at = _extractDate(a['scheduledTime']) ?? DateTime(2100);
            final bt = _extractDate(b['scheduledTime']) ?? DateTime(2100);
            return at.compareTo(bt);
          });

          if (items.isEmpty) {
            return const _EmptyState(
              title: 'No active bookings',
              subtitle: 'When you book a wash, it will show up here.',
              icon: FontAwesomeIcons.calendarXmark,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = items[i];
              final dt = _extractDate(b['scheduledTime']);
              final serviceType = '${b['serviceType'] ?? ''}';
              final canonical = _canonicalStatus(b['status']);
              final bookingId = b['__id'] as String;
              final bSenderId = b["userId"];
              final bRecieverId = b['decision']['byUid'] ?? "";

              // Preferred shape: washProgress { order, stages }
              final List<dynamic>? listStages =
                  (b['washProgress']?['stages'] as List?)?.cast<dynamic>();
              final List<String>? orderStages =
                  (b['washProgress']?['order'] as List?)
                      ?.map((e) => '$e')
                      .toList();

              // Legacy shape: washStageOrder + washStages map (we pass only list+order; live panel uses bookingId anyway)
              final List<String>? legacyOrder = (b['washStageOrder'] as List?)
                  ?.map((e) => '$e')
                  .toList();

              return BookingsServiceButton(
                bookingRecieverId: bRecieverId,
                bookingSenderId: bSenderId,
                bookingId: bookingId, // enables live progress panel
                service: _serviceLabel(serviceType),
                serviceLocation: _locationLabel(b),
                status: canonical,
                day: _dayLabel(dt),
                time: _timeLabel(dt, b['scheduledTimeLabel']),
                duration: (() {
                  final d = _durationForService(serviceType);
                  return d == null ? '⏱️ —' : '⏱️ $d min';
                })(),
                price: (b['price']?.toString()),
                address: b['address'] as String?,
                latitude: (b['latitude'] as num?)?.toDouble(),
                longitude: (b['longitude'] as num?)?.toDouble(),

                // pass whatever we have (for initial render; live stream will take over)
                washProgressStages: listStages,
                washStageOrder: orderStages ?? legacyOrder,

                icon: Icon(
                  FontAwesomeIcons.carSide,
                  size: 16,
                  color: const Color.fromARGB(255, 226, 226, 226),
                ),
                scale: 1.7,
                onPressed: () {},
                iconColor: Theme.of(context).colorScheme.primary,
                iconSize: 18,
              );
            },
          );
        },
      ),
    );
  }
}

class BookingsServiceButton extends StatelessWidget {
  // Core fields
  final String service;
  final String? serviceLocation;
  final String? status;
  final String? day;
  final String? time;
  final String? duration;
  final String? price;
  final String? address;
  final double? latitude;
  final double? longitude;

  // Live / static wash progress
  final String? bookingId; // enable live stream in panel
  final String? bookingSenderId; // enable live stream in panel
  final String? bookingRecieverId; // enable live stream in panel
  final List<String>? washStageOrder; // e.g. ["pre_rinse","washing",...]
  final Map<String, dynamic>? washStages; // { pre_rinse: {status,...}, ... }
  final List<dynamic>? washProgressStages; // optional legacy list

  // NEW — decision block (pass-through)
  final String? decisionType; // "confirm" | "decline" | ...
  final String? decisionByUid;
  final String? decisionByName;
  final String? decisionReason; // may be null
  final DateTime? decisionAt; // convert from Timestamp on the caller

  // Visuals / action
  final String? animation;
  final Icon? icon;
  final Color iconColor;
  final double iconSize;
  final double? scale;
  final VoidCallback onPressed;

  const BookingsServiceButton({
    super.key,
    required this.service,
    this.serviceLocation,
    this.status,
    this.day,
    this.time,
    this.duration,
    this.price,
    this.address,
    this.latitude,
    this.longitude,
    this.icon,
    required this.onPressed,
    required this.iconColor,
    required this.iconSize,
    this.animation,
    this.scale,
    this.bookingId,
    this.washStageOrder,
    this.washStages,
    this.washProgressStages,

    // NEW
    this.decisionType,
    this.decisionByUid,
    this.decisionByName,
    this.decisionReason,
    this.decisionAt,
    this.bookingSenderId,
    this.bookingRecieverId,
  });

  @override
  Widget build(BuildContext context) {
    final serviceLabel = _serviceLabel(service);
    final locationLabel = _serviceLocationLabel(serviceLocation);
    final statusLabel = _statusLabel(status);

    return GestureDetector(
      onTap: () => _openDetailsSheet(
        context,
        serviceLabel: serviceLabel,
        locationLabel: locationLabel,
        statusLabel: statusLabel,
        // NEW — forward decision props //
        decisionType: decisionType,
        decisionByUid: decisionByUid,
        decisionByName: decisionByName,
        decisionReason: decisionReason,
        decisionAt: decisionAt,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.inversePrimary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow,
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // service icon tile
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Transform.scale(
                    scale: scale ?? 1.4,
                    child: _serviceIcon(context, serviceLabel),
                  ),
                ),
                const SizedBox(width: 10),

                // right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service + Day
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            serviceLabel,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            day ?? '—',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      // Location + Time
                      Row(
                        children: [
                          Expanded(
                            child: Tooltip(
                              message: locationLabel,
                              child: Text(
                                locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),
                          Text(
                            time ?? '—',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Status pill + Duration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBar(status: statusLabel),
                          Text(
                            duration ?? '—',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      // NEW — tiny decision note (if present)
                      /* if (shortDecision.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                shortDecision,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.surface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ], */
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Status-specific panel (incl. wash progress)
            _statusPanel(
              context,
              statusLabel,
              bookingId: bookingId ?? "",
              bookingRecieverId: bookingRecieverId ?? "",
              bookingSenderId: bookingSenderId ?? "",
              order: washStageOrder,
              stagesMap: washStages,
              listStages: washProgressStages,
              decisionType: decisionType,
              decisionByUid: decisionByUid,
              decisionByName: decisionByName,
              decisionReason: decisionReason,
              decisionAt: decisionAt,
            ),
          ],
        ),
      ),
    );
  }

  String _decisionSummaryShort() {
    final t = (decisionType ?? '').trim().toLowerCase();
    if (t.isEmpty) return '';
    final who = (decisionByName?.trim().isNotEmpty ?? false)
        ? decisionByName!.trim()
        : (decisionByUid?.trim().isNotEmpty ?? false)
        ? 'Driver ${decisionByUid!.substring(0, 6)}'
        : 'Assigned driver';

    final when = (decisionAt != null)
        ? ' • ${DateFormat('MMM d • h:mm a').format(decisionAt!)}'
        : '';
    if (t == 'confirm') return 'Confirmed by $who$when';
    if (t == 'decline') return 'Declined by $who$when';
    return '${t[0].toUpperCase()}${t.substring(1)} by $who$when';
  }

  // ───────── decision helpers ─────────
  String _formatDecisionAt(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  String _who() {
    final n = (decisionByName ?? '').trim();
    final u = (decisionByUid ?? '').trim();
    if (n.isNotEmpty) return n;
    if (u.isNotEmpty) return u;
    return '';
  }

  // Short, single-line for the tile
  /* String _decisionSummaryShort() {
    final t = (decisionType ?? '').trim().toLowerCase();
    final who = _who();
    if (t.isEmpty) return '';
    if (t == 'confirm') {
      return who.isEmpty ? 'Confirmed' : 'Confirmed by $who';
    }
    if (t == 'decline') {
      return who.isEmpty ? 'Declined' : 'Declined by $who';
    }
    return who.isEmpty ? _cap(t) : '${_cap(t)} by $who';
  } */

  // Full, multi-line for the sheet
  List<Widget> _decisionSection(BuildContext context) {
    final t = (decisionType ?? '').trim().toLowerCase();
    if (t.isEmpty) return const [];
    final who = _who();
    final when = _formatDecisionAt(decisionAt);
    final reason = (decisionReason ?? '').trim();

    final color = Theme.of(context).colorScheme.surface;

    String header;
    IconData icon;
    if (t == 'confirm') {
      header = 'Confirmed';
      icon = Icons.verified;
    } else if (t == 'decline') {
      header = 'Declined';
      icon = Icons.cancel_rounded;
    } else {
      header = _cap(t);
      icon = Icons.info_outline;
    }

    return [
      const SizedBox(height: 16),
      Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            header,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (who.isNotEmpty)
        Text('By: $who', style: TextStyle(color: color, fontSize: 13)),
      if (when.isNotEmpty)
        Text('At: $when', style: TextStyle(color: color, fontSize: 13)),
      if (reason.isNotEmpty)
        Text('Reason: $reason', style: TextStyle(color: color, fontSize: 13)),
    ];
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ───────────── Status panel routing ─────────────
  Widget _statusPanel(
    BuildContext context,
    String statusLabel, {
    required String bookingId,
    required String bookingSenderId,
    required String bookingRecieverId,
    List<String>? order,
    Map<String, dynamic>? stagesMap,
    List<dynamic>? listStages,

    // ↓ decision fields (already normalized to the right types)
    String? decisionType,
    String? decisionByUid,
    String? decisionByName,
    String? decisionReason,
    DateTime? decisionAt,
  }) {
    final s = statusLabel.toLowerCase();

    if (s == 'in progress' ||
        s == 'in_progress' ||
        s.contains('currently washing')) {
      final hasSchema =
          (bookingId != null) ||
          ((order?.isNotEmpty ?? false) || (stagesMap?.isNotEmpty ?? false));

      return CurrentlyWashingPanel(
        bookingId: bookingId,
        washStageOrder: order,
        washStages: stagesMap,
        stages: hasSchema ? null : _vmFromFirestoreList(listStages),

        // pass decision info through
        decisionType: decisionType,
        decisionByUid: bookingRecieverId,
        decisionByName: decisionByName,
        decisionReason: decisionReason,
        decisionAt: decisionAt,
        bookingSenderId: bookingSenderId,
      );
    }

    if (s.contains('completed')) return const CompletedPanel();
    if (s.contains('cancel')) return const CancelledPanel();
    if (s.contains('confirmed')) {
      return ConfirmedPanel(
        bookingRecieverId: bookingRecieverId,
        bookingId: bookingId,
        bookingSenderId: bookingSenderId,
        decisionType: decisionType,
        decisionByUid: bookingRecieverId,
        decisionByName: decisionByName,
        decisionReason: decisionReason,
        decisionAt: decisionAt,
      );
    }
    return const PendingPanel();
  }

  // ───────────── Bottom sheet (uses THIS widget’s props) ─────────────
  void _openDetailsSheet(
    BuildContext context, {
    required String serviceLabel,
    required String locationLabel,
    required String statusLabel,

    // NEW — decision props
    String? decisionType,
    String? decisionByUid,
    String? decisionByName,
    String? decisionReason,
    DateTime? decisionAt,
  }) {
    final text = Theme.of(context).textTheme;

    // Chip palette (unchanged)
    Color chipBg, chipBorder, chipFg, panelBg, panelBorder, dot;
    String chipText;
    final s = statusLabel.toLowerCase();
    final isInProgress = s.contains('progress') || s == 'in_progress';
    final isInConfirmed = s.contains('confirm') || s == 'confirmed';

    if (s.contains('pending')) {
      chipBg = const Color(0xFFFFF7DA);
      chipBorder = const Color(0xFFFFE08A);
      chipFg = const Color(0xFF946200);
      panelBg = const Color(0xFFFFFBEB);
      panelBorder = const Color(0xFFFFE08A);
      dot = const Color(0xFFF7B500);
      chipText = 'Awaiting Confirmation';
    } else if (s.contains('confirmed')) {
      chipBg = const Color(0xFFEFFFF3);
      chipBorder = const Color(0xFFB7E5C6);
      chipFg = const Color(0xFF146C43);
      panelBg = const Color(0xFFF1FFF7);
      panelBorder = const Color(0xFFB7E5C6);
      dot = const Color(0xFF23A067);
      chipText = 'Confirmed';
    } else if (isInProgress) {
      chipBg = const Color(0xFFFFF7ED);
      chipBorder = const Color(0xFFFED7AA);
      chipFg = const Color(0xFFC2410C);
      panelBg = const Color(0xFFFFF4E5);
      panelBorder = const Color(0xFFFED7AA);
      dot = const Color(0xFFF97316);
      chipText = 'In Progress';
    } else if (s.contains('cancel')) {
      chipBg = const Color(0xFFFFEEEE);
      chipBorder = const Color(0xFFFFC3C3);
      chipFg = const Color(0xFF8A1224);
      panelBg = const Color(0xFFFFF5F5);
      panelBorder = const Color(0xFFFFC3C3);
      dot = const Color(0xFFD32F2F);
      chipText = 'Cancelled';
    } else {
      chipBg = const Color(0xFFDBEAFE);
      chipBorder = const Color(0xFF93C5FD);
      chipFg = const Color(0xFF1D4ED8);
      panelBg = const Color(0xFFEFF6FF);
      panelBorder = const Color(0xFF93C5FD);
      dot = const Color(0xFF3B82F6);
      chipText = statusLabel;
    }

    // NEW — build a human-friendly decision summary
    String _decisionSummary() {
      final t = (decisionType ?? '').trim().toLowerCase();
      if (t.isEmpty) return '';
      final who = (decisionByName?.trim().isNotEmpty ?? false)
          ? decisionByName!.trim()
          : (decisionByUid?.trim().isNotEmpty ?? false)
          ? 'Driver ${decisionByUid!.substring(0, 6)}'
          : 'Assigned driver';
      final when = (decisionAt != null)
          ? ' • ${DateFormat('MMM d • h:mm a').format(decisionAt!)}'
          : '';
      final label = t == 'confirm'
          ? 'Confirmed'
          : t == 'decline'
          ? 'Declined'
          : '${t[0].toUpperCase()}${t.substring(1)}';
      final reason = (decisionReason?.trim().isNotEmpty ?? false)
          ? ' — ${decisionReason!.trim()}'
          : '';
      return '$label by $who$when$reason';
    }

    Widget infoTile(IconData icon, String title, String value) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: panelBg,
          border: Border.all(color: panelBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: chipFg),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: text.titleSmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget statusHelpPanel() {
      String title, body;
      if (s.contains('pending')) {
        title = 'Awaiting Confirmation';
        body =
            "Your booking request is being reviewed and will be confirmed shortly.";
      } else if (s.contains('confirmed')) {
        title = 'Confirmed';
        body = "You're all set. See you at the scheduled time!";
      } else if (isInProgress) {
        title = 'In Progress';
        body = "Your car is being washed right now.";
      } else if (s.contains('cancel')) {
        title = 'Cancelled';
        body = "This booking was cancelled.";
      } else if (s.contains('complete')) {
        title = 'Completed';
        body = "This booking has been completed. Thanks!";
      } else {
        title = statusLabel;
        body = "Booking status: $statusLabel";
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: panelBg,
          border: Border.all(color: panelBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: chipFg,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: text.bodyMedium?.copyWith(
                      color: text.bodyMedium?.color?.withOpacity(.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.75,
          initialChildSize: 0.70,
          minChildSize: 0.70,
          builder: (context, controller) {
            final decisionLine = _decisionSummary();

            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      _serviceIcon(context, serviceLabel),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          serviceLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                      ),
                    ],
                  ),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_pin, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Tooltip(
                          message: locationLabel,
                          child: Text(
                            locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Status chip
                  Container(
                    decoration: BoxDecoration(
                      color: chipBg,
                      border: Border.all(color: chipBorder),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      chipText,
                      style: TextStyle(
                        color: chipFg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // NEW — decision note under the chip (if any)
                  if (decisionLine.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.verified, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            decisionLine,
                            style: text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Details grid
                  Row(
                    children: [
                      Expanded(
                        child: infoTile(Icons.event, 'Date', day ?? '—'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: infoTile(
                          Icons.access_time,
                          'Duration',
                          (duration ?? '—').replaceFirst('⏱️ ', ''),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: infoTile(Icons.schedule, 'Time', time ?? '—'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: infoTile(
                          FontAwesomeIcons.car,
                          'Price',
                          price == null ? '—' : '₵$price',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(
                    color: Theme.of(context).dividerColor.withOpacity(.6),
                  ),
                  const SizedBox(height: 16),

                  if (isInConfirmed)
                    ConfirmedPanelModalSHeet(
                      bookingRecieverId: bookingRecieverId ?? "",
                      bookingId: bookingId ?? "",
                      bookingSenderId: bookingSenderId ?? "",
                      decisionType: decisionType,
                      decisionByUid: bookingRecieverId,
                      decisionByName: decisionByName,
                      decisionReason: decisionReason,
                      decisionAt: decisionAt,
                    ),

                  // In-progress panel or help text
                  if (isInProgress)
                    CurrentlyWashingPanelModalSheet(
                      bookingId: bookingId ?? "", // you'll already pass this in
                      washStageOrder: washStageOrder,
                      washStages: washStages,
                      stages: _vmFromFirestoreList(washProgressStages),
                      decisionType: decisionType,
                      decisionByUid: decisionByUid ?? "",
                      decisionByName: decisionByName,
                      decisionReason: decisionReason,
                      decisionAt: decisionAt,
                      bookingSenderId: bookingSenderId ?? "",
                    ),
                  if (!isInConfirmed && !isInProgress) statusHelpPanel(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ───────────── helpers: labels & icons ─────────────
  String _serviceLabel(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'express') return 'Express Wash';
    if (s == 'standard') return 'Standard Wash';
    if (s == 'premium') return 'Premium Detail';
    return raw;
  }

  String _serviceLocationLabel(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    switch (s) {
      case 'mobile':
        return '📍 Mobile Service';
      case 'washing_bay':
      case 'onsite':
      case 'on_site':
        return '🏁 Washing Bay';
      case 'valet':
        return '🅿️ Valet Service';
      default:
        return raw == null || raw.isEmpty ? '—' : raw;
    }
  }

  String _statusLabel(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    switch (s) {
      case 'pending':
      case 'pending_cash':
      case 'awaiting_payment':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
      case 'washing':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return raw == null || raw.isEmpty ? '—' : raw;
    }
  }

  Widget _serviceIcon(BuildContext context, String label) {
    final color = Theme.of(context).colorScheme.primary;
    if (label.toLowerCase().contains('express')) {
      return Icon(FontAwesomeIcons.shower, color: color, size: 18);
    }
    if (label.toLowerCase().contains('standard')) {
      return Icon(Icons.alarm, color: color, size: 20);
    }
    return SvgPicture.asset(
      'assets/icons/cleaning.svg',
      height: 24,
      width: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  /// Adapt a legacy `List<dynamic>` of stages to view models (optional fallback).
  static List<WashStageVM>? _vmFromFirestoreList(List<dynamic>? raw) {
    if (raw == null) return null;
    final out = <WashStageVM>[];

    for (final item in raw) {
      if (item is String) {
        final key = item.trim();
        if (key.isEmpty) continue;
        out.add(WashStageVM(key, _labelFromKey(key), 'pending'));
      } else if (item is Map) {
        final key = (item['key'] ?? item['stage'] ?? item['name'] ?? '')
            .toString()
            .trim();
        if (key.isEmpty) continue;
        final status = _normalizeStageStatus(item['status']?.toString());
        final label = (item['label'] ?? _labelFromKey(key)).toString();
        out.add(WashStageVM(key, label, status));
      }
    }

    if (out.isEmpty) {
      return _kStageOrder
          .map((k) => WashStageVM(k, _labelFromKey(k), 'pending'))
          .toList();
    }

    final index = {
      for (var i = 0; i < _kStageOrder.length; i++) _kStageOrder[i]: i,
    };
    out.sort((a, b) => (index[a.key] ?? 999).compareTo(index[b.key] ?? 999));
    return out;
  }

  static String _normalizeStageStatus(String? s) {
    final v = (s ?? '').trim().toLowerCase();
    if (v == 'done' || v == 'completed') return 'done';
    if (v == 'in_progress' ||
        v == 'in_progress' ||
        v == 'in-progress' ||
        v == 'active' ||
        v == 'processing') {
      return 'in_progress';
    }
    return 'pending';
  }

  static String _labelFromKey(String k) {
    switch (k) {
      case 'pre_rinse':
        return 'Pre-rinse';
      case 'washing':
        return 'Washing';
      case 'rinsing':
        return 'Rinsing';
      case 'cleaning':
        return 'Cleaning';
      default:
        final pretty = k.replaceAll('_', ' ').trim();
        if (pretty.isEmpty) return 'Stage';
        return pretty[0].toUpperCase() + pretty.substring(1);
    }
  }
}

class CompletedPanel extends StatelessWidget {
  const CompletedPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 232, 238, 251),
        border: Border.all(
          color: Color.fromARGB(255, 106, 148, 233),
          width: 1.7,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: Color.fromARGB(255, 59, 104, 195),
                    size: IconSizes.tiny,
                  ),
                  const SizedBox(width: 5),
                  CustomText(
                    text: 'Wash Completed',
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.bold,
                    textColor: Color.fromARGB(255, 4, 47, 187),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 7),
          Row(
            children: [
              CustomText(
                text: 'Your car wash has been completed successfully!',
                textSize: TextSizes.bodyText2,
                textColor: Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CancelledPanel extends StatelessWidget {
  const CancelledPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 251, 232, 232),
        border: Border.all(
          color: Color.fromARGB(255, 233, 106, 106),
          width: 1.7,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: Color.fromARGB(255, 195, 59, 59),
                    size: IconSizes.tiny,
                  ),
                  const SizedBox(width: 5),
                  CustomText(
                    text: 'Wash Cancelled',
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.bold,
                    textColor: Color.fromARGB(255, 187, 4, 4),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 7),
          Row(
            children: [
              CustomText(
                text: 'Your wash has been cancelled!',
                textSize: TextSizes.bodyText2,
                textColor: Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CurrentlyWashingPanel extends StatelessWidget {
  // Live mode: pass bookingId to stream changes from Firestore
  final String bookingId;

  // Static fallback data (used if bookingId is null, or for first paint)
  final List<String>?
  washStageOrder; // ["pre_rinse","washing","rinsing","cleaning"]
  final Map<String, dynamic>? washStages; // { pre_rinse: {...}, ... }
  final List<WashStageVM>? stages; // optional prebuilt VMs

  // Decision/assignment info (can be overridden by live snapshot)
  final String? decisionType; // "confirm" | "decline" | ...
  final String decisionByUid;
  final String bookingSenderId;
  final String? decisionByName;
  final String? decisionReason;
  final DateTime? decisionAt;

  const CurrentlyWashingPanel({
    super.key,
    required this.bookingId,
    this.washStageOrder,
    this.washStages,
    this.stages,
    this.decisionType,
    required this.decisionByUid,
    this.decisionByName,
    this.decisionReason,
    this.decisionAt,
    required this.bookingSenderId,
  });

  // --- look & feel (orange theme) ---
  static const Color _accent = Color(0xFFF97316);
  static const Color _accentSoft = Color.fromARGB(37, 237, 165, 114);
  static const Color _accentBorder = Color.fromARGB(112, 211, 88, 0);
  static const Color _trackGrey = Color.fromARGB(153, 179, 179, 181);

  static const List<String> _defaultOrder = [
    'pre_rinse',
    'washing',
    'rinsing',
    'cleaning',
  ];

  @override
  Widget build(BuildContext context) {
    // LIVE: stream the booking doc
    if (bookingId != null) {
      final docRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId);
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snap) =>
            _shell(child: _innerFromSnap(context, snap)),
      );
    }

    // STATIC: build from props
    final items =
        stages ??
        _buildFromRaw(washStageOrder, washStages, bookingStatus: null);
    return _shell(
      child: _panel(
        context,
        items,
        // pass static decision info
        decisionType: decisionType,
        decisionByUid: decisionByUid,
        decisionByName: decisionByName,
        decisionReason: decisionReason,
        decisionAt: decisionAt,
      ),
    );
  }

  // ============== helpers ==============

  // Outer container
  Widget _shell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _accentBorder, width: 1.7),
        borderRadius: BorderRadius.circular(20),
        color: _accentSoft,
      ),
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }

  // Build from a live snapshot (and read decision fields if present)
  Widget _innerFromSnap(
    BuildContext context,
    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snap,
  ) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const SizedBox(height: 46);
    }
    if (!snap.hasData || !snap.data!.exists) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No wash data yet.......',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    final data = snap.data!.data() ?? <String, dynamic>{};

    // Prefer flat schema; fall back to legacy `washProgress.order`
    final order =
        (data['washStageOrder'] as List?)?.cast<String>() ??
        (data['washProgress']?['order'] as List?)?.cast<String>();

    final stagesMap = (data['washStages'] as Map?)?.cast<String, dynamic>();
    final bookingStatus = '${data['status'] ?? ''}';

    // Decision (live) — override constructor values when available
    final dec = (data['decision'] as Map?)?.cast<String, dynamic>();
    final liveType = dec?['type']?.toString();
    final liveByName = dec?['byName']?.toString();
    final liveByUid = dec?['byUid']?.toString();
    final liveReason = dec?['reason']?.toString();
    DateTime? liveAt;
    final atRaw = dec?['at'];
    if (atRaw is Timestamp) {
      liveAt = atRaw.toDate();
    } else if (atRaw is String) {
      liveAt = DateTime.tryParse(atRaw);
    }

    final items = _buildFromRaw(order, stagesMap, bookingStatus: bookingStatus);

    return _panel(
      context,
      items,
      decisionType: liveType ?? decisionType,
      decisionByUid: liveByUid ?? decisionByUid,
      decisionByName: liveByName ?? decisionByName,
      decisionReason: liveReason ?? decisionReason,
      decisionAt: liveAt ?? decisionAt,
    );
  }

  // Build list of stage VMs from order/map (and infer when data is partial)
  List<WashStageVM> _buildFromRaw(
    List<String>? order,
    Map<String, dynamic>? map, {
    String? bookingStatus,
  }) {
    final o = (order == null || order.isEmpty) ? _defaultOrder : order;

    // clone map
    final m = <String, Map<String, dynamic>>{};
    for (final entry in (map ?? const <String, dynamic>{}).entries) {
      m[entry.key] = Map<String, dynamic>.from(entry.value ?? const {});
    }

    String _norm(dynamic s) {
      final v = '${s ?? ''}'.trim().toLowerCase();
      if (v == 'done' || v == 'completed') return 'done';
      if (v == 'in_progress' ||
          v == 'in-progress' ||
          v == 'active' ||
          v == 'processing') {
        return 'in_progress';
      }
      return 'pending';
    }

    int activeIndex = -1;
    for (int i = 0; i < o.length; i++) {
      final key = o[i];
      if (_norm(m[key]?['status']) == 'in_progress') {
        activeIndex = i;
        break;
      }
    }

    final List<WashStageVM> list = [];
    for (int i = 0; i < o.length; i++) {
      final key = o[i];
      String status = _norm(m[key]?['status']);

      if (activeIndex >= 0) {
        if ((m[key] == null || m[key]!['status'] == null) && i < activeIndex) {
          status = 'done';
        }
        if ((m[key] == null || m[key]!['status'] == null) && i > activeIndex) {
          status = 'pending';
        }
      } else if ((map == null || map.isEmpty) &&
          (bookingStatus ?? '').toLowerCase().contains('progress')) {
        status = (i == 0) ? 'in_progress' : 'pending';
      }

      list.add(WashStageVM(key, _labelForKey(key), status));
    }

    return list;
  }

  // Safe initials (no RangeError on empty/one-word names)
  String _initialsFrom(String? fullName) {
    final s = (fullName ?? '').trim();
    if (s.isEmpty) return '??';
    final parts = s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final first = parts.isNotEmpty ? parts[0] : '';
    final second = parts.length > 1 ? parts[1] : '';
    final i1 = first.isNotEmpty ? first[0] : '';
    final i2 = second.isNotEmpty ? second[0] : '';
    final out = ('$i1$i2').toUpperCase();
    return out.isEmpty ? s[0].toUpperCase() : out;
  }

  String _prettyDecisionType(String? t) {
    final v = (t ?? '').trim().toLowerCase();
    if (v == 'confirm') return 'Confirmed';
    if (v == 'decline') return 'Declined';
    if (v.isEmpty) return 'Assigned';
    return v[0].toUpperCase() + v.substring(1);
  }

  // Paint the progress row (all segments visible) + driver/decision card
  Widget _panel(
    BuildContext context,
    List<WashStageVM> items, {
    String? decisionType,
    required String decisionByUid,
    String? decisionByName,
    String? decisionReason,
    DateTime? decisionAt,
  }) {
    final baseName = (decisionByName?.trim().isNotEmpty ?? false)
        ? decisionByName!.trim()
        : (decisionByUid?.trim().isNotEmpty ?? false)
        ? 'Driver ${decisionByUid!.substring(0, 6)}'
        : 'Assigned Driver';

    final decTypeLabel = _prettyDecisionType(decisionType);
    final whenLabel = (decisionAt != null)
        ? ' • ${DateFormat('MMM d • h:mm a').format(decisionAt)}'
        : '';

    // ---------- stages row (unchanged) ----------
    final stagesRow = Column(
      children: [
        Row(
          children: const [
            Icon(Icons.circle, color: _accent, size: 8),
            SizedBox(width: 6),
            Text(
              'Wash Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(items.length, (i) {
            final first = i == 0;
            final last = i == items.length - 1;
            final stage = items[i];

            final isDone = stage.status == 'done';
            final isActive = stage.status == 'in_progress';
            final barColor = (isDone || isActive) ? _accent : _trackGrey;

            return Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    height: 4,
                    margin: EdgeInsets.only(
                      left: first ? 5 : 0,
                      right: last ? 5 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(first ? 10 : 0),
                        bottomLeft: Radius.circular(first ? 10 : 0),
                        topRight: Radius.circular(last ? 10 : 0),
                        bottomRight: Radius.circular(last ? 10 : 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _StageChip(
                      key: ValueKey('${stage.key}_${stage.status}'),
                      index: i + 1,
                      status: stage.status,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stage.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 15),
      ],
    );

    // ---------- driver card (uses photoUrl when available; initials fallback) ----------
    Widget _driverCard({required String name, String? photoUrl}) {
      final initials = _initialsFrom(name);

      // Only create an ImageProvider if the URL is non-empty.
      ImageProvider? _netIfValid(String? url) {
        if (url == null) return null;
        final u = url.trim();
        if (u.isEmpty) return null;
        return NetworkImage(u);
      }

      final img = _netIfValid(photoUrl);

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.inversePrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
        child: Row(
          children: [
            const SizedBox(width: 5),
            CircleAvatar(
              radius: 18,
              backgroundColor: _accentSoft,
              foregroundImage: img,
              // Only provide the error handler when foregroundImage is non-null
              onForegroundImageError: (img != null)
                  ? (_, __) {
                      /* no-op */
                    }
                  : null,
              // Initials are always provided; they'll show if there's no image or it fails.
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: TextSizes.subtitle1,
                  color: _accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: TextSizes.bodyText1,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Subtitle (ellipsized)
                  Text(
                    'Professional Washer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: TextSizes.caption,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              children: [
                RegularButton(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  borderRadius: 15,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  textWidget: const CustomText(
                    text: 'Call',
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.bold,
                  ),
                  onPressed: () {}, // wire up if you store driver phone
                ),
                const SizedBox(width: 5),
                RegularIconButton(
                  icon: const Icon(Icons.chat, size: IconSizes.minute),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  borderRadius: 15,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  textWidget: const CustomText(
                    text: 'Chat',
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.bold,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => BookingsChat(
                          bookingId: bookingId,
                          bookingRecieverId: decisionByUid,
                          bookingSenderId: bookingSenderId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(width: 5),
          ],
        ),
      );
    }

    // ---------- if we have a uid, stream user doc to read photoUrl ----------
    if (decisionByUid != null && decisionByUid!.trim().isNotEmpty) {
      final uid = decisionByUid!.trim();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      return Column(
        children: [
          stagesRow,
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userRef.snapshots(),
            builder: (context, snap) {
              String name = baseName;
              String? photoUrl;

              if (snap.hasData && snap.data!.exists) {
                final u = snap.data!.data() ?? const {};

                // Try common field names
                photoUrl =
                    (u['photoUrl'] as String?) ??
                    (u['photoURL'] as String?) ??
                    (u['avatarUrl'] as String?) ??
                    (u['avatar'] as String?);

                // Prefer an explicit name if we didn't get one in props
                if (!(decisionByName?.trim().isNotEmpty ?? false)) {
                  name =
                      (u['displayName'] as String?) ??
                      (u['name'] as String?) ??
                      baseName;
                }
              }

              return _driverCard(name: name, photoUrl: photoUrl);
            },
          ),
        ],
      );
    }

    // ---------- no uid → just render with initials ----------
    return Column(
      children: [
        stagesRow,
        _driverCard(name: baseName, photoUrl: null),
      ],
    );
  }

  // Pretty label for a stage key
  String _labelForKey(String k) {
    switch (k) {
      case 'pre_rinse':
        return 'Pre-rinse';
      case 'washing':
        return 'Washing';
      case 'rinsing':
        return 'Rinsing';
      case 'cleaning':
        return 'Cleaning';
      default:
        final pretty = k.replaceAll('_', ' ').trim();
        if (pretty.isEmpty) return 'Stage';
        return pretty[0].toUpperCase() + pretty.substring(1);
    }
  }
}

class CurrentlyWashingPanelModalSheet extends StatelessWidget {
  // Live mode: pass bookingId to stream changes from Firestore
  final String bookingId;

  // Static fallback data (used if bookingId is null, or for first paint)
  final List<String>?
  washStageOrder; // ["pre_rinse","washing","rinsing","cleaning"]
  final Map<String, dynamic>? washStages; // { pre_rinse: {...}, ... }
  final List<WashStageVM>? stages; // optional prebuilt VMs

  // Decision/assignment info (can be overridden by live snapshot)
  final String? decisionType; // "confirm" | "decline" | ...
  final String decisionByUid;
  final String bookingSenderId;
  final String? decisionByName;
  final String? decisionReason;
  final DateTime? decisionAt;

  const CurrentlyWashingPanelModalSheet({
    super.key,
    required this.bookingId,
    this.washStageOrder,
    this.washStages,
    this.stages,
    this.decisionType,
    required this.decisionByUid,
    this.decisionByName,
    this.decisionReason,
    this.decisionAt,
    required this.bookingSenderId,
  });

  // --- look & feel (orange theme) ---
  static const Color _accent = Color(0xFFF97316);
  static const Color _accentSoft = Color.fromARGB(37, 237, 165, 114);
  static const Color _accentBorder = Color.fromARGB(112, 211, 88, 0);
  static const Color _trackGrey = Color.fromARGB(153, 179, 179, 181);

  static const List<String> _defaultOrder = [
    'pre_rinse',
    'washing',
    'rinsing',
    'cleaning',
  ];

  @override
  Widget build(BuildContext context) {
    // LIVE: stream the booking doc
    if (bookingId != null) {
      final docRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId);
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snap) =>
            _shell(child: _innerFromSnap(context, snap)),
      );
    }

    // STATIC: build from props
    final items =
        stages ??
        _buildFromRaw(washStageOrder, washStages, bookingStatus: null);
    return _shell(
      child: _panel(
        context,
        items,
        // pass static decision info
        decisionType: decisionType,
        decisionByUid: decisionByUid,
        decisionByName: decisionByName,
        decisionReason: decisionReason,
        decisionAt: decisionAt,
      ),
    );
  }

  // ============== helpers ==============

  // Outer container
  Widget _shell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _accentBorder, width: 1.7),
        borderRadius: BorderRadius.circular(20),
        color: _accentSoft,
      ),
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }

  // Build from a live snapshot (and read decision fields if present)
  Widget _innerFromSnap(
    BuildContext context,
    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snap,
  ) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const SizedBox(height: 46);
    }
    if (!snap.hasData || !snap.data!.exists) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No wash data yet',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    final data = snap.data!.data() ?? <String, dynamic>{};

    // Prefer flat schema; fall back to legacy `washProgress.order`
    final order =
        (data['washStageOrder'] as List?)?.cast<String>() ??
        (data['washProgress']?['order'] as List?)?.cast<String>();

    final stagesMap = (data['washStages'] as Map?)?.cast<String, dynamic>();
    final bookingStatus = '${data['status'] ?? ''}';

    // Decision (live) — override constructor values when available
    final dec = (data['decision'] as Map?)?.cast<String, dynamic>();
    final liveType = dec?['type']?.toString();
    final liveByName = dec?['byName']?.toString();
    final liveByUid = dec?['byUid']?.toString();
    final liveReason = dec?['reason']?.toString();
    DateTime? liveAt;
    final atRaw = dec?['at'];
    if (atRaw is Timestamp) {
      liveAt = atRaw.toDate();
    } else if (atRaw is String) {
      liveAt = DateTime.tryParse(atRaw);
    }

    final items = _buildFromRaw(order, stagesMap, bookingStatus: bookingStatus);

    return _panel(
      context,
      items,
      decisionType: liveType ?? decisionType,
      decisionByUid: liveByUid ?? decisionByUid,
      decisionByName: liveByName ?? decisionByName,
      decisionReason: liveReason ?? decisionReason,
      decisionAt: liveAt ?? decisionAt,
    );
  }

  // Build list of stage VMs from order/map (and infer when data is partial)
  List<WashStageVM> _buildFromRaw(
    List<String>? order,
    Map<String, dynamic>? map, {
    String? bookingStatus,
  }) {
    final o = (order == null || order.isEmpty) ? _defaultOrder : order;

    // clone map
    final m = <String, Map<String, dynamic>>{};
    for (final entry in (map ?? const <String, dynamic>{}).entries) {
      m[entry.key] = Map<String, dynamic>.from(entry.value ?? const {});
    }

    String _norm(dynamic s) {
      final v = '${s ?? ''}'.trim().toLowerCase();
      if (v == 'done' || v == 'completed') return 'done';
      if (v == 'in_progress' ||
          v == 'in-progress' ||
          v == 'active' ||
          v == 'processing') {
        return 'in_progress';
      }
      return 'pending';
    }

    int activeIndex = -1;
    for (int i = 0; i < o.length; i++) {
      final key = o[i];
      if (_norm(m[key]?['status']) == 'in_progress') {
        activeIndex = i;
        break;
      }
    }

    final List<WashStageVM> list = [];
    for (int i = 0; i < o.length; i++) {
      final key = o[i];
      String status = _norm(m[key]?['status']);

      if (activeIndex >= 0) {
        if ((m[key] == null || m[key]!['status'] == null) && i < activeIndex) {
          status = 'done';
        }
        if ((m[key] == null || m[key]!['status'] == null) && i > activeIndex) {
          status = 'pending';
        }
      } else if ((map == null || map.isEmpty) &&
          (bookingStatus ?? '').toLowerCase().contains('progress')) {
        status = (i == 0) ? 'in_progress' : 'pending';
      }

      list.add(WashStageVM(key, _labelForKey(key), status));
    }

    return list;
  }

  // Safe initials (no RangeError on empty/one-word names)
  String _initialsFrom(String? fullName) {
    final s = (fullName ?? '').trim();
    if (s.isEmpty) return '??';
    final parts = s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final first = parts.isNotEmpty ? parts[0] : '';
    final second = parts.length > 1 ? parts[1] : '';
    final i1 = first.isNotEmpty ? first[0] : '';
    final i2 = second.isNotEmpty ? second[0] : '';
    final out = ('$i1$i2').toUpperCase();
    return out.isEmpty ? s[0].toUpperCase() : out;
  }

  String _prettyDecisionType(String? t) {
    final v = (t ?? '').trim().toLowerCase();
    if (v == 'confirm') return 'Confirmed';
    if (v == 'decline') return 'Declined';
    if (v.isEmpty) return 'Assigned';
    return v[0].toUpperCase() + v.substring(1);
  }

  // Small helper to build an ImageProvider from URL (or null)
  ImageProvider? _imageFromUrl(String? url) {
    if (url == null) return null;
    final u = url.trim();
    if (u.isEmpty) return null;
    return NetworkImage(u);
  }

  // Driver card with avatar (image or initials fallback) and meta line
  Widget _driverCard(
    BuildContext context, {
    required String name,
    String? photoUrl,
    required String
    metaText, // e.g., 'Confirmed • Oct 25 • 4:59 PM' or 'Professional Washer'
  }) {
    final initials = _initialsFrom(name);
    final img = _imageFromUrl(photoUrl);
    final hasUrl = photoUrl != null && photoUrl.trim().isNotEmpty;
    final size = 80.0; // same visual size as radius:18
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
      child: Row(
        children: [
          const SizedBox(width: 7),

          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(12), // <-- rounded corners
            ),
            clipBehavior: Clip.antiAlias, // ensure image respects radius
            child: hasUrl
                ? Image.network(
                    photoUrl!.trim(),
                    fit: BoxFit.cover,
                    // Fallback to initials if the image fails to load
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: TextSizes.subtitle1,
                          color: _accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: TextSizes.subtitle1,
                        color: _accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: TextSizes.bodyText1,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                // Subtitle (ellipsized)
                Text(
                  'Professional Washer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: TextSizes.caption,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              RegularIconButton(
                icon: const Icon(Icons.phone, size: IconSizes.minute),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                borderRadius: 15,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                textWidget: const CustomText(
                  text: 'Call',
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
                onPressed: () {},
              ),
              const SizedBox(height: 6),
              RegularIconButton(
                icon: const Icon(Icons.chat, size: IconSizes.minute),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                borderRadius: 15,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                textWidget: const CustomText(
                  text: 'Chat',
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => BookingsChat(
                        bookingId: bookingId,
                        bookingRecieverId: decisionByUid,
                        bookingSenderId: bookingSenderId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  // Paint the progress row (all segments visible) + driver/decision card
  Widget _panel(
    BuildContext context,
    List<WashStageVM> items, {
    String? decisionType,
    String? decisionByUid,
    String? decisionByName,
    String? decisionReason,
    DateTime? decisionAt,
  }) {
    final baseName = (decisionByName?.trim().isNotEmpty ?? false)
        ? decisionByName!.trim()
        : (decisionByUid?.trim().isNotEmpty ?? false)
        ? 'Driver ${decisionByUid!.substring(0, 6)}'
        : 'Assigned Driver';

    final decTypeLabel = _prettyDecisionType(decisionType);
    final whenLabel = (decisionAt != null)
        ? ' • ${DateFormat('MMM d • h:mm a').format(decisionAt)}'
        : '';
    final metaText = decTypeLabel.isEmpty
        ? 'Professional Washer'
        : '$decTypeLabel$whenLabel';

    // ---------- stages row ----------
    final stagesRow = Column(
      children: [
        Row(
          children: const [
            Icon(Icons.circle, color: _accent, size: 8),
            SizedBox(width: 6),
            Text(
              'Wash Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(items.length, (i) {
            final first = i == 0;
            final last = i == items.length - 1;
            final stage = items[i];

            final isDone = stage.status == 'done';
            final isActive = stage.status == 'in_progress';
            final barColor = (isDone || isActive) ? _accent : _trackGrey;

            return Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    height: 4,
                    margin: EdgeInsets.only(
                      left: first ? 5 : 0,
                      right: last ? 5 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(first ? 10 : 0),
                        bottomLeft: Radius.circular(first ? 10 : 0),
                        topRight: Radius.circular(last ? 10 : 0),
                        bottomRight: Radius.circular(last ? 10 : 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _StageChip(
                      key: ValueKey('${stage.key}_${stage.status}'),
                      index: i + 1,
                      status: stage.status,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stage.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 15),
      ],
    );

    // ---------- if we have a uid, stream user doc to read photoUrl ----------
    if (decisionByUid != null && decisionByUid!.trim().isNotEmpty) {
      final uid = decisionByUid!.trim();
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      return Column(
        children: [
          stagesRow,
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userRef.snapshots(),
            builder: (context, snap) {
              String name = baseName;
              String? photoUrl;

              if (snap.hasData && snap.data!.exists) {
                final u = snap.data!.data() ?? const {};
                photoUrl = (u['photoUrl'] as String?);
                // prefer decisionByName if provided; else use profile displayName/name; else base
                name = (decisionByName?.trim().isNotEmpty ?? false)
                    ? decisionByName!.trim()
                    : (u['displayName'] as String?) ??
                          (u['name'] as String?) ??
                          baseName;
              }

              return _driverCard(
                context,
                name: name,
                photoUrl: photoUrl,
                metaText: metaText,
              );
            },
          ),
        ],
      );
    }

    // ---------- no uid → just render with initials ----------
    return Column(
      children: [
        stagesRow,
        _driverCard(
          context,
          name: baseName,
          photoUrl: null,
          metaText: metaText,
        ),
      ],
    );
  }

  // Pretty label for a stage key
  String _labelForKey(String k) {
    switch (k) {
      case 'pre_rinse':
        return 'Pre-rinse';
      case 'washing':
        return 'Washing';
      case 'rinsing':
        return 'Rinsing';
      case 'cleaning':
        return 'Cleaning';
      default:
        final pretty = k.replaceAll('_', ' ').trim();
        if (pretty.isEmpty) return 'Stage';
        return pretty[0].toUpperCase() + pretty.substring(1);
    }
  }
}

class PendingPanel extends StatelessWidget {
  const PendingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFFFBF8E8),
        border: Border.all(color: Color(0xFFE9C56A), width: 1.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: Color.fromARGB(255, 195, 152, 59),
                    size: IconSizes.tiny,
                  ),
                  const SizedBox(width: 5),
                  CustomText(
                    text: 'Awaiting Confirmation',
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.bold,
                    textColor: Color.fromARGB(255, 187, 129, 4),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 7),
          CustomText(
            text:
                'Your booking request is being reviewed and will be confirmed shortly.',
            textSize: TextSizes.bodyText2,
            textColor: Theme.of(context).colorScheme.surface,
          ),
        ],
      ),
    );
  }
}

class ConfirmedPanel extends StatelessWidget {
  // Required
  final String bookingRecieverId;
  final String bookingId;
  final String bookingSenderId;

  // Decision/assignment (optional – will be overridden by live user doc name/photo when available)
  final String? decisionType; // "confirm" | "decline" | ...
  final String? decisionByUid; // usually the assigned driver's uid
  final String? decisionByName;
  final String? decisionReason;
  final DateTime? decisionAt;

  const ConfirmedPanel({
    super.key,
    required this.bookingRecieverId,
    required this.bookingId,
    required this.bookingSenderId,
    this.decisionType,
    this.decisionByUid,
    this.decisionByName,
    this.decisionReason,
    this.decisionAt,
  });

  // ——— palette (green theme for confirmed) ———
  static const Color _accent = Color(0xFF2ECC71);
  static const Color _accentText = Color.fromARGB(255, 0, 102, 10);
  static const Color _accentSoft = Color.fromARGB(19, 0, 158, 16);
  static const Color _accentBorder = Color.fromARGB(88, 0, 158, 16);
  static const Color _avatarBg = Color(0xFFDFF6E3);

  String _initialsFrom(String? fullName) {
    final s = (fullName ?? '').trim();
    if (s.isEmpty) return '??';
    final parts = s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final first = parts.isNotEmpty ? parts[0] : '';
    final second = parts.length > 1 ? parts[1] : '';
    final i1 = first.isNotEmpty ? first[0] : '';
    final i2 = second.isNotEmpty ? second[0] : '';
    final out = ('$i1$i2').toUpperCase();
    return out.isEmpty ? s[0].toUpperCase() : out;
  }

  String _prettyDecisionType(String? t) {
    final v = (t ?? '').trim().toLowerCase();
    if (v == 'confirm') return 'Confirmed';
    if (v == 'decline') return 'Declined';
    if (v.isEmpty) return 'Assigned';
    return v[0].toUpperCase() + v.substring(1);
  }

  Widget _driverCard({
    required BuildContext context,
    required String name,
    String? photoUrl,
  }) {
    final initials = _initialsFrom(name);

    // Only create an ImageProvider if the URL is non-empty.
    ImageProvider? _netIfValid(String? url) {
      if (url == null) return null;
      final u = url.trim();
      if (u.isEmpty) return null;
      return NetworkImage(u);
    }

    final img = _netIfValid(photoUrl);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inversePrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
      child: Row(
        children: [
          const SizedBox(width: 5),
          CircleAvatar(
            radius: 18,
            backgroundColor: _accentSoft,
            foregroundImage: img,
            // Only provide the error handler when foregroundImage is non-null
            onForegroundImageError: (img != null)
                ? (_, __) {
                    /* no-op */
                  }
                : null,
            // Initials are always provided; they'll show if there's no image or it fails.
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: TextSizes.subtitle1,
                color: _accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: TextSizes.bodyText1,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                // Subtitle (ellipsized)
                Text(
                  'Professional Washer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: TextSizes.caption,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              RegularButton(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                borderRadius: 15,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                textWidget: const CustomText(
                  text: 'Call',
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
                onPressed: () {}, // wire up if you store driver phone
              ),
              const SizedBox(width: 5),
              RegularIconButton(
                icon: const Icon(Icons.chat, size: IconSizes.minute),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                borderRadius: 15,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                textWidget: const CustomText(
                  text: 'Chat',
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => BookingsChat(
                        bookingId: bookingId,
                        bookingRecieverId: decisionByUid!,
                        bookingSenderId: bookingSenderId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prefer explicit decisionByUid; otherwise fall back to the receiver id
    final rawUid = (decisionByUid != null && decisionByUid!.trim().isNotEmpty)
        ? decisionByUid!.trim()
        : bookingRecieverId.trim();

    // Base name while waiting for user doc
    final shortId = rawUid.length >= 6 ? rawUid.substring(0, 6) : rawUid;
    final baseName = (decisionByName?.trim().isNotEmpty ?? false)
        ? decisionByName!.trim()
        : (rawUid.isNotEmpty ? 'Driver $shortId' : 'Assigned Driver');

    final decTypeLabel = _prettyDecisionType(decisionType);
    final whenLabel = (decisionAt != null)
        ? ' • ${DateFormat('MMM d • h:mm a').format(decisionAt!)}'
        : '';

    // shell
    Widget shell(Widget child) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _accentSoft,
        border: Border.all(color: _accentBorder, width: 1.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );

    // header + message
    Widget header() => Column(
      children: [
        Row(
          children: const [
            Icon(Icons.circle, color: _accent, size: IconSizes.tiny),
            SizedBox(width: 5),
            CustomText(
              text: 'Booking Confirmed',
              textSize: TextSizes.bodyText1,
              textWeight: FontWeight.bold,
              textColor: _accentText,
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            CustomText(
              text: "You're all set. See you at the scheduled time!",
              textSize: TextSizes.bodyText3,
              textColor: Theme.of(context).colorScheme.surface,
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );

    // Live-read the user doc for photoUrl/displayName
    if (rawUid.isNotEmpty) {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(rawUid);
      return shell(
        Column(
          children: [
            header(),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: userRef.snapshots(),
              builder: (context, snap) {
                String name = baseName;
                String? photoUrl;

                if (snap.hasData && snap.data!.exists) {
                  final u = snap.data!.data() ?? const {};
                  // Try common keys
                  photoUrl =
                      (u['photoUrl'] as String?) ??
                      (u['photoURL'] as String?) ??
                      (u['avatarUrl'] as String?) ??
                      (u['avatar'] as String?);

                  if (!(decisionByName?.trim().isNotEmpty ?? false)) {
                    name =
                        (u['displayName'] as String?) ??
                        (u['name'] as String?) ??
                        baseName;
                  }
                }

                return _driverCard(
                  context: context,
                  name: name,
                  photoUrl: photoUrl,
                );
              },
            ),
          ],
        ),
      );
    }

    // No uid → just show initials (no photo)
    return shell(
      Column(
        children: [
          header(),
          _driverCard(context: context, name: baseName, photoUrl: null),
        ],
      ),
    );
  }
}

class ConfirmedPanelModalSHeet extends StatelessWidget {
  // Required
  final String bookingRecieverId;
  final String bookingId;
  final String bookingSenderId;

  // Decision/assignment (optional – will be overridden by live user doc name/photo when available)
  final String? decisionType; // "confirm" | "decline" | ...
  final String? decisionByUid; // usually the assigned driver's uid
  final String? decisionByName;
  final String? decisionReason;
  final DateTime? decisionAt;

  const ConfirmedPanelModalSHeet({
    super.key,
    required this.bookingRecieverId,
    required this.bookingId,
    required this.bookingSenderId,
    this.decisionType,
    this.decisionByUid,
    this.decisionByName,
    this.decisionReason,
    this.decisionAt,
  });

  // ——— palette (green theme for confirmed) ———
  static const Color _accent = Color(0xFF2ECC71);
  static const Color _accentText = Color.fromARGB(255, 0, 102, 10);
  static const Color _accentSoft = Color.fromARGB(19, 0, 158, 16);
  static const Color _accentBorder = Color.fromARGB(88, 0, 158, 16);
  static const Color _avatarBg = Color(0xFFDFF6E3);

  String _initialsFrom(String? fullName) {
    final s = (fullName ?? '').trim();
    if (s.isEmpty) return '??';
    final parts = s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final first = parts.isNotEmpty ? parts[0] : '';
    final second = parts.length > 1 ? parts[1] : '';
    final i1 = first.isNotEmpty ? first[0] : '';
    final i2 = second.isNotEmpty ? second[0] : '';
    final out = ('$i1$i2').toUpperCase();
    return out.isEmpty ? s[0].toUpperCase() : out;
  }

  String _prettyDecisionType(String? t) {
    final v = (t ?? '').trim().toLowerCase();
    if (v == 'confirm') return 'Confirmed';
    if (v == 'decline') return 'Declined';
    if (v.isEmpty) return 'Assigned';
    return v[0].toUpperCase() + v.substring(1);
  }

  Widget _roundedAvatar({
    required BuildContext context,
    required String displayName,
    String? photoUrl,
    double size = 76,
    double radius = 15,
  }) {
    final initials = _initialsFrom(displayName);

    Widget initialsBox() => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _avatarBg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: TextSizes.subtitle1,
          color: _accentText,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (photoUrl == null || photoUrl.trim().isEmpty) return initialsBox();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _avatarBg,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        photoUrl.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => initialsBox(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // prefer the explicit decisionByUid; otherwise fall back to the receiver id
    final uid = (decisionByUid != null && decisionByUid!.trim().isNotEmpty)
        ? decisionByUid!.trim()
        : bookingRecieverId.trim();

    // base name shown while waiting for user doc
    final baseName = (decisionByName?.trim().isNotEmpty ?? false)
        ? decisionByName!.trim()
        : (uid.isNotEmpty
              ? 'Driver ${uid.substring(0, uid.length.clamp(0, 6))}'
              : 'Assigned Driver');

    final decTypeLabel = _prettyDecisionType(decisionType);
    final whenLabel = (decisionAt != null)
        ? ' • ${DateFormat('MMM d • h:mm a').format(decisionAt!)}'
        : '';

    // UI shell
    Widget shell(Widget child) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _accentSoft,
        border: Border.all(color: _accentBorder, width: 1.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );

    // header + message
    Widget header() => Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.circle, color: _accent, size: IconSizes.tiny),
                SizedBox(width: 5),
                CustomText(
                  text: 'Booking Confirmed',
                  textSize: TextSizes.bodyText1,
                  textWeight: FontWeight.bold,
                  textColor: _accentText,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            CustomText(
              text: "You're all set. See you at the scheduled time!",
              textSize: TextSizes.bodyText3,
              textColor: Theme.of(context).colorScheme.surface,
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );

    // driver row builder
    Widget driverRow({required String displayName, String? photoUrl}) =>
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.inversePrimary,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
          child: Row(
            children: [
              const SizedBox(width: 7),
              _roundedAvatar(
                context: context,
                displayName: displayName,
                photoUrl: photoUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: TextSizes.bodyText1,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Subtitle (ellipsized)
                    Text(
                      'Professional Washer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: TextSizes.caption,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  RegularIconButton(
                    icon: const Icon(Icons.phone, size: IconSizes.minute),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    borderRadius: 15,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    textWidget: const CustomText(
                      text: 'Call',
                      textSize: TextSizes.bodyText1,
                      textWeight: FontWeight.bold,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => BookingsChat(
                            bookingId: bookingId,
                            bookingRecieverId: bookingRecieverId,
                            bookingSenderId: bookingSenderId,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 7),
                  RegularIconButton(
                    icon: const Icon(Icons.chat, size: IconSizes.minute),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    borderRadius: 15,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    textWidget: const CustomText(
                      text: 'Chat',
                      textSize: TextSizes.bodyText1,
                      textWeight: FontWeight.bold,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => BookingsChat(
                            bookingId: bookingId,
                            bookingRecieverId: bookingRecieverId,
                            bookingSenderId: bookingSenderId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(width: 5),
            ],
          ),
        );

    // If we have a uid, live-read the user doc for photoUrl/displayName
    if (uid.isNotEmpty) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      return shell(
        Column(
          children: [
            header(),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: userRef.snapshots(),
              builder: (context, snap) {
                String name = baseName;
                String? photoUrl;

                if (snap.hasData && snap.data!.exists) {
                  final u = snap.data!.data() ?? const {};
                  photoUrl = (u['photoUrl'] as String?);
                  // prefer passed decisionByName; otherwise fall back to profile fields
                  name = (decisionByName?.trim().isNotEmpty ?? false)
                      ? decisionByName!.trim()
                      : (u['displayName'] as String?) ??
                            (u['name'] as String?) ??
                            baseName;
                }

                return driverRow(displayName: name, photoUrl: photoUrl);
              },
            ),
          ],
        ),
      );
    }

    // No uid → just render with initials (no photo)
    return shell(
      Column(
        children: [
          header(),
          driverRow(displayName: baseName, photoUrl: null),
        ],
      ),
    );
  }
}

class StatusBar extends StatelessWidget {
  final String status;
  const StatusBar({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg, fg;
    if (s == 'pending') {
      bg = const Color.fromARGB(121, 255, 234, 113);
      fg = const Color.fromARGB(255, 187, 129, 4);
    } else if (s == 'confirmed') {
      bg = const Color.fromARGB(121, 180, 255, 180);
      fg = const Color.fromARGB(255, 4, 129, 4);
    } else if (s.contains('progress')) {
      bg = const Color.fromARGB(121, 255, 200, 120);
      fg = const Color.fromARGB(255, 187, 80, 4);
    } else if (s == 'completed') {
      bg = const Color.fromARGB(121, 120, 158, 255);
      fg = const Color.fromARGB(255, 4, 37, 129);
    } else {
      bg = const Color.fromARGB(121, 255, 120, 120);
      fg = const Color.fromARGB(255, 129, 4, 4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        s == 'pending'
            ? 'Pending'
            : s == 'in progress'
            ? 'Currently Washing'
            : s == 'confirmed'
            ? 'Confirmed'
            : s == 'completed'
            ? 'Completed'
            : 'Cancelled',
        style: TextStyle(fontWeight: FontWeight.bold, color: fg, fontSize: 12),
      ),
    );
  }
}

class _NoGlowScroll extends ScrollBehavior {
  const _NoGlowScroll();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class _ListLoading extends StatelessWidget {
  const _ListLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: CircularProgressIndicator(),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
  );
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).disabledColor),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class FadingCircle extends StatefulWidget {
  final int number;
  final double size;

  const FadingCircle({super.key, required this.number, this.size = 24});

  @override
  _FadingCircleState createState() => _FadingCircleState();
}

class _FadingCircleState extends State<FadingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color.fromARGB(255, 247, 163, 104), // Orange color
        ),
        alignment: Alignment.center,
        child: Text(
          widget.number.toString(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final int index;
  final String status; // done | in_progress | pending
  const _StageChip({super.key, required this.index, required this.status});

  static const Color _accent = Color(0xFFF97316);
  static const Color _greyBg = Color.fromARGB(153, 179, 179, 181);
  static const Color _greyFg = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    if (status == 'done') {
      return const Icon(Icons.check_circle, size: 20, color: _accent);
    }
    if (status == 'in_progress') {
      return FadingCircle(number: index, size: 20);
    }
    return CircleAvatar(
      backgroundColor: _greyBg,
      radius: 10,
      child: Text(
        '$index',
        style: const TextStyle(
          color: _greyFg,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
