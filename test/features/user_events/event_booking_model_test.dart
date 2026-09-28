import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/user_events/data/models/event_booking_model.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

// A row of GET /member/events (the member's RSVPs).
Map<String, dynamic> _row({Object? status = 'CONFIRMED'}) => <String, dynamic>{
  'rsvp_id': 5,
  'event_id': 37,
  'title': 'Manja Track Day',
  'location': 'dead sea',
  'start_at': '2026-11-11T14:30:00+03:00',
  'rsvp_status': ?status,
  'guest_count': 2,
};

void main() {
  test('parses a My Events row', () {
    final EventBookingModel booking = EventBookingModel.fromJson(_row());

    expect(booking.id, '5');
    expect(booking.event.id, '37');
    expect(booking.event.title, 'Manja Track Day');
    expect(booking.status, EventBookingStatus.confirmed);
    expect(booking.guestCount, 2);
  });

  test('both spellings of a cancelled RSVP are recognised', () {
    for (final String status in <String>['CANCELLED', 'CANCELED']) {
      expect(
        EventBookingModel.fromJson(_row(status: status)).status,
        EventBookingStatus.canceled,
      );
    }
  });

  test('a row without an RSVP status is not a registration', () {
    expect(
      () => EventBookingModel.fromJson(_row(status: null)),
      throwsFormatException,
    );
  });

  test('the ticket reads qr_token from GET /member/events/{id}/qr', () {
    final EventTicketModel ticket =
        EventTicketModel.fromJson(const <String, dynamic>{
          'event_id': 12,
          'qr_token': 'signed-event-token',
          'attendance_status': 'NOT_CHECKED_IN',
        });

    expect(ticket.id, '12');
    expect(ticket.qrToken, 'signed-event-token');
    expect(ticket.canDisplayQr, isTrue);
  });

  test('recognises only used attendance states as non-displayable', () {
    final EventTicketModel unused = EventTicketModel.fromJson(
      const <String, dynamic>{'attendance_status': 'not_checked_in'},
    );
    final EventTicketModel used = EventTicketModel.fromJson(
      const <String, dynamic>{'attendance_status': 'CHECKED_IN'},
    );

    expect(unused.canDisplayQr, isTrue);
    expect(used.canDisplayQr, isFalse);
  });
}
