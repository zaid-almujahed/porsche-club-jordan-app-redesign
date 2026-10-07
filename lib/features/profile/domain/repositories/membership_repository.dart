import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';

abstract interface class MembershipRepository {
  Future<Membership> getMembership({bool forceRefresh = false});

  Future<Membership> activateWithCode(String code);

  Future<Membership> startMembershipPayment();

  /// The club's CliQ alias for paying the membership, or null while it is
  /// not known.
  Future<CliqPayment?> getCliqPayment();

  /// `POST /member/membership/cliq`: the screenshot of the member's CliQ
  /// transfer, its number and the member's alias for a refund, for an admin
  /// to check.
  Future<void> submitCliqReceipt(
    CliqReceipt receipt, {
    required String transactionNumber,
    required String refundName,
  });
}
