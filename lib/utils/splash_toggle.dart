// utils/splash_toggle.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SplashToggleProvider extends ChangeNotifier {
  bool _showSplash = false; // default off

  bool get showSplash => _showSplash;

  SplashToggleProvider() {
    _load();
  }

  Future<void> _load() async {
    final box = Hive.box('settingsBox');
    _showSplash = box.get('showSplash', defaultValue: false);
    notifyListeners();
  }

  Future<void> toggleSplash(bool value) async {
    final box = Hive.box('settingsBox');
    await box.put('showSplash', value);
    _showSplash = value;
    notifyListeners();
  }
}
