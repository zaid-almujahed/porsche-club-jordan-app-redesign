import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/features/auth/data/models/user_model.dart';
import 'package:pcj_v5/features/profile/domain/repositories/profile_repository.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository({
    required PcjApiClient apiClient,
    required MemoryCache cache,
  }) : _apiClient = apiClient,
       _cache = cache;

  final PcjApiClient _apiClient;
  final MemoryCache _cache;

  static const String _profileCacheKey = 'member:profile';

  @override
  Future<User> getProfile({bool forceRefresh = false}) async {
    return _cache.getOrLoad<User>(
      _profileCacheKey,
      () async {
        final Map<String, dynamic> profile = requireJsonMap(
          await _apiClient.get('/member/profile'),
          description: 'profile response',
        );
        Map<String, dynamic> membership = const <String, dynamic>{};
        Map<String, dynamic> qr = const <String, dynamic>{};
        try {
          membership = requireJsonMap(
            await _apiClient.get('/member/membership'),
            description: 'membership response',
          );
        } catch (_) {
          // Profile details remain useful while membership data is unavailable.
        }
        try {
          qr = requireJsonMap(
            await _apiClient.get('/member/qr'),
            description: 'member QR response',
          );
        } catch (_) {
          // Pending members may not have a member QR yet.
        }
        return UserModel.fromJson(<String, dynamic>{
          ...profile,
          if (membership.isNotEmpty) 'membership': membership,
          if (qr['cars'] != null) 'cars': qr['cars'],
          if (profile['name'] == null && qr['name'] != null) 'name': qr['name'],
          if (profile['email'] == null && qr['email'] != null)
            'email': qr['email'],
          if (profile['phone'] == null && qr['phone'] != null)
            'phone': qr['phone'],
        });
      },
      ttl: const Duration(minutes: 2),
      force: forceRefresh,
    );
  }

  @override
  Future<User> updateProfile(ProfileUpdate update) async {
    await _apiClient.multipart(
      '/member/profile',
      method: 'PUT',
      fields: <String, Object?>{
        'name': update.name.trim(),
        'phone': update.phoneNumber.trim(),
        'city': update.city?.trim(),
        'date_of_birth': update.dateOfBirth == null
            ? null
            : _date(update.dateOfBirth!),
      },
      files: update.avatar == null
          ? const <ApiUpload>[]
          : <ApiUpload>[
              ApiUpload(
                field: 'profile_photo',
                fileName: update.avatar!.fileName,
                bytes: update.avatar!.bytes,
              ),
            ],
    );
    _cache.remove(_profileCacheKey);
    // The mutation response is not guaranteed to include membership or car
    // data, so rebuild the complete member view from the read endpoints.
    return getProfile(forceRefresh: true);
  }

  @override
  Future<User> updatePhoneNumber(String phoneNumber) async {
    final String value = phoneNumber.trim();
    if (value.isEmpty) {
      throw const AppException('Phone number cannot be empty.');
    }
    await _apiClient.multipart(
      '/member/profile',
      method: 'PUT',
      fields: <String, Object?>{'phone': value},
    );
    _cache.remove(_profileCacheKey);
    return getProfile(forceRefresh: true);
  }

  @override
  Future<void> updateEmail(String email) async {
    if (email.trim().isEmpty) {
      throw const AppException('Email address cannot be empty.');
    }
    // Do not invent an endpoint. Replace this exception with the documented
    // request and invalidate [_profileCacheKey] when the backend publishes it.
    throw const UnsupportedApiOperationException(
      'The PCJ API does not currently provide an email update endpoint.',
    );
  }

  @override
  Future<User> uploadAvatar(AvatarUpload upload) async {
    await _apiClient.multipart(
      '/member/profile',
      method: 'PUT',
      files: <ApiUpload>[
        ApiUpload(
          field: 'profile_photo',
          fileName: upload.fileName,
          bytes: upload.bytes,
        ),
      ],
    );
    _cache.remove(_profileCacheKey);
    // The mutation response is not guaranteed to include membership or car
    // data, so rebuild the complete member view from the read endpoints.
    return getProfile(forceRefresh: true);
  }

  @override
  Future<void> deleteAccount() async {
    await _apiClient.delete('/member/account');
    _cache.clear();
  }

  @override
  Future<List<Vehicle>> getVehicles({bool forceRefresh = false}) async {
    return (await getProfile(forceRefresh: forceRefresh)).vehicles;
  }

  @override
  Future<User> addVehicle(VehicleDraft vehicle) async {
    final VehiclePhoto? photo = vehicle.licensePlatePhoto;
    if (photo == null) {
      throw const AppException('Add a photo of the licence plate.');
    }
    await _apiClient.multipart(
      '/member/cars',
      method: 'POST',
      fields: _vehicleFields(vehicle),
      files: <ApiUpload>[_platePhoto(photo)],
    );
    return _refreshedProfile();
  }

  @override
  Future<User> updateVehicle(String vehicleId, VehicleDraft vehicle) async {
    final VehiclePhoto? photo = vehicle.licensePlatePhoto;
    await _apiClient.multipart(
      '/member/cars/${_carId(vehicleId)}',
      method: 'PUT',
      fields: _vehicleFields(vehicle),
      // Without a new photo the backend keeps the current one.
      files: photo == null
          ? const <ApiUpload>[]
          : <ApiUpload>[_platePhoto(photo)],
    );
    return _refreshedProfile();
  }

  @override
  Future<User> deleteVehicle(String vehicleId) async {
    await _apiClient.delete('/member/cars/${_carId(vehicleId)}');
    return _refreshedProfile();
  }

  /// Cars are listed by `/member/qr`, which the profile read includes.
  Future<User> _refreshedProfile() {
    _cache.remove(_profileCacheKey);
    return getProfile(forceRefresh: true);
  }

  static Map<String, Object?> _vehicleFields(VehicleDraft vehicle) {
    final String plate = vehicle.licensePlate?.trim() ?? '';
    return <String, Object?>{
      'VIN_Number': vehicle.vin.trim(),
      'model': vehicle.model.trim(),
      'year': vehicle.year,
      // Optional; left out when empty.
      'License_Plate': plate.isEmpty ? null : plate,
    };
  }

  static ApiUpload _platePhoto(VehiclePhoto photo) => ApiUpload(
    field: 'license_plate_photo',
    fileName: photo.fileName,
    bytes: photo.bytes,
  );

  /// The backend identifies cars by a number.
  static String _carId(String vehicleId) {
    final int? id = int.tryParse(vehicleId.trim());
    if (id == null) {
      throw const AppException('This vehicle cannot be changed from the app.');
    }
    return '$id';
  }

  static String _date(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
