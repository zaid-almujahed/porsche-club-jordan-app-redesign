import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/shared/data/member_status_parser.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';

class MembershipModel extends Membership {
  const MembershipModel({
    required super.memberId,
    required super.memberName,
    required super.status,
    required super.startDate,
    required super.validUntil,
    required super.qrImageUrl,
    required super.annualFee,
    super.currency,
  });

  factory MembershipModel.fromJson(
    Map<String, dynamic> json, {
    required String memberName,
    String qrToken = '',
  }) {
    return MembershipModel(
      memberId: firstString(json, const <String>['member_id']) ?? '',
      memberName: memberName.trim(),
      status: MemberStatusParser.membership(json['status']),
      startDate: firstDateTime(json, const <String>['start_date']),
      validUntil: firstDateTime(json, const <String>['end_date']),
      qrImageUrl: qrToken.trim(),
      // Shown on the payment page when the backend provides it.
      annualFee: firstDouble(json, const <String>[
        'annual_fee',
        'membership_fee',
        'fee',
        'price',
      ]),
      currency: 'JOD',
    );
  }
}
