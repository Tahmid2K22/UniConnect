import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> fetchExamsFromFirestore() async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('exams')
      .get();
  return querySnapshot.docs.map((doc) {
    return {"id": doc.id, "data": doc.data()};
  }).toList();
}

Future<List<Map<String, dynamic>>> fetchNoticesFromFirestore() async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('notices')
      .get();
  return querySnapshot.docs.map((doc) {
    return {"id": doc.id, "data": doc.data()};
  }).toList();
}