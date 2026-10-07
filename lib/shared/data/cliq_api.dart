import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';

/// The club's CliQ alias (`GET /member/CLIQ`), or null while it is not set.
Future<String?> readCliqAlias(PcjApiClient apiClient) async {
  try {
    final Map<String, dynamic> reply = requireJsonMap(
      await apiClient.get('/member/CLIQ'),
      description: 'CliQ response',
    );
    final String? alias = firstString(reply, const <String>['CLIQ'])?.trim();
    return alias == null || alias.isEmpty ? null : alias;
  } catch (_) {
    // The page then asks for the club's usual alias.
    return null;
  }
}

/// Sends a CliQ payment for an admin to approve. Every CliQ endpoint takes
/// the transfer number, the member's own alias for a refund and the receipt,
/// besides its own [fields].
Future<Object?> sendCliqPayment(
  PcjApiClient apiClient,
  String path, {
  Map<String, Object?> fields = const <String, Object?>{},
  required String transactionNumber,
  required String refundName,
  required CliqReceipt receipt,
}) {
  return apiClient.multipart(
    path,
    method: 'POST',
    fields: <String, Object?>{
      ...fields,
      'transaction_number': transactionNumber.trim(),
      'cliq_refund_name': refundName.trim(),
    },
    files: <ApiUpload>[
      ApiUpload(
        field: 'photo',
        fileName: receipt.fileName,
        bytes: receipt.bytes,
      ),
    ],
  );
}
