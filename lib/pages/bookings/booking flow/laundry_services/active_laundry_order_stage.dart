import 'package:flutter/material.dart';

enum ActiveLaundryOrderStage {
  accepted,
  pickupOnTheWay,
  pickedUp,
  processing,
  outForDelivery,
  completed,
}

class ActiveLaundryOrderScreen extends StatelessWidget {
  final String laundryName;
  final String laundryImage;
  final String pickupLocation;
  final String selectedServiceType;
  final List<String> selectedAddOns;
  final int pricePerKg;
  final int totalPrice;
  final double distanceKm;
  final String pickupEta;
  final ActiveLaundryOrderStage stage;
  final String? orderId;

  const ActiveLaundryOrderScreen({
    super.key,
    required this.laundryName,
    required this.laundryImage,
    required this.pickupLocation,
    required this.selectedServiceType,
    this.selectedAddOns = const [],
    required this.pricePerKg,
    required this.totalPrice,
    required this.distanceKm,
    required this.pickupEta,
    this.stage = ActiveLaundryOrderStage.accepted,
    this.orderId,
  });

  static const Color primaryOrange = Color(0xFFE67E22);
  static const Color dark = Color(0xFF1F1F1F);
  static const Color lightBg = Color(0xFFF7F7F7);
  static const Color softOrange = Color(0xFFFFECDB);
  static const Color successBg = Color.fromARGB(255, 228, 247, 216);
  static const Color successText = Color(0xFF3D8B2D);
  static const Color pendingBg = Color(0xFFF3F3F3);

  String get serviceLabel =>
      selectedServiceType == 'wash_iron' ? 'Wash & Iron' : 'Wash & Fold';

  IconData _addOnIcon(String addOn) {
    switch (addOn) {
      case 'Express Wash':
        return Icons.local_laundry_service_outlined;
      case 'Fragrance Booster':
        return Icons.cleaning_services_outlined;
      case 'Whites Bleach':
        return Icons.opacity_outlined;
      case 'Delicate Wash':
        return Icons.checkroom_outlined;
      default:
        return Icons.add_circle_outline_rounded;
    }
  }

  String get stageHeadline {
    switch (stage) {
      case ActiveLaundryOrderStage.accepted:
        return '$laundryName accepted your request';
      case ActiveLaundryOrderStage.pickupOnTheWay:
        return '$laundryName is heading to pickup';
      case ActiveLaundryOrderStage.pickedUp:
        return 'Your laundry has been picked up';
      case ActiveLaundryOrderStage.processing:
        return 'Your laundry is being processed';
      case ActiveLaundryOrderStage.outForDelivery:
        return 'Your laundry is on its way back';
      case ActiveLaundryOrderStage.completed:
        return 'Your order has been completed';
    }
  }

  String get stageSubtitle {
    switch (stage) {
      case ActiveLaundryOrderStage.accepted:
        return 'Pickup has been confirmed and the order is now active.';
      case ActiveLaundryOrderStage.pickupOnTheWay:
        return 'Get your items ready. Pickup should happen soon.';
      case ActiveLaundryOrderStage.pickedUp:
        return 'Your items are now with the laundry service.';
      case ActiveLaundryOrderStage.processing:
        return 'Washing and treatment are currently in progress.';
      case ActiveLaundryOrderStage.outForDelivery:
        return 'Your cleaned items are being returned to you.';
      case ActiveLaundryOrderStage.completed:
        return 'Everything is done. You can review the order anytime.';
    }
  }

  String get etaText {
    switch (stage) {
      case ActiveLaundryOrderStage.accepted:
        return pickupEta;
      case ActiveLaundryOrderStage.pickupOnTheWay:
        return pickupEta;
      case ActiveLaundryOrderStage.pickedUp:
        return 'Picked up';
      case ActiveLaundryOrderStage.processing:
        return 'In progress';
      case ActiveLaundryOrderStage.outForDelivery:
        return 'Returning soon';
      case ActiveLaundryOrderStage.completed:
        return 'Delivered';
    }
  }

