import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'dart:async';
import 'dart:convert';
import '../../features/calendar/calendar_uitils.dart';
import 'package:uni_connect/utils/guest_service.dart';

Map<String, dynamic>? _cachedUserProfile;
List<Map<String, dynamic>>? _batchmatesCache;
String? _cachedProfileImagePath;
List<Map<String, dynamic>>? _teachersCache;
List<Map<String, dynamic>>? _examsCache;
List<Map<String, dynamic>>? _noticesCache;
Map<String, dynamic>? _calendarCache;

/// Loads the current user's profile data from Firestore, but uses cache if available.
Future<Map<String, dynamic>?> loadUserProfile() async {
  if (GuestService.isGuestUser) {
    if (_cachedUserProfile != null) return _cachedUserProfile;
    final jsonString = await rootBundle.loadString(
      'assets/user_profile_demo.json',
    );
    _cachedUserProfile = jsonDecode(jsonString);
    return _cachedUserProfile;
  }

  if (_cachedUserProfile != null) return _cachedUserProfile;

  try {
    final box = Hive.box('userBox');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return null;

    final cachedMap = box.get(user.email);
    if (cachedMap != null) {
      _cachedUserProfile = Map<String, dynamic>.from(cachedMap);
      return _cachedUserProfile;
    }

    // Not in Hive, load from Firestore with timeout
    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user.email)
        .get()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Profile load timeout'),
        );

    final userData = doc.exists ? doc.data() : null;
    if (userData != null) {
      _cachedUserProfile = Map<String, dynamic>.from(userData);
      await box.put(user.email, _cachedUserProfile);
    }
    return _cachedUserProfile;
  } catch (e) {
    debugPrint('Error loading user profile: $e');
    return null;
  }
}

// Call this after reloading from Firestore to force update cache
Future<Map<String, dynamic>?> reloadUserProfile() async {
  _cachedUserProfile = null;

  if (GuestService.isGuestUser) {
    final jsonString = await rootBundle.loadString(
      'assets/user_profile_demo.json',
    );
    _cachedUserProfile = jsonDecode(jsonString);
    return _cachedUserProfile;
  }

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user.email)
        .get()
        .timeout(const Duration(seconds: 10));

    final userData = doc.exists ? doc.data() : null;
    final box = Hive.box('userBox');
    if (userData != null) {
      _cachedUserProfile = Map<String, dynamic>.from(userData);
      await box.put(user.email, _cachedUserProfile);
    }
    return _cachedUserProfile;
  } catch (e) {
    debugPrint('Error reloading user profile: $e');
    return null;
  }
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
  if (GuestService.isGuestUser) {
    if (_batchmatesCache != null) return _batchmatesCache!;
    final jsonString = await rootBundle.loadString('assets/batchmates.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> list = data['batchmates'] ?? [];
    _batchmatesCache = List<Map<String, dynamic>>.from(
      list.map((e) {
        final map = Map<String, dynamic>.from(e);
        map['id'] = map['roll'] ?? map['email'] ?? 'guest_id';
        return map;
      }),
    );
    return _batchmatesCache!;
  }

  if (_batchmatesCache != null) return _batchmatesCache!;

  try {
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
        .get()
        .timeout(const Duration(seconds: 15));

    _batchmatesCache = querySnapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
    await box.put('batchmates', _batchmatesCache);

    return _batchmatesCache!;
  } catch (e) {
    debugPrint('Error fetching batchmates: $e');
    return _batchmatesCache ?? [];
  }
}

Future<List<Map<String, dynamic>>> reloadBatchmates() async {
  _batchmatesCache = null;

  if (GuestService.isGuestUser) {
    final jsonString = await rootBundle.loadString('assets/batchmates.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> list = data['batchmates'] ?? [];
    _batchmatesCache = List<Map<String, dynamic>>.from(
      list.map((e) {
        final map = Map<String, dynamic>.from(e);
        map['id'] = map['roll'] ?? map['email'] ?? 'guest_id';
        return map;
      }),
    );
    return _batchmatesCache!;
  }

  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('students')
        .get()
        .timeout(const Duration(seconds: 15));

    _batchmatesCache = querySnapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();

    final box = Hive.box('batchmatesBox');
    await box.put('batchmates', _batchmatesCache);
    return _batchmatesCache!;
  } catch (e) {
    debugPrint('Error reloading batchmates: $e');
    return _batchmatesCache ?? [];
  }
}

