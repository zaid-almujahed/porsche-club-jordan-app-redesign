import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';

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
      status: _status(json['status']),
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

  static MembershipStatus _status(Object? value) {
    final String status = value?.toString().toLowerCase().trim() ?? '';
    // SUSPENDED and DEACTIVATED are handled identically.
    if (status == 'suspended' || status == 'deactivated') {
      return MembershipStatus.suspended;
    }
    if (status.contains('inactive') || status == 'false') {
      return MembershipStatus.inactive;
    }
    if (status == 'active' || status == 'true') {
      return MembershipStatus.active;
    }
    if (status.contains('expired')) return MembershipStatus.expired;
    return MembershipStatus.inactive;
  }
}
