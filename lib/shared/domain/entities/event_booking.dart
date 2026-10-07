import 'event.dart';

/// `rsvp_status`. A paid RSVP waits in [pendingPayment] until the member
/// sends its CliQ payment, then in [waitingAdminApproval] until an admin
/// approves it ([confirmed]) or turns it down ([rejected]).
enum EventBookingStatus {
  confirmed,
  canceled,
  pendingPayment,
  waitingAdminApproval,
  rejected,
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
  });

  final String id;
  final Event event;
  final EventBookingStatus status;
  final int guestCount;

  /// The guests' names, in the order they were registered.
  final List<String> guestNames;
  final EventTicket? ticket;

  /// The RSVP's own id, which a payment is made against.
  final String? rsvpId;

  /// Holds a place at the event: confirmed, or waiting on its payment.
  bool get isActive =>
      status == EventBookingStatus.confirmed ||
      status == EventBookingStatus.pendingPayment ||
      status == EventBookingStatus.waitingAdminApproval;

  /// No CliQ payment was sent for it yet; the member has to send one.
  bool get awaitsPayment => status == EventBookingStatus.pendingPayment;

  /// The CliQ payment was sent and an admin is checking it.
  bool get isPaymentUnderReview =>
      status == EventBookingStatus.waitingAdminApproval;

  /// Can be cancelled until the event starts. One waiting for its payment
  /// is paid instead.
  bool get canCancel =>
      status == EventBookingStatus.confirmed ||
      status == EventBookingStatus.waitingAdminApproval;

  /// Cancelling before the event starts refunds what the member paid.
  bool get refundsOnCancel =>
      event.isPaid &&
      (status == EventBookingStatus.confirmed || isPaymentUnderReview) &&
      event.startsAt.isAfter(DateTime.now());
}
