import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../services/health_calculation_service.dart';
import '../dashboard/dashboard_screen.dart';


class ProfileChildScreen extends StatefulWidget {
  final String? childId;
  final String? initialName;
  final int? initialAge;
  final String? initialActivity;

  const ProfileChildScreen({
    super.key,
    this.childId,
    this.initialName,
    this.initialAge,
    this.initialActivity,
  });

  @override
  State<ProfileChildScreen> createState() =>
      _ProfileChildScreenState();
}

class _ProfileChildScreenState
    extends State<ProfileChildScreen> {

  final nameController =
      TextEditingController();

  final ageController =
      TextEditingController();

  final weightController =
      TextEditingController();

  final heightController =
      TextEditingController();

  String gender = "Perempuan";
  String activity = "Sedang";

  bool get isEditing => widget.childId != null;

  static const Map<String, String> activityDescriptions = {
    "Sangat Ringan": "lebih banyak duduk",
    "Ringan": "aktivitas santai",
    "Sedang": "aktif bermain",
    "Berat": "banyak bergerak",
    "Sangat Berat": "sangat aktif",
  };

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      nameController.text = widget.initialName ?? "";
      ageController.text = widget.initialAge?.toString() ?? "";
      activity = widget.initialActivity ?? activity;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  Future<void> saveChildData() async {

    try {

      final isMissingRequiredData = isEditing
          ? nameController.text.isEmpty || ageController.text.isEmpty
          : nameController.text.isEmpty ||
              ageController.text.isEmpty ||
              weightController.text.isEmpty ||
              heightController.text.isEmpty;

      if (isMissingRequiredData) {

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "Semua data harus diisi",
            ),
          ),
        );

        return;
      }

      final uid =
          FirebaseAuth.instance
              .currentUser!
              .uid;

      final childName = nameController.text.trim();
      final childAgeYears = int.parse(ageController.text.trim());

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("children")
            .doc(widget.childId)
            .update({
          "childName": childName,
          "age": childAgeYears,
          "activity": activity,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil anak berhasil diperbarui"),
          ),
        );

        Navigator.pop(context);
        return;
      }

      final childWeightKg = double.parse(weightController.text.trim());
      final childHeightCm = double.parse(heightController.text.trim());
      final childGender = gender;
      final childActivity = activity;

      final childDocRef = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("children")
          .add({
        "childName": childName,
        "age": childAgeYears,
        "gender": childGender,
        "weight": childWeightKg,
        "height": childHeightCm,
        "activity": childActivity,
      });

      // Set as active child
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('activeChildId_$uid', childDocRef.id);

      // Auto monitoring: buat record health berdasarkan data profil anak yang baru disimpan
      final ageMonths = childAgeYears * 12;
      final diagnosis =
          HealthCalculationService.diagnoseNutritionalStatus(
        ageMonths,
        childWeightKg,
        childHeightCm,
        childGender,
      );

      await FirebaseFirestore.instance
          .collection("health_records")
          .add({
        "uid": uid,
        "childId": childDocRef.id,
        "date": DateTime.now(),
        "weight": childWeightKg,
        "height": childHeightCm,
        "status": diagnosis["status"],
        "diagnosis": diagnosis["diagnosis"],
        "imt": diagnosis["imt"],
      });


      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );


    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text("Error: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isEditing ? "Edit Profil Anak" : "Profil Anak"),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [

            CustomTextField(
              controller:
                  nameController,
              hint: "Nama Anak",
            ),

            const SizedBox(height: 15),

            CustomTextField(
              controller:
                  ageController,
              hint:
                  "Usia (tahun)",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 15),

            if (!isEditing) ...[
              DropdownButtonFormField<String>(
                initialValue: gender,

                items: const [

                  DropdownMenuItem(
                    value:
                        "Perempuan",
                    child: Text(
                      "Perempuan",
                    ),
                  ),

                  DropdownMenuItem(
                    value:
                        "Laki-laki",
                    child: Text(
                      "Laki-laki",
                    ),
                  ),
                ],

                onChanged: (value) {
                  setState(() {
                    gender = value!;
                  });
                },
              ),

              const SizedBox(height: 15),

              CustomTextField(
                controller:
                    weightController,
                hint:
                    "Berat Badan (kg)",
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 15),

              CustomTextField(
                controller:
                    heightController,
                hint:
                    "Tinggi Badan (cm)",
                keyboardType: TextInputType.number,
              ),

            ],

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: activity,

              decoration: InputDecoration(
                labelText: "Tingkat Aktivitas",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),

              selectedItemBuilder: (context) {
                return activityDescriptions.keys
                    .map(
                      (value) => Text(value),
                    )
                    .toList();
              },

              items: activityDescriptions.entries
                  .map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 105,
                        child: Text(entry.key),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              onChanged: (value) {
                setState(() {
                  activity = value!;
                });
              },
            ),

            const SizedBox(height: 30),

            CustomButton(
              text: isEditing ? "Simpan Perubahan" : "Simpan",

              onPressed: () async {
                await saveChildData();
              },
            ),
          ],
        ),
      ),
    );
  }
}
