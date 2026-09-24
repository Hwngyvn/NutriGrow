import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/colors.dart';
import '../../services/health_calculation_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';

import '../nutrition/nutrition_input_screen.dart';
import '../auth/login_screen.dart';
import '../monitoring/monitoring_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_child_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {

  String? activeChildId;
  String childName = "Loading...";
  String age = "";
  double weight = 0;
  double height = 0;
  String gender = "Laki-laki";
  String activity = "Sedang";

  double totalCalories = 0;
  double totalProtein = 0;
  double totalCarbs = 0;
  double totalFat = 0;

  // AKG Target (dihitung berdasarkan data anak)
  double targetCalories = 1500;
  double targetProtein = 40;
  double targetCarbs = 200;
  double targetFat = 50;

  String nutritionStatus = "Normal";
  String nutritionDiagnosis = "";

  List<Map<String, dynamic>> foodHistory = [];
  int currentNavIndex = 0;

  Future<void> _checkActiveChild() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() {
      activeChildId = prefs.getString('activeChildId_$uid');
    });
    await loadChildData();
  }

  Future<void> loadChildData() async {

    try {
      final uid =
          FirebaseAuth.instance
              .currentUser!
              .uid;

      if (activeChildId == null) {
        final childrenSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('children').limit(1).get();
        if (childrenSnapshot.docs.isNotEmpty) {
          activeChildId = childrenSnapshot.docs.first.id;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('activeChildId_$uid', activeChildId!);
        } else {
          // Tidak ada anak, reset state
          setState(() {
            childName = "Belum ada data anak";
            age = ""; weight = 0; height = 0;
            nutritionStatus = "Tidak ada data";
            nutritionDiagnosis = "Silakan tambahkan profil anak Anda di halaman profil.";
          });
          return;
        }
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("children").doc(activeChildId).get();
      if (doc.exists) {

        final childAge = int.tryParse(
              doc.data()?["age"]
                  .toString() ??
                  "0",
            ) ??
            0;

        final childWeight = double.tryParse(
              doc.data()?["weight"]
                  .toString() ??
                  "0",
            ) ??
            0;

        final childHeight = double.tryParse(
              doc.data()?["height"]
                  .toString() ??
                  "0",
            ) ??
            0;

        final childGender = doc.data()?[
            "gender"] ??
            "Laki-laki";

        final childActivity = doc.data()?[
            "activity"] ??
            "Sedang";
        final normalizedActivity =
            childActivity == "Aktif"
                ? "Berat"
                : childActivity;

        // Hitung kebutuhan kalori berdasarkan AKG
        final calculatedCalories =
            HealthCalculationService
                .calculateDailyCalories(
              childAge,
              childGender,
              childWeight,
              childHeight,
              normalizedActivity,
            );

        final calculatedProtein =
            HealthCalculationService
                .calculateProteinNeeds(
              childWeight,
            );

        final calculatedCarbs =
            HealthCalculationService
                .calculateCarbNeeds(
              calculatedCalories,
            );

        final calculatedFat =
            HealthCalculationService
                .calculateFatNeeds(
              calculatedCalories,
            );

        // Diagnosa status gizi
        final diagnosis =
            HealthCalculationService
                .diagnoseNutritionalStatus(
              childAge * 12,
              // konversi tahun ke bulan
              childWeight,
              childHeight,
              childGender,
            );

        setState(() {

          childName =
              doc.data()?["childName"] ??
                  "";

          age = childAge.toString();

          weight = childWeight;

          height = childHeight;

          gender =
              childGender;

          activity =
              normalizedActivity;

          targetCalories =
              calculatedCalories;

          targetProtein =
              calculatedProtein;

          targetCarbs =
              calculatedCarbs;

          targetFat =
              calculatedFat;

          nutritionStatus =
              diagnosis["status"] ??
                  "Normal";

          nutritionDiagnosis =
              diagnosis["diagnosis"] ??
                  "";
        });
      }

    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadNutritionData() async {

    if (activeChildId == null) return;

    try {

      final uid =
          FirebaseAuth.instance.currentUser!.uid;

      final snapshot =
          await FirebaseFirestore.instance
              .collection("nutrition_logs")
              .where("childId", isEqualTo: activeChildId)
              .where("uid", isEqualTo: uid)
              .get();

      double calories = 0;
      double protein = 0;
      double carbs = 0;
      double fat = 0;

      List<Map<String, dynamic>> history = [];

      for (var doc in snapshot.docs) {

        final data = doc.data();

        calories +=
            (data["calories"] ?? 0).toDouble();

        protein +=
            (data["protein"] ?? 0).toDouble();

        carbs +=
            (data["carbs"] ?? 0).toDouble();

        fat +=
            (data["fat"] ?? 0).toDouble();

        history.add({
          ...data,
          "docId": doc.id,
        });
      }

      setState(() {

        totalCalories = calories;
        totalProtein = protein;
        totalCarbs = carbs;
        totalFat = fat;

        foodHistory = history;
      });

    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteFoodItem(String docId) async {

    try {

      await FirebaseFirestore.instance
          .collection("nutrition_logs")
          .doc(docId)
          .delete();

      await loadNutritionData();

    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> logout(BuildContext context) async {

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _checkActiveChild().then((_) => loadNutritionData());
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          AppColors.background,

      bottomNavigationBar:
          AppBottomNavigationBar(
        currentIndex: currentNavIndex,
        onTap: (int index) async {

          setState(() {
            currentNavIndex = index;
          });

          switch (index) {
            case 0:
              // Beranda (Dashboard)
              return;

            case 1:
              // Gizi (Nutrition Input)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => activeChildId == null ? const ProfileChildScreen() :
                      const NutritionInputScreen(),
                ),
              );
              return;

            case 2:
              // Monitoring
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => activeChildId == null ? const ProfileChildScreen() :
                      const MonitoringScreen(),
                ),
              );
              return;

            case 3:
              // Profil
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => 
                      const ProfileScreen(),
                ),
              );
              return;
          }
        },

      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // App Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/NutriGrow_Logo_App_Icon.png',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "NutriGrow",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Monitoring gizi anak",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    color: AppColors.textPrimary,
                    onPressed: () async {
                      final result =
                          await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text(
                              "Logout",
                            ),
                            content: const Text(
                              "Yakin ingin keluar?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    false,
                                  );
                                },
                                child: const Text(
                                  "Batal",
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    true,
                                  );
                                },
                                child: const Text(
                                  "Keluar",
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (result == true) {
                        final currentContext = context;
                        await FirebaseAuth.instance.signOut();

                        if (!mounted) return;

                        Navigator.pushAndRemoveUntil(
                          currentContext,
                          MaterialPageRoute(
                            builder: (_) =>
                                const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Child Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              childName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              age.isNotEmpty ? "$age tahun" : "-",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            activeChildId == null ? "N/A" : nutritionStatus,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              weight.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              "Berat (kg)",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              height.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              "Tinggi (cm)",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            SizedBox(
                              width: 86,
                              child: Text(
                                activity,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Text(
                              "Aktivitas",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (activeChildId != null && nutritionStatus == "Stunting") ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red[300]!,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nutritionDiagnosis.isNotEmpty
                              ? nutritionDiagnosis
                              : "Anak mengalami stunting (pendek). Segera konsultasi dengan tenaga kesehatan.",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (activeChildId == null) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.blue[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nutritionDiagnosis,
                          style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                        ),
                      ),
                    ],
                  ),
                )
              ],

              const SizedBox(height: 25),

              // Nutrition Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Kalori Hari Ini",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => activeChildId == null ? const ProfileChildScreen() :
                              const NutritionInputScreen(),
                        ),
                      );

                      await loadChildData();
                      await loadNutritionData();

                      if (mounted) {
                        setState(() {
                          currentNavIndex = 0;
                        });
                      }
                    },
                    child: Text(
                      "Target AKG",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          activeChildId == null ? "0 / 0 kcal" : "${totalCalories.toStringAsFixed(0)} / ${targetCalories.toStringAsFixed(0)} kcal",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          activeChildId == null ? "0%" : "${((totalCalories / (targetCalories > 0 ? targetCalories : 1)) * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator( 
                        value: activeChildId == null ? 0 : (totalCalories / (targetCalories > 0 ? targetCalories : 1)).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Nutrition Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutritionBox(
                    "Protein",
                    activeChildId == null ? "0g" : "${totalProtein.toStringAsFixed(0)} g",
                    targetProtein,
                  ),
                  _buildNutritionBox(
                    "Karbohidrat",
                    activeChildId == null ? "0g" : "${totalCarbs.toStringAsFixed(0)} g",
                    targetCarbs,
                  ),
                  _buildNutritionBox(
                    "Lemak",
                    activeChildId == null ? "0g" : "${totalFat.toStringAsFixed(0)} g",
                    targetFat,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Food History Section
              const Text(
                "Catatan Makan Hari Ini",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              foodHistory.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.fastfood_outlined,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Belum ada catatan makanan",
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: foodHistory.map((food) {
                        return Dismissible(
                          key: Key(food['docId'] ?? food['foodName']),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) {
                            deleteFoodItem(food['docId']);
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        food['foodName'] ?? 'Food',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${food['calories'] ?? 0} kcal",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "P: ${(food['protein'] ?? 0).toStringAsFixed(1)}g",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      "K: ${(food['carbs'] ?? 0).toStringAsFixed(1)}g",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionBox(String label, String value, double target) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activeChildId == null ? "Target: 0g" : "Target: ${target.toStringAsFixed(0)}g",
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
