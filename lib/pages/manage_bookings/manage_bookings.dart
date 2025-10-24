import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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

class ManageBookingsScreen extends StatelessWidget {
  const ManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: const [
          ManageBookingsScreenTopBar(),
          // 👇 only this part scrolls
          Expanded(child: ManageBookingsTopNavTabSwitcher()),
        ],
      ),
    );
  }
}

class ManageBookingsTopNavTabSwitcher extends StatelessWidget {
  const ManageBookingsTopNavTabSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTab = context.watch<TopNavProvider>().tabName;

    switch (selectedTab) {
      case 'New':
        return const NewBookingsScreen();
      case 'Active':
        return const ActiveBookingScreen();
      case 'Done':
        return const DoneBookingsScreen();
      case 'Decline':
        return const DeclinedBookingScreen();
      default:
        return const NewBookingsScreen();
    }
  }
}

class ManageBookingsScreenTopBar extends StatelessWidget {
  const ManageBookingsScreenTopBar({super.key});

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
                    text: 'Manage Bookings',
                    textColor: Theme.of(context).colorScheme.primary,
                    textSize: TextSizes.heading1,
                    textWeight: FontWeight.w900,
                  ),
                  CustomText(
                    text: 'Accept requests & track progress',
                    textColor: Theme.of(context).colorScheme.surface,
                    textSize: TextSizes.heading3,
                  ),
                ],
              ),

              // Actions
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
                child: ManageBookingsTopNavBarTab(
                  onPressed: () => topNavProvider.selectTab('New'),
                  textWidget: 'New',
                  numberWidget: activeCount.toString(),
                  borderRadius: 15,
                ),
              ),
              Expanded(
                child: ManageBookingsTopNavBarTab(
                  onPressed: () => topNavProvider.selectTab('Active'),
                  textWidget: 'Active',
                  numberWidget: historyCount.toString(),
                  borderRadius: 15,
                ),
              ),
              Expanded(
                child: ManageBookingsTopNavBarTab(
                  onPressed: () => topNavProvider.selectTab('Done'),
                  textWidget: 'Done',
                  numberWidget: historyCount.toString(),
                  borderRadius: 15,
                ),
              ),
              Expanded(
                child: ManageBookingsTopNavBarTab(
                  onPressed: () => topNavProvider.selectTab('Decline'),
                  textWidget: 'Decline',
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

class NewBookingsScreen extends StatelessWidget {
  const NewBookingsScreen({super.key});

  /// Stream ALL pending bookings (no user filter). No orderBy → sort client-side.
  Stream<List<Map<String, dynamic>>> _pendingBookingsStream() {
    final q = FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: 'pending');

    return q.snapshots().map((s) {
      final list = s.docs.map((d) {
        final data = d.data();
        // Put doc id after spread so a field named "id" can't overwrite it
        final map = <String, dynamic>{...data, '__docId': d.id};
        debugPrint(
          "[NewBookings] fetched __docId=${map['__docId']} "
          "status=${map['status']} userId=${map['userId']}",
        );
        return map;
      }).toList();

      // ---- sort by order asc, then createdAt desc, then scheduledTime asc ----
      int? orderNo(Map<String, dynamic> m) {
        final v = m['order'] ?? m['orderNo'] ?? m['order_number'];
        if (v is num) return v.toInt();
        if (v is String) return int.tryParse(v);
        return null;
      }

      DateTime createdAt(Map<String, dynamic> m) {
        final v = m['createdAt'];
        if (v is Timestamp) return v.toDate();
        if (v is String)
          return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      DateTime scheduled(Map<String, dynamic> m) {
        final v = m['scheduledTime'];
        if (v is Timestamp) return v.toDate();
        if (v is String) return DateTime.tryParse(v) ?? DateTime(2100);
        return DateTime(2100);
      }

      list.sort((a, b) {
        final oa = orderNo(a), ob = orderNo(b);
        if (oa != null && ob != null && oa != ob) return oa.compareTo(ob);

        final createdCmp = createdAt(b).compareTo(createdAt(a)); // newest first
        if (createdCmp != 0) return createdCmp;

        return scheduled(a).compareTo(scheduled(b)); // soonest first
      });

      return list;
    });
  }

  // ---------- helpers ----------
  DateTime? _extractDate(dynamic tsOrIso) {
    if (tsOrIso == null) return null;
    if (tsOrIso is Timestamp) return tsOrIso.toDate();
    if (tsOrIso is String) return DateTime.tryParse(tsOrIso);
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

  String _dayLabel(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(dt);
    if (day == now) return 'Today';
    if (day == now.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('MMM d').format(day).toLowerCase();
  }

  String _format12h(int hour24, int minute) {
    final h12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final mm = minute.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    return '$h12:$mm $ampm';
  }

  String _timeLabel(DateTime? dt, dynamic labelFromDb) {
    final s = labelFromDb?.toString();
    if (s != null && s.trim().isNotEmpty) return s; // already like "08:30 AM"
    if (dt == null) return '—';
    return _format12h(dt.hour, dt.minute);
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
    final addr =
        '${b['address'] ?? b['location'] ?? b['serviceLocation'] ?? ''}'.trim();
    return addr.isEmpty ? '—' : '📍 $addr';
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _NoGlowScroll(),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _pendingBookingsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _ListLoading();
          }
          if (snap.hasError) {
            return const _ErrorState(message: 'Could not load bookings.');
          }

          final items = snap.data ?? const [];

          if (items.isEmpty) {
            return const _EmptyState(
              title: 'No pending bookings',
              subtitle: 'You’ll see pending bookings here.',
              icon: FontAwesomeIcons.calendarXmark,
            );
          }

          // Optional: log how many
          debugPrint("[NewBookings] showing ${items.length} pending bookings");

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = items[i];
              final dt = _extractDate(b['scheduledTime']);
              final serviceType = '${b['serviceType'] ?? ''}';
              final vehicleType = '${b['vehicleType'] ?? ''}';

              // Ensure booking id is present
              final bookingId =
                  (b['__docId'] as String?) ??
                  (b['docId'] as String?) ??
                  (b['id'] as String?) ??
                  (b['bookingId'] as String?);
              debugPrint("[NewBookings] build[$i] bookingId=$bookingId");

              // wash progress (if any, harmless here)
              final List<String> stageOrder =
                  (b['washStageOrder'] as List?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  const [];
              final Map<String, dynamic> stages =
                  (b['washStages'] as Map?)?.cast<String, dynamic>() ??
                  const {};

              return ManageBookingsButton(
                bookingId: bookingId, // 🔑 needed for accept/decline
                service: _serviceLabel(serviceType),
                serviceLocation: _locationLabel(b),
                status: 'pending',
                day: _dayLabel(dt),
                time: _timeLabel(dt, b['scheduledTimeLabel']),
                duration: (() {
                  final d = _durationForService(serviceType);
                  return d == null ? '⏱️ —' : '⏱️ $d min';
                })(),
                price: (b['price']?.toString()),
                vehicleType: vehicleType,
                address: b['address'] as String?,
                latitude: (b['latitude'] as num?)?.toDouble(),
                longitude: (b['longitude'] as num?)?.toDouble(),
                washStageOrder: stageOrder,
                washStages: stages,
                // Use values from the booking doc (no profile mixing here)
                customerName:
                    (b['customerName'] as String?) ??
                    (b['userName'] as String?),
                customerPhone:
                    (b['phone'] as String?) ?? (b['phoneNumber'] as String?),
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

class DoneBookingsScreen extends StatelessWidget {
  const DoneBookingsScreen({super.key});

  // ---------- Booking + Profile combined stream (current user) ----------
  Stream<Map<String, dynamic>> _userProfileAndBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Stream.value(<String, dynamic>{
        'profile': null,
        'bookings': <Map<String, dynamic>>[],
      });
    }

    final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final bookingsRef = FirebaseFirestore.instance.collection('bookings');

    final profileStream = usersRef.snapshots().map<Map<String, dynamic>?>(
      (doc) => doc.data(),
    );

    // No orderBy → avoid composite index; sort client-side
    final bookingsStream = bookingsRef
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map<List<Map<String, dynamic>>>((s) {
          final list = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          // newest first by scheduledTime
          list.sort((a, b) {
            final at =
                (a['scheduledTime'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bt =
                (b['scheduledTime'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });
          return list;
        });

    final controller = StreamController<Map<String, dynamic>>.broadcast();

    Map<String, dynamic>? latestProfile;
    List<Map<String, dynamic>> latestBookings = const [];

    late final StreamSubscription profileSub;
    late final StreamSubscription bookingsSub;

    void emit() {
      controller.add({'profile': latestProfile, 'bookings': latestBookings});
    }

    controller.onListen = () {
      emit();
      profileSub = profileStream.listen((p) {
        latestProfile = p;
        emit();
      }, onError: controller.addError);

      bookingsSub = bookingsStream.listen((b) {
        latestBookings = b;
        emit();
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      await profileSub.cancel();
      await bookingsSub.cancel();
    };

    return controller.stream;
  }

  // ------------------ Helpers (same style as the other screens) ------------------

  String _canonicalStatus(dynamic s) {
    final v = '${s ?? ''}'.trim().toLowerCase();
    if (v == 'pending' ||
        v == 'pending_cash' ||
        v == 'pending-card' ||
        v == 'awaiting_payment')
      return 'pending';
    if (v == 'in_progress' || v == 'in-progress' || v == 'processing')
      return 'in_progress';
    if (v == 'confirmed' || v == 'booked') return 'confirmed';
    if (v == 'completed' || v == 'done' || v == 'finished') return 'completed';
    if (v == 'cancelled' ||
        v == 'canceled' ||
        v == 'declined' ||
        v == 'rejected')
      return 'declined';
    return v;
  }

  DateTime? _extractDate(dynamic tsOrIso) {
    if (tsOrIso == null) return null;
    try {
      if (tsOrIso is Timestamp) return tsOrIso.toDate();
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

  String _dayLabel(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(dt);
    if (day == now) return 'Today';
    if (day == now.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('MMM d').format(day).toLowerCase();
  }

  String _format12h(int hour24, int minute) {
    final h12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final mm = minute.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    return '$h12:$mm $ampm';
  }

  String _timeLabel(DateTime? dt, dynamic labelFromDb) {
    final s = labelFromDb?.toString();
    if (s != null && s.trim().isNotEmpty) return s;
    if (dt == null) return '—';
    return _format12h(dt.hour, dt.minute);
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
    final addr =
        '${b['address'] ?? b['location'] ?? b['serviceLocation'] ?? ''}'.trim();
    return addr.isEmpty ? '—' : '📍 $addr';
  }

  // --- profile name/phone helpers (same as others) ---
  String? _readStr(Map<String, dynamic>? map, String path) {
    if (map == null) return null;
    dynamic cur = map;
    for (final seg in path.split('.')) {
      if (cur is Map && cur.containsKey(seg)) {
        cur = cur[seg];
      } else {
        return null;
      }
    }
    final s = cur?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  String? _firstNonEmpty(Iterable<String?> vals) {
    for (final v in vals) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  String? _bestProfileName(Map<String, dynamic>? p, User? auth) {
    final first = _firstNonEmpty([
      _readStr(p, 'firstName'),
      _readStr(p, 'profile.firstName'),
    ]);
    final last = _firstNonEmpty([
      _readStr(p, 'lastName'),
      _readStr(p, 'profile.lastName'),
    ]);
    final full = _firstNonEmpty([
      if (first != null || last != null)
        [first, last].whereType<String>().join(' '),
    ]);
    return _firstNonEmpty([
      _readStr(p, 'displayName'),
      _readStr(p, 'name'),
      _readStr(p, 'fullName'),
      _readStr(p, 'profile.displayName'),
      full,
      auth?.displayName,
    ]);
  }

  String? _bestProfilePhone(Map<String, dynamic>? p, User? auth) {
    return _firstNonEmpty([
      _readStr(p, 'phone'),
      _readStr(p, 'phoneNumber'),
      _readStr(p, 'mobile'),
      _readStr(p, 'contact.phone'),
      _readStr(p, 'profile.phone'),
      _readStr(p, 'phones.primary'),
      _readStr(p, 'tel'),
      auth?.phoneNumber,
    ]);
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _NoGlowScroll(),
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _userProfileAndBookings(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _ListLoading();
          }
          if (snap.hasError) {
            return const _ErrorState(
              message: 'Could not load completed bookings.',
            );
          }

          final combined =
              snap.data ??
              const {'profile': null, 'bookings': <Map<String, dynamic>>[]};
          final profile = combined['profile'] as Map<String, dynamic>?;
          final raw = (combined['bookings'] as List)
              .cast<Map<String, dynamic>>();

          // ✅ Only COMPLETED
          final items = raw.where((b) {
            final s = _canonicalStatus(b['status']);
            return s == 'completed';
          }).toList();

          // Sort by most recent scheduled time first
          items.sort((a, b) {
            final at = _extractDate(a['scheduledTime']) ?? DateTime(0);
            final bt = _extractDate(b['scheduledTime']) ?? DateTime(0);
            return bt.compareTo(at);
          });

          if (items.isEmpty) {
            return const _EmptyState(
              title: 'No completed bookings',
              subtitle: 'Completed bookings will appear here.',
              icon: FontAwesomeIcons.solidCircleCheck,
            );
          }

          final auth = FirebaseAuth.instance.currentUser;
          final profileName = _bestProfileName(profile, auth);
          final profilePhone = _bestProfilePhone(profile, auth);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = items[i];
              final dt = _extractDate(b['scheduledTime']);
              final serviceType = '${b['serviceType'] ?? ''}'.trim();

              return ManageBookingsButton(
                service: _serviceLabel(serviceType),
                serviceLocation: _locationLabel(b),
                status: 'completed',
                day: _dayLabel(dt),
                time: _timeLabel(dt, b['scheduledTimeLabel']),
                duration: (() {
                  final d = _durationForService(serviceType);
                  return d == null ? '⏱️ —' : '⏱️ $d min';
                })(),
                price: (b['price']?.toString()),
                vehicleType: '${b['vehicleType'] ?? ''}',

                // details for sheet
                address: b['address'] as String?,
                latitude: (b['latitude'] as num?)?.toDouble(),
                longitude: (b['longitude'] as num?)?.toDouble(),

                // wash progress (optional)
                washStageOrder:
                    (b['washStageOrder'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    const [],
                washStages:
                    (b['washStages'] as Map?)?.cast<String, dynamic>() ??
                    const {},

                // 👇 profile info like NewBookingsScreen
                customerName: profileName ?? (b['customerName'] as String?),
                customerPhone:
                    profilePhone ??
                    (b['phone'] as String?) ??
                    (b['phoneNumber'] as String?),

                // visuals
                icon: Icon(
                  FontAwesomeIcons.solidCircleCheck,
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

class DeclinedBookingScreen extends StatelessWidget {
  const DeclinedBookingScreen({super.key});

  // ---------- Booking + Profile combined stream (current user) ----------
  Stream<Map<String, dynamic>> _userProfileAndBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Stream.value(<String, dynamic>{
        'profile': null,
        'bookings': <Map<String, dynamic>>[],
      });
    }

    final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final bookingsRef = FirebaseFirestore.instance.collection('bookings');

    final profileStream = usersRef.snapshots().map<Map<String, dynamic>?>(
      (doc) => doc.data(),
    );

    // No orderBy → avoid composite index; we’ll sort client-side
    final bookingsStream = bookingsRef
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map<List<Map<String, dynamic>>>((s) {
          final list = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          // newest first by scheduledTime
          list.sort((a, b) {
            final at =
                (a['scheduledTime'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bt =
                (b['scheduledTime'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });
          return list;
        });

    final controller = StreamController<Map<String, dynamic>>.broadcast();

    Map<String, dynamic>? latestProfile;
    List<Map<String, dynamic>> latestBookings = const [];

    late final StreamSubscription profileSub;
    late final StreamSubscription bookingsSub;

    void emit() {
      controller.add({'profile': latestProfile, 'bookings': latestBookings});
    }

    controller.onListen = () {
      emit();
      profileSub = profileStream.listen((p) {
        latestProfile = p;
        emit();
      }, onError: controller.addError);

      bookingsSub = bookingsStream.listen((b) {
        latestBookings = b;
        emit();
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      await profileSub.cancel();
      await bookingsSub.cancel();
    };

    return controller.stream;
  }

  // ------------------ Helpers (same style as your other screens) ------------------

  String _canonicalStatus(dynamic s) {
    final v = '${s ?? ''}'.trim().toLowerCase();
    if (v == 'pending' ||
        v == 'pending_cash' ||
        v == 'pending-card' ||
        v == 'awaiting_payment') {
      return 'pending';
    }
    if (v == 'in_progress' || v == 'in-progress' || v == 'processing') {
      return 'in_progress';
    }
    if (v == 'confirmed' || v == 'booked') return 'confirmed';
    if (v == 'completed' || v == 'done' || v == 'finished') return 'completed';
    if (v == 'cancelled' ||
        v == 'canceled' ||
        v == 'declined' ||
        v == 'rejected')
      return 'declined';
    return v;
  }

  DateTime? _extractDate(dynamic tsOrIso) {
    if (tsOrIso == null) return null;
    try {
      if (tsOrIso is Timestamp) return tsOrIso.toDate();
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

  String _dayLabel(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(dt);
    if (day == now) return 'Today';
    if (day == now.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('MMM d').format(day).toLowerCase();
  }

  String _format12h(int hour24, int minute) {
    final h12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final mm = minute.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    return '$h12:$mm $ampm';
  }

  String _timeLabel(DateTime? dt, dynamic labelFromDb) {
    final s = labelFromDb?.toString();
    if (s != null && s.trim().isNotEmpty) return s;
    if (dt == null) return '—';
    return _format12h(dt.hour, dt.minute);
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
    final addr =
        '${b['address'] ?? b['location'] ?? b['serviceLocation'] ?? ''}'.trim();
    return addr.isEmpty ? '—' : '📍 $addr';
  }

  // --- robust name/phone pickers (profile first, with fallbacks) ---
  String? _readStr(Map<String, dynamic>? map, String path) {
    if (map == null) return null;
    dynamic cur = map;
    for (final seg in path.split('.')) {
      if (cur is Map && cur.containsKey(seg)) {
        cur = cur[seg];
      } else {
        return null;
      }
    }
    final s = cur?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  String? _firstNonEmpty(Iterable<String?> vals) {
    for (final v in vals) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  String? _bestProfileName(Map<String, dynamic>? p, User? auth) {
    final first = _firstNonEmpty([
      _readStr(p, 'firstName'),
      _readStr(p, 'profile.firstName'),
    ]);
    final last = _firstNonEmpty([
      _readStr(p, 'lastName'),
      _readStr(p, 'profile.lastName'),
    ]);
    final full = _firstNonEmpty([
      if (first != null || last != null)
        [first, last].whereType<String>().join(' '),
    ]);
    return _firstNonEmpty([
      _readStr(p, 'displayName'),
      _readStr(p, 'name'),
      _readStr(p, 'fullName'),
      _readStr(p, 'profile.displayName'),
      full,
      auth?.displayName,
    ]);
  }

  String? _bestProfilePhone(Map<String, dynamic>? p, User? auth) {
    return _firstNonEmpty([
      _readStr(p, 'phone'),
      _readStr(p, 'phoneNumber'),
      _readStr(p, 'mobile'),
      _readStr(p, 'contact.phone'),
      _readStr(p, 'profile.phone'),
      _readStr(p, 'phones.primary'),
      _readStr(p, 'tel'),
      auth?.phoneNumber,
    ]);
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _NoGlowScroll(),
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _userProfileAndBookings(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _ListLoading();
          }
          if (snap.hasError) {
            return const _ErrorState(
              message: 'Could not load declined bookings.',
            );
          }

          final combined =
              snap.data ??
              const {'profile': null, 'bookings': <Map<String, dynamic>>[]};
          final profile = combined['profile'] as Map<String, dynamic>?;
          final raw = (combined['bookings'] as List)
              .cast<Map<String, dynamic>>();

          // ✅ Only declined/cancelled
          final items = raw.where((b) {
            final s = _canonicalStatus(b['status']);
            return s == 'declined';
          }).toList();

          // Sort by most recent scheduled time
          items.sort((a, b) {
            final at = _extractDate(a['scheduledTime']) ?? DateTime(0);
            final bt = _extractDate(b['scheduledTime']) ?? DateTime(0);
            return bt.compareTo(at);
          });

          if (items.isEmpty) {
            return const _EmptyState(
              title: 'No declined bookings',
              subtitle: 'Declined or cancelled bookings will appear here.',
              icon: FontAwesomeIcons.circleXmark,
            );
          }

          final auth = FirebaseAuth.instance.currentUser;
          final profileName = _bestProfileName(profile, auth);
          final profilePhone = _bestProfilePhone(profile, auth);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = items[i];
              final dt = _extractDate(b['scheduledTime']);
              final serviceType = '${b['serviceType'] ?? ''}'.trim();

              return ManageBookingsButton(
                service: _serviceLabel(serviceType),
                serviceLocation: _locationLabel(b),
                status: 'declined', // normalized
                day: _dayLabel(dt),
                time: _timeLabel(dt, b['scheduledTimeLabel']),
                duration: (() {
                  final d = _durationForService(serviceType);
                  return d == null ? '⏱️ —' : '⏱️ $d min';
                })(),
                price: (b['price']?.toString()),
                vehicleType: '${b['vehicleType'] ?? ''}',

                // details for sheet
                address: b['address'] as String?,
                latitude: (b['latitude'] as num?)?.toDouble(),
                longitude: (b['longitude'] as num?)?.toDouble(),

                // wash progress (optional, probably empty for declined)
                washStageOrder:
                    (b['washStageOrder'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    const [],
                washStages:
                    (b['washStages'] as Map?)?.cast<String, dynamic>() ??
                    const {},

                // 👇 profile info (like NewBookingsScreen)
                customerName: profileName ?? (b['customerName'] as String?),
                customerPhone:
                    profilePhone ??
                    (b['phone'] as String?) ??
                    (b['phoneNumber'] as String?),

                // visuals
                icon: Icon(
                  FontAwesomeIcons.circleXmark,
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

class _NoGlowScroll extends ScrollBehavior {
  const _NoGlowScroll();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class _ListLoading extends StatelessWidget {
  const _ListLoading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Text(message));
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
  Widget build(BuildContext context) => Center(child: Text(title));
}

class ActiveBookingScreen extends StatelessWidget {
  const ActiveBookingScreen({super.key});

  // ---------- Booking + Profile combined stream (current user) ----------
  Stream<Map<String, dynamic>> _userProfileAndBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Stream.value(<String, dynamic>{
        'profile': null,
        'bookings': <Map<String, dynamic>>[],
      });
    }

    final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final bookingsRef = FirebaseFirestore.instance.collection('bookings');

    final profileStream = usersRef.snapshots().map<Map<String, dynamic>?>(
      (doc) => doc.data(),
    );

    // No orderBy → avoid composite index; sort client-side
    final bookingsStream = bookingsRef
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map<List<Map<String, dynamic>>>((s) {
          final list = s.docs.map((d) {
            final data = d.data();
            // ⚠️ put the doc id AFTER the spread so it cannot be overwritten by a field named "id"
            final map = <String, dynamic>{...data, '__docId': d.id};
            // debug: verify we carry the id
            debugPrint(
              "active (map) -> __docId=${map['__docId']} status=${map['status']}",
            );
            return map;
          }).toList();

          // newest first
          list.sort((a, b) {
            final at =
                (a['scheduledTime'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bt =
                (b['scheduledTime'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });
          return list;
        });

    final controller = StreamController<Map<String, dynamic>>.broadcast();

    Map<String, dynamic>? latestProfile;
    List<Map<String, dynamic>> latestBookings = const [];

    late final StreamSubscription profileSub;
    late final StreamSubscription bookingsSub;

    void emit() {
      controller.add({'profile': latestProfile, 'bookings': latestBookings});
    }

    controller.onListen = () {
      emit();
      profileSub = profileStream.listen((p) {
        latestProfile = p;
        emit();
      }, onError: controller.addError);

      bookingsSub = bookingsStream.listen((b) {
        latestBookings = b;
        emit();
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      await profileSub.cancel();
      await bookingsSub.cancel();
    };

    return controller.stream;
  }

  // ------------------ Helpers (same as NewBookingsScreen) ------------------

  String _canonicalStatus(dynamic s) {
    final v = '${s ?? ''}'.trim().toLowerCase();
    if (v == 'pending' ||
        v == 'pending_cash' ||
        v == 'pending-card' ||
        v == 'awaiting_payment') {
      return 'pending';
    }
    if (v == 'in_progress' || v == 'in-progress' || v == 'processing') {
      return 'in_progress';
    }
    if (v == 'confirmed' || v == 'booked') return 'confirmed';
    if (v == 'completed' || v == 'done' || v == 'finished') return 'completed';
    if (v == 'cancelled' || v == 'canceled') return 'cancelled';
    return v;
  }

  DateTime? _extractDate(dynamic tsOrIso) {
    if (tsOrIso == null) return null;
    try {
      if (tsOrIso is Timestamp) return tsOrIso.toDate();
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

  String _dayLabel(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(dt);
    if (day == now) return 'Today';
    if (day == now.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('MMM d').format(day).toLowerCase();
  }

  String _format12h(int hour24, int minute) {
    final h12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final mm = minute.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    return '$h12:$mm $ampm';
  }

  String _timeLabel(DateTime? dt, dynamic labelFromDb) {
    final s = labelFromDb?.toString();
    if (s != null && s.trim().isNotEmpty) return s;
    if (dt == null) return '—';
    return _format12h(dt.hour, dt.minute);
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
    final addr =
        '${b['address'] ?? b['location'] ?? b['serviceLocation'] ?? ''}'.trim();
    return addr.isEmpty ? '—' : '📍 $addr';
  }

  // --- robust name/phone pickers (profile first, with fallbacks) ---
  String? _readStr(Map<String, dynamic>? map, String path) {
    if (map == null) return null;
    dynamic cur = map;
    for (final seg in path.split('.')) {
      if (cur is Map && cur.containsKey(seg)) {
        cur = cur[seg];
      } else {
        return null;
      }
    }
    final s = cur?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  String? _firstNonEmpty(Iterable<String?> vals) {
    for (final v in vals) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  String? _bestProfileName(Map<String, dynamic>? p, User? auth) {
    final first = _firstNonEmpty([
      _readStr(p, 'firstName'),
      _readStr(p, 'profile.firstName'),
    ]);
    final last = _firstNonEmpty([
      _readStr(p, 'lastName'),
      _readStr(p, 'profile.lastName'),
    ]);
    final full = _firstNonEmpty([
      if (first != null || last != null)
        [first, last].whereType<String>().join(' '),
    ]);
    return _firstNonEmpty([
      _readStr(p, 'displayName'),
      _readStr(p, 'name'),
      _readStr(p, 'fullName'),
      _readStr(p, 'profile.displayName'),
      full,
      auth?.displayName,
    ]);
  }

  String? _bestProfilePhone(Map<String, dynamic>? p, User? auth) {
    return _firstNonEmpty([
      _readStr(p, 'phone'),
      _readStr(p, 'phoneNumber'),
      _readStr(p, 'mobile'),
      _readStr(p, 'contact.phone'),
      _readStr(p, 'profile.phone'),
      _readStr(p, 'phones.primary'),
      _readStr(p, 'tel'),
      auth?.phoneNumber,
    ]);
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _NoGlowScroll(),
      child: StreamBuilder<Map<String, dynamic>>(
        stream: _userProfileAndBookings(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _ListLoading();
          }
          if (snap.hasError) {
            return const _ErrorState(
              message: 'Could not load active bookings.',
            );
          }

          final combined =
              snap.data ??
              const {'profile': null, 'bookings': <Map<String, dynamic>>[]};
          final profile = combined['profile'] as Map<String, dynamic>?;
          final raw = (combined['bookings'] as List)
              .cast<Map<String, dynamic>>();

          // ✅ only CONFIRMED or IN_PROGRESS
          final items = raw.where((b) {
            final s = _canonicalStatus(b['status']);
            return s == 'confirmed' || s == 'in_progress';
          }).toList();

          // Sort: in_progress first, then confirmed; each group by soonest time
          int rank(String s) => s == 'in_progress' ? 0 : 1;
          items.sort((a, b) {
            final sa = _canonicalStatus(a['status']);
            final sb = _canonicalStatus(b['status']);
            if (rank(sa) != rank(sb)) return rank(sa).compareTo(rank(sb));
            final at = _extractDate(a['scheduledTime']) ?? DateTime(2100);
            final bt = _extractDate(b['scheduledTime']) ?? DateTime(2100);
            return at.compareTo(bt);
          });

          if (items.isEmpty) {
            return const _EmptyState(
              title: 'No active bookings',
              subtitle: 'Confirmed or in-progress bookings will appear here.',
              icon: FontAwesomeIcons.calendarCheck,
            );
          }

          final auth = FirebaseAuth.instance.currentUser;
          final profileName = _bestProfileName(profile, auth);
          final profilePhone = _bestProfilePhone(profile, auth);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final b = items[i];
              final dt = _extractDate(b['scheduledTime']);
              final serviceType = '${b['serviceType'] ?? ''}'.trim();

              // DEBUG: ensure the id is present here
              debugPrint(
                "builder (active) -> bookingId=${b['__docId']} status=${b['status']}",
              );

              return ManageBookingsButton(
                // 🔑 pass the Firestore document id so stage taps can persist
                bookingId:
                    (b['__docId'] as String?) ??
                    (b['docId'] as String?) ??
                    (b['id'] as String?) ??
                    (b['bookingId'] as String?),

                service: _serviceLabel(serviceType),
                serviceLocation: _locationLabel(b),
                status: _canonicalStatus(
                  b['status'],
                ), // confirmed | in_progress
                day: _dayLabel(dt),
                time: _timeLabel(dt, b['scheduledTimeLabel']),
                duration: (() {
                  final d = _durationForService(serviceType);
                  return d == null ? '⏱️ —' : '⏱️ $d min';
                })(),
                price: (b['price']?.toString()),
                vehicleType: '${b['vehicleType'] ?? ''}',

                // details for sheet
                address: b['address'] as String?,
                latitude: (b['latitude'] as num?)?.toDouble(),
                longitude: (b['longitude'] as num?)?.toDouble(),

                // wash progress (optional)
                washStageOrder:
                    (b['washStageOrder'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    const [],
                washStages:
                    (b['washStages'] as Map?)?.cast<String, dynamic>() ??
                    const {},

                // profile info (with fallbacks)
                customerName: profileName ?? (b['customerName'] as String?),
                customerPhone:
                    profilePhone ??
                    (b['phone'] as String?) ??
                    (b['phoneNumber'] as String?),

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

class _AcceptOptions {
  final bool assignSelf;
  final bool enableTracking;
  const _AcceptOptions({
    required this.assignSelf,
    required this.enableTracking,
  });
}

class ManageBookingsButton extends StatelessWidget {
  // Core fields
  final String service;
  final String? serviceLocation;
  final String?
  status; // pending | confirmed | in_progress | completed | declined | ...
  final String? day; // e.g. Today
  final String? time; // e.g. 11:30 AM
  final String? duration; // e.g. ⏱️ 60 min
  final String? price; // plain number as string
  final String? address;
  final double? latitude;
  final double? longitude;

  // Live / static wash progress
  final String? bookingId;
  final List<String>? washStageOrder;
  final Map<String, dynamic>? washStages;
  final List<dynamic>? washProgressStages; // legacy array

  // Customer
  final String? customerName;
  final String? customerPhone;

  // Visuals / action
  final String? animation;
  final String? vehicleType;
  final Icon? icon;
  final Color iconColor;
  final double iconSize;
  final double? scale;
  final VoidCallback onPressed;

  const ManageBookingsButton({
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
    this.vehicleType,
    this.scale,
    this.bookingId,
    this.washStageOrder,
    this.washStages,
    this.washProgressStages,
    this.customerName,
    this.customerPhone,
  });

  // ---------- helpers ----------
  String _serviceLabel(String raw) {
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'express':
        return 'Express Wash';
      case 'standard':
        return 'Standard Wash';
      case 'premium':
        return 'Premium Detail';
      default:
        return raw.isEmpty ? 'Service' : raw;
    }
  }

  String _statusLabel(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'pending' ||
        v == 'pending_cash' ||
        v == 'pending-card' ||
        v == 'awaiting_payment') {
      return 'Pending';
    }
    if (v == 'confirmed' || v == 'booked') return 'Confirmed';
    if (v == 'in_progress' || v == 'in-progress' || v == 'processing')
      return 'In Progress';
    if (v == 'completed' || v == 'done' || v == 'finished') return 'Completed';
    if (v == 'cancelled' ||
        v == 'canceled' ||
        v == 'declined' ||
        v == 'rejected')
      return 'Declined';
    return (raw ?? '—');
  }

  String _serviceLocationLabel(String? raw) {
    final s = (raw ?? '').replaceAll('📍', '').trim();
    return s.isEmpty ? '—' : s;
  }

  String? _formatPhone(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('+')) return s; // already E.164
    if (s.startsWith('0')) return '+233${s.substring(1)}'; // GH local → E.164
    return s;
  }

  Widget _serviceIcon(BuildContext context, String label) {
    final color = Theme.of(context).colorScheme.primary;
    if (label.toLowerCase().contains('express')) {
      return Icon(FontAwesomeIcons.shower, color: color, size: 15);
    }
    if (label.toLowerCase().contains('standard')) {
      return Icon(Icons.alarm, color: color, size: 18);
    }
    return SvgPicture.asset(
      'assets/icons/cleaning.svg',
      height: 20,
      width: 20,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  String _labelFromKey(String k) {
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
        final pretty = k.replaceAll('_', ' ').trim();
        if (pretty.isEmpty) return 'Stage';
        return pretty[0].toUpperCase() + pretty.substring(1);
    }
  }

  String _normalizeStageStatus(String? s) {
    final v = (s ?? '').trim().toLowerCase();
    if (v == 'done' || v == 'completed') return 'done';
    if (v == 'in_progress' ||
        v == 'in-progress' ||
        v == 'active' ||
        v == 'processing') {
      return 'in_progress';
    }
    return 'pending';
  }

  List<WashStageVM> _vmFromFirestoreList(
    List<dynamic>? raw, {
    List<String> defaultOrder = const [
      'pre_rinse',
      'washing',
      'rinsing',
      'cleaning',
    ],
  }) {
    if (raw == null || raw.isEmpty) {
      return defaultOrder
          .map((k) => WashStageVM(k, _labelFromKey(k), 'pending'))
          .toList();
    }

    final out = <WashStageVM>[];
    for (final item in raw) {
      if (item is String) {
        final key = item.trim();
        if (key.isNotEmpty)
          out.add(WashStageVM(key, _labelFromKey(key), 'pending'));
        continue;
      }
      if (item is Map) {
        final key = (item['key'] ?? item['stage'] ?? item['name'] ?? '')
            .toString()
            .trim();
        if (key.isEmpty) continue;
        final status = _normalizeStageStatus(item['status']?.toString());
        final label = (item['label'] ?? _labelFromKey(key)).toString();
        out.add(WashStageVM(key, label, status));
      }
    }

    if (out.isEmpty) {
      return defaultOrder
          .map((k) => WashStageVM(k, _labelFromKey(k), 'pending'))
          .toList();
    }

    final orderIndex = {
      for (var i = 0; i < defaultOrder.length; i++) defaultOrder[i]: i,
    };
    out.sort(
      (a, b) =>
          (orderIndex[a.key] ?? 9999).compareTo(orderIndex[b.key] ?? 9999),
    );
    return out;
  }

  // ---------- Active-stage detection ----------
  String _norm(String k) =>
      k.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]+'), '_');

  String? _findActiveStage({
    List<String>? order,
    Map<String, dynamic>? stagesMap,
    List<dynamic>? legacyStages,
  }) {
    // 1) schema map
    if (stagesMap != null && stagesMap.isNotEmpty) {
      for (final entry in stagesMap.entries) {
        final key = _norm(entry.key);
        final status = '${entry.value?['status'] ?? ''}'.toLowerCase();
        if (status == 'in_progress' || status == 'in-progress') {
          return key;
        }
      }
    }
    // 2) legacy list
    if (legacyStages != null && legacyStages.isNotEmpty) {
      for (final raw in legacyStages) {
        if (raw is Map) {
          final key = _norm(
            '${raw['key'] ?? raw['stage'] ?? raw['name'] ?? ''}',
          );
          final status = '${raw['status'] ?? ''}'.toLowerCase();
          if (key.isNotEmpty &&
              (status == 'in_progress' || status == 'in-progress')) {
            return key;
          }
        }
      }
    }
    // 3) fallback: first in order
    if (order != null && order.isNotEmpty) return _norm(order.first);
    return null;
  }

  bool _isCleaningActive({
    List<String>? order,
    Map<String, dynamic>? stagesMap,
    List<dynamic>? legacyStages,
  }) {
    final active = _findActiveStage(
      order: order,
      stagesMap: stagesMap,
      legacyStages: legacyStages,
    );
    return active == 'cleaning';
  }

  Future<void> _confirmBookingNoDialog(BuildContext context) async {
    final id = bookingId;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing booking id')));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(id).update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking confirmed.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not confirm: $e')));
    }
  }

  // ---------- COMPLETE booking when cleaning is active ----------
  Future<void> _completeCurrentWash(BuildContext context) async {
    if (bookingId == null) return;
    final db = FirebaseFirestore.instance;
    final ref = db.collection('bookings').doc(bookingId);

    try {
      await db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw Exception('Booking not found');
        }

        final data = Map<String, dynamic>.from(snap.data() ?? {});
        final List<String> rawOrder =
            (data['washStageOrder'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            _kStageOrder;

        // Normalize keys and write all as done
        final now = FieldValue.serverTimestamp();
        final updates = <String, dynamic>{
          'status': 'completed',
          'completedAt': now,
          'updatedAt': now,
          // keep washStageOrder if present; no harm updating explicitly
          'washStageOrder': rawOrder,
        };

        for (final k in rawOrder) {
          final key = _norm(k);
          updates['washStages.$key.status'] = 'done';
          // Preserve startedAt if it already exists; otherwise set it.
          final existing = ((data['washStages'] as Map?)?[key] as Map?)
              ?.cast<String, dynamic>();
          updates['washStages.$key.startedAt'] = existing?['startedAt'] ?? now;
          updates['washStages.$key.completedAt'] = now;
        }

        tx.update(ref, updates);
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wash marked as completed.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not complete wash: $e')));
      }
    }
  }

  Future<void> _onAccept(
    BuildContext context, {
    bool assignSelf = true,
    bool enableTracking = false,
  }) async {
    if (bookingId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing bookingId')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final byName = user?.displayName;

    debugPrint(
      'ACCEPT bookingId=$bookingId assignSelf=$assignSelf enableTracking=$enableTracking',
    );

    final db = FirebaseFirestore.instance;
    final ref = db.collection('bookings').doc(bookingId);
    final now = FieldValue.serverTimestamp();

    // Full update (may be blocked by strict rules; see catch)
    final extended = <String, dynamic>{
      'status': 'confirmed',
      'updatedAt': now,
      'decision': {
        'type': 'confirm',
        'byUid': uid,
        'byName': byName,
        'at': now,
        'reason': null,
      },
      if (assignSelf) 'valetDriverId': uid,
      if (enableTracking) ...{
        'tracking.enabledOwner': true,
        'tracking.enabledBy': uid,
        'tracking.enabledAt': now,
        'tracking.disabledAt': null,
      },
    };

    try {
      await ref.set(extended, SetOptions(merge: true));

      // If tracking was enabled, seed /runtime/live once.
      if (enableTracking) {
        await ref.collection('runtime').doc('live').set({
          'driverId': uid,
          'updatedAt': FieldValue.serverTimestamp(),
          // lat/lng/speed/heading/accuracy come from your location loop later
        }, SetOptions(merge: true));
      }

      // Best-effort audit trail
      await ref.update({
        'washHistory': FieldValue.arrayUnion([
          {
            'action': 'confirm',
            'to': 'confirmed',
            'at': Timestamp.now(),
            if (uid != null) 'by': uid,
          },
        ]),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking confirmed')));
    } on FirebaseException catch (e) {
      // Fallback: only fields allowed by your stricter rules
      try {
        await ref.update({
          'status': 'confirmed',
          'updatedAt': now,
          'washHistory': FieldValue.arrayUnion([
            {
              'action': 'confirm',
              'to': 'confirmed',
              'at': Timestamp.now(),
              if (uid != null) 'by': uid,
            },
          ]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Confirmed (limited write due to rules: ${e.code})'),
          ),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not confirm: ${e.message ?? e.code}')),
        );
      }
    }
  }

  Future<void> _onDecline(BuildContext context) async {
    if (bookingId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing bookingId')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final byName = user?.displayName;

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Decline booking'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.isEmpty) return; // cancelled

    final db = FirebaseFirestore.instance;
    final ref = db.collection('bookings').doc(bookingId);
    final now = FieldValue.serverTimestamp();

    final extended = <String, dynamic>{
      'status': 'cancelled', // or 'canceled' if that’s your canonical
      'updatedAt': now,
      'decision': {
        'type': 'decline',
        'byUid': uid,
        'byName': byName,
        'at': now,
        'reason': reason,
      },
      // if tracking might have been on, shut it off
      'tracking.enabledOwner': false,
      'tracking.disabledAt': now,
    };

    try {
      await ref.set(extended, SetOptions(merge: true));
      await ref.update({
        'washHistory': FieldValue.arrayUnion([
          {
            'action': 'decline',
            'to': 'cancelled',
            'reason': reason,
            'at': Timestamp.now(),
            if (uid != null) 'by': uid,
          },
        ]),
      });
    } on FirebaseException catch (e) {
      // Fallback: fields allowed by your current rules
      try {
        await ref.update({
          'status': 'cancelled',
          'updatedAt': now,
          'washHistory': FieldValue.arrayUnion([
            {
              'action': 'decline',
              'to': 'cancelled',
              'reason': reason,
              'at': Timestamp.now(),
              if (uid != null) 'by': uid,
            },
          ]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Declined (limited write due to rules: ${e.code})'),
          ),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not decline: ${e.message ?? e.code}')),
        );
      }
    }
  }

  Future<void> _markInProgress(BuildContext context) async {
    if (bookingId == null || bookingId!.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing bookingId')));
      return;
    }

    try {
      final ref = FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId);
      await ref.update({
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
        // Optional audit trail (best effort)
        'washHistory': FieldValue.arrayUnion([
          {
            'action': 'start_wash',
            'to': 'in_progress',
            'at': Timestamp.now(),
            'by': FirebaseAuth.instance.currentUser?.uid,
          },
        ]),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wash started')));
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start wash: ${e.message ?? e.code}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start wash: $e')));
    }
  }

  // tiny DTO for the dialog

  @override
  Widget build(BuildContext context) {
    final serviceLabel = _serviceLabel(service);
    final locationLabel = _serviceLocationLabel(serviceLocation);
    final statusLabel = _statusLabel(status);
    final formattedPhone = _formatPhone(customerPhone);

    final order = washStageOrder;
    final stagesMap = washStages;
    final listStages = washProgressStages;
    final hasSchema =
        (order != null && order.isNotEmpty) ||
        (stagesMap != null && stagesMap!.isNotEmpty);

    final cleaningActive = _isCleaningActive(
      order: order,
      stagesMap: stagesMap,
      legacyStages: listStages,
    );

    return GestureDetector(
      onTap: onPressed,
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
                // service icon tile
                Container(
                  padding: const EdgeInsets.all(17),
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

                // right column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service + Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              serviceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.bold,
                                fontSize: TextSizes.subtitle2,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '\$',
                                style: TextStyle(
                                  fontSize: TextSizes.subtitle1,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                price ?? '—',
                                style: TextStyle(
                                  fontSize: TextSizes.subtitle1,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Vehicle + Status pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              vehicleType ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          StatusBar(status: statusLabel),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Customer + phone + location
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                border: Border.all(
                  color: Theme.of(context).colorScheme.scrim,
                  width: 1.7,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // name
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: Theme.of(context).colorScheme.surface,
                        size: IconSizes.medium,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          customerName?.trim().isEmpty ?? true
                              ? '-'
                              : customerName!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: TextSizes.bodyText1,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // phone
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        color: Theme.of(context).colorScheme.surface,
                        size: IconSizes.medium,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          formattedPhone ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: TextSizes.bodyText1,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // location
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Theme.of(context).colorScheme.surface,
                        size: IconSizes.medium,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _serviceLocationLabel(serviceLocation),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: TextSizes.bodyText1,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // Date / time / duration row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    day == null ? '—' : '🗓️ $day',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),

                  Text(
                    time == null ? '—' : '⌚ $time',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Tooltip(
                    message: _serviceLocationLabel(serviceLocation),
                    child: Text(
                      duration ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  statusLabel == 'Confirmed'
                      ? GestureDetector(
                          onTap: () {
                            _markInProgress(context);
                          },
                          child: StatusBar(status: 'start'),
                        )
                      : SizedBox(width: 20),
                ],
              ),
            ),
            if (statusLabel == 'Pending' || statusLabel == 'In Progress')
              const SizedBox(height: 5),

            // Actions / live panel
            if (statusLabel == 'Pending')
              AcceptDeclineBar(
                onDecline: () async => _onDecline(context),
                onAccept: () async {
                  await _onAccept(
                    context,
                    assignSelf: true, // set false if you don’t want auto-assign
                    enableTracking:
                        false, // set true if you want to turn on tracking
                  );
                },
              ),

            if (statusLabel == 'In Progress') ...[
              CurrentlyWashingPanel(
                bookingId: bookingId,
                washStageOrder: order,
                washStages: stagesMap,
                stages: hasSchema
                    ? null
                    : _vmFromFirestoreList(listStages), // legacy fallback
              ),
              const SizedBox(height: 8),

              // ✅ Show "Done" button ONLY when active stage is CLEANING
              if (cleaningActive)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: bookingId == null
                        ? null
                        : () => _completeCurrentWash(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              const SizedBox(height: 5),
            ],
          ],
        ),
      ),
    );
  }
}

const List<String> _kStageOrder = [
  'pre_rinse',
  'washing',
  'rinsing',
  'cleaning',
];

class WashStageVM {
  final String key;
  final String label;
  final String status; // 'pending' | 'in_progress' | 'done'
  const WashStageVM(this.key, this.label, this.status);
  WashStageVM copyWith({String? key, String? label, String? status}) =>
      WashStageVM(key ?? this.key, label ?? this.label, status ?? this.status);
}

class CurrentlyWashingPanel extends StatefulWidget {
  // Live mode: pass bookingId to stream changes from Firestore
  final String? bookingId;

  // Static fallback data (used if bookingId is null, or for first paint)
  final List<String>?
  washStageOrder; // ["pre_rinse","washing","rinsing","cleaning"]
  final Map<String, dynamic>?
  washStages; // { pre_rinse: {status: 'done'}, ... }
  final List<WashStageVM>? stages; // optional prebuilt VMs

  const CurrentlyWashingPanel({
    super.key,
    this.bookingId,
    this.washStageOrder,
    this.washStages,
    this.stages,
  });

  // --- look & feel (same colors) ---
  static const Color _accent = Color(0xFFF97316);
  static const Color _accentSoft = Color.fromARGB(37, 237, 165, 114);
  static const Color _accentBorder = Color.fromARGB(112, 211, 88, 0);
  static const Color _trackGrey = Color.fromARGB(153, 179, 179, 181);

  static const List<String> _defaultOrder = [
    'pre_rinse',
    'washing',
    'rinsing',
    'cleaning',
  ];

  @override
  State<CurrentlyWashingPanel> createState() => _CurrentlyWashingPanelState();
}

class _CurrentlyWashingPanelState extends State<CurrentlyWashingPanel> {
  /// Local override to show instant feedback on tap (optimistic UI).
  /// When a Firestore snapshot arrives, we display that instead.
  List<WashStageVM>? _localItems;

  @override
  Widget build(BuildContext context) {
    // LIVE: stream the booking doc
    if (widget.bookingId != null) {
      final docRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId);
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snap) {
          final child = _innerFromSnap(context, snap);
          return _shell(child: child);
        },
      );
    }

    // STATIC: build from props
    final items =
        _localItems ??
        widget.stages ??
        _buildFromRaw(
          widget.washStageOrder,
          widget.washStages,
          bookingStatus: null,
        );
    return _shell(child: _panel(context, items));
  }

  // ----- container frame (unchanged design) -----
  Widget _shell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: CurrentlyWashingPanel._accentBorder,
          width: 1.7,
        ),
        borderRadius: BorderRadius.circular(20),
        color: CurrentlyWashingPanel._accentSoft,
      ),
      padding: const EdgeInsets.all(10),
      child: child,
    );
  }

  // ----- live snapshot → items → panel -----
  Widget _innerFromSnap(
    BuildContext context,
    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snap,
  ) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const SizedBox(height: 46);
    }
    if (!snap.hasData || !snap.data!.exists) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No wash data yet',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    }

    final data = snap.data!.data() ?? <String, dynamic>{};

    // Prefer flat schema; fall back to legacy `washProgress.order`
    final order =
        (data['washStageOrder'] as List?)?.cast<String>() ??
        (data['washProgress']?['order'] as List?)?.cast<String>();

    final stagesMap = (data['washStages'] as Map?)?.cast<String, dynamic>();
    final bookingStatus = '${data['status'] ?? ''}';

    // If we have an optimistic local override, prefer it until the first snapshot
    // that contains the new active stage; then _localItems can be overridden naturally.
    final items =
        _localItems ??
        _buildFromRaw(order, stagesMap, bookingStatus: bookingStatus);

    return _panel(context, items);
  }

  // ----- build list of stage VMs from order/map (infers missing pieces) -----
  List<WashStageVM> _buildFromRaw(
    List<String>? order,
    Map<String, dynamic>? map, {
    String? bookingStatus,
  }) {
    final o = (order == null || order.isEmpty)
        ? CurrentlyWashingPanel._defaultOrder
        : order;

    // clone map
    final m = <String, Map<String, dynamic>>{};
    for (final entry in (map ?? const <String, dynamic>{}).entries) {
      m[entry.key] = Map<String, dynamic>.from(entry.value ?? const {});
    }

    String _norm(dynamic s) {
      final v = '${s ?? ''}'.trim().toLowerCase();
      if (v == 'done' || v == 'completed') return 'done';
      if (v == 'in_progress' ||
          v == 'in-progress' ||
          v == 'active' ||
          v == 'processing') {
        return 'in_progress';
      }
      return 'pending';
    }

    int activeIndex = -1;
    for (int i = 0; i < o.length; i++) {
      final key = o[i];
      if (_norm(m[key]?['status']) == 'in_progress') {
        activeIndex = i;
        break;
      }
    }

    final List<WashStageVM> list = [];
    for (int i = 0; i < o.length; i++) {
      final key = o[i];
      String status = _norm(m[key]?['status']);

      if (activeIndex >= 0) {
        // Fill missing statuses around the known active one
        if ((m[key] == null || m[key]!['status'] == null) && i < activeIndex) {
          status = 'done';
        }
        if ((m[key] == null || m[key]!['status'] == null) && i > activeIndex) {
          status = 'pending';
        }
      } else if ((map == null || map.isEmpty) &&
          (bookingStatus ?? '').toLowerCase().contains('progress')) {
        // No map yet but booking is in_progress: show the first as active
        status = (i == 0) ? 'in_progress' : 'pending';
      }

      list.add(WashStageVM(key, _labelForKey(key), status));
    }

    return list;
  }

  // ----- segmented bar + chip row (tap = set active) -----
  Widget _panel(BuildContext context, List<WashStageVM> items) {
    return Column(
      children: [
        Row(
          children: const [
            Icon(Icons.circle, color: CurrentlyWashingPanel._accent, size: 8),
            SizedBox(width: 6),
            Text(
              'Wash Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: CurrentlyWashingPanel._accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: List.generate(items.length, (i) {
            final first = i == 0;
            final last = i == items.length - 1;
            final stage = items[i];

            final isDone = stage.status == 'done';
            final isActive = stage.status == 'in_progress';
            final barColor = (isDone || isActive)
                ? CurrentlyWashingPanel._accent
                : CurrentlyWashingPanel._trackGrey;

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _onTapStage(i, items),
                child: Column(
                  children: [
                    // segmented bar piece
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
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

                    // ✓ / pulsing / grey number
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _StageChip(
                        key: ValueKey('${stage.key}_${stage.status}'),
                        index: i + 1,
                        status: stage.status,
                      ),
                    ),

                    const SizedBox(height: 2),

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
              ),
            );
          }),
        ),
      ],
    );
  }

  // ----- Tap handler: optimistic UI + Firestore persist (if bookingId) -----
  Future<void> _onTapStage(int index, List<WashStageVM> current) async {
    // Optimistically compute new statuses
    final updated = List<WashStageVM>.generate(current.length, (i) {
      final st = current[i];
      if (i < index) return st.copyWith(status: 'done');
      if (i == index) return st.copyWith(status: 'in_progress');
      return st.copyWith(status: 'pending');
    });

    setState(() => _localItems = updated);

    // Persist if we can
    if (widget.bookingId != null) {
      final activeKey = updated[index].key;
      final adminId = FirebaseAuth.instance.currentUser?.uid;

      try {
        await adminSetActiveWashStageStrict(
          bookingId: widget.bookingId!,
          activeStageKey: activeKey,
          adminId: adminId,
          // createIfMissing: false, // keep strict; flip to true if you want seeding
        );
        // When Firestore snapshot arrives, it will replace _localItems naturally.
      } catch (e) {
        // Revert on failure and inform user
        if (mounted) {
          setState(() => _localItems = current);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not update stage: $e')));
        }
      }
    }
  }

  // Pretty label for a stage key
  String _labelForKey(String k) {
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
        final pretty = k.replaceAll('_', ' ').trim();
        if (pretty.isEmpty) return 'Stage';
        return pretty[0].toUpperCase() + pretty.substring(1);
    }
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

class _StageChip extends StatelessWidget {
  final int index;
  final String status; // done | in_progress | pending
  const _StageChip({super.key, required this.index, required this.status});

  static const Color _accent = Color(0xFFF97316);
  static const Color _greyBg = Color.fromARGB(153, 179, 179, 181);
  static const Color _greyFg = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    if (status == 'done') {
      return const Icon(Icons.check_circle, size: 20, color: _accent);
    }
    if (status == 'in_progress') {
      return FadingCircle(number: index, size: 20);
    }
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

// ====== STATUS CHIPS / PANELS ======

class StatusBar extends StatelessWidget {
  final String status;
  const StatusBar({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg, fg;
    if (s == 'pending') {
      bg = const Color.fromARGB(121, 255, 234, 113);
      fg = const Color.fromARGB(255, 187, 129, 4);
    } else if (s == 'confirmed') {
      bg = const Color.fromARGB(121, 180, 255, 180);
      fg = const Color.fromARGB(255, 4, 129, 4);
    } else if (s.contains('progress')) {
      bg = const Color.fromARGB(121, 255, 200, 120);
      fg = const Color.fromARGB(255, 187, 80, 4);
    } else if (s == 'completed') {
      bg = const Color.fromARGB(121, 120, 158, 255);
      fg = const Color.fromARGB(255, 4, 37, 129);
    } else if (s == 'declined') {
      bg = const Color.fromARGB(121, 255, 120, 120);
      fg = const Color.fromARGB(255, 129, 4, 4);
    } else if (s == 'start') {
      bg = const Color.fromARGB(121, 216, 180, 254);
      fg = const Color.fromARGB(255, 88, 28, 135);
    } else {
      bg = const Color.fromARGB(121, 255, 120, 120);
      fg = const Color.fromARGB(255, 129, 4, 4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        s == 'pending'
            ? 'Pending'
            : s == 'in progress'
            ? 'Currently Washing'
            : s == 'confirmed'
            ? 'Confirmed'
            : s == 'completed'
            ? 'Completed'
            : s == 'declined'
            ? 'Declined'
            : s == 'start'
            ? ' Start '
            : 'Cancelled',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: fg,
          fontSize: s == 'start' ? 15 : 12,
        ),
      ),
    );
  }
}

class AcceptDeclineBar extends StatelessWidget {
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool accepting;
  final bool declining;
  final String acceptLabel;
  final String declineLabel;
  final IconData acceptIcon;
  final IconData declineIcon;

  const AcceptDeclineBar({
    super.key,
    required this.onAccept,
    required this.onDecline,
    this.accepting = false,
    this.declining = false,
    this.acceptLabel = 'Accept',
    this.declineLabel = 'Decline',
    this.acceptIcon = Icons.check_circle_outlined,
    this.declineIcon = Icons.cancel_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    final onSurface = Theme.of(context).textTheme.bodyLarge?.color;

    return Row(
      children: [
        // --- Decline ---
        Expanded(
          child: OutlinedButton.icon(
            onPressed: declining ? null : onDecline,
            icon: declining
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        scheme.error.withValues(alpha: .9),
                      ),
                    ),
                  )
                : Icon(declineIcon, size: 18, color: scheme.error),
            label: Text(
              declineLabel,
              style: textStyle?.copyWith(color: scheme.error),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              side: BorderSide(
                color: scheme.error.withValues(alpha: .5),
                width: 1.2,
              ),
              backgroundColor: scheme.error.withValues(alpha: .01),
              foregroundColor: scheme.error,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // --- Accept ---
        Expanded(
          child: OutlinedButton.icon(
            onPressed: accepting ? null : onAccept,
            icon: accepting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(acceptIcon, size: 18, color: onSurface),
            label: Text(
              acceptLabel,
              style: textStyle?.copyWith(color: onSurface),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),

              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: .6),
                width: 1.2,
              ),
              backgroundColor: scheme.onSecondary, // white-ish
              foregroundColor: onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> adminSetActiveWashStageStrict({
  required String bookingId,
  required String activeStageKey, // e.g. "pre-rinse", "washing"
  String? adminId, // optional for audit
  List<String> defaultOrder = const [
    'pre_rinse',
    'washing',
    'rinsing',
    'cleaning',
  ],
  bool createIfMissing =
      false, // set true only if you WANT to seed missing keys
}) async {
  final db = FirebaseFirestore.instance;
  final ref = db.collection('bookings').doc(bookingId);

  String norm(String k) =>
      k.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]+'), '_');

  await db.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) throw Exception('Booking not found: $bookingId');

    final data = Map<String, dynamic>.from(snap.data() ?? {});

    // Existing map of stages (normalized keys)
    final rawStages =
        (data['washStages'] as Map?)?.cast<String, dynamic>() ?? {};
    final hasSchema = rawStages.isNotEmpty;

    if (!hasSchema && !createIfMissing) {
      // abort: nothing to update without creating fields
      throw Exception(
        'washStages schema not present on booking; not creating new fields.',
      );
    }

    final stages = <String, Map<String, dynamic>>{};
    rawStages.forEach(
      (k, v) => stages[norm(k)] = Map<String, dynamic>.from(v ?? {}),
    );

    // Use existing order if present; otherwise fall back (but only write it if createIfMissing)
    final rawOrder =
        (data['washStageOrder'] as List?)
            ?.map((e) => norm(e.toString()))
            .toList() ??
        defaultOrder;

    // If we are not creating, restrict the order to keys that already exist
    List<String> order = createIfMissing
        ? List<String>.from(rawOrder)
        : rawOrder.where((k) => stages.containsKey(k)).toList();

    final active = norm(activeStageKey);

    if (!order.contains(active)) {
      if (createIfMissing) {
        order.add(active); // allowed to seed
      } else {
        throw Exception(
          "Stage '$activeStageKey' doesn't exist in washStages; strict mode won't create it.",
        );
      }
    }
    if (!createIfMissing && !stages.containsKey(active)) {
      throw Exception(
        "Stage '$activeStageKey' missing in washStages; strict mode won't create it.",
      );
    }

    final activeIdx = order.indexOf(active);
    bool anyActive = false;
    bool allDone = true;

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only write washStageOrder if it already exists OR we're allowed to create
    if (data.containsKey('washStageOrder') || createIfMissing) {
      updates['washStageOrder'] = order;
    }

    // Update only existing keys unless we allow creation
    for (int i = 0; i < order.length; i++) {
      final key = order[i];
      final exists = stages.containsKey(key);

      if (!createIfMissing && !exists) continue; // skip non-existent keys

      final prev = Map<String, dynamic>.from(stages[key] ?? const {});
      final isBefore = i < activeIdx;
      final isActive = i == activeIdx;

      if (isBefore) {
        updates['washStages.$key.status'] = 'done';
        updates['washStages.$key.startedAt'] =
            prev['startedAt'] ?? FieldValue.serverTimestamp();
        updates['washStages.$key.completedAt'] =
            prev['completedAt'] ?? FieldValue.serverTimestamp();
      } else if (isActive) {
        anyActive = true;
        allDone = false;
        updates['washStages.$key.status'] = 'in_progress';
        updates['washStages.$key.startedAt'] =
            prev['startedAt'] ?? FieldValue.serverTimestamp();
        updates['washStages.$key.completedAt'] = null;
      } else {
        allDone = false;
        updates['washStages.$key.status'] = 'pending';
        updates['washStages.$key.startedAt'] = null;
        updates['washStages.$key.completedAt'] = null;
      }
    }

    // Overall booking.status
    final currentOverall = '${data['status'] ?? ''}'.toLowerCase();
    String nextOverall;
    if (allDone) {
      nextOverall = 'completed';
      updates['completedAt'] = FieldValue.serverTimestamp();
    } else if (anyActive) {
      nextOverall = 'in_progress';
    } else {
      nextOverall = currentOverall.isEmpty ? 'confirmed' : currentOverall;
    }
    if (nextOverall != currentOverall) updates['status'] = nextOverall;

    tx.update(ref, updates);
  });

  // Best-effort audit trail (doesn't create structural fields)
  try {
    await ref.update({
      'washHistory': FieldValue.arrayUnion([
        {
          'action': 'set_active_stage',
          'stage': activeStageKey,
          'to': 'in_progress',
          'at': Timestamp.now(),
          if (adminId != null) 'by': adminId,
        },
      ]),
    });
  } catch (_) {
    /* ignore */
  }
}
