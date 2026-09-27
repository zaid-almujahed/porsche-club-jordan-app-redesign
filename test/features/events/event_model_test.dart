import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/events/data/models/event_model.dart';

void main() {
  group('EventModel', () {
    test('parses documented guest, fee, sponsor, and gallery fields', () {
      final EventModel event = EventModel.fromDetailsJson(<String, dynamic>{
        'id': 'event-1',
        'title': 'Track Day',
        'start_at': '2026-10-01T08:00:00Z',
        'end_at': '2026-10-01T16:00:00Z',
        'max_guest_count': 2,
        'registration_fee': '35.5',
        'guest_fee': 10,
        'sponsor': <String, dynamic>{'name': 'Partner'},
        'photos': <String, dynamic>{'url': 'https://example.com/photo.jpg'},
      });

      expect(event.guestLimit, 2);
      expect(event.registrationFee, 35.5);
      expect(event.guestFee, 10);
      expect(event.sponsors, <String>['Partner']);
      expect(event.galleryUrls, <String>['https://example.com/photo.jpg']);
      expect(event.isPaid, isTrue);
      expect(event.isFree, isFalse);
    });

    test('zero or omitted capacity is not automatically sold out', () {
      final EventModel event = EventModel.fromSummaryJson(<String, dynamic>{
        'id': 'event-2',
        'start_at': '2026-10-01T08:00:00Z',
      });

      expect(event.isAtCapacity, isFalse);
    });

    test('explicit zero availability is sold out', () {
      final EventModel event = EventModel.fromSummaryJson(<String, dynamic>{
        'id': 'event-3',
        'start_at': '2026-10-01T08:00:00Z',
        'available': 0,
      });

      expect(event.isAtCapacity, isTrue);
    });

    test('parses nested sponsor and location payloads', () {
      final EventModel event = EventModel.fromDetailsJson(<String, dynamic>{
        'id': 4,
        'start_at': '2026-10-01T08:00:00Z',
        'location': <String, dynamic>{
          'name': 'Jordan Motorsport Arena',
          'coordinates': <String, dynamic>{'lat': 31.9539, 'lng': 35.9106},
        },
        'sponsors': <String, dynamic>{
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'sponsor': <String, dynamic>{'sponsor_name': 'PCJ Partner'},
            },
          ],
        },
      });

      expect(event.location, 'Jordan Motorsport Arena');
      expect(event.latitude, 31.9539);
      expect(event.longitude, 35.9106);
      expect(event.sponsors, <String>['PCJ Partner']);
    });

    test('an event becomes past as soon as its start time passes', () {
      final EventModel event = EventModel.fromSummaryJson(<String, dynamic>{
        'id': 'event-past',
        'start_at': '2026-09-18T09:00:00Z',
      });

      expect(
        event.hasStartedAt(DateTime.parse('2026-09-18T09:00:01Z')),
        isTrue,
      );
      expect(
        event.hasStartedAt(DateTime.parse('2026-09-18T08:59:59Z')),
        isFalse,
      );
    });
  });
}
