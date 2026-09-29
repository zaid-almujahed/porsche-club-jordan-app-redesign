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

  String get _normalizedAttendanceStatus => attendanceStatus
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  bool get isAwaitingCheckIn =>
      _normalizedAttendanceStatus == 'not checked in';

  bool get hasBeenUsed => _normalizedAttendanceStatus == 'checked in';

  /// Attendance is independent from RSVP confirmation. A confirmed RSVP can
  /// display its QR until the backend reports that it has been checked in.
  bool get canDisplayQr => isAwaitingCheckIn;
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
