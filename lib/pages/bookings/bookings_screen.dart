import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ✅ Add these
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// your own imports
import 'package:omeeowash/providers/top_nav_provider.dart';
import 'package:omeeowash/widgets.dart/responsiveness.dart';
import 'package:omeeowash/widgets.dart/utility_widgets.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: const [
            BookingScreenTopBar(),
            // 👇 only this part scrolls
            Expanded(child: TopNavTabSwitcher()),
          ],
        ),
      ),
    );
  }
}

class BookingScreenTopBar extends StatelessWidget {
  const BookingScreenTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.all(10),
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'My Bookings',
                    textColor: Theme.of(context).colorScheme.primary,
                    textSize: TextSizes.heading1,
                    textWeight: FontWeight.w900,
                  ),
                  CustomText(
                    text: 'Manage appointments 📚',
                    textColor: Theme.of(context).colorScheme.surface,
                    textSize: TextSizes.heading3,
                  ),
                ],
              ),
              // Actions
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      FontAwesomeIcons.filter,
                      size: IconSizes.midSmall,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      FontAwesomeIcons.plus,
                      size: IconSizes.midSmall,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const CustomTopNav(),
        ],
      ),
    );
  }
}

class CustomTopNav extends StatefulWidget {
  const CustomTopNav({super.key});

  @override
  State<CustomTopNav> createState() => _CustomTopNavState();
}

class _CustomTopNavState extends State<CustomTopNav> {
  Stream<List<Map<String, dynamic>>> _userBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid) // ✅ no composite index needed
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  @override
  Widget build(BuildContext context) {
    final topNavProvider = Provider.of<TopNavProvider>(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _userBookings(),
      builder: (context, snap) {
        final data = snap.data ?? const [];
        const activeSet = {'pending', 'confirmed', 'in_progress'};
        const historySet = {'completed', 'cancelled'};

        final activeCount = data
            .where((b) => activeSet.contains('${b['status']}'))
            .length;
        final historyCount = data
            .where((b) => historySet.contains('${b['status']}'))
            .length;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            color: Theme.of(context).colorScheme.secondary,
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TopNavBarTab(
                  onPressed: () => topNavProvider.selectTab('Active'),
                  textWidget: 'Active',
                  numberWidget: activeCount.toString(),
                  borderRadius: 15,
                ),
              ),
              Expanded(
                child: TopNavBarTab(
                  onPressed: () => topNavProvider.selectTab('History'),
                  textWidget: 'History',
                  numberWidget: historyCount.toString(),
                  borderRadius: 15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TopNavTabSwitcher extends StatelessWidget {
  const TopNavTabSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTab = context.watch<TopNavProvider>().tabName;

    switch (selectedTab) {
      case 'Booking Status':
        return const ActiveTabScreen();
      case 'History':
        return const HistoryTabScreen();
      default:
        return const ActiveTabScreen();
    }
  }
}

/// Removes overscroll glow
class _NoGlowScroll extends ScrollBehavior {
  const _NoGlowScroll();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class ActiveTabScreen extends StatelessWidget {
  const ActiveTabScreen({super.key});

  // ... keep your helpers as-is ...

  Stream<List<Map<String, dynamic>>> _userBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .snapshots()
        // ⬇️ carry doc id too (handy later)
        .map((s) => s.docs.map((d) => {'__docId': d.id, ...d.data()}).toList());
  }

  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

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
    if (v == 'confirmed' || v == 'booked') return 'confirmed';
    if (v == 'completed' || v == 'done' || v == 'finished') return 'completed';
    if (v == 'cancelled' || v == 'canceled') return 'cancelled';
    return v;
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
              final bSenderId = b["userId"];
              final bRecieverId = b['decision']['byUid'] ?? "";

              // wash schema (unchanged)
              final List<String> stageOrder =
                  (b['washStageOrder'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  const [];
              final Map<String, dynamic> stages =
                  (b['washStages'] as Map?)?.cast<String, dynamic>() ??
                  const {};

              // ⬇️ NEW: read the decision block safely
              final Map<String, dynamic> decision =
                  (b['decision'] as Map?)?.cast<String, dynamic>() ?? const {};
              final String? decisionType = (decision['type'] as String?)
                  ?.trim();
              final String? decisionByUid = (decision['byUid'] as String?)
                  ?.trim();
              final String? decisionByName = (decision['byName'] as String?)
                  ?.trim();
              final String? decisionReason = (decision['reason'] as String?)
                  ?.trim();
              final DateTime? decisionAt = _toDate(decision['at']);
              final bookingId = b["bookingId"];

              return BookingsServiceButton(
                bookingRecieverId: bRecieverId,
                bookingSenderId: bSenderId,
                bookingId: bookingId,
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
                // details
                address: b['address'] as String?,
                latitude: (b['latitude'] as num?)?.toDouble(),
                longitude: (b['longitude'] as num?)?.toDouble(),

                // wash progress
                washStageOrder: stageOrder,
                washStages: stages,

                // ⬇️ pass-through decision fields
                decisionType: decisionType,
                decisionByUid: decisionByUid,
                decisionByName: decisionByName,
                decisionReason: decisionReason,
                decisionAt: decisionAt,
                // visuals
                icon: Icon(
                  FontAwesomeIcons.carSide,
                  size: TextSizes.bodyText1,
                  color: const Color.fromARGB(255, 226, 226, 226),
                ),
                scale: 1.7,
                onPressed: () {},
                iconColor: Theme.of(context).colorScheme.primary,
                iconSize: IconSizes.medium,
              );
            },
          );
        },
      ),
    );
  }
}

