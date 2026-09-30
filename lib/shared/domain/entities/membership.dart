import 'user.dart';

class Membership {
  const Membership({
    required this.memberId,
    required this.status,
    required this.startDate,
    required this.validUntil,
    required this.annualFee,
    this.currency = 'JOD',
  });

  final String memberId;
  final MembershipStatus status;
  /// The activation date returned as `start_date` by `/member/membership`.
  final DateTime? startDate;
  /// Null until payment/activation assigns an end date.
  final DateTime? validUntil;
  final double? annualFee;
  final String currency;
}
