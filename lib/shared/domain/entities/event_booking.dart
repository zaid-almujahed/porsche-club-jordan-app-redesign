import 'event.dart';

/// `rsvp_status`. A paid RSVP waits in [pendingPayment] until an admin
/// approves its payment ([confirmed]) or turns it down ([rejected]).
enum EventBookingStatus { confirmed, canceled, pendingPayment, rejected }

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
    this.paymentStatus = '',
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

  /// `payment_status` of a paid RSVP, e.g. REFUNDED once a cancelled one
  /// is being refunded.
  final String paymentStatus;

  /// Holds a place at the event: confirmed, or waiting on its payment.
  bool get isActive =>
      status == EventBookingStatus.confirmed ||
      status == EventBookingStatus.pendingPayment;

  /// An admin is checking the CliQ payment. The app only sends an RSVP
  /// together with its payment, so every PENDING_PAYMENT RSVP has one.
  bool get isPaymentUnderReview => status == EventBookingStatus.pendingPayment;

  /// A cancelled paid RSVP whose payment is being refunded.
  bool get isRefunded =>
      status == EventBookingStatus.canceled &&
      paymentStatus.trim().toUpperCase() == 'REFUNDED';

  /// Cancelling before the event starts refunds what the member paid.
  bool get refundsOnCancel =>
      event.isPaid &&
      (status == EventBookingStatus.confirmed || isPaymentUnderReview) &&
      event.startsAt.isAfter(DateTime.now());
}
