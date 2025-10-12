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

/// Uses your app’s CustomText, TextSizes, IconSizes, StatusBar,
/// PendingPanel, ConfirmedPanel, CurrentlyWashingPanel widgets.

class BookingsServiceButton extends StatelessWidget {
  // Core display props (all optional-safe)
  final String service; // e.g. "Express Wash" or "express"
  final String?
  serviceLocation; // e.g. "mobile" | "washing_bay" | "valet" or label
  final String?
  status; // e.g. "pending_cash" | "confirmed" | "in_progress" | "completed"
  final String? day; // e.g. "🗓️ Today"
  final String? time; // e.g. "⌚ 12:00"
  final String? duration; // e.g. "⏱️ 90 min"
  final String? price; // e.g. "150"
  final String? address; // optional human address
  final double? latitude; // optional coords
  final double? longitude;

  // Visuals
  final String? animation;
  final Icon? icon;
  final Color iconColor;
  final double iconSize;
  final double? scale;

  // Tap action (kept for your flow)
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
  });

  @override
  Widget build(BuildContext context) {
    // Friendly labels
    final String serviceLabel = _serviceLabel(service);
    final String locationLabel = _serviceLocationLabel(serviceLocation);
    final String statusLabel = _statusLabel(status);

    return GestureDetector(
      onTap: () => _openDetailsSheet(
        context,
        serviceLabel: serviceLabel,
        locationLabel: locationLabel,
        statusLabel: statusLabel,
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
                // Leading service icon in a soft tile
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
                // Right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Service + day
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            text: serviceLabel,
                            textColor: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.color,
                            textSize: TextSizes.bodyText1,
                            textWeight: FontWeight.bold,
                          ),
                          CustomText(
                            text: day ?? '—',
                            textSize: TextSizes.bodyText1,
                          ),
                        ],
                      ),
                      // Middle row: Location + time
                      Row(
                        children: [
                          // Left: location, single line with ellipsis
                          Expanded(
                            child: Tooltip(
                              // optional: long-press to see full address
                              message: locationLabel ?? '',
                              child: Text(
                                locationLabel ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  fontSize:
                                      TextSizes.bodyText1, // keep your sizing
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),
                          // Right: time
                          Text(
                            time ?? '—',
                            style: TextStyle(
                              fontSize: TextSizes.bodyText1,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Bottom row: Status + duration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Your StatusBar, now dynamic
                          StatusBar(status: statusLabel),
                          CustomText(
                            text: duration ?? '—',
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

            // Show only the relevant status panel (no clutter)
            _statusPanel(statusLabel),
          ],
        ),
      ),
    );
  }

  // ——————————————————————————————————————————
  // Helpers
  // ——————————————————————————————————————————

  void _openDetailsSheet(
    BuildContext context, {
    required String serviceLabel,
    required String locationLabel,
    required String statusLabel,
  }) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // — Status chip palette
    Color chipBg, chipBorder, chipFg, panelBg, panelBorder, dot;
    String chipText;
    final s = statusLabel.toLowerCase();
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
    } else if (s.contains('progress')) {
      chipBg = const Color(0xFFEEF6FF);
      chipBorder = const Color(0xFFBFDFFF);
      chipFg = const Color(0xFF0B63B6);
      panelBg = const Color(0xFFF4F9FF);
      panelBorder = const Color(0xFFBFDFFF);
      dot = const Color(0xFF0B63B6);
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
      // Blue theme (light)
      chipBg = const Color(0xFFDBEAFE); // blue-100
      chipBorder = const Color(0xFF93C5FD); // blue-300
      chipFg = const Color(0xFF1D4ED8); // blue-600
      panelBg = const Color(0xFFEFF6FF); // blue-50
      panelBorder = const Color(0xFF93C5FD); // blue-300
      dot = const Color(0xFF3B82F6); // blue-500
      chipText = statusLabel;
    }

    // Small label + value tile (for grid items)
    Widget infoTile(IconData icon, String label, String value) {
      return Row(
        children: [
          Icon(icon, size: 25, color: Theme.of(context).colorScheme.surface),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: text.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      );
    }

    // Context help panel under the divider
    Widget statusHelpPanel() {
      String title;
      String body;
      if (s.contains('pending')) {
        title = 'Awaiting Confirmation';
        body =
            "Your booking request is being reviewed and will be confirmed shortly. You'll receive a notification once it's approved.";
      } else if (s.contains('confirmed')) {
        title = 'Confirmed';
        body = "You're all set. See you at the scheduled time!";
      } else if (s.contains('progress')) {
        title = 'In Progress';
        body =
            "Your car is being washed right now. We'll notify you when it's done.";
      } else if (s.contains('cancel')) {
        title = 'Cancelled';
        body =
            "This booking was cancelled. If this was a mistake, please book again.";
      } else if (s.contains('complete')) {
        title = 'Completed';
        body = "This booking has been completed. Thanks for choosing us!";
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
            // dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            // texts
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
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.92,
          initialChildSize: 0.75,
          minChildSize: 0.45,
          builder: (context, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Close
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Service icon widget (monochrome-friendly)
                      serviceLabel.contains('express')
                          ? Icon(
                              FontAwesomeIcons.shower,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            )
                          : serviceLabel.contains('standard')
                          ? Icon(
                              Icons.alarm,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            )
                          :
                            // Premium → your SVG
                            SvgPicture.asset(
                              'assets/icons/cleaning.svg',
                              height: 40,
                              width: 40,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                            ),

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
                  const SizedBox(height: 16),

                  // 2x2 details grid
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
                          duration?.replaceFirst('⏱️ ', '') ?? '—',
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

                  // Context help panel
                  statusHelpPanel(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _kvRow(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Pick the right status panel
  Widget _statusPanel(String statusLabel) {
    switch (statusLabel.toLowerCase()) {
      case 'pending':
        return PendingPanel();
      case 'confirmed':
        return ConfirmedPanel();
      case 'in_progress':
        return CurrentlyWashingPanel();
      case 'completed':
        return CompletedPanel();
      case 'cancelled':
        return CancelledPanel();
      default:
        return const SizedBox.shrink();
    }
  }

  // Friendly service label (accepts code or label)
  String _serviceLabel(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'express') return 'Express Wash';
    if (s == 'standard') return 'Standard Wash';
    if (s == 'premium') return 'Premium Detail';
    // If dev passed already-formatted text, keep it
    return raw;
  }

  // Friendly location label with emoji
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
        // If dev passed "📍Omeeo Car wash" keep it as-is.
        return raw == null || raw.isEmpty ? '—' : raw;
    }
  }

  // Map backend status → readable label
  String _statusLabel(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    switch (s) {
      case 'pending':
        return 'pending';
      case 'confirmed':
        return 'confirmed';
      case 'in_progress':
        return 'in_progress';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return raw == null || raw.isEmpty ? '—' : raw;
    }
  }

  // Service icon widget (monochrome-friendly)
  Widget _serviceIcon(BuildContext context, String label) {
    final color = Theme.of(context).colorScheme.primary;
    if (label.toLowerCase().contains('express')) {
      return Icon(FontAwesomeIcons.shower, color: color, size: 18);
    }
    if (label.toLowerCase().contains('standard')) {
      return Icon(Icons.alarm, color: color, size: 20);
    }
    // Premium → your SVG
    return SvgPicture.asset(
      'assets/icons/cleaning.svg',
      height: 24,
      width: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
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
        border: Border.all(color: Color.fromARGB(88, 0, 158, 16), width: 1.7),
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
                    color: Color(0xFF2ECC71),
                    size: IconSizes.tiny,
                  ),
                  const SizedBox(width: 5),
                  CustomText(
                    text: 'Booking Confirmed',
                    textSize: TextSizes.bodyText1,
                    textWeight: FontWeight.bold,
                    textColor: Color.fromARGB(255, 0, 102, 10),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 7),
          Row(
            children: [
              CustomText(
                text: "You're all set. See you at the scheduled time!",
                textSize: TextSizes.bodyText2,
                textColor: Theme.of(context).colorScheme.surface,
              ),
            ],
          ),

          /*  LiveLocationProgressBar(), */
          /* Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
              borderRadius: BorderRadius.circular(17),
            ),
            padding: EdgeInsets.symmetric(horizontal: 1, vertical: 5),
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
          ), */
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

/// Optional tiny VM if you want to pass prebuilt stages.
/// If you already have a WashStageVM elsewhere, remove this.
class WashStageVM {
  final String key; // pre_rinse, washing, rinsing, cleaning
  final String label; // Pre-rinse, Washing, Rinsing, Cleaning
  final String status; // pending | in_progress | done
  const WashStageVM(this.key, this.label, this.status);
}

/// Dynamic wash progress panel
class CurrentlyWashingPanel extends StatelessWidget {
  /// EITHER pass raw Firestore fields:
  final List<String>?
  washStageOrder; // e.g. ["pre_rinse","washing","rinsing","cleaning"]
  final Map<String, dynamic>?
  washStages; // map of { stageKey: { status, startedAt?, completedAt? } }

  /// OR pass already-built VMs:
  final List<WashStageVM>? stages;

  const CurrentlyWashingPanel({
    super.key,
    this.washStageOrder,
    this.washStages,
    this.stages,
  });

  // ----- palette (orange theme, like your mock) -----
  static const Color _accent = Color(0xFFF97316); // orange
  static const Color _accentSoft = Color.fromARGB(37, 237, 165, 114);
  static const Color _accentBorder = Color.fromARGB(112, 211, 88, 0);
  static const Color _trackGrey = Color.fromARGB(153, 179, 179, 181);
  static const Color _labelGrey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    // Build stage list
    final items = stages ?? _buildStagesFromRaw(washStageOrder, washStages);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _accentBorder, width: 1.7),
        borderRadius: BorderRadius.circular(20),
        color: _accentSoft,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Header
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

          // Segments + chips + labels
          Row(
            children: List.generate(items.length, (i) {
              final first = i == 0;
              final last = i == items.length - 1;
              final stage = items[i];

              // bar color by status
              final isDone = stage.status == 'done';
              final isActive = stage.status == 'in_progress';
              final barColor = (isDone || isActive) ? _accent : _trackGrey;

              return Expanded(
                child: Column(
                  children: [
                    // segmented bar
                    Container(
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

                    // chip (done ✓ | active loader | pending number)
                    _StageChip(index: i + 1, status: stage.status),

                    const SizedBox(height: 2),

                    // label
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
        ],
      ),
    );
  }

  // Build from raw Firestore maps if VMs were not provided
  List<WashStageVM> _buildStagesFromRaw(
    List<String>? order,
    Map<String, dynamic>? map,
  ) {
    final fallbackOrder = ['pre_rinse', 'washing', 'rinsing', 'cleaning'];
    final o = (order?.isNotEmpty == true) ? order! : fallbackOrder;
    final m = (map ?? const {}).map((k, v) => MapEntry(k, (v ?? {}) as Map));

    String labelOf(String k) {
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
          // Capitalize fallback
          return k
              .replaceAll('_', ' ')
              .splitMapJoin(
                RegExp(r'(^| )\w'),
                onMatch: (m) => m.group(0)!.toUpperCase(),
                onNonMatch: (s) => s,
              );
      }
    }

    String statusOf(String k) {
      final raw = '${m[k]?['status'] ?? 'pending'}'.toLowerCase().trim();
      if (raw == 'done' || raw == 'completed') return 'done';
      if (raw == 'in_progress' || raw == 'active' || raw == 'processing') {
        return 'in_progress';
      }
      return 'pending';
    }

    return o.map((k) => WashStageVM(k, labelOf(k), statusOf(k))).toList();
  }
}

/// The little chip under each segment.
/// - done    → orange check
/// - active  → pulsing/loader-style (uses your FadingCircle if present)
/// - pending → grey numbered circle
class _StageChip extends StatelessWidget {
  final int index;
  final String status; // done | in_progress | pending

  const _StageChip({required this.index, required this.status});

  static const Color _accent = Color(0xFFF97316);
  static const Color _greyBg = Color.fromARGB(153, 179, 179, 181);
  static const Color _greyFg = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    if (status == 'done') {
      return const Icon(Icons.check_circle, size: 20, color: _accent);
    }

    if (status == 'in_progress') {
      // If you have your own loader: FadingCircle(number: index, size: 20)
      // else fallback to a tiny progress indicator inside a soft circle
      return SizedBox(
        height: 20,
        width: 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
            ),
            Text(
              '$index',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _accent,
              ),
            ),
          ],
        ),
      );
    }

    // pending (numbered circle)
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

class StatusBar extends StatelessWidget {
  final String status;
  const StatusBar({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      decoration: BoxDecoration(
        color: status == 'pending'
            ? const Color.fromARGB(121, 255, 234, 113)
            : status == 'confirmed'
            ? Color.fromARGB(121, 180, 255, 180)
            : status == 'in_progress'
            ? Color.fromARGB(121, 255, 200, 120)
            : status == 'completed'
            ? Color.fromARGB(121, 120, 158, 255)
            : Color.fromARGB(121, 255, 120, 120),
        borderRadius: BorderRadius.circular(50),
      ),
      child: CustomText(
        text: status == 'pending'
            ? 'Pending'
            : status == 'in_progress'
            ? 'Currently Washing'
            : status == 'confirmed'
            ? 'Confirmed'
            : status == 'completed'
            ? 'Completed'
            : 'Cancelled',
        textSize: TextSizes.bodyText1,
        textWeight: FontWeight.bold,
        textColor: status == 'pending'
            ? Color.fromARGB(255, 187, 129, 4)
            : status == 'confirmed'
            ? Color.fromARGB(255, 4, 129, 4)
            : status == 'in_progress'
            ? Color.fromARGB(255, 187, 80, 4)
            : status == 'completed'
            ? Color.fromARGB(255, 4, 37, 129)
            : Color.fromARGB(255, 129, 4, 4),
      ),
    );
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
