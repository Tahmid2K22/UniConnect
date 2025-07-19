import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

Map<String, dynamic>? _cachedUserProfile;
List<Map<String, dynamic>>? _batchmatesCache;
String? _cachedProfileImagePath;
List<Map<String, dynamic>>? _teachersCache;
List<Map<String, dynamic>>? _examsCache;
List<Map<String, dynamic>>? _noticesCache;

/// Loads the current user's profile data from Firestore, but uses cache if available.
Future<Map<String, dynamic>?> loadUserProfile() async {
  if (_cachedUserProfile != null) return _cachedUserProfile;

  final box = Hive.box('userBox');
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.email == null) return null;

  final cachedMap = box.get(user.email);
  if (cachedMap != null) {
    _cachedUserProfile = Map<String, dynamic>.from(cachedMap);
    return _cachedUserProfile;
  }

  // Not in Hive, load from Firestore
  final doc = await FirebaseFirestore.instance
      .collection('students')
      .doc(user.email)
      .get();

  final userData = doc.exists ? doc.data() : null;
  if (userData != null) {
    _cachedUserProfile = Map<String, dynamic>.from(userData);
    await box.put(user.email, _cachedUserProfile); // Save to Hive
  }
  return _cachedUserProfile;
}

// Call this after reloading from Firestore to force update cache
Future<Map<String, dynamic>?> reloadUserProfile() async {
  _cachedUserProfile = null;
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.email == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('students')
      .doc(user.email)
      .get();

  final userData = doc.exists ? doc.data() : null;
  final box = Hive.box('userBox');
  if (userData != null) {
    _cachedUserProfile = Map<String, dynamic>.from(userData);
    await box.put(user.email, _cachedUserProfile);
  }
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
  if (_batchmatesCache != null) return _batchmatesCache!;

  final box = Hive.box('batchmatesBox');
  final cachedList = box.get('batchmates');
  if (cachedList != null) {
    _batchmatesCache = List<Map<String, dynamic>>.from(
      (cachedList as List).map((e) => Map<String, dynamic>.from(e)),
    );
    return _batchmatesCache!;
  }

  // Not in Hive, load from Firestore
  final querySnapshot = await FirebaseFirestore.instance
      .collection('students')
      .get();

  _batchmatesCache = querySnapshot.docs.map((doc) {
    return {'id': doc.id, ...doc.data()};
  }).toList();
  await box.put('batchmates', _batchmatesCache);

  return _batchmatesCache!;
}

Future<List<Map<String, dynamic>>> reloadBatchmates() async {
  _batchmatesCache = null;
  final querySnapshot = await FirebaseFirestore.instance
      .collection('students')
      .get();

  _batchmatesCache = querySnapshot.docs.map((doc) {
    return {'id': doc.id, ...doc.data()};
  }).toList();

  final box = Hive.box('batchmatesBox');
  await box.put('batchmates', _batchmatesCache);
  return _batchmatesCache!;
}

// Load teachers with cache
Future<List<Map<String, dynamic>>> fetchTeachersFromFirestore() async {
  if (_teachersCache != null) return _teachersCache!;

  final box = Hive.box('teachersBox');
  final cachedList = box.get('teachers');
  if (cachedList != null) {
    _teachersCache = List<Map<String, dynamic>>.from(
      (cachedList as List).map((e) => Map<String, dynamic>.from(e)),
    );
    return _teachersCache!;
  }

  final querySnapshot = await FirebaseFirestore.instance
      .collection('teachers')
      .get();
  _teachersCache = querySnapshot.docs.map((doc) {
    return {'id': doc.id, ...doc.data()};
  }).toList();
  await box.put('teachers', _teachersCache);

  return _teachersCache!;
}

Future<List<Map<String, dynamic>>> reloadTeachers() async {
  _teachersCache = null;
  final querySnapshot = await FirebaseFirestore.instance
      .collection('teachers')
      .get();
  _teachersCache = querySnapshot.docs.map((doc) {
    return {'id': doc.id, ...doc.data()};
  }).toList();

  final box = Hive.box('teachersBox');
  await box.put('teachers', _teachersCache);
  return _teachersCache!;
}

// Load exams with cache
// In-memory cache for exams
/// Get exams from cache -> Hive -> Firestore
Future<List<Map<String, dynamic>>> fetchExamsFromFirestore() async {
  if (_examsCache != null) return _examsCache!;

  final box = Hive.box('examsBox');
  final cachedList = box.get('exams');
  if (cachedList != null) {
    _examsCache = List<Map<String, dynamic>>.from(
      (cachedList as List).map((e) => Map<String, dynamic>.from(e)),
    );
    return _examsCache!;
  }

  final querySnapshot = await FirebaseFirestore.instance
      .collection('exams')
      .get();
  _examsCache = querySnapshot.docs.map((doc) {
    return {'id': doc.id, 'data': doc.data()};
  }).toList();
  await box.put('exams', _examsCache);

  return _examsCache!;
}

/// Explicitly reload (force refresh) exams from Firestore
Future<List<Map<String, dynamic>>> reloadExams() async {
  _examsCache = null;

  final querySnapshot = await FirebaseFirestore.instance
      .collection('exams')
      .get();
  _examsCache = querySnapshot.docs.map((doc) {
    return {'id': doc.id, 'data': doc.data()};
  }).toList();

  final box = Hive.box('examsBox');
  await box.put('exams', _examsCache);

  return _examsCache!;
}

// Load notices with cache
Future<List<Map<String, dynamic>>> fetchNoticesFromFirestore() async {
  if (_noticesCache != null) return _noticesCache!;

  final box = Hive.box('noticesBox');
  final cachedList = box.get('notices');
  if (cachedList != null) {
    _noticesCache = List<Map<String, dynamic>>.from(
      (cachedList as List).map((e) => Map<String, dynamic>.from(e)),
    );
    return _noticesCache!;
  }

  final querySnapshot = await FirebaseFirestore.instance
      .collection('notices')
      .get();
  _noticesCache = querySnapshot.docs.map((doc) {
    return {'id': doc.id, 'data': doc.data()};
  }).toList();
  await box.put('notices', _noticesCache);

  return _noticesCache!;
}

/// Explicitly reload (force refresh) notices from Firestore
Future<List<Map<String, dynamic>>> reloadNotices() async {
  _noticesCache = null;

  final querySnapshot = await FirebaseFirestore.instance
      .collection('notices')
      .get();
  _noticesCache = querySnapshot.docs.map((doc) {
    return {'id': doc.id, 'data': doc.data()};
  }).toList();

  final box = Hive.box('noticesBox');
  await box.put('notices', _noticesCache);

  return _noticesCache!;
}
