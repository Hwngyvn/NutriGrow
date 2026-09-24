import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/food_model.dart';

class NutritionService {
  NutritionService._();
  static final NutritionService instance = NutritionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addNutritionLog({
    required String uid,
    required FoodModel food,
  }) async {
    await _firestore.collection('nutrition_logs').add({
      'uid': uid,
      'foodName': food.name,
      'calories': food.calories,
      'protein': food.protein,
      'carbs': food.carbs,
      'fat': food.fat,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNutritionLog(String logId) async {
    await _firestore.collection('nutrition_logs').doc(logId).delete();
  }

  Future<List<FoodModel>> fetchNutritionLogs({
    required String uid,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> query =
        _firestore.collection('nutrition_logs').where('uid', isEqualTo: uid);

    if (startDate != null && endDate != null) {
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final snapshot = await query.orderBy('createdAt', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return FoodModel(
        name: data['foodName']?.toString() ?? '',
        calories: (data['calories'] ?? 0).toInt(),
        protein: (data['protein'] ?? 0.0).toDouble(),
        fat: (data['fat'] ?? 0.0).toDouble(),
        carbs: (data['carbs'] ?? 0.0).toDouble(),
      );
    }).toList();
  }

  Future<Map<String, double>> calculateDailyTotals({
    required String uid,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('nutrition_logs')
        .where('uid', isEqualTo: uid)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      calories += (data['calories'] ?? 0).toDouble();
      protein += (data['protein'] ?? 0).toDouble();
      carbs += (data['carbs'] ?? 0).toDouble();
      fat += (data['fat'] ?? 0).toDouble();
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}
