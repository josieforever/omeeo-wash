import 'package:flutter/material.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class ReviewAutoCareScreen extends StatelessWidget {
  const ReviewAutoCareScreen({super.key});

  static const Color seafoam = Color(0xFF5FB8A5);
  static const Color deepSeafoam = Color(0xFF2F8F83);
  static const Color mintBg = Color.fromARGB(255, 255, 255, 255);
  static const Color darkAccent = Color(0xFF1F5F57);
  static const Color _teal = Color.fromARGB(255, 75, 161, 140);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mintBg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSelectedPackageCard(),
                  const SizedBox(height: 24),
                  _buildVehicleAndTurnaround(),
                  const SizedBox(height: 30),
                  const Text(
                    "INCLUDED IN THIS SERVICE",
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: deepSeafoam,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildIncludedChips(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 5, right: 5, top: 30, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_teal, Color.fromARGB(255, 30, 122, 107)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoBack(
            bgColor: Colors.white.withOpacity(0.18),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                text: "Review Auto Care",
                textSize: TextSizes.heading1,
                textWeight: FontWeight.w700,
                textColor: Colors.white,
              ),
              CustomText(
                text: "Last look at your package",
                textSize: TextSizes.bodyText1,
                textWeight: FontWeight.normal,
                textColor: Colors.white.withOpacity(0.85),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= PACKAGE CARD =================

  Widget _buildSelectedPackageCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFBFE9DF), Color(0xFFE9F7F4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Selected package",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.star_border,
                  size: 28,
                  color: darkAccent,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Wax & Polish",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: darkAccent,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Paint correction and protective wax coat",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "\$55",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: deepSeafoam,
                    ),
                  ),
                  Text("starting price", style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= VEHICLE & TURNAROUND =================

  Widget _buildVehicleAndTurnaround() {
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            title: "VEHICLE",
            mainText: "Truck",
            subText: "Pickup & full-size trucks",
            icon: Icons.local_shipping,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _infoCard(
            title: "TURNAROUND",
            mainText: "1-2 hrs",
            subText: "Choose schedule in the next step",
            icon: Icons.access_time,
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String title,
    required String mainText,
    required String subText,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF3EE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, color: deepSeafoam),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(subText, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= INCLUDED =================

  Widget _buildIncludedChips() {
    final items = ["Paint Correction", "Wax Coat", "UV Protection"];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: items
          .map(
            (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, color: deepSeafoam),
                  const SizedBox(width: 8),
                  Text(e),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ================= BOTTOM BAR =================

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black12,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Selected total"),
              SizedBox(height: 4),
              Text(
                "\$55",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: deepSeafoam,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: seafoam,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {},
            child: const Text(
              "Continue to booking",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
