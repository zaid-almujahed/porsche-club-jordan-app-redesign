import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';

/// `GET /member/membership/cliq`, also the reply to a receipt upload.
class CliqPaymentModel extends CliqPayment {
  const CliqPaymentModel({
    required super.alias,
    required super.accountName,
    required super.amount,
    required super.currency,
    required super.reference,
    super.receiptStatus,
    super.rejectionReason,
    super.submittedAt,
  });

  factory CliqPaymentModel.fromJson(Map<String, dynamic> json) {
    final String? status = firstString(json, const <String>['receipt_status']);
    return CliqPaymentModel(
      alias: firstString(json, const <String>['alias']) ?? '',
      accountName: firstString(json, const <String>['account_name']) ?? '',
      amount: firstDouble(json, const <String>['amount']) ?? 0,
      currency: firstString(json, const <String>['currency']) ?? 'JOD',
      reference: firstString(json, const <String>['reference']) ?? '',
      receiptStatus: switch (status?.toUpperCase()) {
        'PENDING' => CliqReceiptStatus.pending,
        'REJECTED' => CliqReceiptStatus.rejected,
        _ => CliqReceiptStatus.none,
      },
      rejectionReason: firstString(json, const <String>['rejection_reason']),
      submittedAt: firstServerDateTime(json, const <String>['submitted_at']),
    );
  }
}
