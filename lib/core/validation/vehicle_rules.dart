/// Vehicle rules shared by registration and the garage (add / edit a car).
abstract final class VehicleRules {
  static const int oldestYear = 1948;

  /// Next year's models are already on sale.
  static int get newestYear => DateTime.now().year + 1;

  static bool isValidModel(String value) => value.trim().isNotEmpty;

  static bool isValidYear(int? value) =>
      value != null && value >= oldestYear && value <= newestYear;

  /// 17 characters, or 10 for older cars.
  static bool isValidVin(String value) {
    final int length = value.trim().length;
    return length == 10 || length == 17;
  }

  /// The first problem with the entered details, or null when they are valid.
  static String? validationMessage({
    required String model,
    required String year,
    required String vin,
  }) {
    if (!isValidModel(model)) return 'Enter the car model.';
    if (!isValidYear(int.tryParse(year.trim()))) {
      return 'Enter a year between $oldestYear and $newestYear.';
    }
    if (!isValidVin(vin)) return 'The VIN must be 10 or 17 characters.';
    return null;
  }
}
