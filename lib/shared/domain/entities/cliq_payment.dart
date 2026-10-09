import 'dart:typed_data';

/// Where the member's CliQ receipt stands, from its payment's
/// `payment_status`: [pending] while it waits for an admin
/// (WAITING_ADMIN_REVIEW), [rejected] once an admin turned it down (FAILED).
enum CliqReceiptStatus { none, pending, rejected }

/// Paying the membership with CliQ: the club's alias and the state of the
/// receipt the member sent.
class CliqPayment {
  const CliqPayment({
    required this.alias,
    this.receiptStatus = CliqReceiptStatus.none,
    this.submittedAt,
    this.rejectionReason,
  });

  final String alias;
  final CliqReceiptStatus receiptStatus;
  final DateTime? submittedAt;

  /// Why an admin turned the receipt down, when they said.
  final String? rejectionReason;
}

/// A screenshot of the member's CliQ transfer.
class CliqReceipt {
  const CliqReceipt({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}
