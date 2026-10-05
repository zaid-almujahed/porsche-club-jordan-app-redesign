import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';

abstract interface class MembershipRepository {
  Future<Membership> getMembership({bool forceRefresh = false});

  Future<Membership> activateWithCode(String code);

  Future<Membership> startMembershipPayment();

  /// The club's CliQ details for this membership, or null while the backend
  /// does not offer CliQ.
  Future<CliqPayment?> getCliqPayment();

  /// Sends the screenshot of the member's CliQ transfer for an admin to
  /// check.
  Future<CliqPayment> submitCliqReceipt(CliqReceipt receipt);
}
