import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'no_internet_screen.dart';

class NetworkListener extends StatefulWidget {
  final Widget child;
  const NetworkListener({super.key, required this.child});

  @override
  State<NetworkListener> createState() => _NetworkListenerState();
}

class _NetworkListenerState extends State<NetworkListener> {
  bool hasInternet = true;
  bool? _lastReportedOnline; // track last value we wrote to Firestore
  Timer? _debounce;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();

    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final connected = _isConnected(results);
      if (!mounted) return;
      setState(() => hasInternet = connected);
      _scheduleOnlineToggle(connected); // debounced + change-only
    });
  }

  // Treat anything but 'none' as connected (covers wifi/mobile/ethernet/vpn)
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    final connected = _isConnected(results);
    if (!mounted) return;
    setState(() => hasInternet = connected);
    _scheduleOnlineToggle(connected); // ensure we report initial state
  }

  void _scheduleOnlineToggle(bool value) {
    // avoid redundant writes
    if (_lastReportedOnline == value) return;

    // debounce quick flaps (adjust 800ms ↔︎ 1500ms if needed)
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 900), () {
      toggleIsOnline(value);
    });
  }

  Future<void> toggleIsOnline(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isOnline': value,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _lastReportedOnline = value;
      debugPrint('✅ User online status updated: $value');
    } catch (e) {
      // With Firestore offline persistence, this will queue and sync later.
      debugPrint('❌ Failed to update online status: $e');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!hasInternet)
          Positioned.fill(
            child: NoInternetScreen(onRetry: _checkInitialConnection),
          ),
      ],
    );
  }
}
