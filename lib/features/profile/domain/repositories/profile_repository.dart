import 'dart:typed_data';

import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';

class ProfileUpdate {
  const ProfileUpdate({
    required this.name,
    required this.phoneNumber,
    this.city,
    this.dateOfBirth,
    this.avatar,
  });

  final String name;
  final String phoneNumber;
  final String? city;
  final DateTime? dateOfBirth;
  final AvatarUpload? avatar;
}

class AvatarUpload {
  const AvatarUpload({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

abstract interface class ProfileRepository {
  Future<User> getProfile({bool forceRefresh = false});

  Future<User> updateProfile(ProfileUpdate update);

  Future<User> updatePhoneNumber(String phoneNumber);

  /// Reserved for the future backend operation that allows an applicant or
  /// member to change the account email. It is currently unsupported.
  Future<void> updateEmail(String email);

  Future<User> uploadAvatar(AvatarUpload upload);

  Future<void> deleteAccount();

  Future<List<Vehicle>> getVehicles({bool forceRefresh = false});
}
