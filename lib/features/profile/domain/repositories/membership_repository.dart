import 'package:pcj_v5/shared/domain/entities/membership.dart';

abstract interface class MembershipRepository {
  Future<Membership> getMembership({bool forceRefresh = false});

  Future<Membership> activateWithCode(String code);

  Future<Membership> startMembershipPayment();

  Future<Object?> createPaypalOrder(String amount);

  Future<Object?> confirmPaypalPayment(String token);
}
