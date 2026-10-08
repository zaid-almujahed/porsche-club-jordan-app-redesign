import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/features/user_events/domain/repositories/user_events_repository.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

import '../models/event_booking_model.dart';

/// An RSVP's latest CliQ payment: its `payment_status` and `amount`.
typedef _Payment = ({String status, double? amount});

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
    final DateTime now = DateTime.now();
    final List<EventBooking> bookings =
        (await _rsvps(forceRefresh: forceRefresh))
            .where((EventBooking booking) => _isPast(booking, now) != upcoming)
            .toList();
    // Upcoming events are listed nearest first. The server lists past ones
    // oldest first, so they are reversed: the most recent first.
    if (upcoming) {
      bookings.sort(
        (EventBooking first, EventBooking second) =>
            first.event.startsAt.compareTo(second.event.startsAt),
      );
    }
    _lastBookings = List<EventBooking>.unmodifiable(
      upcoming ? bookings : bookings.reversed,
    );
    return _lastBookings;
  }

  @override
  Future<Set<String>> getRegisteredEventIds() async {
    return (await _rsvps(forceRefresh: false))
        .where((EventBooking booking) => booking.isActive)
        .map((EventBooking booking) => booking.event.id)
        .toSet();
  }

  @override
  Future<EventBooking?> findBooking(String eventId) async {
    final List<EventBooking> rows = (await _rsvps(forceRefresh: false))
        .where(
          (EventBooking booking) =>
              booking.event.id == eventId &&
              booking.status != EventBookingStatus.canceled,
        )
        .toList();
    if (rows.isEmpty) return null;
    // A new RSVP after a rejected one is the one that counts.
    for (final EventBooking booking in rows) {
      if (booking.isActive) return booking;
    }
    return rows.last;
  }

  /// Under Past: events that have ended, and RSVPs that were cancelled,
  /// rejected or removed by their payment, whatever the event's date. After
  /// one of those the member can register again.
  static bool _isPast(EventBooking booking, DateTime now) =>
      booking.isRemoved || booking.event.hasEndedAt(now);

  /// The member's RSVPs from `GET /member/events`, whatever their status.
  Future<List<EventBooking>> _rsvps({required bool forceRefresh}) async {
    final Object? response = await _cache.getOrLoad<Object?>(
      'user-events:all',
      () => _apiClient.get('/member/events'),
      ttl: const Duration(minutes: 1),
      force: forceRefresh,
    );
    final List<EventBooking> bookings = <EventBooking>[];
    for (final Map<String, dynamic> item in requireJsonMapList(
      response,
      description: 'registered-events response',
    )) {
      try {
        final EventBooking booking = EventBookingModel.fromJson(item);
        if (booking.event.id.trim().isNotEmpty) bookings.add(booking);
      } on FormatException {
        // Rows without a known rsvp_status are not RSVPs.
      }
    }
    if (!bookings.any(_hasPayments)) return bookings;
    Map<String, _Payment> payments = const <String, _Payment>{};
    try {
      payments = await _paymentStatuses(forceRefresh: forceRefresh);
    } catch (_) {
      // Shown by rsvp_status alone until the payments can be read.
    }
    return <EventBooking>[
      for (final EventBooking booking in bookings)
        _hasPayments(booking)
            ? booking.withPaymentStatus(
                payments[booking.rsvpId]?.status,
                amount: payments[booking.rsvpId]?.amount,
              )
            : booking,
    ];
  }

  /// A paid event's RSVP (its row's is_paid) shows its latest CliQ payment
  /// next to rsvp_status. Free events keep rsvp_status alone.
  static bool _hasPayments(EventBooking booking) =>
      booking.event.isPaid && booking.rsvpId != null;

  /// The latest CliQ payment state of each RSVP, by its id (`related_id` of
  /// an RSVP payment), from `GET /member/payments`.
  Future<Map<String, _Payment>> _paymentStatuses({
    required bool forceRefresh,
  }) async {
    final Object? response = await _cache.getOrLoad<Object?>(
      'user-events:payments',
      () => _apiClient.get('/member/payments'),
      ttl: const Duration(minutes: 1),
      force: forceRefresh,
    );
    final Map<String, (int, _Payment)> latest = <String, (int, _Payment)>{};
    for (final Map<String, dynamic> payment in requireJsonMapList(
      requireJsonMap(response, description: 'payments response')['payments'],
      description: 'payments',
    )) {
      final String? rsvpId = firstString(payment, const <String>['related_id']);
      if (_upper(payment['payment_type']) != 'RSVP' || rsvpId == null) {
        continue;
      }
      final int order = firstInt(payment, const <String>['payment_id']) ?? 0;
      final (int, _Payment)? previous = latest[rsvpId];
      if (previous == null || order > previous.$1) {
        latest[rsvpId] = (
          order,
          (
            status: _upper(payment['payment_status']),
            amount: firstDouble(payment, const <String>['amount']),
          ),
        );
      }
    }
    return <String, _Payment>{
      for (final MapEntry<String, (int, _Payment)> entry in latest.entries)
        entry.key: entry.value.$2,
    };
  }

  static String _upper(Object? value) =>
      value?.toString().trim().toUpperCase() ?? '';

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

  /// `GET /member/events/{event_id}/qr`: the QR (`qr_token`) with the
  /// attendance and payment state.
  @override
  Future<EventTicket> getTicket(String eventId) async {
    return EventTicketModel.fromJson(
      requireJsonMap(
        await _apiClient.get(
          '/member/events/${Uri.encodeComponent(eventId)}/qr',
        ),
        description: 'event ticket response',
      ),
      fallbackId: eventId,
    );
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
