import 'dart:typed_data';

/// Where the member's CliQ receipt stands.
enum CliqReceiptStatus { none, pending }

/// Paying the membership with CliQ: the club's alias and the state of the
/// receipt the member sent.
class CliqPayment {
  const CliqPayment({
    required this.alias,
    this.receiptStatus = CliqReceiptStatus.none,
    this.submittedAt,
  });

  final String alias;
  final CliqReceiptStatus receiptStatus;
  final DateTime? submittedAt;
}

/// A screenshot of the member's CliQ transfer.
class CliqReceipt {
  const CliqReceipt({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}