  IconData get stageBannerIcon {
    switch (stage) {
      case ActiveLaundryOrderStage.accepted:
        return Icons.check_circle_rounded;
      case ActiveLaundryOrderStage.pickupOnTheWay:
        return Icons.two_wheeler_rounded;
      case ActiveLaundryOrderStage.pickedUp:
        return Icons.inventory_2_rounded;
      case ActiveLaundryOrderStage.processing:
        return Icons.local_laundry_service_rounded;
      case ActiveLaundryOrderStage.outForDelivery:
        return Icons.local_shipping_rounded;
      case ActiveLaundryOrderStage.completed:
        return Icons.verified_rounded;
    }
  }

  Color get stageBannerBg {
    switch (stage) {
      case ActiveLaundryOrderStage.accepted:
      case ActiveLaundryOrderStage.completed:
        return successBg;
      default:
        return softOrange;
    }
  }

  Color get stageBannerIconColor {
    switch (stage) {
      case ActiveLaundryOrderStage.accepted:
      case ActiveLaundryOrderStage.completed:
        return successText;
      default:
        return primaryOrange;
    }
  }

  bool get showTrackButton =>
      stage != ActiveLaundryOrderStage.completed &&
      stage != ActiveLaundryOrderStage.processing;

  bool get showContactButton => stage != ActiveLaundryOrderStage.completed;

  bool get showRateButton => stage == ActiveLaundryOrderStage.completed;

