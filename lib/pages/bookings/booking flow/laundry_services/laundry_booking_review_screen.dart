import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'active_laundry_order_stage.dart';

class LaundryRequestFlowScreen extends StatefulWidget {
  final String laundryName;
  final String laundryImage;
  final String pickupLocation;
  final String selectedServiceType;
  final int pricePerKg;
  final int totalPrice;
  final double distanceKm;
  final String estimatedTime;
  final List<String> selectedAddOns;
  final ActiveLaundryOrderStage stage;
  final String? orderId;

  const LaundryRequestFlowScreen({
    super.key,
    required this.laundryName,
    required this.laundryImage,
    required this.pickupLocation,
    required this.selectedServiceType,
    required this.pricePerKg,
    required this.totalPrice,
    required this.distanceKm,
    required this.estimatedTime,
    this.selectedAddOns = const [],
    this.stage = ActiveLaundryOrderStage.accepted,
    this.orderId,
  });

  static const Color primaryOrange = Color(0xFFE67E22);
  static const Color dark = Color(0xFF1F1F1F);
  static const Color lightBg = Color(0xFFF7F7F7);
  static const Color softOrange = Color(0xFFFFECDB);
  static const Color successBg = Color.fromARGB(255, 228, 247, 216);
  static const Color successText = Color(0xFF3D8B2D);

  @override
  State<LaundryRequestFlowScreen> createState() =>
      _LaundryRequestFlowScreenState();
}

