import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/shared/data/member_status_parser.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';

class MembershipModel extends Membership {
  const MembershipModel({
    required super.memberId,
    required super.status,
    required super.startDate,
    required super.validUntil,
    required super.annualFee,
    super.currency,
  });

  /// `GET /member/membership`: `member_id`, `status`, `start_date` and
  /// `end_date`.
  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      memberId: firstString(json, const <String>['member_id']) ?? '',
      status: MemberStatusParser.membership(json['status']),
      startDate: firstDateTime(json, const <String>['start_date']),
      validUntil: firstDateTime(json, const <String>['end_date']),
      // `/member/membership` has no fee yet, so the payment page shows none.
      annualFee: null,
      currency: 'JOD',
    );
  }
}
