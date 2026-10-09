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
    final (String? alias, Map<String, dynamic>? payment) = await (
      readCliqAlias(_apiClient),
      _latestPayment(),
    ).wait;
    // Never point a member at an alias that is not there.
    if (alias == null) return null;
    final String status = '${payment?['payment_status'] ?? ''}'
        .trim()
        .toUpperCase();
    final String reason =
        firstString(payment ?? const <String, dynamic>{}, const <String>[
          'rejection_reason',
        ])?.trim() ??
        '';
    return CliqPayment(
      alias: alias,
      receiptStatus: switch (status) {
        'WAITING_ADMIN_REVIEW' ||
        'WAITING_ADMIN_APPROVAL' => CliqReceiptStatus.pending,
        'FAILED' || 'REJECTED' => CliqReceiptStatus.rejected,
        // PENDING has no transfer yet; COMPLETED made the membership
        // active.
        _ => CliqReceiptStatus.none,
      },
      submittedAt: payment == null
          ? null
          : firstDateTime(payment, const <String>['created_at', 'paid_at']),
      rejectionReason: reason.isEmpty ? null : reason,
    );
  }

  /// The member's latest membership payment (the highest `payment_id` of
  /// type MEMBERSHIP) from `GET /member/payments`; null when there is none.
  Future<Map<String, dynamic>?> _latestPayment() async {
    Map<String, dynamic>? latest;
    int latestId = -1;
    for (final Map<String, dynamic> payment in requireJsonMapList(
      requireJsonMap(
        await _apiClient.get('/member/payments'),
        description: 'payments response',
      )['payments'],
      description: 'payments',
    )) {
      final bool isMembership =
          '${payment['payment_type'] ?? ''}'.trim().toUpperCase() ==
              'MEMBERSHIP' ||
          payment['membership_id'] != null;
      final int id =
          int.tryParse(
            firstString(payment, const <String>['payment_id']) ?? '',
          ) ??
          -1;
      if (isMembership && id > latestId) {
        latest = payment;
        latestId = id;
      }
    }
    return latest;
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
