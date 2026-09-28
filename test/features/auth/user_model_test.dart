import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel membership routing states', () {
    test('ACTIVE grants approved application and active membership', () {
      final UserModel user = UserModel.fromJson(<String, dynamic>{
        'email': 'member@example.com',
        'membership': <String, dynamic>{'status': 'ACTIVE'},
      });

      expect(user.applicationStatus, ApplicationStatus.approved);
      expect(user.membershipStatus, MembershipStatus.active);
    });

    test('APPROVED requires payment before membership becomes active', () {
      final UserModel user = UserModel.fromJson(<String, dynamic>{
        'email': 'member@example.com',
        'membership': <String, dynamic>{'status': 'APPROVED'},
      });

      expect(user.applicationStatus, ApplicationStatus.approved);
      expect(user.membershipStatus, MembershipStatus.inactive);
    });

    test('pending and denied states cannot enter member content', () {
      final UserModel pending = UserModel.fromJson(<String, dynamic>{
        'membership': <String, dynamic>{'status': 'PENDING'},
      });
      final UserModel denied = UserModel.fromJson(<String, dynamic>{
        'membership': <String, dynamic>{'status': 'REJECTED'},
      });

      expect(pending.applicationStatus, ApplicationStatus.pending);
      expect(denied.applicationStatus, ApplicationStatus.denied);
    });

    test('EXPIRED is an approved member who must renew', () {
      final UserModel user = UserModel.fromJson(<String, dynamic>{
        'membership': <String, dynamic>{'status': 'EXPIRED'},
      });

      expect(user.applicationStatus, ApplicationStatus.approved);
      expect(user.membershipStatus, MembershipStatus.expired);
    });

    test('SUSPENDED and DEACTIVATED are the same suspended state', () {
      for (final String status in <String>['SUSPENDED', 'DEACTIVATED']) {
        final UserModel user = UserModel.fromJson(<String, dynamic>{
          'membership': <String, dynamic>{'status': status},
        });

        expect(
          user.membershipStatus,
          MembershipStatus.suspended,
          reason: status,
        );
        expect(user.applicationStatus, ApplicationStatus.approved);
      }
    });

    test('unknown non-empty state fails closed', () {
      final UserModel user = UserModel.fromJson(<String, dynamic>{
        'membership': <String, dynamic>{'status': 'ON_HOLD'},
      });

      expect(user.applicationStatus, ApplicationStatus.denied);
      expect(user.membershipStatus, MembershipStatus.inactive);
    });

    test('missing status is treated as a new application', () {
      final UserModel user = UserModel.fromJson(const <String, dynamic>{});

      expect(user.applicationStatus, ApplicationStatus.notSubmitted);
    });
  });
}