// Load teachers with cache
Future<List<Map<String, dynamic>>> fetchTeachersFromFirestore() async {
  if (GuestService.isGuestUser) {
    if (_teachersCache != null) return _teachersCache!;
    final jsonString = await rootBundle.loadString('assets/teachers.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> list = data['teachers'] ?? [];
    _teachersCache = List<Map<String, dynamic>>.from(
      list.map((e) {
        final map = Map<String, dynamic>.from(e);
        map['id'] = map['email'] ?? 'guest_id';
        return map;
      }),
    );
    return _teachersCache!;
  }

  if (_teachersCache != null) return _teachersCache!;

  try {
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
        .get()
        .timeout(const Duration(seconds: 10));

    _teachersCache = querySnapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
    await box.put('teachers', _teachersCache);

    return _teachersCache!;
  } catch (e) {
    debugPrint('Error fetching teachers: $e');
    return _teachersCache ?? [];
  }
}

Future<List<Map<String, dynamic>>> reloadTeachers() async {
  _teachersCache = null;

  if (GuestService.isGuestUser) {
    final jsonString = await rootBundle.loadString('assets/teachers.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> list = data['teachers'] ?? [];
    _teachersCache = List<Map<String, dynamic>>.from(
      list.map((e) {
        final map = Map<String, dynamic>.from(e);
        map['id'] = map['email'] ?? 'guest_id';
        return map;
      }),
    );
    return _teachersCache!;
  }

  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .get()
        .timeout(const Duration(seconds: 10));

    _teachersCache = querySnapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();

    final box = Hive.box('teachersBox');
    await box.put('teachers', _teachersCache);
    return _teachersCache!;
  } catch (e) {
    debugPrint('Error reloading teachers: $e');
    return _teachersCache ?? [];
  }
}

// Load exams with cache
// In-memory cache for exams
/// Get exams from cache -> Hive -> Firestore
Future<List<Map<String, dynamic>>> fetchExamsFromFirestore() async {
  if (GuestService.isGuestUser) {
    if (_examsCache != null) return _examsCache!;
    final jsonString = await rootBundle.loadString('assets/exams.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> list = data['upcoming_exams'] ?? [];
    _examsCache = List<Map<String, dynamic>>.from(
      list.map((e) {
        final map = Map<String, dynamic>.from(e);
        return {'id': map['title'] ?? 'guest_exam', 'data': map};
      }),
    );
    return _examsCache!;
  }

  if (_examsCache != null) return _examsCache!;

  try {
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
        .get()
        .timeout(const Duration(seconds: 10));

    _examsCache = querySnapshot.docs.map((doc) {
      return {'id': doc.id, 'data': doc.data()};
    }).toList();
    await box.put('exams', _examsCache);

    return _examsCache!;
  } catch (e) {
    debugPrint('Error fetching exams: $e');
    return _examsCache ?? [];
  }
}

/// Explicitly reload (force refresh) exams from Firestore
Future<List<Map<String, dynamic>>> reloadExams() async {
  _examsCache = null;

  if (GuestService.isGuestUser) {
    final jsonString = await rootBundle.loadString('assets/exams.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> list = data['upcoming_exams'] ?? [];
    _examsCache = List<Map<String, dynamic>>.from(
      list.map((e) {
        final map = Map<String, dynamic>.from(e);
        return {'id': map['title'] ?? 'guest_exam', 'data': map};
      }),
    );
    return _examsCache!;
  }

  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('exams')
        .get()
        .timeout(const Duration(seconds: 10));

    _examsCache = querySnapshot.docs.map((doc) {
      return {'id': doc.id, 'data': doc.data()};
    }).toList();

    final box = Hive.box('examsBox');
    await box.put('exams', _examsCache);

    return _examsCache!;
  } catch (e) {
    debugPrint('Error reloading exams: $e');
    return _examsCache ?? [];
  }
}

// Load notices with cache
Future<List<Map<String, dynamic>>> fetchNoticesFromFirestore() async {
  if (GuestService.isGuestUser) {
    if (_noticesCache != null) return _noticesCache!;
    final jsonString = await rootBundle.loadString('assets/notices.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> list = data['notices'] ?? [];
    _noticesCache = List<Map<String, dynamic>>.from(
      list.map((e) {
        final map = Map<String, dynamic>.from(e);
        return {'id': map['title'] ?? 'guest_notice', 'data': map};
      }),
    );
    return _noticesCache!;
  }

  if (_noticesCache != null) return _noticesCache!;

  try {
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
        .get()
        .timeout(const Duration(seconds: 10));

    _noticesCache = querySnapshot.docs.map((doc) {
      return {'id': doc.id, 'data': doc.data()};
    }).toList();
    await box.put('notices', _noticesCache);

    return _noticesCache!;
  } catch (e) {
    debugPrint('Error fetching notices: $e');
    return _noticesCache ?? [];
  }
}

/// Explicitly reload (force refresh) notices from Firestore
Future<List<Map<String, dynamic>>> reloadNotices() async {
  _noticesCache = null;

  if (GuestService.isGuestUser) {
    final jsonString = await rootBundle.loadString('assets/notices.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> list = data['notices'] ?? [];
    _noticesCache = List<Map<String, dynamic>>.from(
      list.map((e) {
        final map = Map<String, dynamic>.from(e);
        return {'id': map['title'] ?? 'guest_notice', 'data': map};
      }),
    );
    return _noticesCache!;
  }

  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('notices')
        .get()
        .timeout(const Duration(seconds: 10));

    _noticesCache = querySnapshot.docs.map((doc) {
      return {'id': doc.id, 'data': doc.data()};
    }).toList();

    final box = Hive.box('noticesBox');
    await box.put('notices', _noticesCache);

    return _noticesCache!;
  } catch (e) {
    debugPrint('Error reloading notices: $e');
    return _noticesCache ?? [];
  }
}

/// Converts all Firestore Timestamp (and DateTime) values in a raw calendar
/// document map to ISO 8601 strings so the map can be safely stored in Hive.
/// Hive cannot serialize Firestore Timestamp objects; they come back as null
/// or a broken HiveMap on the next cold boot, causing 'no calendar data'.
Map<String, dynamic> _normalizeCalendarMap(Map<String, dynamic> raw) {
  String? dateToIso(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is String) return value; // already ISO
    return null;
  }

  final normalized = Map<String, dynamic>.from(raw);

  // Top-level date fields
  for (final field in [
    'startDate',
    'endDate',
    'plStart',
    'plEnd',
    'finalsStart',
    'finalsEnd',
  ]) {
    final iso = dateToIso(normalized[field]);
    if (iso != null) normalized[field] = iso;
  }

  // Vacation list — each entry has its own startDate/endDate
  if (normalized['vacations'] is List) {
    normalized['vacations'] = (normalized['vacations'] as List).map((v) {
      if (v is! Map) return v;
      final vMap = Map<String, dynamic>.from(v);
      final vStart = dateToIso(vMap['startDate']);
      final vEnd = dateToIso(vMap['endDate']);
      if (vStart != null) vMap['startDate'] = vStart;
      if (vEnd != null) vMap['endDate'] = vEnd;
      return vMap;
    }).toList();
  }

  return normalized;
}

/// Get calendar data from cache -> Hive -> Firestore
Future<Map<String, dynamic>?> fetchCalendarFromFirestore() async {
  if (GuestService.isGuestUser) {
    if (_calendarCache != null) return _calendarCache;
    final jsonString = await rootBundle.loadString('assets/calendar_demo.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    _calendarCache = {'id': 'calendar_guest', ...data};
    return _calendarCache;
  }

  if (_calendarCache != null) return _calendarCache;

  try {
    final box = Hive.box('calendarBox');
    final cachedMap = box.get('calendar');
    if (cachedMap != null) {
      final map = Map<String, dynamic>.from(cachedMap);
      // Validate the cached entry uses the ISO string format (new format).
      // If startDate is not a String, it's a pre-fix Timestamp entry — evict
      // it and re-fetch from Firestore so stale/corrupt data is not served.
      if (map['startDate'] is String) {
        _calendarCache = map;
        return _calendarCache;
      } else {
        debugPrint(
          'Calendar Hive cache is in old (Timestamp) format — evicting and re-fetching.',
        );
        await box.delete('calendar');
      }
    }

    // Only one document in calendar collection
    final querySnapshot = await FirebaseFirestore.instance
        .collection('calendar')
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final normalized = _normalizeCalendarMap({'id': doc.id, ...doc.data()});
      _calendarCache = normalized;
      await box.put('calendar', normalized);
    }

    return _calendarCache;
  } catch (e) {
    debugPrint('Error fetching calendar: $e');
    return null;
  }
}

/// Explicitly reload (force refresh) calendar from Firestore
Future<Map<String, dynamic>?> reloadCalendar() async {
  _calendarCache = null;

  if (GuestService.isGuestUser) {
    final jsonString = await rootBundle.loadString('assets/calendar_demo.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    _calendarCache = {'id': 'calendar_guest', ...data};
    return _calendarCache;
  }

  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('calendar')
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final normalized = _normalizeCalendarMap({'id': doc.id, ...doc.data()});
      _calendarCache = normalized;

      final box = Hive.box('calendarBox');
      await box.put('calendar', normalized);

      // Clear local notes because the admin has updated the calendar dates
      clearAllCalendarNotes();
    }

    return _calendarCache;
  } catch (e) {
    debugPrint('Error reloading calendar: $e');
    return null;
  }
}
