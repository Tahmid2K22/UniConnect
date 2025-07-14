import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

Map<String, dynamic>? _cachedUserProfile;
String? _cachedProfileImagePath;

/// Loads the current user's profile data from Firestore, but uses cache if available.
Future<Map<String, dynamic>?> loadUserProfile() async {
  if (_cachedUserProfile != null) return _cachedUserProfile;

  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.email == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('students')
      .doc(user.email)
      .get();

  _cachedUserProfile = doc.exists ? doc.data() : null;
  return _cachedUserProfile;
}

/// Loads the local profile image path from Hive, but uses cache if available.
String? loadLocalProfileImagePath() {
  if (_cachedProfileImagePath != null) return _cachedProfileImagePath;
  final box = Hive.box('profileBox');
  _cachedProfileImagePath = box.get('profileImagePath');
  return _cachedProfileImagePath;
}

// In load_user.dart

void updateCachedProfilePic(String base64Str) {
  if (_cachedUserProfile != null) {
    _cachedUserProfile!['profile_pic'] = base64Str;
  }
}

void updateCachedProfileImagePath(String localPath) {
  _cachedProfileImagePath = localPath;
}

// Load batchmates
Future<List<Map<String, dynamic>>> fetchBatchmatesFromFirestore() async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('students')
      .get();
  return querySnapshot.docs.map((doc) {
    return {'id': doc.id, ...doc.data()};
  }).toList();
}

// Load exams
Future<List<Map<String, dynamic>>> fetchExamsFromFirestore() async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('exams')
      .get();
  return querySnapshot.docs.map((doc) {
    return {"id": doc.id, "data": doc.data()};
  }).toList();
}

// Load notices
Future<List<Map<String, dynamic>>> fetchNoticesFromFirestore() async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('notices')
      .get();
  return querySnapshot.docs.map((doc) {
    return {"id": doc.id, "data": doc.data()};
  }).toList();
}
