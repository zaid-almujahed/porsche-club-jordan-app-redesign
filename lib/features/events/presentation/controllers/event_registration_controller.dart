import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/core/state/safe_change_notifier.dart';
import 'package:pcj_v5/features/events/domain/repositories/events_repository.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';

class EventRegistrationController extends SafeChangeNotifier {
  EventRegistrationController({
    required EventsRepository eventsRepository,
    required this.eventId,
    Event? initialEvent,
  }) : _eventsRepository = eventsRepository,
       _eventState = initialEvent == null
           ? const AsyncState<Event>.initial()
           : AsyncState<Event>.success(initialEvent);

  final EventsRepository _eventsRepository;
  final String eventId;

  AsyncState<Event> _eventState;
  int _guestCount = 0;
  bool _guestNoticeAccepted = false;
  bool _isSubmitting = false;
  Object? _submissionError;

  AsyncState<Event> get eventState => _eventState;
  int get guestCount => _guestCount;
  bool get guestNoticeAccepted => _guestNoticeAccepted;
  bool get isSubmitting => _isSubmitting;
  Object? get submissionError => _submissionError;

  double get basePrice {
    final Event? event = _eventState.data;
    return event == null || !event.isPaid ? 0 : event.registrationFee;
  }

  // PCJ currently permits guests at no additional charge. Keep this separate
  // from the event's own registration fee so a paid event can still show its
  // member price without adding a guest charge.
  double get guestPrice => 0;

  double get guestsTotal => guestPrice * _guestCount;
  double get total => basePrice + guestsTotal;

  Future<void> load({bool force = false}) async {
    await _loadEvent(force: force);
  }

  Future<void> _loadEvent({required bool force}) async {
    if (!force && (_eventState.isLoading || _eventState.hasData)) return;
    _eventState = AsyncState<Event>.loading(previousData: _eventState.data);
    notifyListeners();
    try {
      final Event event = await _eventsRepository.getEvent(
        eventId,
        forceRefresh: force,
        fallbackEvent: _eventState.data,
      );
      _eventState = AsyncState<Event>.success(event);
      if (event.guestLimit <= 0) {
        _guestCount = 0;
        _guestNoticeAccepted = false;
      } else if (_guestCount > event.guestLimit) {
        _guestCount = event.guestLimit;
        _guestNoticeAccepted = false;
      }
    } catch (error, stackTrace) {
      _eventState = AsyncState<Event>.failure(
        error,
        stackTrace,
        previousData: _eventState.data,
      );
    }
    notifyListeners();
  }

  void incrementGuests() {
    final int limit = _eventState.data?.guestLimit ?? 0;
    if (_guestCount >= limit) return;
    _guestCount++;
    _guestNoticeAccepted = false;
    notifyListeners();
  }

  void decrementGuests() {
    if (_guestCount == 0) return;
    _guestCount--;
    _guestNoticeAccepted = false;
    notifyListeners();
  }

  void acceptGuestNotice() {
    _guestNoticeAccepted = true;
    _submissionError = null;
    notifyListeners();
  }

  Future<EventBooking?> submit() async {
    final Event? event = _eventState.data;
    if (_isSubmitting || event == null || event.isAtCapacity) return null;
    if (event.hasStartedAt(DateTime.now())) {
      _submissionError = const AppException(
        'Registration is closed because this event has already started.',
      );
      notifyListeners();
      return null;
    }
    if (_guestCount > 0 && !_guestNoticeAccepted) {
      _submissionError = const AppException(
        'Please acknowledge the guest admission notice before registering.',
      );
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _submissionError = null;
    notifyListeners();
    try {
      return await _eventsRepository.registerForEvent(
        EventRegistrationRequest(eventId: eventId, guestCount: _guestCount),
      );
    } catch (error) {
      if (error is AppException &&
          error.statusCode == 400 &&
          error.message.toLowerCase().contains('full')) {
        _submissionError = const AppException(
          'Registration could not be completed because this event has reached '
          'capacity.',
          statusCode: 400,
        );
      } else {
        _submissionError = error;
      }
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
