import 'package:pcj_v5/core/network/json_readers.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.model,
    required super.year,
    required super.exteriorColor,
    required super.vin,
    required super.licensePlate,
    super.imageUrl,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: JsonReaders.string(json, 'id'),
      model: JsonReaders.string(json, 'model'),
      year: JsonReaders.integer(json, 'year'),
      exteriorColor: JsonReaders.string(json, 'exterior_color'),
      vin: JsonReaders.string(json, 'vin'),
      licensePlate: JsonReaders.string(json, 'license_plate'),
      imageUrl: JsonReaders.nullableString(json, 'image_url'),
    );
  }
}
