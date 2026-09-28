import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/profile/data/models/membership_model.dart';
import 'package:pcj_v5/shared/data/member_status_parser.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';

void main() {
  const Map<Object?, (ApplicationStatus, MembershipStatus)> expected =
      <Object?, (ApplicationStatus, MembershipStatus)>{
        null: (ApplicationStatus.notSubmitted, MembershipStatus.inactive),
        'PENDING': (ApplicationStatus.pending, MembershipStatus.inactive),
        'REJECTED': (ApplicationStatus.denied, MembershipStatus.inactive),
        'APPROVED': (ApplicationStatus.approved, MembershipStatus.inactive),
        'ACTIVE': (ApplicationStatus.approved, MembershipStatus.active),
        'EXPIRED': (ApplicationStatus.approved, MembershipStatus.expired),
        'SUSPENDED': (ApplicationStatus.approved, MembershipStatus.suspended),
        'DEACTIVATED': (ApplicationStatus.approved, MembershipStatus.suspended),
        'SOMETHING_NEW': (ApplicationStatus.denied, MembershipStatus.inactive),
      };

  test('maps every backend status to both app statuses', () {
    expected.forEach((Object? value, (ApplicationStatus, MembershipStatus) e) {
      expect(MemberStatusParser.application(value), e.$1, reason: '$value');
      expect(MemberStatusParser.membership(value), e.$2, reason: '$value');
    });
  });

  test('the membership page reads the status the same way', () {
    expected.forEach((Object? value, (ApplicationStatus, MembershipStatus) e) {
      final MembershipModel membership = MembershipModel.fromJson(
        <String, dynamic>{'status': value},
        memberName: 'Member',
      );
      expect(membership.status, e.$2, reason: '$value');
    });
  });
}
