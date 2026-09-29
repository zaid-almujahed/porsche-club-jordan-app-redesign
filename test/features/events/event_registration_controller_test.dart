import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/events/data/models/event_model.dart';
import 'package:pcj_v5/features/events/domain/repositories/events_repository.dart';
import 'package:pcj_v5/features/events/presentation/controllers/event_registration_controller.dart';
import 'package:pcj_v5/features/user_events/domain/repositories/user_events_repository.dart';

Event _event({int maxGuests = 2}) =>
    EventModel.fromDetailsJson(<String, dynamic>{
      'id': 7,
      'title': 'Dead Sea Drive',
      'start_at': DateTime.now()
          .add(const Duration(days: 20))
          .toIso8601String(),
      'capacity': 40,
      'Max_guest_count': maxGuests,
    });

class _Repository implements EventsRepository {
  Event event = _event();
  final List<EventRegistrationRequest> requests = <EventRegistrationRequest>[];

  @override
  Future<Event> getEvent(
    String eventId, {
    bool forceRefresh = false,
    Event? fallbackEvent,
  }) async => event;

  @override
  Future<void> registerForEvent(EventRegistrationRequest request) async {
    requests.add(request);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UserEvents implements UserEventsRepository {
  Set<String> registered = <String>{};

  @override
  Future<Set<String>> getRegisteredEventIds() async => registered;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _Repository repository;
  late _UserEvents userEvents;
  late EventRegistrationController controller;

  setUp(() async {
    repository = _Repository();
    userEvents = _UserEvents();
    controller = EventRegistrationController(
      eventsRepository: repository,
      userEventsRepository: userEvents,
      eventId: '7',
    );
    await controller.load();
  });

  test('an RSVP\'d member cannot RSVP again', () async {
    userEvents.registered = <String>{'7'};
    await controller.load(force: true);

    expect(controller.isAlreadyRegistered, isTrue);
    expect(await controller.submit(), isFalse);
    expect(controller.submissionError.toString(), contains('already'));
    expect(repository.requests, isEmpty);
  });

  tearDown(() => controller.dispose());

  test('each added guest gets a name field', () {
    controller.incrementGuests();
    controller.incrementGuests();
    controller.incrementGuests();

    expect(controller.guestCount, 2);
    expect(controller.guestNameControllers, hasLength(2));

    controller.removeGuest(1);
    expect(controller.guestNameControllers, hasLength(1));
  });

  test('guests without a name block the RSVP', () async {
    controller.incrementGuests();
    controller.guestNameControllers.single.text = '   ';
    controller.acceptGuestNotice();

    expect(await controller.submit(), isFalse);
    expect(controller.submissionError.toString(), contains('name'));
    expect(repository.requests, isEmpty);

    controller.onGuestNameChanged('');
    expect(controller.submissionError, isNull);
  });

  test('the RSVP sends the guest count and trimmed names', () async {
    controller.incrementGuests();
    controller.incrementGuests();
    controller.guestNameControllers[0].text = ' Lina Haddad ';
    controller.guestNameControllers[1].text = 'Omar Saleh';
    controller.acceptGuestNotice();

    expect(await controller.submit(), isTrue);
    final EventRegistrationRequest request = repository.requests.single;
    expect(request.guestCount, 2);
    expect(request.guestNames, <String>['Lina Haddad', 'Omar Saleh']);
  });

  test('no guests sends an empty name list', () async {
    await controller.submit();

    expect(repository.requests.single.guestCount, 0);
    expect(repository.requests.single.guestNames, isEmpty);
  });

  test('removing a guest keeps the other names in order', () {
    controller.incrementGuests();
    controller.incrementGuests();
    controller.guestNameControllers[0].text = 'Lina';
    controller.guestNameControllers[1].text = 'Omar';

    controller.removeGuest(0);

    expect(controller.guestCount, 1);
    expect(controller.guestNames, <String>['Omar']);
  });

  test('a lower guest limit drops the extra names', () async {
    controller.incrementGuests();
    controller.incrementGuests();
    controller.guestNameControllers[0].text = 'Lina';
    repository.event = _event(maxGuests: 1);

    await controller.load(force: true);

    expect(controller.guestCount, 1);
    expect(controller.guestNames, <String>['Lina']);
  });
}
