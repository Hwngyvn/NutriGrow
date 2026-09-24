import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/colors.dart';
import '../../services/health_calculation_service.dart';
import '../../widgets/health_recording_dialog.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../dashboard/dashboard_screen.dart';
import '../nutrition/nutrition_input_screen.dart';
import '../profile/profile_child_screen.dart';
import '../profile/profile_screen.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() =>
      _MonitoringScreenState();
}

class _MonitoringScreenState
    extends State<MonitoringScreen> {

  String? activeChildId;
  String childName = "Loading...";
  int childAge = 0;
  String childGender = "Laki-laki";
  List<Map<String, dynamic>> healthHistory = [];
  Map<String, dynamic> latestStatus = {};
  String? errorMessage;

  String formatRecordDate(dynamic value) {
    final date = parseRecordDate(value);

    if (date == null) {
      return "-";
    }

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  DateTime? parseRecordDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    loadHealthData();
  }

  Future<void> loadHealthData() async {

    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    activeChildId = prefs.getString('activeChildId_$uid');

    if (activeChildId == null) {
      setState(() {
        errorMessage = "Pilih anak terlebih dahulu di halaman profil.";
      });
      return;
    }

    try {

      // Load profil anak
      final childDoc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("children")
              .doc(activeChildId)
              .get();

      if (childDoc.exists) {
        final childWeight = double.tryParse(
              childDoc.data()?[
                  "weight"]
                  .toString() ??
                  "0",
            ) ??
            0;

        final childHeight = double.tryParse(
              childDoc.data()?[
                  "height"]
                  .toString() ??
                  "0",
            ) ??
            0;

        final loadedChildAge =
            int.tryParse(
                  childDoc.data()?[
                      "age"]
                      .toString() ??
                      "0",
                ) ??
                0;

        final loadedChildGender =
            childDoc.data()?[
                "gender"] ??
                "Laki-laki";

        setState(() {
          childName =
              childDoc.data()?["childName"] ?? "";

          childAge =
              loadedChildAge;

          childGender =
              loadedChildGender;
        });

        // Load riwayat kesehatan
        final healthSnapshot =
            await FirebaseFirestore.instance
                .collection("health_records")
                .where("childId", isEqualTo: activeChildId)
                .where("uid", isEqualTo: uid)
                .get();

        List<Map<String, dynamic>> history = [];
        for (var doc in healthSnapshot.docs) {
          history.add(doc.data());
        }

        if (history.isEmpty &&
            childWeight > 0 &&
            childHeight > 0 &&
            loadedChildAge > 0) {
          final diagnosis =
              HealthCalculationService
                  .diagnoseNutritionalStatus(
            loadedChildAge * 12,
            childWeight,
            childHeight,
            loadedChildGender,
          );

          final initialRecord = {
            "uid": uid,
            "childId": activeChildId,
            "date": Timestamp.now(),
            "weight": childWeight,
            "height": childHeight,
            "status": diagnosis["status"],
            "diagnosis": diagnosis["diagnosis"],
            "imt": diagnosis["imt"],
          };

          await FirebaseFirestore.instance
              .collection("health_records")
              .add(initialRecord);

          history.add(initialRecord);
        }

        history.sort((a, b) {
          final firstDate = parseRecordDate(a["date"]);
          final secondDate = parseRecordDate(b["date"]);

          if (firstDate == null && secondDate == null) {
            return 0;
          }

          if (firstDate == null) {
            return 1;
          }

          if (secondDate == null) {
            return -1;
          }

          return secondDate.compareTo(firstDate);
        });

        setState(() {
          healthHistory = history;
          if (history.isNotEmpty) {
            latestStatus = history[0];
          }
          errorMessage = null;
        });
      }

    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        errorMessage = "Gagal memuat riwayat pertumbuhan";
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        title: const Text(
          "Monitoring Pertumbuhan",
        ),
        backgroundColor:
            AppColors.primary,
      ),

      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;

          Widget destination;
          switch (index) {
            case 0:
              destination = const DashboardScreen();
              break;
            case 1:
              destination = activeChildId == null
                  ? const ProfileChildScreen()
                  : const NutritionInputScreen();
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

      floatingActionButton:
          activeChildId == null
        ? null
        : FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return HealthRecordingDialog(
                    childName:
                        childName,

                    childAge:
                        childAge,

                    childGender:
                        childGender,
                    childId: activeChildId!,
                  );
                },
              ).then((result) {

                if (result == true) {

                  loadHealthData();
                }
              });
            },

        backgroundColor:
            AppColors.primary,

        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // Card Status Gizi Terkini
            Container(
              padding:
                  const EdgeInsets.all(
                      20),

              decoration:
                  BoxDecoration(
                color: AppColors
                    .darkGreenCard,

                borderRadius:
                    BorderRadius
                        .circular(
                            20),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  const Text(
                    "Status Gizi Terkini",
                    style: TextStyle(
                      color:
                          Colors.white70,
                    ),
                  ),

                  const SizedBox(
                      height: 10),

                  Text(
                    latestStatus
                            .isEmpty
                        ? "Data Tidak Tersedia"
                        : latestStatus[
                                "status"] ??
                            "Normal",

                    style:
                        const TextStyle(
                      color:
                          Colors.white,

                      fontSize: 26,

                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  const SizedBox(
                      height: 10),

                  Text(
                    latestStatus
                            .isEmpty
                        ? ""
                        : latestStatus[
                                "diagnosis"] ??
                            "",

                    style:
                        const TextStyle(
                      color:
                          Colors.white70,

                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(
                      height: 15),

                  // IMT Info
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [

                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          const Text(
                            "IMT",
                            style:
                                TextStyle(
                              color:
                                  Colors
                                      .white70,

                              fontSize:
                                  12,
                            ),
                          ),

                          const SizedBox(
                              height: 5),

                          Text(
                            latestStatus
                                    .isEmpty
                                ? "-"
                                : latestStatus[
                                        "imt"]
                                    .toStringAsFixed(
                                        1),

                            style:
                                const TextStyle(
                              color:
                                  Colors
                                      .white,

                              fontSize:
                                  18,

                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ],
                      ),

                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          const Text(
                            "Tanggal",
                            style:
                                TextStyle(
                              color:
                                  Colors
                                      .white70,

                              fontSize:
                                  12,
                            ),
                          ),

                          const SizedBox(
                              height: 5),

                          Text(
                            latestStatus
                                    .isEmpty
                                ? "-"
                                : formatRecordDate(
                                    latestStatus[
                                        "date"],
                                  ),

                            style:
                                const TextStyle(
                              color:
                                  Colors
                                      .white,

                              fontSize:
                                  14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // Grafik Pertumbuhan
            const Text(
              "Riwayat Pertumbuhan",

              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            if (errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red[200]!,
                  ),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],

            Container(
              padding:
                  const EdgeInsets.all(
                      20),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius
                        .circular(
                            15),
              ),

              child: healthHistory
                      .isEmpty
                  ? Center(
                      child: Text(
                        "Belum ada data riwayat",
                        style: TextStyle(
                          color:
                              Colors
                                  .grey[
                                  400],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Container(
                          height: 200,

                          decoration:
                              BoxDecoration(
                            color: Colors
                                .grey[
                                100],

                            borderRadius:
                                BorderRadius
                                    .circular(
                                        10),
                          ),

                          child: GrowthChart(
                            records:
                                healthHistory,
                          ),
                        ),

                        const SizedBox(
                            height: 20),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: const [
                            _ChartLegend(
                              color:
                                  AppColors
                                      .primary,
                              label:
                                  "Berat",
                            ),
                            SizedBox(
                              width: 18,
                            ),
                            _ChartLegend(
                              color:
                                  Colors
                                      .blue,
                              label:
                                  "Tinggi",
                            ),
                          ],
                        ),

                        const SizedBox(
                            height: 20),

                        // Data list
                        const Text(
                          "Data Riwayat",
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,

                            fontSize:
                                14,
                          ),
                        ),

                        const SizedBox(
                            height: 10),

                        ListView.builder(
                          shrinkWrap:
                              true,

                          physics:
                              const NeverScrollableScrollPhysics(),

                          itemCount:
                              healthHistory
                                  .length,

                          itemBuilder:
                              (context,
                                  index) {

                            final record =
                                healthHistory[
                                    index];

                            return Card(
                              margin:
                                  const EdgeInsets
                                      .symmetric(
                                    vertical:
                                        5,
                                  ),

                              child:
                                  ListTile(
                                title: Text(
                                  "${record["weight"]} kg / ${record["height"]} cm",
                                ),

                                subtitle:
                                    Text(
                                  formatRecordDate(
                                    record["date"],
                                  ),
                                ),

                                trailing:
                                    Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                        horizontal:
                                            10,

                                        vertical:
                                            5,
                                      ),

                                  decoration:
                                      BoxDecoration(
                                    color: record["status"] ==
                                            "Normal"
                                        ? Colors
                                            .green
                                        : record["status"] ==
                                                "Malnutrisi"
                                            ? Colors
                                                .orange
                                            : Colors
                                                .red,

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                5),
                                  ),

                                  child:
                                      Text(
                                    record[
                                            "status"] ??
                                        "Normal",

                                    style:
                                        const TextStyle(
                                      color:
                                          Colors
                                              .white,

                                      fontSize:
                                          12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),

            const SizedBox(
              height: 25,
            ),

            // Peringatan / Catatan Penting
            Builder(builder: (context) {
              final status = latestStatus.isEmpty ? null : latestStatus['status'];
              final diagnosisText = latestStatus.isEmpty ? '' : (latestStatus['diagnosis'] ?? '');

              if (status == 'Stunting') {
                return Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          diagnosisText.isNotEmpty
                              ? diagnosisText
                              : 'Anak mengalami stunting (pendek). Segera konsultasi dengan tenaga kesehatan.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.amber[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Segera konsultasi dengan tenaga kesehatan jika ada perubahan status gizi yang signifikan",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          ],
        ),
      ),
    );
  }
}

class GrowthChart extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const GrowthChart({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Text(
          "Belum ada data grafik",
          style: TextStyle(
            color: Colors.grey[400],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        14,
        12,
        10,
      ),
      child: CustomPaint(
        painter: GrowthChartPainter(
          records: records,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class GrowthChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> records;

  GrowthChartPainter({
    required this.records,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final orderedRecords = records.reversed.toList();

    final weights = orderedRecords
        .map((record) => _toDouble(record["weight"]))
        .where((value) => value > 0)
        .toList();

    final heights = orderedRecords
        .map((record) => _toDouble(record["height"]))
        .where((value) => value > 0)
        .toList();

    if (weights.isEmpty && heights.isEmpty) {
      return;
    }

    const leftPadding = 34.0;
    const rightPadding = 12.0;
    const topPadding = 12.0;
    const bottomPadding = 28.0;

    final chartWidth =
        size.width - leftPadding - rightPadding;
    final chartHeight =
        size.height - topPadding - bottomPadding;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.22)
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = Colors.grey.withOpacity(0.45)
      ..strokeWidth = 1.2;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= 4; i++) {
      final y = topPadding +
          (chartHeight / 4) * i;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(size.width - rightPadding,
          topPadding + chartHeight),
      axisPaint,
    );

    _drawLine(
      canvas: canvas,
      size: size,
      values: weights,
      color: AppColors.primary,
      leftPadding: leftPadding,
      topPadding: topPadding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      textPainter: textPainter,
      suffix: "kg",
      labelOffset: -18,
    );

    _drawLine(
      canvas: canvas,
      size: size,
      values: heights,
      color: Colors.blue,
      leftPadding: leftPadding,
      topPadding: topPadding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      textPainter: textPainter,
      suffix: "cm",
      labelOffset: 2,
    );

    final pointCount = math.max(
      weights.length,
      heights.length,
    );

    if (pointCount <= 1) {
      _drawBottomLabel(
        canvas,
        textPainter,
        "1",
        Offset(
          leftPadding,
          topPadding + chartHeight + 8,
        ),
      );
    } else {
      _drawBottomLabel(
        canvas,
        textPainter,
        "Awal",
        Offset(
          leftPadding - 8,
          topPadding + chartHeight + 8,
        ),
      );

      _drawBottomLabel(
        canvas,
        textPainter,
        "Terbaru",
        Offset(
          size.width - rightPadding - 40,
          topPadding + chartHeight + 8,
        ),
      );
    }
  }

  void _drawLine({
    required Canvas canvas,
    required Size size,
    required List<double> values,
    required Color color,
    required double leftPadding,
    required double topPadding,
    required double chartWidth,
    required double chartHeight,
    required TextPainter textPainter,
    required String suffix,
    required double labelOffset,
  }) {
    if (values.isEmpty) {
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range =
        maxValue == minValue ? 1 : maxValue - minValue;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? leftPadding + (chartWidth / 2)
          : leftPadding +
              (chartWidth / (values.length - 1)) * i;

      final y = topPadding +
          chartHeight -
          ((values[i] - minValue) / range * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(
        Offset(x, y),
        3.6,
        pointPaint,
      );
    }

    canvas.drawPath(path, linePaint);

    final lastValue = values.last;
    final lastX = values.length == 1
        ? leftPadding + (chartWidth / 2)
        : leftPadding + chartWidth;
    final lastY = topPadding +
        chartHeight -
        ((lastValue - minValue) / range * chartHeight);

    textPainter.text = TextSpan(
      text: "${lastValue.toStringAsFixed(1)} $suffix",
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        math.min(
          lastX - textPainter.width,
          size.width - textPainter.width - 4,
        ),
        (lastY + labelOffset)
            .clamp(0, size.height - textPainter.height),
      ),
    );
  }

  void _drawBottomLabel(
    Canvas canvas,
    TextPainter textPainter,
    String label,
    Offset offset,
  ) {
    textPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      offset,
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  @override
  bool shouldRepaint(
    covariant GrowthChartPainter oldDelegate,
  ) {
    return oldDelegate.records != records;
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
