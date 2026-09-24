import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/colors.dart';
import '../../services/health_calculation_service.dart';

class HealthRecordingDialog
    extends StatefulWidget {

  final String childName;
  final int childAge;
  final String childGender;
  final String childId;

  const HealthRecordingDialog({
    super.key,
    required this.childName,
    required this.childAge,
    required this.childGender,
    required this.childId,
  });

  @override
  State<HealthRecordingDialog>
      createState() =>
          _HealthRecordingDialogState();
}

class _HealthRecordingDialogState
    extends State<HealthRecordingDialog> {

  final TextEditingController
      weightController =
          TextEditingController();

  final TextEditingController
      heightController =
          TextEditingController();

  bool isSaving = false;

  Future<void> saveHealthRecord()
      async {

    if (weightController
            .text.isEmpty ||
        heightController
            .text.isEmpty) {

      ScaffoldMessenger.of(
          context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Semua field harus diisi",
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {

      final uid =
          FirebaseAuth.instance
              .currentUser!
              .uid;

      final weight = double.parse(
          weightController.text);

      final height = double.parse(
          heightController.text);

      // Diagnosa status gizi
      final diagnosis =
          HealthCalculationService
              .diagnoseNutritionalStatus(
            widget.childAge * 12,
            weight,
            height,
            widget.childGender,
          );

      // Simpan ke Firestore
      await FirebaseFirestore.instance
          .collection(
              "health_records")
          .add({
        "childId": widget.childId,
        "uid": uid,
        "date": Timestamp.now(),
        "weight": weight,
        "height": height,
        "status":
            diagnosis["status"],
        "diagnosis":
            diagnosis["diagnosis"],
        "imt": diagnosis["imt"],
      });

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("children")
          .doc(widget.childId)
          .update({
        "weight": weight,
        "height": height,
      });

      if (mounted) {

        ScaffoldMessenger.of(
            context)
            .showSnackBar(

          const SnackBar(
            content: Text(
              "Rekam kesehatan berhasil disimpan",
            ),
            duration:
                Duration(
                    seconds: 2),
          ),
        );

        Navigator.pop(context,
            true);
      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(
            context)
            .showSnackBar(

          SnackBar(
            content:
                Text(
              "Error: $e",
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: const Text(
        "Rekam Pengukuran Kesehatan",
      ),

      content:
          SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [

            Text(
              "Data anak: ${widget.childName} (${widget.childAge} tahun)",

              style:
                  const TextStyle(
                fontSize: 12,

                color: Colors.grey,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            TextField(
              controller:
                  weightController,

              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                    decimal:
                        true,
                  ),

              decoration:
                  InputDecoration(
                hintText:
                    "Berat Badan (kg)",

                labelText:
                    "Berat Badan",

                prefixIcon:
                    const Icon(
                  Icons
                      .monitor_weight,
                ),

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                              8),
                ),
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            TextField(
              controller:
                  heightController,

              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                    decimal:
                        true,
                  ),

              decoration:
                  InputDecoration(
                hintText:
                    "Tinggi Badan (cm)",

                labelText:
                    "Tinggi Badan",

                prefixIcon:
                    const Icon(
                  Icons.height,
                ),

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                              8),
                ),
              ),
            ),
          ],
        ),
      ),

      actions: [

        TextButton(
          onPressed: isSaving
              ? null
              : () {

                Navigator.pop(
                    context);
              },

          child: const Text(
            "Batal",
          ),
        ),

        ElevatedButton(
          onPressed: isSaving
              ? null
              : saveHealthRecord,

          style:
              ElevatedButton
                  .styleFrom(
            backgroundColor:
                AppColors.primary,
          ),

          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(
                    strokeWidth:
                        2,
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                          Colors
                              .white,
                        ),
                  ),
                )
              : const Text(
                  "Simpan",

                  style:
                      TextStyle(
                    color:
                        Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }
}
