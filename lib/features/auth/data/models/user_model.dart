import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/shared/data/member_status_parser.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';

export 'package:pcj_v5/shared/domain/entities/user.dart';

/// A member from `/auth/me` or `/member/profile` (both send `id`, `name`,
/// `email`, `phone`, `photo_url`, `city` and `Date_of_Birth`), with the
/// status from `/member/membership` and the cars listed by `/member/qr`.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phoneNumber,
    required super.applicationStatus,
    required super.membershipStatus,
    super.memberId,
    super.avatarUrl,
    super.city,
    super.dateOfBirth,
    super.membershipValidUntil,
    super.vehicles,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> profile, {
    Map<String, dynamic> membership = const <String, dynamic>{},
    Map<String, dynamic> memberQr = const <String, dynamic>{},
  }) {
    return UserModel(
      id: firstString(profile, const <String>['id']) ?? '',
      name: firstString(profile, const <String>['name']) ?? '',
      email: firstString(profile, const <String>['email']) ?? '',
      phoneNumber: firstString(profile, const <String>['phone']) ?? '',
      memberId: firstString(membership, const <String>['member_id']),
      avatarUrl: firstString(profile, const <String>['photo_url']),
      city: firstString(profile, const <String>['city']),
      dateOfBirth: firstDateTime(profile, const <String>['Date_of_Birth']),
      applicationStatus: MemberStatusParser.application(membership['status']),
      membershipStatus: MemberStatusParser.membership(membership['status']),
      membershipValidUntil: firstDateTime(membership, const <String>[
        'end_date',
      ]),
      vehicles: _vehicles(memberQr['cars']),
    );
  }

  /// [user] with the status and end date from a `/member/membership`
  /// response.
  static User withMembership(User user, Map<String, dynamic> membership) {
    return user.copyWith(
      applicationStatus: MemberStatusParser.application(membership['status']),
      membershipStatus: MemberStatusParser.membership(membership['status']),
      membershipValidUntil: firstDateTime(membership, const <String>[
        'end_date',
      ]),
    );
  }

  /// `/member/qr` lists each car's `model` and `vin` only. Editing or
  /// removing a car also needs its id, read from `car_id` (the name the car
  /// endpoints use) once the backend sends it.
  static List<Vehicle> _vehicles(Object? cars) {
    if (cars is! List) return const <Vehicle>[];
    return cars
        .whereType<Map>()
        .map<Vehicle>((Map value) {
          final Map<String, dynamic> car = Map<String, dynamic>.from(value);
          return Vehicle(
            id: firstString(car, const <String>['car_id']) ?? '',
            model: firstString(car, const <String>['model']) ?? '',
            year: 0,
            vin: firstString(car, const <String>['vin']) ?? '',
            licensePlate: '',
          );
        })
        .toList(growable: false);
  }
}
