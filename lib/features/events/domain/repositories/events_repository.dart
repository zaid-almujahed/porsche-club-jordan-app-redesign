import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

class EventRegistrationRequest {
  const EventRegistrationRequest({
    required this.eventId,
    required this.guestCount,
    this.guestNames = const <String>[],
  });

  final String eventId;
  final int guestCount;

  /// One name per guest, in order.
  final List<String> guestNames;
}

abstract interface class EventsRepository {
  Future<List<Event>> getEvents({
    String? category,
    String? search,
    bool forceRefresh = false,
  });

  Future<Event> getEvent(
    String eventId, {
    bool forceRefresh = false,
    Event? fallbackEvent,
  });

  Future<List<Event>> getRecentEvents({bool forceRefresh = false});

  Future<EventBooking> registerForEvent(EventRegistrationRequest request);

  Future<void> cancelRegistration(String eventId);

  /// `POST /member/events/{rsvpId}/payment`. Not called yet: registration
  /// currently treats every event as free; this is for paid events.
  Future<Object?> startEventPayment(String rsvpId);
}
