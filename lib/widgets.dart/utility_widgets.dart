import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:omeeowash/providers/top_nav_provider.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:provider/provider.dart';

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
  final Color? backgroundColor;
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
    this.backgroundColor,
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
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          color: const Color.fromARGB(47, 255, 255, 255),
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
}

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
                        textColor: Theme.of(context).textTheme.bodyLarge?.color,
                        textSize: TextSizes.subtitle1,
                        textWeight: FontWeight.bold,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: '₵$price',
                        textColor: Theme.of(context).colorScheme.primary,
                        textSize: TextSizes.subtitle1,
                        textWeight: FontWeight.w800,
                      ),
                      const SizedBox(height: 30),
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
              Color(0xFF6D66F6), // Right (periwinkle blue-purple)
              Color(0xFFA558F2),
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
                  borderRadius: 7,
                  backgroundColor: Theme.of(
                    context,
                  ).textTheme.headlineLarge?.color,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  textWidget: CustomText(
                    text: 'Claim Now',
                    textColor: Theme.of(context).colorScheme.primary,
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.normal,
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
        padding: widget.textWidget == 'Pending'
            ? EdgeInsets.symmetric(vertical: 5, horizontal: 10)
            : EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        margin: widget.margin,
        child: Center(
          child: Row(
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
    return Container(
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
      child: Column(
        children: [
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.only(
                      top: 20,
                      bottom: 20,
                      left: 20,
                      right: 25,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: const [
                          Color(0xFF6D66F6), // Right (periwinkle blue-purple)
                          Color(0xFFA558F2), // Left (light pink-purple)
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
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomText(
                          text: '₵$price',
                          textColor: Theme.of(context).colorScheme.primary,
                          textSize: TextSizes.subtitle1,
                          textWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 5),
                        Icon(
                          FontAwesomeIcons.chevronRight,
                          color: Theme.of(context).colorScheme.primary,
                          size: TextSizes.caption,
                        ),
                      ],
                    ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(text: day!, textSize: TextSizes.bodyText1),
                  const SizedBox(width: 10),
                  CustomText(text: time!, textSize: TextSizes.bodyText1),
                  const SizedBox(width: 10),
                  CustomText(text: duration!, textSize: TextSizes.bodyText1),
                ],
              ),

              RegularButton(
                onPressed: () {},
                borderRadius: 15,
                backgroundColor: status! == 'Confirmed'
                    ? const Color.fromARGB(76, 129, 199, 132)
                    : status! == 'Completed'
                    ? const Color.fromARGB(87, 0, 89, 255)
                    : const Color.fromARGB(73, 212, 197, 33),
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                textWidget: CustomText(
                  text: status!,
                  textColor: status! == 'Confirmed'
                      ? const Color.fromARGB(255, 0, 119, 6)
                      : status! == 'Completed'
                      ? const Color.fromARGB(255, 0, 10, 146)
                      : const Color.fromARGB(255, 119, 81, 0),
                  textSize: TextSizes.bodyText2,
                  textWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
                color: Theme.of(context).textTheme.bodyLarge?.color,
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
