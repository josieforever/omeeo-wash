import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:omeeowash/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final String cacheKey = 'cached_user';

  UserModel? get user => _user;

  /// Load user from cache or Firestore
  Future<void> loadUser({required String uid}) async {
    final prefs = await SharedPreferences.getInstance();

    // Load from cache
    if (prefs.containsKey(cacheKey)) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        _user = UserModel.fromMap(jsonDecode(cachedData));
        notifyListeners();
      }
    }

    // Fetch latest from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists) {
      _user = UserModel.fromMap(doc.data()!);
      await prefs.setString(cacheKey, jsonEncode(_user!.toMap()));
      notifyListeners();
    }
  }

  /// Immediately update user data in provider and cache
  Future<void> setUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    _user = user;
    await prefs.setString(cacheKey, jsonEncode(user.toMap()));
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
    if (_user == null) return;

    final updatedSettings = Map<String, bool>.from(_user!.notificationSettings);
    updatedSettings[key] = value;

    final updatedUser = _user!.copyWith(notificationSettings: updatedSettings);
    _user = updatedUser;
    notifyListeners();

    // Update Firestore
    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update(
      {'notificationSettings': updatedSettings},
    );

    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, jsonEncode(_user!.toMap()));
  }

  /// ⚙️ Get app setting toggle value
  bool getSettingValue(String key) {
    return _user?.settings[key] ?? false;
  }

  /// ⚙️ Update an app setting in memory, Firestore & cache
  Future<void> updateSetting(String key, bool value) async {
    if (_user == null) return;

    final updatedSettings = Map<String, bool>.from(_user!.settings);
    updatedSettings[key] = value;

    final updatedUser = _user!.copyWith(settings: updatedSettings);
    _user = updatedUser;
    notifyListeners();

    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update(
      {'settings': updatedSettings},
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, jsonEncode(_user!.toMap()));
  }
}
