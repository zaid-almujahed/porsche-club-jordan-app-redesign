import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/core/state/safe_change_notifier.dart';
import 'package:pcj_v5/features/user_events/domain/repositories/user_events_repository.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

import '../../domain/repositories/events_repository.dart';

class EventDetailsController extends SafeChangeNotifier {
  EventDetailsController({
    required EventsRepository repository,
    required UserEventsRepository userEventsRepository,
    required this.eventId,
    Event? initialEvent,
  }) : _repository = repository,
       _userEventsRepository = userEventsRepository,
       _state = initialEvent == null
           ? const AsyncState<Event>.initial()
           : AsyncState<Event>.success(initialEvent);

  final EventsRepository _repository;
  final UserEventsRepository _userEventsRepository;
  final String eventId;
  AsyncState<Event> _state;
  bool _isRegistered = false;
  EventBooking? _booking;
  bool _isCancellingRsvp = false;
  Object? _rsvpError;

  AsyncState<Event> get state => _state;

  /// Whether the member has RSVP'd to this event.
  bool get isRegistered => _isRegistered;

  /// The member's RSVP for this event, any status.
  EventBooking? get booking => _booking;

  bool get isCancellingRsvp => _isCancellingRsvp;

  /// The event was deleted or withdrawn (404 / 410), also while its page
  /// was open.
  bool get isUnavailable {
    final Object? error = _state.error;
    return _state.hasError &&
        error is AppException &&
        (error.statusCode == 404 || error.statusCode == 410);
  }

  Object? get rsvpError => _rsvpError;

  Future<void> load({bool force = false}) async {
    if (!force && (_state.isLoading || _state.hasData)) return;
    await refresh();
  }

  Future<void> refresh() async {
    final Event? current = _state.data;
    _state = AsyncState<Event>.loading(previousData: current);
    notifyListeners();
    final Future<void> booking = _loadBooking();
    try {
      _state = AsyncState<Event>.success(
        await _repository.getEvent(
          eventId,
          forceRefresh: true,
          fallbackEvent: current,
        ),
      );
    } catch (error, stackTrace) {
      _state = AsyncState<Event>.failure(
        error,
        stackTrace,
        previousData: current,
      );
    }
    await booking;
    notifyListeners();
  }

  /// True once the member's RSVP is cancelled.
  Future<bool> cancelRsvp() async {
    if (_isCancellingRsvp) return false;
    _isCancellingRsvp = true;
    _rsvpError = null;
    notifyListeners();
    try {
      await _repository.cancelRegistration(eventId);
      _isRegistered = false;
      await _loadBooking();
      return true;
    } catch (error) {
      _rsvpError = error;
      return false;
    } finally {
      _isCancellingRsvp = false;
      notifyListeners();
    }
  }

  /// When My Events cannot be read, the last known RSVP is kept.
  Future<void> _loadBooking() async {
    try {
      _booking = await _userEventsRepository.findBooking(eventId);
      _isRegistered = _booking?.isActive ?? false;
    } catch (_) {
      // Kept as it was.
    }
  }
}
