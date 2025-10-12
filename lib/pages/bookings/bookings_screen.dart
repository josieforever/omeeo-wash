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
                  onPressed: () => topNavProvider.selectTab('Booking Status'),
                  textWidget: 'Booking Status',
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
        return const StatusTabScreen();
      case 'History':
        return const HistoryTabScreen();
      default:
        return const StatusTabScreen();
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

class StatusTabScreen extends StatelessWidget {
  const StatusTabScreen({super.key});

  // Map DB strings to a small canonical set
  String _canonicalStatus(dynamic s) {
    final v = '${s ?? ''}'.trim().toLowerCase();
    if (v == 'pending' ||
        v == 'pending_cash' ||
        v == 'pending-card' ||
        v == 'awaiting_payment') {
      return 'pending';
    }
    if (v == 'in_progress' ||
        v == 'inprogress' ||
        v == 'in-progress' ||
        v == 'processing') {
      return 'in_progress';
    }
    if (v == 'confirmed' || v == 'booked') {
      return 'confirmed';
    }
    if (v == 'completed' || v == 'done' || v == 'finished') {
      return 'completed';
    }
    if (v == 'cancelled' || v == 'canceled') {
      return 'cancelled';
    }
    return v; // fallback
  }

  DateTime? _extractDate(dynamic tsOrIso) {
    if (tsOrIso == null) return null;
    try {
      // Firestore Timestamp
      if (tsOrIso is Timestamp) return tsOrIso.toDate();
      // ISO string
      if (tsOrIso is String) return DateTime.tryParse(tsOrIso);
    } catch (_) {}
    return null;
  }

  String _serviceLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'express':
        return 'Express Wash';
      case 'standard':
        return 'Standard Wash';
      case 'premium':
      default:
        return 'Premium Detail';
    }
  }

  // import 'package:intl/intl.dart';
  String _dayLabel(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(dt);
    if (day == now) return 'Today';
    if (day == now.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('MMM d').format(day).toLowerCase(); // e.g., "dec 10"
  }

  String _timeLabel(DateTime? dt, dynamic labelFromDb) {
    // Try to normalize a DB-provided label first.
    final fromDb = _convertDbLabelTo12h(labelFromDb?.toString());
    if (fromDb != null) return fromDb;

    // Fallback to DateTime
    if (dt == null) return '—';
    return _format12h(dt.hour, dt.minute);
  }

  String? _convertDbLabelTo12h(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    // Matches: "14:05", "2:05", "2:05pm", "02:05 PM", etc.
    final re = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?$');
    final m = re.firstMatch(s);
    if (m == null) return null;

    var h = int.tryParse(m.group(1)!) ?? 0;
    final min = int.tryParse(m.group(2)!) ?? 0;
    final ampmRaw = m.group(3);

    if (ampmRaw != null) {
      // Has AM/PM → normalize case and convert to 24h first
      final ampm = ampmRaw.toUpperCase();
      if (ampm == 'PM' && h != 12) h += 12;
      if (ampm == 'AM' && h == 12) h = 0;
    } else {
      // No AM/PM → assume 24h input (e.g., "14:30")
      h = h.clamp(0, 23);
    }

    return _format12h(h, min);
  }

  String _format12h(int hour24, int minute) {
    final h12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final mm = minute.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    return '$h12:$mm $ampm';
  }

  int? _durationForService(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'express':
        return 10;
      case 'standard':
        return 30;
      case 'premium':
        return 120;
      default:
        return null;
    }
  }

  String _locationLabel(Map<String, dynamic> b) {
    // Prefer address string, fallback to location name if you have one.
    final addr =
        '${b['address'] ?? b['location'] ?? b['serviceLocation'] ?? ''}'.trim();
    if (addr.isEmpty) return '—';
    return '📍 $addr';
  }

  Stream<List<Map<String, dynamic>>> _userBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid) // ✅ single-filter stream
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
            return const _ErrorState(message: 'Could not load bookings.');
          }

          final raw = snap.data ?? const [];
          final items = raw.where((b) {
            final s = _canonicalStatus(b['status']);
            return s == 'pending' || s == 'in_progress' || s == 'confirmed';
          }).toList();

          // sort by scheduledTime asc (client-side)
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

              return BookingsServiceButton(
                service: _serviceLabel(serviceType),
                serviceLocation: _locationLabel(b),
                status: canonical, // 👈 pass canonical status
                day: _dayLabel(dt),
                time: _timeLabel(dt, b['scheduledTimeLabel']),
                duration: (() {
                  final d = _durationForService(serviceType);
                  return d == null ? '⏱️ —' : '⏱️ $d min';
                })(),
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

              return BookingsServiceButton(
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
