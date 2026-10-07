import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final String cacheKey = 'cached_user';

  UserModel? get user => _user;

  // ---------------------------------------------------------------------------
  // JSON-SAFE ENCODING HELPERS
  // ---------------------------------------------------------------------------

  dynamic _jsonSafe(dynamic v) {
    if (v == null) return null;

    if (v is DateTime) return v.toIso8601String();
    if (v is Timestamp) return v.toDate().toIso8601String();

    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), _jsonSafe(val)));
    }

    if (v is List) {
      return v.map(_jsonSafe).toList();
    }

    return v;
  }

  Map<String, dynamic> _toJsonSafeMap(Map<String, dynamic> map) {
    final out = <String, dynamic>{};
    for (final e in map.entries) {
      out[e.key] = _jsonSafe(e.value);
    }
    return out;
  }

  Map<String, dynamic>? _safeDecodeMap(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty || s == 'null') return null;

    try {
      final decoded = jsonDecode(s);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final safe = _toJsonSafeMap(user.toMap());
    await prefs.setString(cacheKey, jsonEncode(safe));
  }

  Future<void> _persistAndNotify(UserModel user) async {
    _user = user;
    await _cacheUser(user);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // CORE
  // ---------------------------------------------------------------------------

  Future<void> loadUser({required String uid}) async {
    final prefs = await SharedPreferences.getInstance();

    final cachedMap = _safeDecodeMap(prefs.getString(cacheKey));
    if (cachedMap != null) {
      _user = UserModel.fromMap(cachedMap);
      notifyListeners();
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data();
      if (doc.exists && data != null) {
        _user = UserModel.fromMap(data);
        await _cacheUser(_user!);
        notifyListeners();
      }
    } catch (_) {
      // optional debugPrint
    }
  }

  Future<void> setUser(UserModel user) async {
    await _persistAndNotify(user);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
    _user = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATION SETTINGS
  // ---------------------------------------------------------------------------

  bool getNotificationValue(String key) {
    return _user?.notificationSettings[key] ?? true;
  }

  Future<void> updateNotificationSetting(String key, bool value) async {
    final current = _user;
    if (current == null) return;

    final updatedSettings = Map<String, bool>.from(
      current.notificationSettings,
    );
    updatedSettings[key] = value;

    final updatedUser = current.copyWith(
      notificationSettings: updatedSettings,
      updatedAt: DateTime.now(),
    );

    _user = updatedUser;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .set({
            'notificationSettings': updatedSettings,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}

    await _cacheUser(updatedUser);
  }

  // ---------------------------------------------------------------------------
  // GENERAL SETTINGS
  // ---------------------------------------------------------------------------

  dynamic getSettingValue(String key) {
    return _user?.settings[key];
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final current = _user;
    if (current == null) return;

    final updatedSettings = Map<String, dynamic>.from(current.settings);
    updatedSettings[key] = value;

    final updatedUser = current.copyWith(
      settings: updatedSettings,
      updatedAt: DateTime.now(),
    );

    _user = updatedUser;
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('users').doc(current.uid).set(
        {
          'settings': updatedSettings,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}

    await _cacheUser(updatedUser);
  }

  // ---------------------------------------------------------------------------
  // PROFILE UPDATES
  // ---------------------------------------------------------------------------

  Future<void> updateProfile({
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    final current = _user;
    if (current == null) return;

    final updatedUser = current.copyWith(
      name: name,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      updatedAt: DateTime.now(),
    );

    _user = updatedUser;
    notifyListeners();

    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) payload['name'] = name;
    if (firstName != null) payload['firstName'] = firstName;
    if (lastName != null) payload['lastName'] = lastName;
    if (email != null) payload['email'] = email;
    if (phoneNumber != null) payload['phoneNumber'] = phoneNumber;
    if (photoUrl != null) payload['photoUrl'] = photoUrl;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .set(payload, SetOptions(merge: true));
    } catch (_) {}

    await _cacheUser(updatedUser);
  }

  Future<void> updateDefaultAddressId(String? addressId) async {
    final current = _user;
    if (current == null) return;

    final updatedUser = current.copyWith(
      defaultAddressId: addressId,
      updatedAt: DateTime.now(),
    );

    _user = updatedUser;
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('users').doc(current.uid).set(
        {
          'defaultAddressId': addressId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}

    await _cacheUser(updatedUser);
  }

  // ---------------------------------------------------------------------------
  // PRESENCE
  // ---------------------------------------------------------------------------

  Future<void> updatePresence({
    required bool isOnline,
    DateTime? lastSeen,
  }) async {
    final current = _user;
    if (current == null) return;

    final resolvedLastSeen = lastSeen ?? DateTime.now();

    final updatedUser = current.copyWith(
      isOnline: isOnline,
      lastSeen: resolvedLastSeen,
      updatedAt: DateTime.now(),
    );

    _user = updatedUser;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .set({
            'isOnline': isOnline,
            'lastSeen': Timestamp.fromDate(resolvedLastSeen),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}

    await _cacheUser(updatedUser);
  }

  Future<void> updateLastLoginAt([DateTime? dateTime]) async {
    final current = _user;
    if (current == null) return;

    final loginTime = dateTime ?? DateTime.now();

    final updatedUser = current.copyWith(
      lastLoginAt: loginTime,
      updatedAt: DateTime.now(),
    );

    _user = updatedUser;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .set({
            'lastLoginAt': Timestamp.fromDate(loginTime),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}

    await _cacheUser(updatedUser);
  }

  // ---------------------------------------------------------------------------
  // FCM TOKENS
  // ---------------------------------------------------------------------------

  Map<String, bool> get fcmTokens => _user?.fcmTokens ?? {};

  Future<void> addFcmToken(String token) async {
    final current = _user;
    if (current == null || token.trim().isEmpty) return;

    final updatedTokens = Map<String, bool>.from(current.fcmTokens);
    updatedTokens[token] = true;

    final now = DateTime.now();

    final updatedUser = current.copyWith(
      fcmTokens: updatedTokens,
      fcmUpdatedAt: now,
      updatedAt: now,
    );

    _user = updatedUser;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .set({
            'fcmTokens': updatedTokens,
            'fcmUpdatedAt': Timestamp.fromDate(now),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}

    await _cacheUser(updatedUser);
  }

  Future<void> removeFcmToken(String token) async {
    final current = _user;
    if (current == null || token.trim().isEmpty) return;

    final updatedTokens = Map<String, bool>.from(current.fcmTokens);
    updatedTokens.remove(token);

    final now = DateTime.now();

    final updatedUser = current.copyWith(
      fcmTokens: updatedTokens,
      fcmUpdatedAt: now,
      updatedAt: now,
    );

    _user = updatedUser;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .set({
            'fcmTokens': updatedTokens,
            'fcmUpdatedAt': Timestamp.fromDate(now),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}

    await _cacheUser(updatedUser);
  }

  Future<void> replaceAllFcmTokens(Map<String, bool> tokens) async {
    final current = _user;
    if (current == null) return;

    final now = DateTime.now();

    final updatedUser = current.copyWith(
      fcmTokens: Map<String, bool>.from(tokens),
      fcmUpdatedAt: now,
      updatedAt: now,
    );

    _user = updatedUser;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(current.uid)
          .set({
            'fcmTokens': tokens,
            'fcmUpdatedAt': Timestamp.fromDate(now),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}

    await _cacheUser(updatedUser);
  }
}
