import 'package:flutter/material.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  const DeliveryDetailsScreen({super.key});

  double sw(BuildContext context) => MediaQuery.of(context).size.width;
  double sh(BuildContext context) => MediaQuery.of(context).size.height;

  double rs(BuildContext context, double size) {
    final width = sw(context);
    final scale = width / 390; // base iPhone width
    return (size * scale).clamp(size * 0.90, size * 1.08);
  }

  @override
  Widget build(BuildContext context) {
    final width = sw(context);
    final horizontalPadding = width * 0.05;
    final radius = 22.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            10,
            horizontalPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(context),
              SizedBox(height: rs(context, 8)),

              _header(context),
              SizedBox(height: rs(context, 20)),

              _actionButtons(context),
              SizedBox(height: rs(context, 20)),

              _routeCard(context, radius),
              SizedBox(height: rs(context, 26)),

              _sectionTitle(context, 'Details'),
              SizedBox(height: rs(context, 14)),

              _detailsSection(context),
              SizedBox(height: rs(context, 28)),

              _sectionTitle(context, 'Price'),
              SizedBox(height: rs(context, 14)),

              _priceCard(context, radius),
              SizedBox(height: rs(context, 22)),

              _deleteCard(context, radius),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return SizedBox(
      height: rs(context, 44),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pop(context),
          child: SizedBox(
            height: rs(context, 44),
            width: rs(context, 44),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: rs(context, 22),
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final boxSize = rs(context, 86);

    return Column(
      children: [
        Center(
          child: Container(
            height: boxSize,
            width: boxSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Container(
                height: rs(context, 58),
                width: rs(context, 58),
                decoration: BoxDecoration(
                  color: const Color(0xFFF04E23),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: rs(context, 30),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: rs(context, 14)),
        Center(
          child: Text(
            'Delivery, 13:30',
            style: TextStyle(
              fontSize: rs(context, 23),
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            context,
            icon: Icons.headset_mic_rounded,
            label: 'Help',
          ),
        ),
        SizedBox(width: rs(context, 12)),
        Expanded(
          child: _actionButton(
            context,
            icon: Icons.refresh_rounded,
            label: 'Request again',
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: rs(context, 16),
        horizontal: rs(context, 10),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: rs(context, 24), color: Colors.black87),
          SizedBox(height: rs(context, 6)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: rs(context, 14),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard(BuildContext context, double radius) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            child: Container(
              height: rs(context, 190),
              width: double.infinity,
              color: const Color(0xFFF3EEE3),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0xFFF4EFE4)),
                  Positioned(
                    left: rs(context, 22),
                    top: rs(context, 70),
                    child: _marker(context, Icons.inventory_2_rounded),
                  ),
                  Positioned(
                    right: rs(context, 24),
                    top: rs(context, 65),
                    child: _marker(context, Icons.flag_rounded),
                  ),
                  Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: rs(context, 50),
                      color: Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: rs(context, 20),
              vertical: rs(context, 18),
            ),
            child: Column(
              children: [
                _locationRow(
                  context,
                  icon: Icons.inventory_2_outlined,
                  text: 'Teikofio Street',
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: rs(context, 16)),
                  child: Divider(
                    height: 1,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                _locationRow(
                  context,
                  icon: Icons.flag_outlined,
                  text: 'Gulf Road, 8',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _marker(BuildContext context, IconData icon) {
    return Container(
      height: rs(context, 34),
      width: rs(context, 34),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, size: rs(context, 18), color: Colors.black87),
    );
  }

  Widget _locationRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: rs(context, 21), color: Colors.black87),
        SizedBox(width: rs(context, 14)),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rs(context, 16),
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: rs(context, 22),
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Widget _detailsSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asiedu Michael',
                    style: TextStyle(
                      fontSize: rs(context, 17),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: rs(context, 2)),
                  Text(
                    'Courier',
                    style: TextStyle(
                      fontSize: rs(context, 14),
                      fontWeight: FontWeight.w400,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: rs(context, 18)),
        Divider(height: 1, color: Colors.black.withValues(alpha: 0.08)),
        SizedBox(height: rs(context, 18)),
        Row(
          children: [
            Expanded(
              child: Text(
                'Bike Courier',
                style: TextStyle(
                  fontSize: rs(context, 16),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              'M-22-GE741',
              style: TextStyle(
                fontSize: rs(context, 16),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _priceCard(BuildContext context, double radius) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: rs(context, 18),
        vertical: rs(context, 18),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        children: [
          _priceRow(
            context,
            label: 'Courier delivery service',
            amount: '31GHS',
            isBold: false,
          ),
          SizedBox(height: rs(context, 16)),
          Divider(height: 1, color: Colors.black.withValues(alpha: 0.08)),
          SizedBox(height: rs(context, 16)),
          _priceRow(context, label: 'Total', amount: '31GHS', isBold: true),
          SizedBox(height: rs(context, 18)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: rs(context, 16),
              vertical: rs(context, 16),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'In cash upon delivery',
              style: TextStyle(
                fontSize: rs(context, 15),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    BuildContext context, {
    required String label,
    required String amount,
    required bool isBold,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: rs(context, isBold ? 16 : 15),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: rs(context, isBold ? 18 : 16),
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _deleteCard(BuildContext context, double radius) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: rs(context, 18),
        vertical: rs(context, 18),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.visibility_off_outlined,
            color: const Color(0xFFFF5A3C),
            size: rs(context, 24),
          ),
          SizedBox(width: rs(context, 14)),
          Expanded(
            child: Text(
              'Delete record',
              style: TextStyle(
                fontSize: rs(context, 16),
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFF5A3C),
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: rs(context, 24),
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
}
