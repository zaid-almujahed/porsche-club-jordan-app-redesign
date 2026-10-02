import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/services/image_picker_service.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';

import '../../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({
    required ProfileRepository repository,
    required ImagePickerService imagePickerService,
  }) : _repository = repository,
       _imagePickerService = imagePickerService;

  final ProfileRepository _repository;
  final ImagePickerService _imagePickerService;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();

  AsyncState<User> _profile = const AsyncState<User>.initial();
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isPerformingAccountAction = false;
  bool _isEditing = false;
  XFile? _pendingAvatar;
  Object? _actionError;
  bool _isSavingVehicle = false;
  Object? _vehicleError;

  AsyncState<User> get profile => _profile;
  User? get user => _profile.data;
  List<Vehicle> get vehicles => user?.vehicles ?? const <Vehicle>[];
  bool get isSaving => _isSaving;
  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isPerformingAccountAction => _isPerformingAccountAction;
  String? get avatarPreviewPath => _pendingAvatar?.path;
  Object? get actionError => _actionError;

  /// Adding, updating or removing a car.
  bool get isSavingVehicle => _isSavingVehicle;
  Object? get vehicleError => _vehicleError;

  Future<void> load({bool force = false}) async {
    if (!force && (_profile.isLoading || _profile.hasData)) return;
    _profile = AsyncState<User>.loading(previousData: user);
    notifyListeners();
    try {
      final User value = await _repository.getProfile(forceRefresh: force);
      _setUser(value, synchronizeDraft: !_isEditing);
    } catch (error, stackTrace) {
      _profile = AsyncState<User>.failure(
        error,
        stackTrace,
        previousData: user,
      );
    }
    notifyListeners();
  }

  void _setUser(User value, {bool synchronizeDraft = true}) {
    _profile = AsyncState<User>.success(value);
    if (!synchronizeDraft) return;
    _synchronizeDraft(value);
  }

  void _synchronizeDraft(User value) {
    nameController.text = value.name;
    emailController.text = value.email;
    phoneController.text = value.phoneNumber;
    cityController.text = value.city ?? '';
    dateOfBirthController.text = _formatDate(value.dateOfBirth);
  }

  Future<bool> saveProfile() async {
    if (_isSaving) return false;
    _isSaving = true;
    _actionError = null;
    notifyListeners();
    try {
      final XFile? pendingAvatar = _pendingAvatar;
      final String? previousAvatarUrl = user?.avatarUrl;
      final User value = await _repository.updateProfile(
        ProfileUpdate(
          name: nameController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          city: cityController.text.trim(),
          dateOfBirth: _parseDate(dateOfBirthController.text),
          avatar: pendingAvatar == null
              ? null
              : AvatarUpload(
                  bytes: await pendingAvatar.readAsBytes(),
                  fileName: pendingAvatar.name,
                ),
        ),
      );
      if (pendingAvatar != null) {
        await _evictRemoteAvatar(previousAvatarUrl);
        await _evictRemoteAvatar(value.avatarUrl);
      }
      _pendingAvatar = null;
      _isEditing = false;
      _setUser(
        pendingAvatar == null
            ? value
            : value.copyWith(avatarUrl: pendingAvatar.path),
      );
      return true;
    } catch (error) {
      _actionError = error;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void setDateOfBirth(DateTime value) {
    dateOfBirthController.text = _formatDate(value);
    notifyListeners();
  }

  Future<void> changeAvatar([PhotoSource source = PhotoSource.library]) async {
    if (_isUploadingAvatar) return;
    _isUploadingAvatar = true;
    _actionError = null;
    notifyListeners();
    try {
      final XFile? image = await _imagePickerService.pick(source);
      if (image == null) return;
      _pendingAvatar = image;
    } catch (error) {
      _actionError = error;
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  void beginEditing() {
    final User? current = user;
    if (current == null) return;
    _isEditing = true;
    _pendingAvatar = null;
    _actionError = null;
    _synchronizeDraft(current);
    notifyListeners();
  }

  void discardProfileEdits() {
    final User? current = user;
    _isEditing = false;
    _pendingAvatar = null;
    _actionError = null;
    if (current != null) _synchronizeDraft(current);
    notifyListeners();
  }

  Future<bool> addVehicle(VehicleDraft vehicle) =>
      _saveVehicle(() => _repository.addVehicle(vehicle));

  Future<bool> updateVehicle(String vehicleId, VehicleDraft vehicle) =>
      _saveVehicle(() => _repository.updateVehicle(vehicleId, vehicle));

  Future<bool> deleteVehicle(String vehicleId) =>
      _saveVehicle(() => _repository.deleteVehicle(vehicleId));

  /// Picks the licence plate photo for a car.
  Future<XFile?> pickVehiclePhoto([PhotoSource source = PhotoSource.library]) =>
      _imagePickerService.pick(source);

  void clearVehicleError() {
    if (_vehicleError == null) return;
    _vehicleError = null;
    notifyListeners();
  }

  Future<bool> _saveVehicle(Future<User> Function() request) async {
    if (_isSavingVehicle) return false;
    _isSavingVehicle = true;
    _vehicleError = null;
    notifyListeners();
    try {
      // The profile draft being edited on screen is left as it is.
      _setUser(await request(), synchronizeDraft: !_isEditing);
      return true;
    } catch (error) {
      _vehicleError = error;
      return false;
    } finally {
      _isSavingVehicle = false;
      notifyListeners();
    }
  }

  Future<bool> updatePhoneNumber(String phoneNumber) async {
    final String value = phoneNumber.trim();
    if (value.isEmpty) {
      _actionError = const AppException('Phone number cannot be empty.');
      notifyListeners();
      return false;
    }
    return _runAccountAction(() async {
      final User updated = await _repository.updatePhoneNumber(value);
      _setUser(updated);
    });
  }

  Future<bool> deleteAccount() {
    return _runAccountAction(_repository.deleteAccount);
  }

  Future<bool> _runAccountAction(Future<void> Function() action) async {
    if (_isPerformingAccountAction) return false;
    _isPerformingAccountAction = true;
    _actionError = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (error) {
      _actionError = error;
      return false;
    } finally {
      _isPerformingAccountAction = false;
      notifyListeners();
    }
  }

  void reset() {
    _profile = const AsyncState<User>.initial();
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    cityController.clear();
    dateOfBirthController.clear();
    _isSaving = false;
    _isUploadingAvatar = false;
    _isPerformingAccountAction = false;
    _isEditing = false;
    _pendingAvatar = null;
    _actionError = null;
    _isSavingVehicle = false;
    _vehicleError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    dateOfBirthController.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '';
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static DateTime? _parseDate(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) return null;
    final DateTime? parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      throw const AppException('Enter the date of birth as YYYY-MM-DD.');
    }
    return parsed;
  }

  static Future<void> _evictRemoteAvatar(String? url) async {
    if (url == null ||
        (!url.startsWith('https://') && !url.startsWith('http://'))) {
      return;
    }
    try {
      await NetworkImage(url).evict();
    } catch (_) {
      // The saved local preview still updates immediately if eviction fails.
    }
  }
}
