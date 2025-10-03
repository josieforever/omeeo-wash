import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
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
              color: Color.fromARGB(60, 0, 0, 0),
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
                          ? AppColors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      textSize: TextSizes.bodyText1,
                      textWeight: FontWeight.bold,
                    ),
                    textWidget2 == null
                        ? SizedBox()
                        : CustomText(
                            text: textWidget2!,
                            textColor: isSelected
                                ? AppColors.white
                                : Theme.of(context).textTheme.bodyMedium?.color,
                            textSize: TextSizes.bodyText1,
                          ),
                    CustomText(
                      text: textWidget3,
                      textColor: isSelected
                          ? AppColors.white
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
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final double borderRadius;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const RegularButton({
    super.key,
    required this.onPressed,
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
          color: const Color.fromARGB(80, 0, 0, 0),
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
                    icon,
                    if (numberWidget != null) ...[
                      const SizedBox(height: 8),
                      numberWidget!,
                    ],
                    const SizedBox(height: 5),
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
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.inversePrimary,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(26, 0, 0, 0),
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
                  textColor: Theme.of(context).textTheme.headlineLarge?.color,
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
              textColor: Theme.of(context).textTheme.headlineLarge?.color,
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
              ? Theme.of(context).textTheme.headlineLarge?.color
              : const Color.fromARGB(0, 255, 255, 255),
          borderRadius: BorderRadius.circular(7),
          border: widget.border,
        ),
        // fixed height
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
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
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: topNavProvider.isTabSelected(widget.textWidget)
                    ? const Color.fromARGB(255, 232, 222, 241)
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

class BookingsServiceButton extends StatelessWidget {
  final String textWidget1;
  final String? animation;
  final String? textWidget2;
  final String? status;
  final String? time;
  final String? duration;
  final String? day;
  final String? price;
  final String? stars;
  final Icon? icon;
  final Color iconColor;
  final double iconSize;
  final double? scale;
  final VoidCallback onPressed;
  const BookingsServiceButton({
    super.key,
    required this.textWidget1,
    this.textWidget2,
    this.price,
    this.icon,
    required this.onPressed,
    required this.iconColor,
    required this.iconSize,
    this.stars,
    this.animation,
    this.scale,
    this.status,
    this.time,
    this.duration,
    this.day,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          backgroundColor: Colors.white,
          isScrollControlled: true, // Makes it full height if needed
          builder: (context) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  margin: const EdgeInsets.all(15),
                  width:
                      constraints.maxWidth * 0.89, // take all available width
                  height: 680,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Wrap content
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Booking Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Service: Express Clean"),
                      const Text("Date: Monday, 26th Aug"),
                      const Text("Time: 10:30 AM"),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth, // make it responsive
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: Theme.of(context).textTheme.headlineLarge?.color,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(26, 12, 0, 235),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 6), // x, y
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(
                              top: 20,
                              bottom: 20,
                              left: 20,
                              right: 25,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              gradient: const LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Color(0xFF6D66F6), // Right
                                  Color(0xFFA558F2), // Left
                                ],
                              ),
                            ),
                            child: Transform.scale(
                              scale: scale,
                              child: Icon(
                                textWidget1 == 'Express Clean'
                                    ? Icons.local_car_wash_outlined
                                    : textWidget1 == 'Premium Detail'
                                    ? FontAwesomeIcons.sprayCan
                                    : FontAwesomeIcons.shower,
                                size: TextSizes.bodyText1,
                                color: const Color.fromARGB(255, 226, 226, 226),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Expanded ensures the right column flexes to fill space
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 13,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                text: textWidget1,
                                textColor: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                textSize: TextSizes.bodyText1,
                                textWeight: FontWeight.bold,
                              ),
                              CustomText(
                                text: day!,
                                textSize: TextSizes.bodyText1,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomText(
                                text: textWidget2!,
                                textColor: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                                textSize: TextSizes.bodyText1,
                              ),
                              CustomText(
                                text: time!,
                                textSize: TextSizes.bodyText1,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              StatusBar(status: 'Pending'),
                              CustomText(
                                text: duration!,
                                textSize: TextSizes.bodyText1,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                PendingPanel(),
                const SizedBox(height: 10),
                ConfirmedPanel(),
                const SizedBox(height: 10),
                CurrentlyWashingPanel(),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
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
          borderRadius: BorderRadius.circular(7),
          color: Theme.of(context).textTheme.headlineLarge?.color,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(26, 12, 0, 235),
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
                    color: Color.fromARGB(32, 137, 43, 226),
                    borderRadius: BorderRadius.circular(10),
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
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color.fromARGB(154, 255, 145, 145)),
          color: Theme.of(context).textTheme.headlineLarge?.color,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(26, 12, 0, 235),
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
                    color: Color.fromARGB(32, 137, 43, 226),
                    borderRadius: BorderRadius.circular(10),
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
                  textColor: Theme.of(context).textTheme.headlineLarge?.color,
                  textSize: TextSizes.heading1,
                  textWeight: FontWeight.bold,
                ),

                CustomText(
                  text: 'points',
                  textColor: Theme.of(context).textTheme.headlineLarge?.color,
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
          backgroundColor: bgColor ?? const Color.fromARGB(78, 255, 255, 255),
          // backgroundColor: Colors.red,
          child: Center(
            child: Transform.scale(
              scale: 1.2,
              child: Icon(
                Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* class PaymentIconStackTextButton extends StatelessWidget {
  final Widget textWidget;
  final Widget? numberWidget;
  final Icon icon;
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
    required this.icon,
    required this.textWidget,
    this.numberWidget,
    required this.onPressed,
    this.backgroundColor,
    this.border,
    required this.borderRadius,
    this.padding,
    this.margin,
    this.gradient,
    this.width,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            numberWidget == null ? const SizedBox() : const SizedBox(height: 8),
            numberWidget == null ? const SizedBox() : numberWidget!,
            const SizedBox(height: 5),
            textWidget,
          ],
        ),
      ),
    );
  }
} */

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

class PendingPanel extends StatelessWidget {
  const PendingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFFFBF8E8),
        border: Border.all(color: Color(0xFFE9C56A)),
        borderRadius: BorderRadius.circular(7),
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
              CustomText(
                text: 'Pending approval',
                textSize: TextSizes.bodyText3,
                textColor: Color.fromARGB(255, 192, 143, 36),
              ),
            ],
          ),
          const SizedBox(width: 7),
          CustomText(
            text:
                'Your booking request is being reviewed and will be confirmed shortly.',
            textSize: TextSizes.bodyText2,
            textColor: Color.fromARGB(255, 192, 143, 36),
          ),
        ],
      ),
    );
  }
}

