import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/features/events/domain/repositories/events_repository.dart';

import '../known_locations.dart';
import '../models/event_model.dart';

class ApiEventsRepository implements EventsRepository {
  ApiEventsRepository({
    required PcjApiClient apiClient,
    required MemoryCache cache,
  }) : _apiClient = apiClient,
       _cache = cache;

  final PcjApiClient _apiClient;
  final MemoryCache _cache;
  final Map<String, Event> _eventSummaries = <String, Event>{};
  static const Duration _listTtl = Duration(minutes: 2);
  static const Duration _detailsTtl = Duration(minutes: 5);

  @override
  Future<List<Event>> getEvents({bool forceRefresh = false}) async {
    final List<Event> allEvents = await _cache.getOrLoad<List<Event>>(
      'events:list',
      () async => requireJsonMapList(
        await _apiClient.get('/member/allevents'),
        description: 'events response',
      ).map<Event>(EventModel.fromSummaryJson).toList(growable: false),
      ttl: _listTtl,
      force: forceRefresh,
    );
    for (final Event event in allEvents) {
      if (event.id.isNotEmpty) _eventSummaries[event.id] = event;
    }

    return allEvents;
  }

  @override
  Future<Event> getEvent(
    String eventId, {
    bool forceRefresh = false,
    Event? fallbackEvent,
  }) async {
    final Event event = await _cache.getOrLoad<Event>(
      'events:details:$eventId',
      () async => EventModel.fromDetailsJson(
        requireJsonMap(
          await _apiClient.get(
            '/member/events/${Uri.encodeComponent(eventId)}',
          ),
          description: 'event response',
        ),
        fallbackEvent: fallbackEvent ?? _eventSummaries[eventId],
      ),
      ttl: _detailsTtl,
      force: forceRefresh,
    );
    final Event hydratedEvent = await _withLocationAndWeather(
      event,
      forceRefresh: forceRefresh,
    );
    if (hydratedEvent.id.isNotEmpty) {
      _eventSummaries[hydratedEvent.id] = hydratedEvent;
    }
    return hydratedEvent;
  }

  @override
  Future<List<Event>> getRecentEvents({bool forceRefresh = false}) async {
    final DateTime now = DateTime.now();
    final DateTime end = DateTime(
      now.year,
      now.month + 3,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
    final List<Event> events =
        (await getEvents(forceRefresh: forceRefresh))
            .where((Event event) {
              return !event.endsAt.isBefore(now) &&
                  !event.startsAt.isAfter(end);
            })
            .toList(growable: false)
          ..sort((Event left, Event right) {
            return left.startsAt.compareTo(right.startsAt);
          });
    return List<Event>.unmodifiable(events);
  }

  @override
  Future<void> registerForEvent(EventRegistrationRequest request) async {
    await _apiClient.postJson(
      '/member/events/${Uri.encodeComponent(request.eventId)}/rsvp',
      body: <String, Object?>{
        'guest_count': request.guestCount,
        'guest_names': request.guestNames,
      },
    );
    _cache.removeWhere((String key) => key.startsWith('events:'));
    _cache.removeWhere((String key) => key.startsWith('user-events:'));
  }

  @override
  Future<void> cancelRegistration(String eventId) async {
    await _apiClient.delete(
      '/member/events/${Uri.encodeComponent(eventId)}/rsvp',
    );
    _cache.removeWhere((String key) => key.startsWith('events:'));
    _cache.removeWhere((String key) => key.startsWith('user-events:'));
  }

  @override
  Future<Object?> startEventPayment(String rsvpId) {
    return _apiClient.post(
      '/member/events/${Uri.encodeComponent(rsvpId)}/payment',
    );
  }

  Future<Event> _withLocationAndWeather(
    Event event, {
    required bool forceRefresh,
  }) async {
    final _Coordinates? coordinates = await _resolveCoordinates(
      event,
      forceRefresh: forceRefresh,
    );
    final Event locatedEvent = coordinates == null
        ? event
        : event.copyWith(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
          );
    if (event.weatherCelsius != null) return locatedEvent;
    // Only within the forecast window. The endpoint knows a fixed list of
    // places (others answer 404); a place not on it is still asked for by
    // its address, in case the list grows, and otherwise shows "No
    // information available".
    if (!event.hasForecastAt(DateTime.now())) return locatedEvent;
    final String location =
        knownLocationFor(event.location)?.key ?? event.location.trim();
    if (location.isEmpty) {
      return locatedEvent.copyWith(weatherUnavailable: true);
    }

    return _cache.getOrLoad<Event>(
      'events:weather:${event.id}',
      () async {
        final DateTime localStart = event.startsAt.toLocal();
        try {
          final Map<String, dynamic> response = requireJsonMap(
            await _apiClient.get(
              '/weather',
              query: <String, Object?>{
                'location': location,
                'date': _date(localStart),
                'hour': localStart.hour,
              },
              authenticated: false,
            ),
            description: 'weather response',
          );
          final Object? weatherValue = response['weather'];
          final Map<String, dynamic> weather = weatherValue is Map
              ? Map<String, dynamic>.from(weatherValue)
              : response;
          final double? temperature = firstDouble(weather, const <String>[
            'temperature',
          ]);
          final double? precipitation = firstDouble(weather, const <String>[
            'precipitation_probability',
          ]);
          final double? windSpeed = firstDouble(weather, const <String>[
            'wind_speed',
          ]);
          if (temperature == null &&
              precipitation == null &&
              windSpeed == null) {
            return locatedEvent.copyWith(weatherUnavailable: true);
          }
          return locatedEvent.copyWith(
            weatherCelsius: temperature?.ceil(),
            precipitationProbability: precipitation?.round(),
            windSpeedKmh: windSpeed,
          );
        } catch (_) {
          // Weather is supplementary; event details stay available if the
          // PCJ forecast endpoint rejects the date or is unavailable.
          return locatedEvent.copyWith(weatherUnavailable: true);
        }
      },
      ttl: const Duration(minutes: 15),
      force: forceRefresh,
    );
  }

  static String _date(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<_Coordinates?> _resolveCoordinates(
    Event event, {
    required bool forceRefresh,
  }) async {
    if (event.latitude != null && event.longitude != null) {
      return _Coordinates(event.latitude!, event.longitude!);
    }
    final String location = event.location.trim();
    if (location.length < 2) return null;
    final KnownLocation? place = knownLocationFor(location);
    if (place != null) return _Coordinates(place.latitude, place.longitude);

    return _cache.getOrLoad<_Coordinates?>(
      'events:coordinates:${location.toLowerCase()}',
      () async {
        try {
          final Map<String, dynamic> response = requireJsonMap(
            await _apiClient.get(
              'https://geocoding-api.open-meteo.com/v1/search',
              query: <String, Object?>{
                'name': location,
                'count': 1,
                'countryCode': 'JO',
                'language': 'en',
                'format': 'json',
              },
              authenticated: false,
            ),
            description: 'location response',
          );
          final Object? results = response['results'];
          if (results is! List || results.isEmpty || results.first is! Map) {
            return null;
          }
          final Map<String, dynamic> match = Map<String, dynamic>.from(
            results.first as Map,
          );
          final double? latitude = firstDouble(match, const <String>[
            'latitude',
          ]);
          final double? longitude = firstDouble(match, const <String>[
            'longitude',
          ]);
          if (latitude == null || longitude == null) return null;
          return _Coordinates(latitude, longitude);
        } catch (_) {
          return null;
        }
      },
      ttl: const Duration(days: 1),
      force: forceRefresh,
    );
  }
}

class _Coordinates {
  const _Coordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
