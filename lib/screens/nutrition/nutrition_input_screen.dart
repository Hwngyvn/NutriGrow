import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../monitoring/food_database.dart';
import '../dashboard/dashboard_screen.dart';
import '../monitoring/monitoring_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_child_screen.dart';
import '../../widgets/app_bottom_navigation_bar.dart';



class NutritionInputScreen extends StatefulWidget {
  const NutritionInputScreen({super.key});

  @override
  State<NutritionInputScreen> createState() => _NutritionInputScreenState();
}

class _NutritionInputScreenState extends State<NutritionInputScreen> {
  final foodNameController = TextEditingController();
  final caloriesController = TextEditingController();
  final proteinController = TextEditingController();
  final carbsController = TextEditingController();
  final fatController = TextEditingController();

  List<Map<String, dynamic>> searchResults = [];
  bool showSearchResults = false;
  String? activeChildId;

  @override
  void initState() {
    super.initState();
    foodNameController.addListener(_onSearchChanged);
    _loadActiveChild();
  }

  Future<void> _loadActiveChild() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      activeChildId = prefs.getString('activeChildId_$uid');
    });
  }

  @override
  void dispose() {
    foodNameController.removeListener(_onSearchChanged);
    foodNameController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (foodNameController.text.isEmpty) {
      setState(() {
        searchResults = [];
        showSearchResults = false;
      });
      return;
    }

    final query = foodNameController.text.toLowerCase();

    final results = FoodDatabase.foods.where((food) {
      return food['name'].toString().toLowerCase().contains(query);
    }).toList();

    setState(() {
      searchResults = results;
      showSearchResults = true;
    });
  }


  void _onFoodSelected(Map<String, dynamic> food) {
    foodNameController.text = food['name'];
    caloriesController.text = food['calories'].toString();
    proteinController.text = food['protein'].toString();
    carbsController.text = food['carbs'].toString();
    fatController.text = food['fat'].toString();

    setState(() {
      showSearchResults = false;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> saveNutritionData() async {
    if (foodNameController.text.isEmpty || caloriesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama makanan dan kalori harus diisi.")),
      );
      return;
    }

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final prefs = await SharedPreferences.getInstance();
      final activeChildId = prefs.getString('activeChildId_$uid');

      if (activeChildId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak ada anak yang aktif.")),
        );
        return;
      }

      await FirebaseFirestore.instance.collection("nutrition_logs").add({
        "uid": uid,
        "childId": activeChildId,
        "foodName": foodNameController.text.trim(),
        "calories": double.tryParse(caloriesController.text) ?? 0,
        "protein": double.tryParse(proteinController.text) ?? 0,
        "carbs": double.tryParse(carbsController.text) ?? 0,
        "fat": double.tryParse(fatController.text) ?? 0,
        "createdAt": Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Catatan makanan berhasil disimpan!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan data: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catat Makanan"),
        backgroundColor: AppColors.primary,
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return;

          Widget destination;
          switch (index) {
            case 0:
              destination = const DashboardScreen();
              break;
            case 2:
              destination = activeChildId == null
                  ? const ProfileChildScreen()
                  : const MonitoringScreen();
              break;
            case 3:
              destination = const ProfileScreen();
              break;
            default:
              return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            showSearchResults = false;
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Cari atau Tambah Makanan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Stack(
                children: [
                  Column(
                    children: [
                      CustomTextField(
                        controller: foodNameController,
                        hint: "Contoh: Nasi Putih",
                      ),
                      const SizedBox(height: 15),
                      CustomTextField(
                        controller: caloriesController,
                        hint: "Kalori (kcal)",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: proteinController,
                              hint: "Protein (g)",
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: CustomTextField(
                              controller: carbsController,
                              hint: "Karbo (g)",
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      CustomTextField(
                        controller: fatController,
                        hint: "Lemak (g)",
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  if (showSearchResults && searchResults.isNotEmpty)
                    Positioned(
                      top: 65,
                      left: 0,
                      right: 0,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                            )
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final food = searchResults[index];
                            return ListTile(
                              title: Text(food['name']),
                              subtitle: Text(
                                  "${food['calories']} kcal, P:${food['protein']}g, K:${food['carbs']}g, L:${food['fat']}g"),
                              onTap: () => _onFoodSelected(food),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              CustomButton(
                text: "Simpan Catatan",
                onPressed: saveNutritionData,
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  "Jika makanan tidak ada di pencarian, Anda bisa menambahkannya secara manual dengan mengisi semua kolom di atas.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
