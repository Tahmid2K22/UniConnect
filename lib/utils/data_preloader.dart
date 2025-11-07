import 'package:uni_connect/firebase/firestore/database.dart';

/// Preload critical data during app startup
class DataPreloader {
  static bool _isPreloaded = false;
  
  static Future<void> preloadCriticalData() async {
    if (_isPreloaded) return;
    
    // Preload data in parallel for faster app startup
    await Future.wait([
      fetchNoticesFromFirestore(),
      fetchExamsFromFirestore(),
      loadUserProfile(),
    ]).catchError((e) {
      // Silently fail - data will be loaded lazily later
      return [];
    });
    
    _isPreloaded = true;
  }
  
  static void resetPreloadFlag() {
    _isPreloaded = false;
  }
}
