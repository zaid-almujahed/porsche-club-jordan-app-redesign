import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/core/state/safe_change_notifier.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';

import '../../domain/repositories/events_repository.dart';

class EventDetailsController extends SafeChangeNotifier {
  EventDetailsController({
    required EventsRepository repository,
    required this.eventId,
    Event? initialEvent,
  }) : _repository = repository,
       _state = initialEvent == null
           ? const AsyncState<Event>.initial()
           : AsyncState<Event>.success(initialEvent);

  final EventsRepository _repository;
  final String eventId;
  AsyncState<Event> _state;

  AsyncState<Event> get state => _state;

  Future<void> load({bool force = false}) async {
    if (!force && (_state.isLoading || _state.hasData)) return;
    await refresh();
  }

  Future<void> refresh() async {
    final Event? current = _state.data;
    _state = AsyncState<Event>.loading(previousData: current);
    notifyListeners();
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
    notifyListeners();
  }
}
