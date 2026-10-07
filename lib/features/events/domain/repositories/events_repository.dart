import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';

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
  Future<List<Event>> getEvents({bool forceRefresh = false});

  Future<Event> getEvent(
    String eventId, {
    bool forceRefresh = false,
    Event? fallbackEvent,
  });

  Future<List<Event>> getRecentEvents({bool forceRefresh = false});

  /// Returns the RSVP's id (`rsvp_id`), which a paid event's payment is
  /// sent for; empty when the reply has none.
  Future<String> registerForEvent(EventRegistrationRequest request);

  /// `POST /member/events/{rsvpId}/cliq`: the transfer number, the
  /// member's alias for a refund and a screenshot of the receipt, for an
  /// admin to approve.
  Future<void> payWithCliq({
    required String rsvpId,
    required String transactionNumber,
    required String refundName,
    required CliqReceipt receipt,
  });

  /// The club's CliQ alias (`GET /member/CLIQ`), or null while it is not known.
  Future<String?> getCliqAlias();

  Future<void> cancelRegistration(String eventId);

  /// `POST /member/events/{rsvpId}/payment`. Not called yet: registration
  /// currently treats every event as free; this is for paid events.
  Future<Object?> startEventPayment(String rsvpId);
}
