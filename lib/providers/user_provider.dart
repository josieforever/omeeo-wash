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
      // Cache updated user
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
}
