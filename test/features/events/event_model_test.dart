import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/events/data/models/event_model.dart';

// Shape of GET /member/events/{id} (the Manja Track Day response).
Map<String, dynamic> _details() => <String, dynamic>{
  'id': 37,
  'title': 'Manja Track Day',
  'description': 'A private track day event for Porsche Club Members.',
  'location': 'dead sea',
  'latitude': 31.541946,
  'longitude': 35.4812013,
  'start_at': '2016-11-11T14:30:00+02:00',
  'capacity': 100,
  'Max_guest_count': 2,
  'cover_image': 'https://example.com/events/cover.jpg',
  'gallery': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 7,
      'type': 'image',
      'file_url': 'https://example.com/events/1.jpg',
    },
    <String, dynamic>{
      'id': 8,
      'type': 'image',
      'file_url': 'https://example.com/events/2.jpg',
    },
  ],
  'sponsors': <Map<String, dynamic>>[
    <String, dynamic>{
      'sponsor_id': 10,
      'tier': 'Platinum',
      'sponor_name': 'NUQUL',
      'sponsor_logo': 'https://example.com/sponsors/nuqul.jpg',
    },
  ],
};

void main() {
  group('EventModel', () {
    test('parses the event details response', () {
      final EventModel event = EventModel.fromDetailsJson(_details());

      expect(event.id, '37');
      expect(event.title, 'Manja Track Day');
      expect(event.location, 'dead sea');
      expect(event.latitude, 31.541946);
      expect(event.longitude, 35.4812013);
      expect(event.capacity, 100);
      expect(event.guestLimit, 2);
      expect(event.posterUrl, 'https://example.com/events/cover.jpg');
      expect(
        event.gallery.map((EventGalleryItem item) => item.fileUrl),
        <String>[
          'https://example.com/events/1.jpg',
          'https://example.com/events/2.jpg',
        ],
      );
      expect(event.sponsors.single.name, 'NUQUL');
      expect(event.sponsors.single.tier, 'Platinum');
      expect(
        event.sponsors.single.logoUrl,
        'https://example.com/sponsors/nuqul.jpg',
      );
    });

    test('sponsors are listed by tier, Platinum first', () {
      final EventModel event = EventModel.fromDetailsJson(<String, dynamic>{
        ..._details(),
        'sponsors': <Map<String, dynamic>>[
          for (final String tier in <String>['Bronze', 'Gold', 'Platinum'])
            <String, dynamic>{
              'sponsor_id': tier,
              'tier': tier,
              'sponor_name': '$tier Sponsor',
              'sponsor_logo': 'https://example.com/$tier.png',
            },
        ],
      });

      expect(
        event.sponsors.map((EventSponsor sponsor) => sponsor.tier),
        <String>['Platinum', 'Gold', 'Bronze'],
      );
    });

    test('incomplete gallery and sponsor entries are skipped', () {
      final EventModel event = EventModel.fromDetailsJson(<String, dynamic>{
        ..._details(),
        'gallery': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'type': 'image'},
        ],
        'sponsors': <Map<String, dynamic>>[
          <String, dynamic>{'sponsor_id': 1, 'tier': 'Gold'},
        ],
      });

      expect(event.gallery, isEmpty);
      expect(event.sponsors, isEmpty);
    });

    test('zero or omitted capacity is not automatically sold out', () {
      final EventModel event = EventModel.fromSummaryJson(<String, dynamic>{
        'id': 'event-2',
        'start_at': '2026-10-01T08:00:00Z',
      });

      expect(event.isAtCapacity, isFalse);
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
