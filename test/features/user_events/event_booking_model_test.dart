import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/user_events/data/models/event_booking_model.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

// A row of GET /member/events (the member's RSVPs), as the backend sends it.
Map<String, dynamic> _row({
  Object? status = 'CONFIRMED',
  String attendance = 'Not Checked In',
}) => <String, dynamic>{
  'event_id': 38,
  'title': 'test event',
  'description': 'sadas',
  'location': 'Amman',
  'latitude': 31.953421758774535,
  'longitude': 35.91051753311293,
  'start_at': '2026-09-29T11:33:00+03:00',
  'capacity': 10,
  'cover_image': 'https://example.com/events/cover.jpg',
  'rsvp_status': ?status,
  'guest_count': 0,
  'is_paid': true,
  'attendance_status': attendance,
};

void main() {
  test('parses a My Events row', () {
    final EventBookingModel booking = EventBookingModel.fromJson(_row());

    // There is no rsvp_id: the booking is identified by its event.
    expect(booking.id, '38');
    expect(booking.event.id, '38');
    expect(booking.event.title, 'test event');
    expect(booking.event.capacity, 10);
    expect(booking.status, EventBookingStatus.confirmed);
    expect(booking.guestCount, 0);
    expect(booking.guestNames, isEmpty);
  });

  test('reads the guests and their names', () {
    final EventBookingModel booking = EventBookingModel.fromJson(
      <String, dynamic>{
        ..._row(),
        'guest_count': 2,
        'guest_names': <Object?>['Test Guest', ' Another Guest ', ''],
      },
    );

    expect(booking.guestCount, 2);
    expect(booking.guestNames, <String>['Test Guest', 'Another Guest']);
  });

  test('the row decides whether the QR shows', () {
    final EventTicket awaiting = EventBookingModel.fromJson(_row()).ticket!;
    expect(awaiting.isPaid, isTrue);
    expect(awaiting.canDisplayQr, isTrue);

    final EventTicket used = EventBookingModel.fromJson(
      _row(attendance: 'Checked In'),
    ).ticket!;
    expect(used.canDisplayQr, isFalse);
    expect(used.hasBeenUsed, isTrue);
  });

  test('a CANCELED RSVP is recognised', () {
    expect(
      EventBookingModel.fromJson(_row(status: 'CANCELED')).status,
      EventBookingStatus.canceled,
    );
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
