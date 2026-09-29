import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/features/events/data/models/event_model.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

class EventTicketModel extends EventTicket {
  const EventTicketModel({
    required super.id,
    required super.qrImageUrl,
    super.attendanceStatus,
    super.isPaid,
  });

  /// The ticket state on a My Events row (`attendance_status`, `is_paid`),
  /// or the reply of `GET /member/events/{event_id}/qr`, which adds the
  /// `qr_token`.
  factory EventTicketModel.fromJson(
    Map<String, dynamic> json, {
    String fallbackId = '',
  }) {
    return EventTicketModel(
      id: firstString(json, const <String>['event_id']) ?? fallbackId,
      qrImageUrl: firstString(json, const <String>['qr_token']) ?? '',
      attendanceStatus:
          firstString(json, const <String>['attendance_status']) ?? '',
      isPaid: json['is_paid'] == true,
    );
  }
}

/// A row of `GET /member/events` (the member's RSVPs).
class EventBookingModel extends EventBooking {
  const EventBookingModel({
    required super.id,
    required super.event,
    required super.status,
    required super.guestCount,
    super.guestNames,
    super.ticket,
  });

  factory EventBookingModel.fromJson(Map<String, dynamic> source) {
    final Event event = EventModel.fromMemberEventJson(source);
    return EventBookingModel(
      // There is no RSVP id: a booking is identified by its event.
      id: event.id,
      event: event,
      status: _status(source['rsvp_status']),
      guestCount: firstInt(source, const <String>['guest_count']) ?? 0,
      guestNames: _guestNames(source['guest_names']),
      ticket: EventTicketModel.fromJson(source, fallbackId: event.id),
    );
  }

  static List<String> _guestNames(Object? value) {
    if (value is! List) return const <String>[];
    return List<String>.unmodifiable(
      value
          .map((Object? name) => name?.toString().trim() ?? '')
          .where((String name) => name.isNotEmpty),
    );
  }

  static EventBookingStatus _status(Object? value) {
    return switch (value?.toString().trim().toUpperCase()) {
      'CONFIRMED' => EventBookingStatus.confirmed,
      'CANCELED' => EventBookingStatus.canceled,
      _ => throw const FormatException(
        'The server returned an invalid RSVP status.',
      ),
    };
  }
}
