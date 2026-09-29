import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/features/user_events/domain/repositories/user_events_repository.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

import '../models/event_booking_model.dart';

class ApiUserEventsRepository implements UserEventsRepository {
  ApiUserEventsRepository({
    required PcjApiClient apiClient,
    required MemoryCache cache,
  }) : _apiClient = apiClient,
       _cache = cache;

  final PcjApiClient _apiClient;
  final MemoryCache _cache;
  List<EventBooking> _lastBookings = const <EventBooking>[];

  @override
  Future<List<EventBooking>> getBookings({
    required bool upcoming,
    bool forceRefresh = false,
  }) async {
    final Object? response = await _cache.getOrLoad<Object?>(
        'user-events:all',
        () => _apiClient.get('/member/events'),
        ttl: const Duration(minutes: 1),
        force: forceRefresh,
      );
    final List<Map<String, dynamic>> rows = requireJsonMapList(
      response,
      description: 'registered-events response',
    );
    final DateTime now = DateTime.now();
    final List<EventBooking> parsedBookings = <EventBooking>[];
    for (final Map<String, dynamic> item in rows) {
      try {
        final EventBooking booking = EventBookingModel.fromJson(item);
        if (booking.event.id.trim().isNotEmpty) parsedBookings.add(booking);
      } on FormatException {
        // My Events is RSVP-only. Records without a CONFIRMED / CANCELED
        // rsvp_status are not registrations and must not be shown as though
        // the member registered for them.
      }
    }
    // Do not group or select a "latest" row by event id. The endpoint can
    // return RSVP history rows for the same event; each row keeps its own
    // status, and only that row's CONFIRMED status controls its visibility.
    final List<EventBooking> bookings = parsedBookings
        .where(
          (EventBooking booking) =>
              booking.status == EventBookingStatus.confirmed,
        )
        .where((EventBooking booking) {
          final bool isUpcoming = !booking.event.hasEndedAt(now);
          return upcoming ? isUpcoming : !isUpcoming;
        })
        .toList();
    bookings.sort(
      (EventBooking first, EventBooking second) => upcoming
          ? first.event.startsAt.compareTo(second.event.startsAt)
          : second.event.startsAt.compareTo(first.event.startsAt),
    );
    _lastBookings = List<EventBooking>.unmodifiable(bookings);
    return _lastBookings;
  }

  @override
  Future<EventBooking> getBooking(
    String bookingId, {
    bool forceRefresh = false,
  }) async {
    EventBooking? match = forceRefresh
        ? null
        : _find(_lastBookings, bookingId);
    match ??= _find(
      await getBookings(upcoming: true, forceRefresh: forceRefresh),
      bookingId,
    );
    match ??= _find(await getBookings(upcoming: false), bookingId);
    if (match == null) {
      throw const AppException('The event registration could not be found.');
    }
    return match;
  }

  @override
  Future<EventTicket> getTicket(String eventId) async {
    final Object? response = await _apiClient.get(
      '/member/events/${Uri.encodeComponent(eventId)}/qr',
    );
    final Object? value = unwrapApiData(response);
    if (value is String) {
      final String token = value.trim();
      if (token.isEmpty) {
        throw const AppException(
          'The server did not return a QR ticket. Please try again.',
        );
      }
      return EventTicket(id: eventId, qrImageUrl: token, holderName: 'Member');
    }
    final Map<String, dynamic> json = requireJsonMap(
      response,
      description: 'event ticket response',
    );
    final String? status = firstString(json, const <String>[
      'rsvp_status',
      'status',
    ]);
    if (status != null && status.trim().toUpperCase() != 'CONFIRMED') {
      throw const AppException(
        'A QR ticket is available only for a confirmed event registration.',
      );
    }
    final EventTicket ticket = EventTicketModel.fromJson(
      json,
      fallbackId: eventId,
    );
    if (!ticket.isPaid || !ticket.canDisplayQr) return ticket;
    if (ticket.qrToken.trim().isEmpty) {
      throw const AppException(
        'The server did not return a QR ticket. Please try again.',
      );
    }
    return ticket;
  }

  @override
  Future<void> cancelRegistration(String eventId) async {
    await _apiClient.delete(
      '/member/events/${Uri.encodeComponent(eventId)}/rsvp',
    );
    _cache.removeWhere((String key) => key.startsWith('user-events:'));
    _lastBookings = const <EventBooking>[];
  }

  static EventBooking? _find(List<EventBooking> bookings, String id) {
    for (final EventBooking booking in bookings) {
      if (booking.id == id || booking.event.id == id) return booking;
    }
    return null;
  }
}
