import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';

abstract interface class MembershipRepository {
  Future<Membership> getMembership({bool forceRefresh = false});

  Future<Membership> activateWithCode(String code);

  Future<Membership> startMembershipPayment();

  /// The club's CliQ alias for paying the membership, with where the
  /// member's latest membership payment stands; null while the alias is not
  /// known. Throws when the payment cannot be read.
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