class ConfirmedPanel extends StatelessWidget {
  const ConfirmedPanel({super.key});

  String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials("John Doe");

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color.fromARGB(19, 0, 158, 16),
        border: Border.all(color: Color.fromARGB(88, 0, 158, 16)),
        borderRadius: BorderRadius.circular(7),
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
                    color: Color(0xFF2ECC71),
                    size: IconSizes.tiny,
                  ),
                  const SizedBox(width: 5),
                  CustomText(
                    text: 'Booking Confirmed',
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.normal,
                    textColor: Color.fromARGB(255, 0, 102, 10),
                  ),
                ],
              ),
              /* CustomText(
                text: 'Ready to start',
                textSize: TextSizes.bodyText2,
                textColor: Color.fromARGB(255, 0, 158, 16),
              ), */
              CustomText(
                text: '5 min away',
                textSize: TextSizes.bodyText3,
                textColor: Color.fromARGB(255, 0, 158, 16),
              ),
            ],
          ),
          const SizedBox(width: 7),

          /* CustomText(
            text:
                'Your car wash is confirmed and will begin shortly at the schedules time.',
            textSize: TextSizes.bodyText2,
            textColor: Color.fromARGB(255, 0, 158, 16),
          ),
          Divider(color: Color.fromARGB(159, 51, 181, 64)), */
          const SizedBox(height: 10),
          /* Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 236, 236, 236),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  text: 'Google Maps Integration',
                  textSize: TextSizes.bodyText2,
                ),
                const SizedBox(height: 10),
                CustomText(
                  text: 'Add your Google Maps API key to enable live ',
                  textSize: TextSizes.bodyText2,
                ),
                const SizedBox(height: 10),
                CustomText(text: 'tracking', textSize: TextSizes.bodyText2),
              ],
            ),
          ), */
          LiveLocationProgressBar(),
          const SizedBox(height: 10),
          /* Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme.headlineLarge?.color,
              borderRadius: BorderRadius.circular(7),
            ),
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFDFF6E3),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: TextSizes.subtitle2,
                      color: Color.fromARGB(255, 0, 102, 10),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: 'John Doe',
                      textSize: TextSizes.bodyText2,
                      textWeight: FontWeight.bold,
                    ),
                    CustomText(
                      text: 'Professional Washer',
                      textSize: TextSizes.caption,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CustomText(text: '4.9', textSize: TextSizes.caption),
                        const SizedBox(width: 5),
                        Icon(
                          FontAwesomeIcons.solidStar,
                          size: 10,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ],
                ),

                RegularIconButton(
                  onPressed: () {},
                  border: Border.all(color: Color(0xFF2ECC71)),
                  icon: Icon(
                    Icons.phone,
                    color: Color(0xFF2ECC71),
                    size: IconSizes.small,
                  ),
                  borderRadius: 5,
                  textWidget: CustomText(
                    text: 'Chat',
                    textColor: Color.fromARGB(255, 0, 102, 10),
                    textSize: TextSizes.bodyText1,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                ),
                RegularIconButton(
                  onPressed: () {},
                  border: Border.all(color: Color(0xFF2ECC71)),
                  icon: Icon(
                    Icons.chat,
                    size: IconSizes.small,
                    color: Color(0xFF2ECC71),
                  ),
                  borderRadius: 5,
                  textWidget: CustomText(
                    text: 'Chat',
                    textColor: Color.fromARGB(255, 0, 102, 10),
                    textSize: TextSizes.bodyText1,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                ),
              ],
            ),
          ), */
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme.headlineLarge?.color,
              borderRadius: BorderRadius.circular(7),
            ),
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 5),
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFDFF6E3),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: TextSizes.bodyText1,
                      color: Color.fromARGB(255, 0, 102, 10),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CustomText(
                  text: 'John Doe',
                  textSize: TextSizes.bodyText2,
                  textWeight: FontWeight.bold,
                ),
                const SizedBox(width: 10),
                CustomText(
                  text: 'Professional Washer',
                  textSize: TextSizes.caption,
                ),
                const SizedBox(width: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText(text: '4.9', textSize: TextSizes.caption),
                    const SizedBox(width: 5),
                    Icon(
                      FontAwesomeIcons.solidStar,
                      size: 10,
                      color: Colors.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class CurrentlyWashingPanel extends StatefulWidget {
  const CurrentlyWashingPanel({super.key});

  @override
  State<CurrentlyWashingPanel> createState() => _CurrentlyWashingPanelState();
}

class _CurrentlyWashingPanelState extends State<CurrentlyWashingPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color.fromARGB(112, 211, 88, 0)),
        borderRadius: BorderRadius.circular(10),
        color: Color.fromARGB(153, 229, 231, 235),
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Wash Progress',
                textSize: TextSizes.bodyText1,
                textWeight: FontWeight.bold,
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              CustomText(
                text: '25 min left',
                textSize: TextSizes.bodyText3,
                textWeight: FontWeight.w500,
                textColor: Color.fromARGB(255, 211, 88, 0),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      margin: EdgeInsets.only(left: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.check_circle,
                      size: 24,
                      color: const Color(0xFFF97316),
                    ),
                    const SizedBox(height: 5),
                    CustomText(
                      text: 'Pre-rinse',
                      textColor: const Color(0xFFF97316),
                      textSize: TextSizes.bodyText2,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFF97316)),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.check_circle,
                      size: 24,
                      color: const Color(0xFFF97316),
                    ),
                    const SizedBox(height: 5),
                    CustomText(
                      text: 'Washing',
                      textColor: const Color(0xFFF97316),
                      textSize: TextSizes.bodyText2,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(153, 179, 179, 181),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadingCircle(number: 3),
                    const SizedBox(height: 5),
                    CustomText(
                      text: 'Rinsing',
                      textColor: Color(0xFF6B7280),
                      textSize: TextSizes.bodyText2,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      margin: EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(153, 179, 179, 181),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    CircleAvatar(
                      backgroundColor: Color.fromARGB(153, 179, 179, 181),
                      radius: 12,
                      child: CustomText(
                        text: '4',
                        textColor: Color(0xFF6B7280),
                        textWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),
                    CustomText(
                      text: 'Cleaning',
                      textColor: Color(0xFF6B7280),
                      textSize: TextSizes.bodyText2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* 

// Main Orange (progress bar, active step, "25 min left" text)
const Color kOrange = Color(0xFFF97316);

// Light Gray (progress bar background, step 4 background)
const Color kLightGray = Color(0xFFE5E7EB);

// Dark Gray (step 4 text)
const Color kDarkGray = Color(0xFF6B7280);

// Light Orange (step 3 background)
const Color kLightOrange = Color(0xFFFCD9B6);

// White (card background, checkmark inside circles)
const Color kWhite = Color(0xFFFFFFFF);

// Almost Black (section title "Wash Progress")
const Color kAlmostBlack = Color(0xFF111827); 

*/

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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class StatusBar extends StatelessWidget {
  final String status;
  const StatusBar({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      decoration: BoxDecoration(
        color: status == 'Pending'
            ? const Color.fromARGB(121, 255, 234, 113)
            : status == 'Currently Washing'
            ? Color.fromARGB(121, 255, 200, 120)
            : Color.fromARGB(121, 180, 255, 180),
        borderRadius: BorderRadius.circular(50),
      ),
      child: CustomText(
        text: status == 'Pending'
            ? 'Pending'
            : status == 'Currently Washing'
            ? 'Currently Washing'
            : 'Waiting to Start',
        textSize: TextSizes.bodyText1,
        textWeight: FontWeight.bold,
        textColor: status == 'Pending'
            ? Color.fromARGB(255, 187, 129, 4)
            : status == 'Currently Washing'
            ? Color.fromARGB(255, 187, 80, 4)
            : Color.fromARGB(255, 4, 129, 4),
      ),
    );
  }
}
