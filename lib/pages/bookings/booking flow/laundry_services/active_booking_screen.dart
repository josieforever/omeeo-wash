import 'package:cloud_firestore/cloud_firestore.dart'
    show QuerySnapshot, FirebaseFirestore, Timestamp;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'
    show
        StatelessWidget,
        CircularProgressIndicator,
        Scaffold,
        Colors,
        Material,
        InkWell,
        Icons,
        MaterialPageRoute;
import 'package:flutter/widgets.dart';

import 'active_laundry_order_stage.dart';
import 'laundry_services.dart';

class CustomerActiveBookingsScreen extends StatelessWidget {
  const CustomerActiveBookingsScreen({super.key});

  static const List<String> activeStatuses =
      CustomerActiveBookingsPreview.activeStatuses;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Please sign in first.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        _ActiveBookingsBackButton(
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Active bookings',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: Text(
                      'Track all your ongoing laundry orders in one place.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9A7153),
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .where(
                            'customerSnapshot.customerId',
                            isEqualTo: user.uid,
                          )
                          .where('status', whereIn: activeStatuses)
                          .limit(20)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          debugPrint(
                            'Active bookings screen error: ${snapshot.error}',
                          );

                          return const _ActiveBookingsEmptyState(
                            title: 'Could not load bookings',
                            subtitle: 'Please try again in a moment.',
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE67E22),
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs.toList();

                        docs.sort((a, b) {
                          final aCreatedAt = a.data()['createdAt'];
                          final bCreatedAt = b.data()['createdAt'];

                          final aDate = aCreatedAt is Timestamp
                              ? aCreatedAt.toDate()
                              : DateTime.fromMillisecondsSinceEpoch(0);

                          final bDate = bCreatedAt is Timestamp
                              ? bCreatedAt.toDate()
                              : DateTime.fromMillisecondsSinceEpoch(0);

                          return bDate.compareTo(aDate);
                        });

                        if (docs.isEmpty) {
                          return const _ActiveBookingsEmptyState(
                            title: 'No active bookings',
                            subtitle:
                                'Your active laundry orders will appear here.',
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final booking = docs[index].data();
                            final cardData =
                                ActiveLaundryOrderCardData.fromBooking(booking);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _BookingCodeChip(
                                  bookingCode:
                                      (booking['bookingCode'] ?? docs[index].id)
                                          .toString(),
                                ),
                                ActiveLaundryOrderCard(
                                  dateText: cardData.dateText,
                                  laundryName: cardData.laundryName,
                                  currentStage: cardData.currentStage,
                                  currentTimeText: cardData.currentTimeText,
                                  nextStage: cardData.nextStage,
                                  nextTimeText: cardData.nextTimeText,
                                  durationText: cardData.durationText,
                                  progress: cardData.progress,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ActiveLaundryOrderScreen(
                                              bookingId: docs[index].id,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ActiveBookingsBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ActiveBookingsBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFECDB),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back_rounded, color: Color(0xFFE67E22)),
        ),
      ),
    );
  }
}

class _BookingCodeChip extends StatelessWidget {
  final String bookingCode;

  const _BookingCodeChip({required this.bookingCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECDB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        bookingCode,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE67E22),
        ),
      ),
    );
  }
}

class _ActiveBookingsEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ActiveBookingsEmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6ED),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE67E22).withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFECDB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_laundry_service_outlined,
                color: Color(0xFFE67E22),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9A7153),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
