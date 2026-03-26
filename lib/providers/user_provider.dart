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
  // JSON-SAFE ENCODING HELPERS (fix DateTime/Timestamp caching crash)
  // ---------------------------------------------------------------------------

  dynamic _jsonSafe(dynamic v) {
    if (v == null) return null;

    // ✅ Convert DateTime to ISO string
    if (v is DateTime) return v.toIso8601String();

    // ✅ Convert Timestamp to ISO string
    if (v is Timestamp) return v.toDate().toIso8601String();

    // ✅ Recurse into maps/lists
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), _jsonSafe(val)));
    }

    if (v is List) {
      return v.map(_jsonSafe).toList();
    }

    // primitives are fine (String, num, bool)
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

  // ---------------------------------------------------------------------------
  // CORE
  // ---------------------------------------------------------------------------

  /// Load user from cache then refresh from Firestore
  Future<void> loadUser({required String uid}) async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ 1) Load from cache safely
    final cachedMap = _safeDecodeMap(prefs.getString(cacheKey));
    if (cachedMap != null) {
      _user = UserModel.fromMap(cachedMap);
      notifyListeners();
    }

    // ✅ 2) Refresh from Firestore safely
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data();
      if (doc.exists && data != null) {
        _user = UserModel.fromMap(data);

        // ✅ Cache safely (DateTime/Timestamp-safe)
        final safe = _toJsonSafeMap(_user!.toMap());
        await prefs.setString(cacheKey, jsonEncode(safe));

        notifyListeners();
      }
    } catch (_) {
      // optional debugPrint
    }
  }

  /// Immediately update user data in provider and cache
  Future<void> setUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    _user = user;

    // ✅ Cache safely (DateTime/Timestamp-safe)
    final safe = _toJsonSafeMap(user.toMap());
    await prefs.setString(cacheKey, jsonEncode(safe));

    notifyListeners();
  }

  /// Clear cache and memory
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKey);
    _user = null;
    notifyListeners();
  }

  /// 🔔 Get notification toggle value
  bool getNotificationValue(String key) {
    return _user?.notificationSettings[key] ?? true;
  }

  /// 🔔 Update a notification setting in memory, Firestore & cache
  Future<void> updateNotificationSetting(String key, bool value) async {
    final current = _user;
    if (current == null) return;

    final updatedSettings = Map<String, bool>.from(
      current.notificationSettings,
    );
    updatedSettings[key] = value;

    final updatedUser = current.copyWith(notificationSettings: updatedSettings);
    _user = updatedUser;
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('users').doc(current.uid).set(
        {'notificationSettings': updatedSettings},
        SetOptions(merge: true),
      );
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final safe = _toJsonSafeMap(updatedUser.toMap());
    await prefs.setString(cacheKey, jsonEncode(safe));
  }

  /// ⚙️ Get app setting toggle value
  bool getSettingValue(String key) {
    return _user?.settings[key] ?? false;
  }

  /// ⚙️ Update an app setting in memory, Firestore & cache
  Future<void> updateSetting(String key, bool value) async {
    final current = _user;
    if (current == null) return;

    final updatedSettings = Map<String, bool>.from(current.settings);
    updatedSettings[key] = value;

    final updatedUser = current.copyWith(settings: updatedSettings);
    _user = updatedUser;
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('users').doc(current.uid).set(
        {'settings': updatedSettings},
        SetOptions(merge: true),
      );
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final safe = _toJsonSafeMap(updatedUser.toMap());
    await prefs.setString(cacheKey, jsonEncode(safe));
  }
}
