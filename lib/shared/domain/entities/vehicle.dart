class Vehicle {
  const Vehicle({
    required this.id,
    required this.model,
    required this.year,
    required this.vin,
    required this.licensePlate,
    this.imageUrl,
  });

  final String id;
  final String model;
  final int year;
  final String vin;
  final String licensePlate;
  final String? imageUrl;
}
