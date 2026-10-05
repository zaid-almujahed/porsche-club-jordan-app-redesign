import 'dart:typed_data';

/// Where the member's CliQ receipt stands.
enum CliqReceiptStatus { none, pending, rejected }

/// How to pay the membership with CliQ (the club's alias, the amount and the
/// note that identifies the member) and the state of the receipt the member
/// sent.
class CliqPayment {
  const CliqPayment({
    required this.alias,
    required this.accountName,
    required this.amount,
    required this.currency,
    required this.reference,
    this.receiptStatus = CliqReceiptStatus.none,
    this.rejectionReason,
    this.submittedAt,
  });

  final String alias;
  final String accountName;
  final double amount;
  final String currency;

  /// Goes in the transfer note, so admins can match the transfer.
  final String reference;
  final CliqReceiptStatus receiptStatus;
  final String? rejectionReason;
  final DateTime? submittedAt;
}

/// A screenshot of the member's CliQ transfer.
class CliqReceipt {
  const CliqReceipt({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}
