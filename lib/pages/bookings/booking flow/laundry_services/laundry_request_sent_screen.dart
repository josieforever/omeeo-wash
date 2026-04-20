import 'package:flutter/material.dart';

class LaundryRequestSentScreen extends StatefulWidget {
  final String laundryName;
  final String laundryImagePath;
  final String pickupLocation;
  final String selectedServiceType;
  final String estimatedResponseTime;
  final double distanceKm;
  final int totalPrice;

  const LaundryRequestSentScreen({
    super.key,
    required this.laundryName,
    required this.laundryImagePath,
    required this.pickupLocation,
    required this.selectedServiceType,
    required this.estimatedResponseTime,
    required this.distanceKm,
    required this.totalPrice,
  });

  @override
  State<LaundryRequestSentScreen> createState() =>
      _LaundryRequestSentScreenState();
}

class _LaundryRequestSentScreenState extends State<LaundryRequestSentScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  static const Color primaryOrange = Color(0xFFE67E22);
  static const Color softOrange = Color(0xFFFFECDB);
  static const Color appBlack = Color(0xFF212121);
  static const Color cardBg = Color(0xFFF7F7F7);
  static const Color successBg = Color.fromARGB(255, 228, 247, 216);
  static const Color successText = Color(0xFF3D8B2D);

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

  String get _serviceLabel {
    return widget.selectedServiceType == 'wash_iron'
        ? 'Wash & Iron'
        : 'Wash & Fold';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  // TODO: cancel request logic
                },
                child: Container(
                  width: 56,
                  height: 56,
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
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: navigate to track request page
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appBlack,
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
                        color: primaryOrange,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _RoundTopButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Request Sent',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: successBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 0.95 + (_pulseController.value * 0.08);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: successText,
                              size: 32,
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
                            'Request sent to ${widget.laundryName}',
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
              ),

              const SizedBox(height: 18),

              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  color: const Color(0xFFEDEDED),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          SizedBox(
                            height: 220,
                            width: double.infinity,
                            child: Image.asset(
                              widget.laundryImagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.08),
                                    Colors.black.withOpacity(0.10),
                                    Colors.black.withOpacity(0.48),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.laundryName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _HeroChip(
                                      icon: Icons.schedule_rounded,
                                      text: widget.estimatedResponseTime,
                                    ),
                                    const SizedBox(width: 8),
                                    _HeroChip(
                                      icon: Icons.near_me_rounded,
                                      text:
                                          '${widget.distanceKm.toStringAsFixed(1)} km away',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Expanded(
                              child: _QuickInfoCard(
                                icon: Icons.local_laundry_service_outlined,
                                title: _serviceLabel,
                                subtitle: 'Service',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickInfoCard(
                                icon: Icons.payments_outlined,
                                title: 'GH₵${widget.totalPrice}',
                                subtitle: 'Estimated',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickInfoCard(
                                icon: Icons.hourglass_top_rounded,
                                title: 'Pending',
                                subtitle: 'Status',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: const [
                    _StatusRow(
                      isActive: true,
                      title: 'Request sent',
                      subtitle: 'Your request has been delivered successfully.',
                    ),
                    SizedBox(height: 14),
                    _StatusConnector(),
                    SizedBox(height: 14),
                    _StatusRow(
                      isActive: true,
                      isWaiting: true,
                      title: 'Waiting for acceptance',
                      subtitle: 'The laundry is reviewing your request now.',
                    ),
                    SizedBox(height: 14),
                    _StatusConnector(),
                    SizedBox(height: 14),
                    _StatusRow(
                      isActive: false,
                      title: 'Pickup confirmation',
                      subtitle: 'You’ll be notified when the laundry accepts.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Request Details',
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
                value: widget.pickupLocation,
              ),
              const SizedBox(height: 12),
              _DetailTile(
                icon: Icons.local_laundry_service_outlined,
                title: 'Selected service',
                value: _serviceLabel,
              ),
              const SizedBox(height: 12),
              _DetailTile(
                icon: Icons.access_time_rounded,
                title: 'Usual response time',
                value: widget.estimatedResponseTime,
              ),
              const SizedBox(height: 12),
              _DetailTile(
                icon: Icons.payments_outlined,
                title: 'Estimated total',
                value: 'GH₵${widget.totalPrice}',
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: softOrange,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can still cancel this request before the laundry accepts it.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                    ),
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

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Colors.white,
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
  final String subtitle;

  const _QuickInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFE67E22)),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final bool isActive;
  final bool isWaiting;
  final String title;
  final String subtitle;

  const _StatusRow({
    required this.isActive,
    required this.title,
    required this.subtitle,
    this.isWaiting = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isWaiting
        ? const Color(0xFFE67E22)
        : const Color(0xFF3D8B2D);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.12)
                : const Color(0xFFE9E9E9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive
                ? (isWaiting
                      ? Icons.hourglass_top_rounded
                      : Icons.check_rounded)
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isActive ? activeColor : Colors.black38,
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
                  color: isActive ? Colors.black : Colors.black54,
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
      child: Container(width: 2, height: 16, color: const Color(0xFFDCDCDC)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
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
            child: Icon(icon, color: const Color(0xFFE67E22)),
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
