import 'package:flutter/foundation.dart';

import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

import '../../domain/repositories/user_events_repository.dart';

class UserEventsController extends ChangeNotifier {
  UserEventsController({required UserEventsRepository repository})
    : _repository = repository;

  final UserEventsRepository _repository;
  AsyncState<List<EventBooking>> _bookings =
      const AsyncState<List<EventBooking>>.initial();
  bool _showUpcoming = true;
  int _requestId = 0;
  final Set<String> _cancellingEventIds = <String>{};
  Object? _actionError;
  final Set<String> _rejectionsShown = <String>{};

  AsyncState<List<EventBooking>> get bookings => _bookings;
  bool get showUpcoming => _showUpcoming;
  Object? get actionError => _actionError;
  bool isCancelling(String eventId) => _cancellingEventIds.contains(eventId);

  /// A rejected payment not pointed out yet, once per event.
  EventBooking? takeRejectionNotice() {
    for (final EventBooking booking
        in _bookings.data ?? const <EventBooking>[]) {
      if (booking.status == EventBookingStatus.rejected &&
          markRejectionShown(booking.event.id)) {
        return booking;
      }
    }
    return null;
  }

  /// True the first time the rejected payment for [eventId] is pointed
  /// out, here or on the event's page.
  bool markRejectionShown(String eventId) => _rejectionsShown.add(eventId);

  Future<void> load({bool force = false}) async {
    if (!force && (_bookings.isLoading || _bookings.hasData)) return;
    await _fetch(force: force);
  }

  Future<void> showTab({required bool upcoming}) async {
    if (_showUpcoming == upcoming) return;
    _showUpcoming = upcoming;
    _actionError = null;
    // Data from the other tab must never remain visible under the newly
    // selected label. The repository still reuses its one-minute response
    // cache, so this does not force an unnecessary network request.
    _bookings = const AsyncState<List<EventBooking>>.initial();
    notifyListeners();
    await _fetch(preserveData: false);
  }

  Future<bool> cancelRegistration(EventBooking booking) async {
    final String eventId = booking.event.id;
    if (_cancellingEventIds.contains(eventId)) return false;
    _cancellingEventIds.add(eventId);
    _actionError = null;
    notifyListeners();
    try {
      await _repository.cancelRegistration(eventId);
      // A cancelled RSVP moves to Past.
      await _fetch(force: true);
      return true;
    } catch (error) {
      _actionError = error;
      return false;
    } finally {
      _cancellingEventIds.remove(eventId);
      notifyListeners();
    }
  }

  Future<void> _fetch({bool force = false, bool preserveData = true}) async {
    final int requestId = ++_requestId;
    final List<EventBooking>? previousData = preserveData
        ? _bookings.data
        : null;
    _bookings = AsyncState<List<EventBooking>>.loading(
      previousData: previousData,
    );
    notifyListeners();
    try {
      final List<EventBooking> bookings = List<EventBooking>.unmodifiable(
        await _repository.getBookings(
          upcoming: _showUpcoming,
          forceRefresh: force,
        ),
      );
      if (requestId != _requestId) return;
      _bookings = AsyncState<List<EventBooking>>.success(bookings);
    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
      _bookings = AsyncState<List<EventBooking>>.failure(
        error,
        stackTrace,
        previousData: previousData,
      );
    }
    if (requestId != _requestId) return;
    notifyListeners();
  }

  void reset() {
    _requestId++;
    _bookings = const AsyncState<List<EventBooking>>.initial();
    _showUpcoming = true;
    _cancellingEventIds.clear();
    _actionError = null;
    _rejectionsShown.clear();
    notifyListeners();
  }
}
