import 'event.dart';

enum EventBookingStatus { confirmed, canceled }

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
  });

  final String id;
  final Event event;
  final EventBookingStatus status;
  final int guestCount;

  /// The guests' names, in the order they were registered.
  final List<String> guestNames;
  final EventTicket? ticket;
}