  @override
  Widget build(BuildContext context) {
    final statusSteps = [
      _OrderStepData(
        subtitle: 'Request was sent successfully.',
        isCompleted: true,
        isCurrent: false,
      ),
      _OrderStepData(
        subtitle: 'Laundry accepted your request.',
        isCompleted: stage.index >= ActiveLaundryOrderStage.accepted.index,
        isCurrent: stage == ActiveLaundryOrderStage.accepted,
      ),
      _OrderStepData(
        subtitle: 'Laundry is being picked up.',
        isCompleted: stage.index >= ActiveLaundryOrderStage.pickedUp.index,
        isCurrent:
            stage == ActiveLaundryOrderStage.pickupOnTheWay ||
            stage == ActiveLaundryOrderStage.pickedUp,
      ),
      _OrderStepData(
        subtitle: 'Wash is in progress.',
        isCompleted: stage.index >= ActiveLaundryOrderStage.processing.index,
        isCurrent: stage == ActiveLaundryOrderStage.processing,
      ),
      _OrderStepData(
        subtitle: 'Laundry is returning to you.',
        isCompleted:
            stage.index >= ActiveLaundryOrderStage.outForDelivery.index,
        isCurrent: stage == ActiveLaundryOrderStage.outForDelivery,
      ),
      _OrderStepData(
        subtitle: 'Order has been completed.',
        isCompleted: stage == ActiveLaundryOrderStage.completed,
        isCurrent: stage == ActiveLaundryOrderStage.completed,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _RoundTopButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      orderId!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: 0,
                  child: _RoundTopButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 100,
                          width: double.infinity,
                          child: Image.asset(laundryImage, fit: BoxFit.cover),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(.55),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      laundryName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              .18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.location_on_rounded,
                                                color: primaryOrange,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${distanceKm.toStringAsFixed(1)} km away',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              .18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            etaText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickInfoCard(
                          icon: Icons.local_laundry_service_rounded,
                          title: serviceLabel,
                          subtitle: 'Service',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickInfoCard(
                          icon: Icons.payments_outlined,
                          title: 'GHS $totalPrice',
                          subtitle: 'Estimated',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickInfoCard(
                          icon: Icons.schedule_rounded,
                          title: etaText,
                          subtitle: 'Status',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: List.generate(statusSteps.length, (index) {
                  final step = statusSteps[index];
                  final isLast = index == statusSteps.length - 1;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusRow(
                        isCompleted: step.isCompleted,
                        isCurrent: step.isCurrent,
                        subtitle: step.subtitle,
                      ),
                      if (!isLast) ...[
                        const SizedBox(height: 5),
                        const _StatusConnector(),
                        const SizedBox(height: 5),
                      ],
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 10),

            if (selectedAddOns.isNotEmpty) ...[
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ActiveLaundryOrderScreen.lightBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.add_box_outlined,
                        color: ActiveLaundryOrderScreen.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected add-ons',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedAddOns.map((addOn) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: ActiveLaundryOrderScreen.softOrange,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _addOnIcon(addOn),
                                      size: 16,
                                      color: ActiveLaundryOrderScreen
                                          .primaryOrange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      addOn,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: softOrange,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primaryOrange.withOpacity(.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      stage == ActiveLaundryOrderStage.completed
                          ? 'Your laundry order has been completed successfully.'
                          : 'You’ll keep getting updates here as your order progresses.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStepData {
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;

  const _OrderStepData({
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
  });
}

class _QuickInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _QuickInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: ActiveLaundryOrderScreen.primaryOrange),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ActiveLaundryOrderScreen.dark,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;
  final String subtitle;

  const _StatusRow({
    required this.isCompleted,
    required this.isCurrent,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isCurrent
        ? ActiveLaundryOrderScreen.primaryOrange
        : ActiveLaundryOrderScreen.successText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: (isCompleted || isCurrent)
                ? activeColor.withOpacity(0.12)
                : const Color(0xFFE9E9E9),
            shape: BoxShape.circle,
          ),
          child: isCompleted && subtitle == 'Request was sent successfully.'
              ? Icon(
                  Icons.send,
                  size: 20,
                  color: (isCompleted || isCurrent)
                      ? activeColor
                      : Colors.black38,
                )
              : isCompleted && subtitle == 'Laundry accepted your request.'
              ? Icon(
                  Icons.thumb_up_rounded,
                  size: 20,
                  color: (isCompleted || isCurrent)
                      ? activeColor
                      : Colors.black38,
                )
              : isCompleted && subtitle == 'Laundry is being picked up.'
              ? Transform.flip(
                  child: Icon(
                    Icons.moped,
                    size: 20,
                    color: (isCompleted || isCurrent)
                        ? activeColor
                        : Colors.black38,
                  ),
                )
              : isCompleted && subtitle == 'Wash is in progress.'
              ? Icon(
                  Icons.local_laundry_service_rounded,
                  size: 20,
                  color: (isCompleted || isCurrent)
                      ? activeColor
                      : Colors.black38,
                )
              : isCompleted && subtitle == 'Laundry is returning to you.'
              ? Icon(
                  Icons.moped,
                  size: 20,
                  color: (isCompleted || isCurrent)
                      ? activeColor
                      : Colors.black38,
                )
              : isCompleted && subtitle == 'Order has been completed.'
              ? Icon(
                  Icons.verified,
                  size: 20,
                  color: (isCompleted || isCurrent)
                      ? activeColor
                      : Colors.black38,
                )
              : isCurrent
              ? Icon(Icons.hourglass_top_rounded)
              : Icon(Icons.radio_button_unchecked_rounded),
        ),
        const SizedBox(width: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            color: Colors.black.withOpacity(0.65),
          ),
        ),
      ],
    );
  }
}

class _StatusConnector extends StatelessWidget {
  const _StatusConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Container(width: 2, height: 16, color: const Color(0xFFDCDCDC)),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;

  final String value;

  const _DetailTile({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ActiveLaundryOrderScreen.lightBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: ActiveLaundryOrderScreen.primaryOrange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ActiveLaundryOrderScreen.dark,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundTopButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundTopButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.black87, size: 22),
        ),
      ),
    );
  }
}
