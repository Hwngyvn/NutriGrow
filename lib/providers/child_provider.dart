import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _name = 'Loading...';
  int _age = 0;
  double _weight = 0.0;
  double _height = 0.0;
  String _gender = 'Laki-laki';
  String _activity = 'Sedang';
  bool _isLoading = false;
  String? _errorMessage;

  String get name => _name;
  int get age => _age;
  double get weight => _weight;
  double get height => _height;
  String get gender => _gender;
  String get activity => _activity;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadChildData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        _name = doc.data()?['childName'] ?? 'Child';
        _age = int.tryParse(doc.data()?['age'].toString() ?? '0') ?? 0;
        _weight = double.tryParse(doc.data()?['weight'].toString() ?? '0') ?? 0.0;
        _height = double.tryParse(doc.data()?['height'].toString() ?? '0') ?? 0.0;
        _gender = doc.data()?['gender'] ?? 'Laki-laki';
        _activity = doc.data()?['activity'] ?? 'Sedang';
      }

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateChildData({
    required String name,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activity,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uid = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(uid).update({
        'childName': name,
        'age': age,
        'weight': weight,
        'height': height,
        'gender': gender,
        'activity': activity,
      });

      _name = name;
      _age = age;
      _weight = weight;
      _height = height;
      _gender = gender;
      _activity = activity;

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
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