class HistoryTabScreen extends StatelessWidget {
  const HistoryTabScreen({super.key});

  Stream<List<Map<String, dynamic>>> _userBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
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
            return const _ErrorState(message: 'Could not load history.');
          }

          final raw = snap.data ?? const [];
          const hist = {'completed', 'cancelled', 'canceled'};
          final items = raw
              .where((b) => hist.contains('${b['status']}'))
              .toList();

          // sort by scheduledTime desc
          items.sort((a, b) {
            final at = _extractDate(a['scheduledTime']);
            final bt = _extractDate(b['scheduledTime']);
            return (bt ?? DateTime(0)).compareTo(at ?? DateTime(0));
          });

          if (items.isEmpty) {
            return const _EmptyState(
              title: 'No past bookings',
              subtitle: 'Your completed or cancelled bookings will show here.',
              icon: FontAwesomeIcons.clockRotateLeft,
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
              final serviceType = '${b['serviceType']}'.trim();
              final bookingId = b["bookingId"];
              return BookingsServiceButton(
                bookingId: bookingId,
                service: _serviceLabel(serviceType),
                serviceLocation: _locationLabel(b),
                status: '${b['status']}',
                day: _dayLabel(dt),
                time: _timeLabel(dt, b['scheduledTimeLabel']),
                duration: _durationForService(serviceType) == null
                    ? '⏱️ —'
                    : '⏱️ ${_durationForService(serviceType)} min',
                price: (b['price']?.toString()),
                icon: Icon(
                  FontAwesomeIcons.carSide,
                  size: TextSizes.bodyText1,
                  color: const Color.fromARGB(255, 226, 226, 226),
                ),
                scale: 1.7,
                onPressed: () {},
                iconColor: Theme.of(context).colorScheme.primary,
                iconSize: IconSizes.medium,
              );
            },
          );
        },
      ),
    );
  }
}

/// ---------- Small UI states ----------

class _ListLoading extends StatelessWidget {
  const _ListLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FontAwesomeIcons.triangleExclamation,
              size: 28,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: cs.primary.withOpacity(.65)),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13.5,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------- Helpers (dates, labels, mapping) ----------

DateTime? _extractDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) {
    // support ISO strings like "2025-10-17"
    try {
      return DateTime.parse(v);
    } catch (_) {}
  }
  return null;
}

String _dayLabel(DateTime? dt) {
  if (dt == null) return '—';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);

  if (d == today) return 'Today';

  const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final wd = w[dt.weekday - 1];
  return '$wd ${dt.day}/${dt.month}';
}

String _timeLabel(DateTime? dt, dynamic fallbackField) {
  if (dt != null) {
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h12:$m $ampm';
  }
  final s = (fallbackField ?? '').toString().trim(); // e.g., "12:00"
  return s.isEmpty ? '—' : s;
}

int? _durationForService(String serviceType) {
  switch (serviceType.toLowerCase()) {
    case 'express':
    case 'express wash':
      return 10;
    case 'standard':
    case 'standard wash':
      return 30;
    case 'premium':
    case 'premium detail':
      return 120;
    default:
      return null;
  }
}

String _serviceLabel(String raw) {
  switch (raw.toLowerCase()) {
    case 'express':
      return 'Express Wash';
    case 'standard':
      return 'Standard Wash';
    case 'premium':
      return 'Premium Detail';
    default:
      if (raw.isEmpty) return 'Service';
      return raw[0].toUpperCase() + raw.substring(1);
  }
}

String _locationLabel(Map<String, dynamic> b) {
  final loc = (b['serviceLocation'] ?? '').toString();
  final addr = (b['address'] ?? '').toString();
  final address = addr.isNotEmpty ? addr : loc;
  return '📍 $address';
}
