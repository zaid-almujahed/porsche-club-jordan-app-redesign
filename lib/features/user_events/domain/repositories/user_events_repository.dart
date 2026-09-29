import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

abstract interface class UserEventsRepository {
  Future<List<EventBooking>> getBookings({
    required bool upcoming,
    bool forceRefresh = false,
  });

  /// [forceRefresh] re-reads `GET /member/events`, e.g. to see a check-in.
  Future<EventBooking> getBooking(
    String bookingId, {
    bool forceRefresh = false,
  });

  Future<EventTicket> getTicket(String eventId);

  Future<void> cancelRegistration(String eventId);

  /// The events the member has a CONFIRMED RSVP for, upcoming or past.
  Future<Set<String>> getRegisteredEventIds();
}
