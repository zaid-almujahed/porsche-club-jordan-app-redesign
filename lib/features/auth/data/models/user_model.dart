import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/shared/data/member_status_parser.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';

export 'package:pcj_v5/shared/domain/entities/user.dart';

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
    super.applicationReviewedAt,
    super.vehicles,
  });

  factory UserModel.fromJson(Map<String, dynamic> source) {
    final Map<String, dynamic> json = _unwrapUser(source);
    final Object? membershipValue = json['membership'] ?? source['membership'];
    final Map<String, dynamic> membership = membershipValue is Map
        ? Map<String, dynamic>.from(membershipValue)
        : const <String, dynamic>{};

    return UserModel(
      id:
          firstString(json, const <String>['id', 'user_id', 'member_id']) ??
          firstString(json, const <String>['email']) ??
          '',
      name: firstString(json, const <String>['name', 'full_name']) ?? '',
      email: firstString(json, const <String>['email']) ?? '',
      phoneNumber:
          firstString(json, const <String>['phone', 'phone_number']) ?? '',
      memberId:
          firstString(json, const <String>['member_id', 'membership_id']) ??
          firstString(membership, const <String>['member_id', 'id']),
      avatarUrl: firstString(json, const <String>[
        'photo',
        'profile_photo',
        'avatar_url',
        'photo_url',
        'userphoto',
      ]),
      city: firstString(json, const <String>['city']),
      dateOfBirth: firstDateTime(json, const <String>[
        'Date_of_Birth',
        'date_of_birth',
        'birth_date',
      ]),
      applicationStatus: MemberStatusParser.application(
        membership['status'] ??
            json['application_status'] ??
            json['approval_status'] ??
            json['approved'] ??
            json['status'] ??
            json['is_approved'],
      ),
      membershipStatus: MemberStatusParser.membership(
        membership['status'] ??
            json['membership_status'] ??
            json['is_active_member'],
      ),
      membershipValidUntil:
          firstDateTime(json, const <String>[
            'membership_valid_until',
            'valid_until',
            'expires_at',
          ]) ??
          firstDateTime(membership, const <String>[
            'end_date',
            'valid_until',
            'expires_at',
          ]),
      applicationReviewedAt: firstDateTime(json, const <String>[
        'application_reviewed_at',
        'reviewed_at',
      ]),
      vehicles: _vehicles(json, source: source),
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
        'valid_until',
        'expires_at',
      ]),
    );
  }

  static Map<String, dynamic> _unwrapUser(Map<String, dynamic> source) {
    final Object? nested = source['user'] ?? source['profile'];
    return nested is Map ? Map<String, dynamic>.from(nested) : source;
  }

  static List<Vehicle> _vehicles(
    Map<String, dynamic> json, {
    Map<String, dynamic>? source,
  }) {
    final Object? raw =
        json['vehicles'] ??
        json['cars'] ??
        json['car'] ??
        source?['vehicles'] ??
        source?['cars'] ??
        source?['car'] ??
        (json['car_model'] != null ? json : null);
    final List<Object?> values = raw is List
        ? raw.cast<Object?>()
        : raw is Map
        ? <Object?>[raw]
        : const <Object?>[];

    return values
        .whereType<Map>()
        .map<Vehicle>((Map value) {
          final Map<String, dynamic> car = Map<String, dynamic>.from(value);
          final String vin =
              firstString(car, const <String>['vin', 'car_vin']) ?? '';
          return Vehicle(
            id: firstString(car, const <String>['id', 'car_id']) ?? vin,
            model: firstString(car, const <String>['model', 'car_model']) ?? '',
            year: firstInt(car, const <String>['year', 'car_year']) ?? 0,
            exteriorColor:
                firstString(car, const <String>['exterior_color', 'color']) ??
                '',
            vin: vin,
            licensePlate:
                firstString(car, const <String>[
                  'license_plate',
                  'plate_number',
                ]) ??
                '',
            imageUrl: firstString(car, const <String>[
              'photo',
              'license_plate_photo',
              'licens_plate_photo',
              'image_url',
            ]),
          );
        })
        .toList(growable: false);
  }
}
