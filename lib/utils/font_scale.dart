import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class FontScaleProvider extends ChangeNotifier {
  double _fontScale = 1.0; // Default: Large

  double get fontScale => _fontScale;

  FontScaleProvider() {
    _loadFontScale();
  }

  void setFontScale(double scale) {
    _fontScale = scale;
    notifyListeners();
    _saveFontScale(scale); // Save whenever changed
  }

  void setSmall() => setFontScale(0.8);
  void setMedium() => setFontScale(0.9);
  void setLarge() => setFontScale(1.0);

  Future<void> _saveFontScale(double scale) async {
    final box = Hive.box('settingsBox');
    box.put('fontScale', scale);
  }

  Future<void> _loadFontScale() async {
    final box = Hive.box('settingsBox');
    final saved = box.get('fontScale');
    if (saved != null && saved is double) {
      _fontScale = saved;
      notifyListeners();
    }
  }
}
