import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/features/profile/data/models/cliq_payment_model.dart';
import 'package:pcj_v5/features/profile/data/models/membership_model.dart';
import 'package:pcj_v5/features/profile/domain/repositories/membership_repository.dart';
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

  // Not in /openapi.json yet; the README describes what the app expects.
  static const String _cliqPath = '/member/membership/cliq';

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
    final Object? response;
    try {
      response = await _apiClient.get(_cliqPath);
    } on AppException catch (error) {
      // The backend does not offer CliQ yet.
      if (error.statusCode == 404) return null;
      rethrow;
    }
    final CliqPayment payment = CliqPaymentModel.fromJson(
      requireJsonMap(response, description: 'CliQ payment response'),
    );
    // Never point a member at an alias that is not there.
    return payment.alias.isEmpty ? null : payment;
  }

  @override
  Future<CliqPayment> submitCliqReceipt(CliqReceipt receipt) async {
    await _apiClient.multipart(
      '$_cliqPath/receipt',
      method: 'POST',
      files: <ApiUpload>[
        ApiUpload(
          field: 'receipt',
          fileName: receipt.fileName,
          bytes: receipt.bytes,
        ),
      ],
    );
    final CliqPayment? payment = await getCliqPayment();
    if (payment == null) {
      throw const AppException('CliQ payments are not available right now.');
    }
    return payment;
  }
}
