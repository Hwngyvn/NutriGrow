import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionLog {
  final String id;
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime createdAt;

  NutritionLog({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.createdAt,
  });

  factory NutritionLog.fromFirestore(Map<String, dynamic> data, String id) {
    return NutritionLog(
      id: id,
      foodName: data['foodName'] ?? '',
      calories: data['calories'] ?? 0,
      protein: (data['protein'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class NutritionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<NutritionLog> _logs = [];
  double _totalCalories = 0.0;
  double _totalProtein = 0.0;
  double _totalCarbs = 0.0;
  double _totalFat = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  List<NutritionLog> get logs => _logs;
  double get totalCalories => _totalCalories;
  double get totalProtein => _totalProtein;
  double get totalCarbs => _totalCarbs;
  double get totalFat => _totalFat;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadNutritionLogs() async {
    try {
      _isLoading = true;
      notifyListeners();

      final uid = _auth.currentUser!.uid;
      final snapshot = await _firestore
          .collection('nutrition_logs')
          .where('uid', isEqualTo: uid)
          .get();

      _logs = snapshot.docs
          .map((doc) => NutritionLog.fromFirestore(doc.data(), doc.id))
          .toList();

      _calculateTotals();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateTotals() {
    _totalCalories = 0.0;
    _totalProtein = 0.0;
    _totalCarbs = 0.0;
    _totalFat = 0.0;

    for (var log in _logs) {
      _totalCalories += log.calories;
      _totalProtein += log.protein;
      _totalCarbs += log.carbs;
      _totalFat += log.fat;
    }
  }

  Future<bool> addNutritionLog({
    required String foodName,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uid = _auth.currentUser!.uid;
      await _firestore.collection('nutrition_logs').add({
        'uid': uid,
        'foodName': foodName,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await loadNutritionLogs();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNutritionLog(String logId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('nutrition_logs').doc(logId).delete();
      await loadNutritionLogs();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
