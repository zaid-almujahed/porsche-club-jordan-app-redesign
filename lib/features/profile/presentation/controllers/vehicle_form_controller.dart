import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pcj_v5/core/services/image_picker_service.dart';
import 'package:pcj_v5/core/validation/vehicle_rules.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';

import '../../domain/repositories/profile_repository.dart';

/// The add / edit car form. Owned by the form sheet; saving goes through
/// `ProfileController`.
class VehicleFormController extends ChangeNotifier {
  VehicleFormController({
    required Future<XFile?> Function(PhotoSource source) pickPhoto,
    this.vehicle,
  }) : _pickPhoto = pickPhoto {
    final Vehicle? current = vehicle;
    if (current == null) return;
    modelController.text = current.model;
    yearController.text = current.year > 0 ? '${current.year}' : '';
    vinController.text = current.vin;
    plateController.text = current.licensePlate;
  }

  static const int maximumPhotoSize = 5 * 1024 * 1024;

  final Future<XFile?> Function(PhotoSource source) _pickPhoto;

  /// The car being edited; null when adding one.
  final Vehicle? vehicle;

  final TextEditingController modelController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController vinController = TextEditingController();
  final TextEditingController plateController = TextEditingController();

  XFile? _photo;
  bool _isPickingPhoto = false;
  String? _error;

  bool get isEditing => vehicle != null;
  XFile? get photo => _photo;
  bool get isPickingPhoto => _isPickingPhoto;
  String? get error => _error;

  /// A new photo is required when adding; editing keeps the current one.
  bool get needsPhoto => !isEditing && _photo == null;

  Future<void> pickPhoto([PhotoSource source = PhotoSource.library]) async {
    if (_isPickingPhoto) return;
    _isPickingPhoto = true;
    _error = null;
    notifyListeners();
    try {
      final XFile? image = await _pickPhoto(source);
      if (image == null) return;
      if (await image.length() > maximumPhotoSize) {
        _error = 'The photo must be smaller than 5MB.';
        return;
      }
      _photo = image;
    } catch (_) {
      _error = 'The photo could not be selected. Please try again.';
    } finally {
      _isPickingPhoto = false;
      notifyListeners();
    }
  }

  void onChanged(String _) {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// The request to send, or null (with [error] set) when something is
  /// missing or invalid.
  Future<VehicleDraft?> buildDraft() async {
    final String? problem =
        VehicleRules.validationMessage(
          model: modelController.text,
          year: yearController.text,
          vin: vinController.text,
        ) ??
        (needsPhoto ? 'Add a photo of the licence plate.' : null);
    if (problem != null) {
      _error = problem;
      notifyListeners();
      return null;
    }
    final XFile? photo = _photo;
    return VehicleDraft(
      vin: vinController.text.trim(),
      model: modelController.text.trim(),
      year: int.parse(yearController.text.trim()),
      licensePlate: plateController.text.trim(),
      licensePlatePhoto: photo == null
          ? null
          : VehiclePhoto(
              bytes: await photo.readAsBytes(),
              fileName: photo.name,
            ),
    );
  }

  @override
  void dispose() {
    modelController.dispose();
    yearController.dispose();
    vinController.dispose();
    plateController.dispose();
    super.dispose();
  }
}
