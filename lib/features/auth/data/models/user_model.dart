import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/shared/data/member_status_parser.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';

export 'package:pcj_v5/shared/domain/entities/user.dart';

/// A member from `/auth/me` or `/member/profile` (both send `id`, `name`,
/// `email`, `phone`, `photo_url`, `city` and `Date_of_Birth`), with the
/// status from `/member/membership` and the `cars` of `/member/cars`.
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
    List<Object?> cars = const <Object?>[],
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
      vehicles: _vehicles(cars),
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

  /// A car of `GET /member/cars`: `id`, `VIN_Number`, `model`, `year`,
  /// `License_Plate` and `photo_url` (the licence plate photo).
  static List<Vehicle> _vehicles(List<Object?> cars) {
    return cars
        .whereType<Map>()
        .map<Vehicle>((Map value) {
          final Map<String, dynamic> car = Map<String, dynamic>.from(value);
          return Vehicle(
            id: firstString(car, const <String>['id']) ?? '',
            model: firstString(car, const <String>['model']) ?? '',
            year: firstInt(car, const <String>['year']) ?? 0,
            vin: firstString(car, const <String>['VIN_Number']) ?? '',
            licensePlate:
                firstString(car, const <String>['License_Plate']) ?? '',
            imageUrl: firstString(car, const <String>['photo_url']),
          );
        })
        .toList(growable: false);
  }
}
