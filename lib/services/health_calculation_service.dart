class HealthCalculationService {
  // Menghitung kebutuhan kalori berdasarkan AKG Indonesia
  // Berdasarkan usia, jenis kelamin, berat badan, tinggi badan, dan aktivitas fisik
  static double calculateDailyCalories(
    int ageYears,
    String gender,
    double weightKg,
    double heightCm,
    String activityLevel,
  ) {
    double bmr = calculateBMR(ageYears, gender, weightKg);
    double activityFactor = _getActivityFactor(activityLevel);
    return bmr * activityFactor;
  }

  // Harris-Benedict Formula untuk menghitung Basal Metabolic Rate (BMR)
  static double calculateBMR(
    int ageYears,
    String gender,
    double weightKg,
  ) {
    if (gender.toLowerCase() == 'laki-laki') {
      // Anak laki-laki: 88.362 + (13.397 × berat) + (4.799 × tinggi) - (5.677 × usia)
      return 88.362 + (13.397 * weightKg) - (6.673 * ageYears);
    } else {
      // Anak perempuan: 447.593 + (9.247 × berat) + (3.098 × tinggi) - (4.330 × usia)
      return 447.593 + (9.247 * weightKg) - (4.330 * ageYears);
    }
  }

  // Faktor aktivitas berdasarkan tingkat aktivitas fisik
  static double _getActivityFactor(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sangat ringan':
        return 1.2; // Istirahat, tidur, aktivitas minimal
      case 'ringan':
        return 1.375; // Aktivitas ringan, duduk di meja
      case 'sedang':
        return 1.55; // Aktivitas sedang, bermain
      case 'berat':
        return 1.725; // Aktivitas fisik intensif
      case 'sangat berat':
        return 1.9; // Aktivitas fisik sangat intensif
      default:
        return 1.375; // Default ringan
    }
  }

  // Menghitung kebutuhan protein harian (gram) untuk anak
  // Rekomendasi: 1.2-1.5g per kg berat badan untuk anak
  static double calculateProteinNeeds(double weightKg) {
    return weightKg * 1.2;
  }

  // Menghitung kebutuhan karbohidrat (gram)
  // Rekomendasi: 50-60% dari total kalori (1g karbohidrat = 4 kalori)
  static double calculateCarbNeeds(double totalCalories) {
    return (totalCalories * 0.55) / 4;
  }

  // Menghitung kebutuhan lemak (gram)
  // Rekomendasi: 25-35% dari total kalori (1g lemak = 9 kalori)
  static double calculateFatNeeds(double totalCalories) {
    return (totalCalories * 0.30) / 9;
  }

  // Diagnosis status gizi berdasarkan IMT dan perbandingan BB/TB
  // Kategori: 0=Normal, 1=Malnutrisi, 2=Stunting
  static Map<String, dynamic> diagnoseNutritionalStatus(
    int ageMonths,
    double weightKg,
    double heightCm,
    String gender,
  ) {
    // Hitung IMT (Indeks Massa Tubuh)
    double heightM = heightCm / 100;
    double imt = weightKg / (heightM * heightM);

    // Standar WHO untuk anak (IMT by age)
    String status = 'Normal';
    String diagnosis = '';

    // Kategori berdasarkan IMT dan kurva pertumbuhan WHO
    if (imt < 14.5 || weightKg < _getMinWeightByAge(ageMonths)) {
      status = 'Malnutrisi';
      diagnosis = 'Anak mengalami gizi kurang. Perlu peningkatan asupan nutrisi.';
    } else if (heightCm < _getMinHeightByAge(ageMonths)) {
      status = 'Stunting';
      diagnosis = 'Anak mengalami stunting (pendek). Segera konsultasi dengan tenaga kesehatan.';
    } else if (imt >= 14.5 && imt < 18.5 && heightCm >= _getMinHeightByAge(ageMonths)) {
      status = 'Normal';
      diagnosis = 'Status gizi normal. Pertahankan pola makan seimbang.';
    } else if (imt >= 18.5) {
      status = 'Overweight';
      diagnosis = 'Anak memiliki berat badan berlebih. Perlu pengaturan diet dan aktivitas fisik.';
    }

    return {
      'status': status,
      'diagnosis': diagnosis,
      'imt': imt,
    };
  }

  // Tinggi badan minimum berdasarkan usia (WHO)
  static double _getMinHeightByAge(int ageMonths) {
    if (ageMonths < 12) {
      return 60 + (ageMonths * 0.5);
    } else if (ageMonths < 24) {
      return 72 + ((ageMonths - 12) * 0.4);
    } else if (ageMonths < 36) {
      return 80 + ((ageMonths - 24) * 0.35);
    } else if (ageMonths < 60) {
      return 88 + ((ageMonths - 36) * 0.3);
    } else {
      return 100 + ((ageMonths - 60) * 0.25);
    }
  }

  // Berat badan minimum berdasarkan usia (WHO)
  static double _getMinWeightByAge(int ageMonths) {
    if (ageMonths < 12) {
      return 4.0 + (ageMonths * 0.3);
    } else if (ageMonths < 24) {
      return 8.0 + ((ageMonths - 12) * 0.2);
    } else if (ageMonths < 36) {
      return 10.5 + ((ageMonths - 24) * 0.18);
    } else if (ageMonths < 60) {
      return 12.5 + ((ageMonths - 36) * 0.15);
    } else {
      return 16 + ((ageMonths - 60) * 0.12);
    }
  }

  // Persentase pemenuhan gizi
  static Map<String, double> getNutritionPercentage(
    double consumed,
    double target,
  ) {
    double percentage = (consumed / target) * 100;

    return {
      'percentage': percentage,
      'status': percentage >= 100 ? 1.0 : (percentage >= 75 ? 0.75 : 0.5),
    };
  }

  // Warna indikator untuk status gizi
  static String getStatusColor(String status) {
    switch (status) {
      case 'Normal':
        return '#4CAF50'; // Hijau
      case 'Malnutrisi':
        return '#FF9800'; // Orange
      case 'Stunting':
        return '#F44336'; // Merah
      case 'Overweight':
        return '#FF5722'; // Merah gelap
      default:
        return '#2196F3'; // Biru
    }
  }
}
