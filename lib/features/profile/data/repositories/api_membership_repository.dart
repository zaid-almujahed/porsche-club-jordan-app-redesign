import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/features/profile/data/models/membership_model.dart';
import 'package:pcj_v5/features/profile/domain/repositories/membership_repository.dart';
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
      () async {
        final Map<String, dynamic> membership = requireJsonMap(
          await _apiClient.get('/member/membership'),
          description: 'membership response',
        );
        Map<String, dynamic> qr = const <String, dynamic>{};
        try {
          qr = requireJsonMap(
            await _apiClient.get('/member/qr'),
            description: 'member QR response',
          );
        } catch (_) {
          // A pending/approved member may not have a QR token yet.
        }
        return MembershipModel.fromJson(
          membership,
          memberName: firstString(qr, const <String>['name']) ?? '',
          qrToken: firstString(qr, const <String>['qr_token']) ?? '',
        );
      },
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
  Future<Object?> createPaypalOrder(String amount) {
    return _apiClient.postJson(
      '/member/paypal/create-order',
      body: <String, Object?>{'amount': amount},
    );
  }

  @override
  Future<Object?> confirmPaypalPayment(String token) {
    return _apiClient.get(
      '/member/paypal/success',
      query: <String, Object?>{'token': token},
      authenticated: false,
    );
  }
}
