import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/features/profile/data/models/membership_model.dart';
import 'package:pcj_v5/features/profile/domain/repositories/membership_repository.dart';
import 'package:pcj_v5/shared/data/cliq_api.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';

class ApiMembershipRepository implements MembershipRepository {
  ApiMembershipRepository({
    required PcjApiClient apiClient,
    required MemoryCache cache,
  }) : _apiClient = apiClient,
       _cache = cache;

  final PcjApiClient _apiClient;
  final MemoryCache _cache;

  @override
  Future<Membership> getMembership({bool forceRefresh = false}) async {
    return _cache.getOrLoad<Membership>(
      'member:membership',
      () async => MembershipModel.fromJson(
        requireJsonMap(
          await _apiClient.get('/member/membership'),
          description: 'membership response',
        ),
      ),
      ttl: const Duration(minutes: 2),
      force: forceRefresh,
    );
  }

  @override
  Future<Membership> activateWithCode(String code) async {
    await _apiClient.postForm(
      '/member/pay-membership',
      fields: <String, Object?>{'code': code.trim()},
    );
    _cache.remove('member:membership');
    _cache.remove('member:profile');
    return getMembership(forceRefresh: true);
  }

  @override
  Future<Membership> startMembershipPayment() async {
    await _apiClient.post('/member/membership/payment');
    _cache.remove('member:membership');
    _cache.remove('member:profile');
    return getMembership(forceRefresh: true);
  }

  @override
  Future<CliqPayment?> getCliqPayment() async {
    // Never point a member at an alias that is not there.
    final String? alias = await readCliqAlias(_apiClient);
    return alias == null ? null : CliqPayment(alias: alias);
  }

  @override
  Future<void> submitCliqReceipt(
    CliqReceipt receipt, {
    required String transactionNumber,
    required String refundName,
  }) async {
    await sendCliqPayment(
      _apiClient,
      '/member/membership/cliq',
      transactionNumber: transactionNumber,
      refundName: refundName,
      receipt: receipt,
    );
    _cache.remove('member:membership');
    _cache.remove('member:profile');
  }
}
