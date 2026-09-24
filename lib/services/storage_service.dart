import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<void> createUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> addNutritionLog(Map<String, dynamic> data) async {
    await _firestore.collection('nutrition_logs').add(data);
  }

  Future<void> deleteNutritionLog(String logId) async {
    await _firestore.collection('nutrition_logs').doc(logId).delete();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getNutritionLogs(String uid) async {
    return await _firestore
        .collection('nutrition_logs')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getHealthRecords(String uid) async {
    return await _firestore
        .collection('health_records')
        .where('uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .get();
  }
}