class _LaundryRequestFlowScreenState extends State<LaundryRequestFlowScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  bool _requestSent = false;
  bool _submitting = false;

  String get _serviceLabel {
    return widget.selectedServiceType == 'wash_iron'
        ? 'Wash & Iron'
        : 'Wash & Fold';
  }

  String get _responseText => 'Usually responds in 1–3 minutes';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _confirmRequest() async {
    if (_submitting || _requestSent) return;

    setState(() {
      _submitting = true;
    });

    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    setState(() {
      _submitting = false;
      _requestSent = true;
    });
  }

  void _cancelRequest() {
    Navigator.pop(context);
  }

  void _trackRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveLaundryOrderScreen(
          laundryName: widget.laundryName,
          laundryImage: widget.laundryImage,
          pickupLocation: widget.pickupLocation,
          selectedServiceType: widget.selectedServiceType,
          selectedAddOns: widget.selectedAddOns,
          pricePerKg: widget.pricePerKg,
          totalPrice: widget.totalPrice,
          distanceKm: widget.distanceKm,
          pickupEta: '${widget.estimatedTime} min away',
          stage: ActiveLaundryOrderStage.accepted,
          orderId: 'LDR-2048',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _requestSent
              ? _RequestSentBottomBar(
                  key: const ValueKey('request_sent_bar'),
                  totalPrice: widget.totalPrice,
                  onCancelTap: _cancelRequest,
                  onTrackTap: _trackRequest,
                )
              : _ConfirmBottomBar(
                  key: const ValueKey('confirm_bar'),
                  totalPrice: widget.totalPrice,
                  isSubmitting: _submitting,
                  onConfirmTap: _confirmRequest,
                ),
        ),
      ),
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Text(
                      _requestSent ? 'Request Sent' : 'Review Request',
                      key: ValueKey(_requestSent),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
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

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 320),
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeOut,
              sizeCurve: Curves.easeInOut,
              crossFadeState: _requestSent
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _BeforeConfirmBanner(isSubmitting: _submitting),
              secondChild: _AfterConfirmBanner(
                laundryName: widget.laundryName,
                pulseController: _pulseController,
              ),
            ),

            const SizedBox(height: 14),

            Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: Image.asset(
                            widget.laundryImage,
                            fit: BoxFit.cover,
                          ),
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
                                      widget.laundryName,
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
                                                color: LaundryRequestFlowScreen
                                                    .primaryOrange,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${widget.distanceKm.toStringAsFixed(1)} km away',
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
                                            _requestSent
                                                ? _responseText
                                                : widget.estimatedTime,
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
                          icon: Icons.star_rounded,
                          title: '4.8',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickInfoCard(
                          icon: Icons.local_laundry_service_rounded,
                          title: _serviceLabel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickInfoCard(
                          icon: Icons.payments_outlined,
                          title: 'GHS ${widget.totalPrice}/kg',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: _requestSent
                  ? _RequestStatusSection(key: const ValueKey('status_section'))
                  : _RequestDetailsSection(
                      pickupLocation: widget.pickupLocation,
                      serviceLabel: _serviceLabel,
                      pricePerKg: widget.pricePerKg,
                      selectedAddOns: widget.selectedAddOns,
                    ),
            ),

            const SizedBox(height: 5),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _requestSent
                    ? LaundryRequestFlowScreen.softOrange
                    : const Color(0xFFFFF4EA),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          (_requestSent
                                  ? LaundryRequestFlowScreen.primaryOrange
                                  : const Color(0xFFE67E22))
                              .withOpacity(.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFE67E22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _requestSent
                              ? 'While you wait'
                              : 'Before you confirm',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: LaundryRequestFlowScreen.dark,
                            fontFamily: 'Poppins',
                          ),
                        ),

                        Text(
                          _requestSent
                              ? 'You can still cancel this request before the laundry accepts it.'
                              : 'Your request will be sent to this laundry service. You can still cancel before they accept.',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.black87,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _BeforeConfirmBanner extends StatelessWidget {
  final bool isSubmitting;

  const _BeforeConfirmBanner({required this.isSubmitting});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('before_banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: isSubmitting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Transform.scale(
                    scale: 1.4,
                    child: Lottie.asset(
                      'assets/animations/Search.json',
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review before sending',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LaundryRequestFlowScreen.dark,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check the laundry, location, service, and pricing before you confirm.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AfterConfirmBanner extends StatelessWidget {
  final String laundryName;
  final AnimationController pulseController;

  const _AfterConfirmBanner({
    required this.laundryName,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('after_banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final scale = 0.95 + (pulseController.value * 0.08);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Transform.scale(
                    scale: 3,
                    child: Lottie.asset(
                      'assets/animations/Hourglass.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request sent to $laundryName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We’re waiting for the laundry to accept your request.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: Colors.black.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestDetailsSection extends StatelessWidget {
  final String pickupLocation;
  final String serviceLabel;
  final int pricePerKg;
  final List<String> selectedAddOns;

  const _RequestDetailsSection({
    super.key,
    required this.pickupLocation,
    required this.serviceLabel,
    required this.pricePerKg,
    required this.selectedAddOns,
  });

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailTile(
          icon: Icons.location_on_outlined,
          title: 'Pickup location',
          value: pickupLocation,
        ),

        if (selectedAddOns.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: LaundryRequestFlowScreen.lightBg,
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
                    color: LaundryRequestFlowScreen.primaryOrange,
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
                              color: const Color(0xFFFFECDB),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _addOnIcon(addOn),
                                  size: 16,
                                  color: LaundryRequestFlowScreen.primaryOrange,
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
      ],
    );
  }
}

class _RequestStatusSection extends StatelessWidget {
  const _RequestStatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Request Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: LaundryRequestFlowScreen.lightBg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusRow(
                isCompleted: true,
                isCurrent: false,
                title: 'Request sent',
                subtitle: 'Your request has been delivered successfully.',
              ),
              SizedBox(height: 5),
              _StatusConnector(),
              SizedBox(height: 5),
              _StatusRow(
                isCompleted: false,
                isCurrent: true,
                title: 'Waiting for acceptance',
                subtitle: 'The laundry is reviewing your request now.',
              ),
              SizedBox(height: 5),
              _StatusConnector(),
              SizedBox(height: 5),
              _StatusRow(
                isCompleted: false,
                isCurrent: false,
                title: 'Pickup confirmation',
                subtitle: 'You’ll be notified when the laundry accepts.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _ConfirmBottomBar extends StatelessWidget {
  final int totalPrice;
  final bool isSubmitting;
  final VoidCallback onConfirmTap;

  const _ConfirmBottomBar({
    super.key,
    required this.totalPrice,
    required this.isSubmitting,
    required this.onConfirmTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onConfirmTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: LaundryRequestFlowScreen.dark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          disabledBackgroundColor: LaundryRequestFlowScreen.dark.withOpacity(
            0.85,
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: LaundryRequestFlowScreen.primaryOrange,
                ),
              )
            : const Text(
                'Confirm Request',
                style: TextStyle(
                  color: LaundryRequestFlowScreen.primaryOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
      ),
    );
  }
}

class _RequestSentBottomBar extends StatelessWidget {
  final int totalPrice;
  final VoidCallback onCancelTap;
  final VoidCallback onTrackTap;

  const _RequestSentBottomBar({
    super.key,
    required this.totalPrice,
    required this.onCancelTap,
    required this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancelTap,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onTrackTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LaundryRequestFlowScreen.dark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Track Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: LaundryRequestFlowScreen.primaryOrange,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _QuickInfoCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: icon == Icons.star_rounded
                ? Colors.amber
                : const Color(0xFFE67E22),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: LaundryRequestFlowScreen.dark,
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
  final String title;
  final String subtitle;

  const _StatusRow({
    required this.isCompleted,
    required this.isCurrent,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isCurrent
        ? LaundryRequestFlowScreen.primaryOrange
        : LaundryRequestFlowScreen.successText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: (isCompleted || isCurrent)
                ? activeColor.withOpacity(0.12)
                : const Color(0xFFE9E9E9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted
                ? Icons.check_rounded
                : isCurrent
                ? Icons.hourglass_top_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: (isCompleted || isCurrent) ? activeColor : Colors.black38,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: (isCompleted || isCurrent)
                      ? Colors.black
                      : Colors.black54,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                  color: Colors.black.withOpacity(0.65),
                ),
              ),
            ],
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
      child: Container(width: 2, height: 25, color: const Color(0xFFDCDCDC)),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: LaundryRequestFlowScreen.lightBg,
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
            child: Icon(icon, color: LaundryRequestFlowScreen.primaryOrange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: LaundryRequestFlowScreen.dark,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
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

class _OrderStepData {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isCurrent;

  const _OrderStepData({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isCurrent,
  });
}

class _TrackRequestBottomSheet extends StatelessWidget {
  final String laundryName;
  final String pickupLocation;
  final String selectedServiceType;
  final List<String> selectedAddOns;
  final int totalPrice;
  final double distanceKm;
  final ActiveLaundryOrderStage stage;
  final String? orderId;

  const _TrackRequestBottomSheet({
    required this.laundryName,
    required this.pickupLocation,
    required this.selectedServiceType,
    required this.selectedAddOns,
    required this.totalPrice,
    required this.distanceKm,
    required this.stage,
    required this.orderId,
  });

  String get _serviceLabel {
    return selectedServiceType == 'wash_iron' ? 'Wash & Iron' : 'Wash & Fold';
  }

  String get _etaText {
    switch (stage) {
      case ActiveLaundryOrderStage.accepted:
        return 'Pickup in 8 min';
      case ActiveLaundryOrderStage.pickupOnTheWay:
        return 'Arriving in 5 min';
      case ActiveLaundryOrderStage.pickedUp:
        return 'Picked up';
      case ActiveLaundryOrderStage.processing:
        return 'In progress';
      case ActiveLaundryOrderStage.outForDelivery:
        return 'Returning in 12 min';
      case ActiveLaundryOrderStage.completed:
        return 'Delivered';
    }
  }

  String get _statusText {
    switch (stage) {
      case ActiveLaundryOrderStage.accepted:
        return 'Accepted';
      case ActiveLaundryOrderStage.pickupOnTheWay:
        return 'Pickup on the way';
      case ActiveLaundryOrderStage.pickedUp:
        return 'Picked up';
      case ActiveLaundryOrderStage.processing:
        return 'Processing';
      case ActiveLaundryOrderStage.outForDelivery:
        return 'Out for delivery';
      case ActiveLaundryOrderStage.completed:
        return 'Completed';
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final statusSteps = [
      _OrderStepData(
        title: 'Request sent',
        subtitle: 'Your request was sent successfully.',
        isCompleted: true,
        isCurrent: false,
      ),
      _OrderStepData(
        title: 'Accepted',
        subtitle: 'The laundry accepted your request.',
        isCompleted: stage.index >= ActiveLaundryOrderStage.accepted.index,
        isCurrent: stage == ActiveLaundryOrderStage.accepted,
      ),
      _OrderStepData(
        title: 'Pickup',
        subtitle: 'Your laundry is being picked up.',
        isCompleted: stage.index >= ActiveLaundryOrderStage.pickedUp.index,
        isCurrent:
            stage == ActiveLaundryOrderStage.pickupOnTheWay ||
            stage == ActiveLaundryOrderStage.pickedUp,
      ),
      _OrderStepData(
        title: 'Processing',
        subtitle: 'Cleaning and treatment are in progress.',
        isCompleted: stage.index >= ActiveLaundryOrderStage.processing.index,
        isCurrent: stage == ActiveLaundryOrderStage.processing,
      ),
      _OrderStepData(
        title: 'Delivery',
        subtitle: 'Your laundry is returning to you.',
        isCompleted:
            stage.index >= ActiveLaundryOrderStage.outForDelivery.index,
        isCurrent: stage == ActiveLaundryOrderStage.outForDelivery,
      ),
      _OrderStepData(
        title: 'Completed',
        subtitle: 'Your order has been completed.',
        isCompleted: stage == ActiveLaundryOrderStage.completed,
        isCurrent: stage == ActiveLaundryOrderStage.completed,
      ),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2425),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Track Request',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECDB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              color: ActiveLaundryOrderScreen.primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ActiveLaundryOrderScreen.lightBg,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFECDB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.store,
                              color: ActiveLaundryOrderScreen.primaryOrange,
                              size: 45,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  laundryName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${distanceKm.toStringAsFixed(1)} km away • $_etaText',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // TODO: contact laundry
                            },
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Live Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ActiveLaundryOrderScreen.lightBg,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: List.generate(statusSteps.length, (index) {
                          final step = statusSteps[index];
                          final isLast = index == statusSteps.length - 1;

                          return Column(
                            children: [
                              _StatusRow(
                                isCompleted: step.isCompleted,
                                isCurrent: step.isCurrent,
                                title: step.title,
                                subtitle: step.subtitle,
                              ),
                              if (!isLast) ...[
                                const SizedBox(height: 14),
                                const _StatusConnector(),
                                const SizedBox(height: 14),
                              ],
                            ],
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _DetailTile(
                      icon: Icons.location_on_outlined,
                      title: 'Pickup location',
                      value: pickupLocation,
                    ),
                    const SizedBox(height: 12),
                    _DetailTile(
                      icon: Icons.local_laundry_service_outlined,
                      title: 'Selected service',
                      value: _serviceLabel,
                    ),
                    const SizedBox(height: 12),
                    _DetailTile(
                      icon: Icons.payments_outlined,
                      title: 'Estimated total',
                      value: 'GH₵$totalPrice',
                    ),

                    if (selectedAddOns.isNotEmpty) ...[
                      const SizedBox(height: 12),
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
                                          color: ActiveLaundryOrderScreen
                                              .softOrange,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
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

                    if (orderId != null) ...[
                      const SizedBox(height: 12),
                      _DetailTile(
                        icon: Icons.receipt_long_outlined,
                        title: 'Order ID',
                        value: orderId!,
                      ),
                    ],

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: contact laundry
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF3F3F3),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Contact Laundry',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  stage.index <=
                                      ActiveLaundryOrderStage.accepted.index
                                  ? () {
                                      // TODO: cancel request
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                disabledBackgroundColor: Colors.black
                                    .withOpacity(0.25),
                              ),
                              child: const Text(
                                'Cancel Request',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                  color: ActiveLaundryOrderScreen.primaryOrange,
                                ),
                              ),
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
        );
      },
    );
  }
}
