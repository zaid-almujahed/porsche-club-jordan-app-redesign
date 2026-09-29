import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/auth/data/models/user_model.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';

// GET /auth/me, as the backend sends it (credentials left out).
const Map<String, dynamic> _me = <String, dynamic>{
  'created_at': '2026-09-26',
  'is_active': true,
  'updated_at': '2026-09-29',
  'id': 33,
  'photo_url': 'https://example.com/members/f56.jpg',
  'phone': '+962791234567',
  'email_verified': true,
  'email': 'member@example.com',
  'is_approved': true,
  'city': 'Amman',
  'role': 'member',
  'Date_of_Birth': '2000-01-17',
  'name': 'Test Member',
};

const Map<String, dynamic> _membership = <String, dynamic>{
  'member_id': 'PCJ-200033',
  'status': 'ACTIVE',
  'start_date': '2026-09-26',
  'end_date': '2027-09-26',
};

// GET /member/qr: each car has its model and VIN only.
const Map<String, dynamic> _memberQr = <String, dynamic>{
  'name': 'Test Member',
  'phone': '+962791234567',
  'email': 'member@example.com',
  'cars': <Map<String, dynamic>>[
    <String, dynamic>{'model': 'e', 'vin': 'hjhj5j5j5j'},
    <String, dynamic>{'model': '911', 'vin': '7878787878'},
  ],
  'qr_token': 'signed-member-token',
};

void main() {
  test('reads /auth/me, /member/membership and /member/qr', () {
    final UserModel user = UserModel.fromJson(
      _me,
      membership: _membership,
      memberQr: _memberQr,
    );

    expect(user.id, '33');
    expect(user.name, 'Test Member');
    expect(user.email, 'member@example.com');
    expect(user.phoneNumber, '+962791234567');
    expect(user.avatarUrl, 'https://example.com/members/f56.jpg');
    expect(user.city, 'Amman');
    expect(user.dateOfBirth, DateTime(2000, 1, 17));
    expect(user.memberId, 'PCJ-200033');
    expect(user.applicationStatus, ApplicationStatus.approved);
    expect(user.membershipStatus, MembershipStatus.active);
    expect(user.membershipValidUntil, DateTime(2027, 9, 26));
    expect(
      user.vehicles.map((Vehicle car) => '${car.model} ${car.vin}'),
      <String>['e hjhj5j5j5j', '911 7878787878'],
    );
  });

  test('a car without car_id has no id, never its VIN', () {
    final UserModel user = UserModel.fromJson(_me, memberQr: _memberQr);

    expect(user.vehicles.map((Vehicle car) => car.id), <String>['', '']);
  });

  test('car_id identifies a car once the backend sends it', () {
    final UserModel user = UserModel.fromJson(
      _me,
      memberQr: <String, dynamic>{
        'cars': <Map<String, dynamic>>[
          <String, dynamic>{'car_id': 4, 'model': '911', 'vin': '7878787878'},
        ],
      },
    );

    expect(user.vehicles.single.id, '4');
  });

  test('the status comes from /member/membership only', () {
    // /auth/me's is_approved does not decide anything.
    final UserModel pending = UserModel.fromJson(
      _me,
      membership: const <String, dynamic>{'status': 'PENDING'},
    );
    expect(pending.applicationStatus, ApplicationStatus.pending);

    final UserModel missing = UserModel.fromJson(_me);
    expect(missing.applicationStatus, ApplicationStatus.notSubmitted);
    expect(missing.membershipStatus, MembershipStatus.inactive);
  });

  test('withMembership updates the status and end date', () {
    final User user = UserModel.withMembership(
      UserModel.fromJson(_me, membership: _membership),
      const <String, dynamic>{
        'member_id': 'PCJ-200033',
        'status': 'EXPIRED',
        'start_date': '2025-09-26',
        'end_date': '2026-09-26',
      },
    );

    expect(user.membershipStatus, MembershipStatus.expired);
    expect(user.membershipValidUntil, DateTime(2026, 9, 26));
  });
}
