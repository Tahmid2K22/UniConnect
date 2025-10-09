import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SplashToggleProvider with ChangeNotifier {
  bool _showSplash = Hive.box('settingsBox').get('showSplash', defaultValue: false);

  bool get showSplash => _showSplash;

  void toggleSplash(bool value) {
    _showSplash = value;
    Hive.box('settingsBox').put('showSplash', value);
    notifyListeners();
  }
}
