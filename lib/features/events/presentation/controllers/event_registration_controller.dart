import 'package:flutter/widgets.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/core/state/safe_change_notifier.dart';
import 'package:pcj_v5/features/events/domain/repositories/events_repository.dart';
import 'package:pcj_v5/features/user_events/domain/repositories/user_events_repository.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';

class EventRegistrationController extends SafeChangeNotifier {
  EventRegistrationController({
    required EventsRepository eventsRepository,
    required UserEventsRepository userEventsRepository,
    required this.eventId,
    Event? initialEvent,
  }) : _eventsRepository = eventsRepository,
       _userEventsRepository = userEventsRepository,
       _eventState = initialEvent == null
           ? const AsyncState<Event>.initial()
           : AsyncState<Event>.success(initialEvent);

  final EventsRepository _eventsRepository;
  final UserEventsRepository _userEventsRepository;
  final String eventId;

  AsyncState<Event> _eventState;
  int _guestCount = 0;
  bool _guestNoticeAccepted = false;
  bool _isAlreadyRegistered = false;
  bool _isSubmitting = false;
  Object? _submissionError;

  /// One name field per guest; the page shows them in this order.
  final List<TextEditingController> _guestNameControllers =
      <TextEditingController>[];

  AsyncState<Event> get eventState => _eventState;
  int get guestCount => _guestCount;
  List<TextEditingController> get guestNameControllers =>
      List<TextEditingController>.unmodifiable(_guestNameControllers);
  List<String> get guestNames => _guestNameControllers
      .map((TextEditingController field) => field.text.trim())
      .toList();
  bool get hasAllGuestNames =>
      guestNames.every((String name) => name.isNotEmpty);
  bool get guestNoticeAccepted => _guestNoticeAccepted;

  /// The member already has an RSVP for this event.
  bool get isAlreadyRegistered => _isAlreadyRegistered;
  bool get isSubmitting => _isSubmitting;
  Object? get submissionError => _submissionError;

  /// A paid event: the RSVP is sent together with its CliQ payment, from
  /// the payment page.
  bool get requiresPayment => total > 0;

  double get basePrice {
    final Event? event = _eventState.data;
    return event == null || !event.isPaid ? 0 : event.registrationFee;
  }

  /// On a paid event a guest costs the same as the member.
  double get guestPrice {
    final Event? event = _eventState.data;
    return event == null || !event.isPaid ? 0 : event.guestFee;
  }

  double get guestsTotal => guestPrice * _guestCount;
  double get total => basePrice + guestsTotal;

  Future<void> load({bool force = false}) async {
    await _loadEvent(force: force);
  }

  Future<void> _loadEvent({required bool force}) async {
    if (!force && (_eventState.isLoading || _eventState.hasData)) return;
    _eventState = AsyncState<Event>.loading(previousData: _eventState.data);
    notifyListeners();
    final Future<Set<String>> registered = _userEventsRepository
        .getRegisteredEventIds()
        .catchError((Object _) => const <String>{});
    try {
      final Event event = await _eventsRepository.getEvent(
        eventId,
        forceRefresh: force,
        fallbackEvent: _eventState.data,
      );
      _eventState = AsyncState<Event>.success(event);
      _isAlreadyRegistered = (await registered).contains(eventId);
      if (event.guestLimit <= 0) {
        _setGuestCount(0);
        _guestNoticeAccepted = false;
      } else if (_guestCount > event.guestLimit) {
        _setGuestCount(event.guestLimit);
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
    _setGuestCount(_guestCount + 1);
    _guestNoticeAccepted = false;
    notifyListeners();
  }

  /// Removes the guest at [index], keeping the other names in order.
  void removeGuest(int index) {
    if (index < 0 || index >= _guestCount) return;
    _guestNameControllers.removeAt(index).dispose();
    _guestCount--;
    _guestNoticeAccepted = false;
    _submissionError = null;
    notifyListeners();
  }

  void onGuestNameChanged(String _) {
    if (_submissionError != _missingGuestNames) return;
    _submissionError = null;
    notifyListeners();
  }

  /// False, with an error shown, while a guest has no name.
  bool validateGuestNames() {
    if (hasAllGuestNames) return true;
    _submissionError = _missingGuestNames;
    notifyListeners();
    return false;
  }

  static const AppException _missingGuestNames = AppException(
    'Enter a name for each guest.',
  );

  /// Adds empty name fields or drops them from the end.
  void _setGuestCount(int count) {
    while (_guestNameControllers.length < count) {
      _guestNameControllers.add(TextEditingController());
    }
    while (_guestNameControllers.length > count) {
      _guestNameControllers.removeLast().dispose();
    }
    _guestCount = count;
  }

  void acceptGuestNotice() {
    _guestNoticeAccepted = true;
    _submissionError = null;
    notifyListeners();
  }

  /// True when the RSVP may be sent; otherwise false, with an error shown.
  bool validate() {
    final Event? event = _eventState.data;
    if (_isSubmitting || event == null || event.isAtCapacity) return false;
    if (_isAlreadyRegistered) {
      _submissionError = const AppException(
        'You are already registered for this event.',
      );
      notifyListeners();
      return false;
    }
    if (event.hasStartedAt(DateTime.now())) {
      _submissionError = const AppException(
        'Registration is closed because this event has already started.',
      );
      notifyListeners();
      return false;
    }
    if (!validateGuestNames()) return false;
    if (_guestCount > 0 && !_guestNoticeAccepted) {
      _submissionError = const AppException(
        'Please acknowledge the guest admission notice before registering.',
      );
      notifyListeners();
      return false;
    }
    return true;
  }

  /// True once the RSVP is sent.
  Future<bool> submit() async {
    if (!validate()) return false;
    _isSubmitting = true;
    _submissionError = null;
    notifyListeners();
    try {
      await _eventsRepository.registerForEvent(
        EventRegistrationRequest(
          eventId: eventId,
          guestCount: _guestCount,
          guestNames: guestNames,
        ),
      );
      return true;
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
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final TextEditingController field in _guestNameControllers) {
      field.dispose();
    }
    super.dispose();
  }
}
