class AppValidator {
  AppValidator._();

  static String? requiredField(
    String? value, {
    String fieldName = "Field",
  }) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName harus diisi";
    }

    return null;
  }

  static String? name(String? value) {
    final requiredError = requiredField(
      value,
      fieldName: "Nama",
    );

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < 2) {
      return "Nama minimal 2 karakter";
    }

    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredField(
      value,
      fieldName: "Email",
    );

    if (requiredError != null) {
      return requiredError;
    }

    final emailRegex = RegExp(
      r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$',
    );

    if (!emailRegex.hasMatch(value!.trim())) {
      return "Format email tidak valid";
    }

    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredField(
      value,
      fieldName: "Password",
    );

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.length < 6) {
      return "Password minimal 6 karakter";
    }

    return null;
  }

  static String? confirmPassword(
    String? value,
    String passwordValue,
  ) {
    final passwordError = password(value);

    if (passwordError != null) {
      return passwordError;
    }

    if (value != passwordValue) {
      return "Password tidak sama";
    }

    return null;
  }

  static String? ageYears(String? value) {
    final requiredError = requiredField(
      value,
      fieldName: "Usia",
    );

    if (requiredError != null) {
      return requiredError;
    }

    final age = int.tryParse(value!.trim());

    if (age == null) {
      return "Usia harus berupa angka";
    }

    if (age < 0 || age > 18) {
      return "Usia anak harus 0 sampai 18 tahun";
    }

    return null;
  }

  static String? weightKg(String? value) {
    return _decimalRange(
      value,
      fieldName: "Berat badan",
      unit: "kg",
      min: 1,
      max: 120,
    );
  }

  static String? heightCm(String? value) {
    return _decimalRange(
      value,
      fieldName: "Tinggi badan",
      unit: "cm",
      min: 30,
      max: 220,
    );
  }

  static String? foodName(String? value) {
    final requiredError = requiredField(
      value,
      fieldName: "Nama makanan",
    );

    if (requiredError != null) {
      return requiredError;
    }

    if (value!.trim().length < 2) {
      return "Nama makanan minimal 2 karakter";
    }

    return null;
  }

  static String? calories(String? value) {
    final requiredError = requiredField(
      value,
      fieldName: "Kalori",
    );

    if (requiredError != null) {
      return requiredError;
    }

    final calories = int.tryParse(value!.trim());

    if (calories == null) {
      return "Kalori harus berupa angka";
    }

    if (calories < 0 || calories > 5000) {
      return "Kalori harus 0 sampai 5000 kcal";
    }

    return null;
  }

  static String? macroGram(
    String? value, {
    required String fieldName,
  }) {
    return _decimalRange(
      value,
      fieldName: fieldName,
      unit: "g",
      min: 0,
      max: 1000,
    );
  }

  static String? protein(String? value) {
    return macroGram(
      value,
      fieldName: "Protein",
    );
  }

  static String? carbs(String? value) {
    return macroGram(
      value,
      fieldName: "Karbohidrat",
    );
  }

  static String? fat(String? value) {
    return macroGram(
      value,
      fieldName: "Lemak",
    );
  }

  static bool hasErrors(List<String?> validations) {
    return validations.any((error) => error != null);
  }

  static String? firstError(List<String?> validations) {
    for (final validation in validations) {
      if (validation != null) {
        return validation;
      }
    }

    return null;
  }

  static String? _decimalRange(
    String? value, {
    required String fieldName,
    required String unit,
    required double min,
    required double max,
  }) {
    final requiredError = requiredField(
      value,
      fieldName: fieldName,
    );

    if (requiredError != null) {
      return requiredError;
    }

    final normalizedValue = value!.trim().replaceAll(',', '.');
    final number = double.tryParse(normalizedValue);

    if (number == null) {
      return "$fieldName harus berupa angka";
    }

    if (number < min || number > max) {
      return "$fieldName harus $min sampai $max $unit";
    }

    return null;
  }
}
