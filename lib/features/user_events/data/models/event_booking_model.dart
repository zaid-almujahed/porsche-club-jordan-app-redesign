import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/features/events/data/models/event_model.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

class EventTicketModel extends EventTicket {
  const EventTicketModel({
    required super.id,
    required super.qrImageUrl,
    required super.holderName,
    super.attendanceStatus,
    super.isPaid,
  });

  factory EventTicketModel.fromJson(
    Map<String, dynamic> json, {
    String fallbackId = '',
  }) {
    return EventTicketModel(
      id:
          firstString(json, const <String>['event_id']) ??
          fallbackId,
      qrImageUrl: _qrToken(json) ?? '',
      holderName: firstString(json, const <String>['event_name']) ?? 'Member',
      attendanceStatus:
          firstString(json, const <String>['attendance_status']) ?? '',
      isPaid: json['is_paid'] == true,
    );
  }

  static String? _qrToken(Object? value) {
    if (value is String) {
      final String token = value.trim();
      return token.isEmpty ? null : token;
    }
    if (value is! Map) return null;

    final Map<String, dynamic> json = Map<String, dynamic>.from(value);
    return _qrToken(json['qr_token']);
  }
}

class EventBookingModel extends EventBooking {
  const EventBookingModel({
    required super.id,
    required super.event,
    required super.status,
    required super.guestCount,
    super.paymentStatus,
    super.amount,
    super.ticket,
  });

  factory EventBookingModel.fromJson(
    Map<String, dynamic> source, {
    Event? fallbackEvent,
    int fallbackGuestCount = 0,
    EventBookingStatus? fallbackStatus,
  }) {
    final String? eventId = firstString(source, const <String>['event_id']);
    final bool containsMemberEvent = eventId != null && source['title'] != null;
    final Event event = containsMemberEvent
        ? EventModel.fromMemberEventJson(source)
        : fallbackEvent ??
              EventModel.fromSummaryJson(<String, dynamic>{
                'id': eventId ?? '',
              });
    final bool hasTicketState =
        source['attendance_status'] != null || source['qr_token'] != null;

    return EventBookingModel(
      id:
          firstString(source, const <String>['rsvp_id']) ??
          event.id,
      event: event,
      status: _status(
        source['rsvp_status'] ?? source['status'],
        fallback: fallbackStatus,
      ),
      guestCount:
          firstInt(source, const <String>['guest_count']) ??
          fallbackGuestCount,
      paymentStatus: firstString(source, const <String>['payment_status']),
      amount: firstDouble(source, const <String>['amount']),
      ticket: hasTicketState
          ? EventTicketModel.fromJson(source, fallbackId: event.id)
          : null,
    );
  }

  static EventBookingStatus _status(
    Object? value, {
    EventBookingStatus? fallback,
  }) {
    final Object? rawValue = value is Map
        ? value['value'] ?? value['name'] ?? value['status']
        : value;
    final String normalized = rawValue?.toString().trim().toUpperCase() ?? '';
    return switch (normalized) {
      '' when fallback != null => fallback,
      'CONFIRMED' => EventBookingStatus.confirmed,
      'CANCELED' || 'CANCELLED' => EventBookingStatus.canceled,
      _ => throw const FormatException(
        'The server returned an invalid RSVP status.',
      ),
    };
  }
}
