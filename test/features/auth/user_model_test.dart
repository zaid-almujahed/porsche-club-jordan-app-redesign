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

// The `cars` of GET /member/cars.
const List<Object?> _cars = <Object?>[
  <String, dynamic>{
    'id': 33,
    'VIN_Number': 'hjhj5j5j5j',
    'model': 'e',
    'year': 1999,
    'License_Plate': 'trtrtrtt',
    'photo_url': 'https://example.com/members/scaled_35.jpg',
  },
  <String, dynamic>{
    'id': 41,
    'VIN_Number': '7878787878',
    'model': '911',
    'year': 2026,
    'License_Plate': '8888888',
    'photo_url': 'https://example.com/members/scaled_36.png',
  },
];

void main() {
  test('reads /auth/me and /member/membership', () {
    final UserModel user = UserModel.fromJson(_me, membership: _membership);

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
    expect(user.vehicles, isEmpty);
  });

  test('reads each car of /member/cars', () {
    final UserModel user = UserModel.fromJson(_me, cars: _cars);

    final Vehicle car = user.vehicles.first;
    expect(car.id, '33');
    expect(car.model, 'e');
    expect(car.year, 1999);
    expect(car.vin, 'hjhj5j5j5j');
    expect(car.licensePlate, 'trtrtrtt');
    expect(car.imageUrl, 'https://example.com/members/scaled_35.jpg');
    expect(user.vehicles.map((Vehicle car) => car.id), <String>['33', '41']);
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
