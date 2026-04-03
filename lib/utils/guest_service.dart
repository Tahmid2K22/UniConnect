import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

class GuestService {
  static const String _boxName = 'settingsBox';
  static const String _guestKey = 'is_guest';

  /// Check if the current user is a guest.
  static bool get isGuestUser {
    try {
      final box = Hive.box(_boxName);
      return box.get(_guestKey, defaultValue: false) ?? false;
    } catch (e) {
      debugPrint('Error reading guest state: $e');
      return false;
    }
  }

  /// Log in as a guest. Sets the guest flag to true.
  static Future<void> loginAsGuest() async {
    try {
      final box = Hive.box(_boxName);
      await box.put(_guestKey, true);
    } catch (e) {
      debugPrint('Error setting guest state: $e');
    }
  }

  /// Log out from guest mode. Sets the guest flag to false.
  static Future<void> logoutGuest() async {
    try {
      final box = Hive.box(_boxName);
      await box.put(_guestKey, false);
    } catch (e) {
      debugPrint('Error clearing guest state: $e');
    }
  }
}
