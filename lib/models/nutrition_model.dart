class NutritionModel {
  final int targetCalories;
  final int consumedCalories;

  final double protein;
  final double carbs;
  final double fat;

  NutritionModel({
    required this.targetCalories,
    required this.consumedCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  double get percentage =>
      consumedCalories / targetCalories;
}