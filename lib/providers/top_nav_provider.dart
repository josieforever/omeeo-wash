import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopNavProvider extends ChangeNotifier {
  static const String _prefsKey = 'selected_tab';

  String _tabName = '';
  String get tabName => _tabName;

  TopNavProvider() {
    _loadTabFromPrefs();
  }

  void selectTab(String tab) async {
    _tabName = tab;
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, tab); // Use fixed key
  }

  bool isTabSelected(String tab) {
    return _tabName == tab;
  }

  Future<void> _loadTabFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _tabName = prefs.getString(_prefsKey) ?? ''; // Use fixed key
    notifyListeners();
  }
}
