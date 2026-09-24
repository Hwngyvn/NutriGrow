import 'package:flutter/material.dart';

class NutritionResultScreen extends StatelessWidget {
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionResultScreen({
    super.key,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Hasil Gizi"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foodName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Card(
                        child: ListTile(
                          title: const Text("Kalori"),
                          trailing: Text("$calories kcal"),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text("Protein"),
                          trailing: Text("$protein g"),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text("Karbohidrat"),
                          trailing: Text("$carbs g"),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          title: const Text("Lemak"),
                          trailing: Text("$fat g"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text("Kembali ke Dashboard"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
