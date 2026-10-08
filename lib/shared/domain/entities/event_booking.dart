import 'event.dart';

/// `rsvp_status`. A paid RSVP waits in [pendingPayment] until the member
/// sends its CliQ payment, then in [waitingAdminApproval] until an admin
/// approves it ([confirmed]) or turns it down ([rejected]). A cancelled paid
/// one waits in [pendingRefund] while its refund is made, and is [refunded]
/// once it was.
enum EventBookingStatus {
  confirmed,
  canceled,
  pendingPayment,
  waitingAdminApproval,
  rejected,
  pendingRefund,
  refunded,
}

class EventTicket {
  const EventTicket({
    required this.id,
    required this.qrImageUrl,
    this.attendanceStatus = '',
    this.isPaid = true,
  });

  final String id;
  final String qrImageUrl;
  final String attendanceStatus;
  final bool isPaid;

  /// The API returns a signed token (`qr_token`); qr_flutter converts that
  /// payload to pixels.
  /// The legacy field name is retained to avoid breaking existing widgets.
  String get qrToken => qrImageUrl;

  /// `attendance_status` values.
  static const String notCheckedIn = 'Not Checked In';
  static const String partiallyCheckedIn = 'PARTIALLY_CHECKED_IN';
  static const String checkedIn = 'CHECKED_IN';

  String get _attendance => attendanceStatus.trim();

  /// The ticket has never been opened, so no QR has been issued yet.
  bool get isAwaitingCheckIn => _attendance == notCheckedIn;

  /// The QR was issued (the first time the ticket was opened) and has not
  /// been scanned at the event yet.
  bool get isPartiallyCheckedIn => _attendance == partiallyCheckedIn;

  /// Scanned at the event: the QR is no longer shown.
  bool get hasBeenUsed => _attendance == checkedIn;

  bool get canDisplayQr => isAwaitingCheckIn || isPartiallyCheckedIn;
}

class EventBooking {
  const EventBooking({
    required this.id,
    required this.event,
    required this.status,
    required this.guestCount,
    this.guestNames = const <String>[],
    this.ticket,
    this.rsvpId,
    this.paymentStatus,
    this.paymentAmount,
  });

  final String id;
  final Event event;

  /// `rsvp_status`.
  final EventBookingStatus status;
  final int guestCount;

  /// The guests' names, in the order they were registered.
  final List<String> guestNames;
  final EventTicket? ticket;

  /// The RSVP's own id, which a payment is made against.
  final String? rsvpId;

  /// `payment_status` of the RSVP's latest CliQ payment, in capitals:
  /// PENDING, WAITING_ADMIN_APPROVAL, COMPLETED, REJECTED or CANCELLED. Null
  /// for a free event or before the first payment.
  final String? paymentStatus;

  /// What that payment came to.
  final double? paymentAmount;

  /// This booking with its latest CliQ payment.
  EventBooking withPaymentStatus(String? paymentStatus, {double? amount}) {
    return EventBooking(
      id: id,
      event: event,
      status: status,
      guestCount: guestCount,
      guestNames: guestNames,
      ticket: ticket,
      rsvpId: rsvpId,
      paymentStatus: paymentStatus,
      paymentAmount: amount,
    );
  }

  /// What the member pays: the event's price for them and each guest, or
  /// what its payment came to when the row has no price.
  double get amountDue => event.registrationFee > 0
      ? event.registrationFee * (1 + guestCount)
      : paymentAmount ?? 0;

  /// Its payment was rejected, cancelled or is being refunded, which removes
  /// the RSVP. A FAILED one did not go through and can be sent again.
  bool get isRemovedByPayment => switch (paymentStatus) {
    'REJECTED' ||
    'CANCELLED' ||
    'CANCELED' ||
    'PENDING_REFUND' ||
    'REFUND_PENDING' ||
    'REFUNDED' ||
    'REJECT_REFUNDED' => true,
    _ => false,
  };

  /// An admin turned its payment down: the member is told, with Contact
  /// Support.
  bool get isPaymentRejected =>
      status == EventBookingStatus.rejected || paymentStatus == 'REJECTED';

  /// Its last payment did not go through; another can be sent.
  bool get hasFailedPayment => paymentStatus == 'FAILED';

  /// No longer a registration: cancelled, rejected, or removed by its
  /// payment. Listed under Past; the member can register again.
  bool get isRemoved =>
      status == EventBookingStatus.canceled ||
      status == EventBookingStatus.rejected ||
      status == EventBookingStatus.pendingRefund ||
      status == EventBookingStatus.refunded ||
      isRemovedByPayment;

  /// Holds a place at the event: confirmed, or waiting on its payment.
  bool get isActive =>
      !isRemovedByPayment &&
      (status == EventBookingStatus.confirmed ||
          status == EventBookingStatus.pendingPayment ||
          status == EventBookingStatus.waitingAdminApproval);

  /// A CliQ payment can be sent for it: none was sent yet, or the latest is
  /// still PENDING or FAILED. Not while an admin checks one (WAITING_ADMIN_APPROVAL)
  /// or once it is COMPLETED.
  bool get canSendPayment {
    if (!event.isPaid || !isActive) return false;
    if (status == EventBookingStatus.confirmed) return false;
    return switch (paymentStatus) {
      null => status == EventBookingStatus.pendingPayment,
      'PENDING' || 'FAILED' => true,
      _ => false,
    };
  }

  /// The CliQ payment was sent and an admin is checking it.
  bool get isPaymentUnderReview =>
      isActive &&
      (paymentStatus == 'WAITING_ADMIN_APPROVAL' ||
          (paymentStatus == null &&
              status == EventBookingStatus.waitingAdminApproval));

  /// Cancelling before the event starts refunds what the member paid.
  bool get refundsOnCancel =>
      event.isPaid &&
      isActive &&
      (status == EventBookingStatus.confirmed ||
          isPaymentUnderReview ||
          paymentStatus == 'COMPLETED') &&
      event.startsAt.isAfter(DateTime.now());
}
