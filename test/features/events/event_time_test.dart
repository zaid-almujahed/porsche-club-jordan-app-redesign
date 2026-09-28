import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/features/events/data/models/event_model.dart';

// Shape of GET /member/allevents and /member/events/{id}.
Map<String, dynamic> _event(String startAt) => <String, dynamic>{
  'id': 37,
  'title': 'Manja Track Day',
  'location': 'dead sea',
  'start_at': startAt,
  'capacity': 100,
};

void main() {
  test('start_at is shown at the time it states, not converted to UTC', () {
    final EventModel event = EventModel.fromDetailsJson(
      _event('2016-11-11T14:30:00+02:00'),
    );

    expect(event.startsAt.isUtc, isFalse);
    expect(AppFormatters.time(event.startsAt), '02:30 PM');
    expect(AppFormatters.date(event.startsAt), '11 Nov, 2016');
  });

  test('an offset near midnight does not move the event to another day', () {
    final EventModel event = EventModel.fromSummaryJson(
      _event('2026-10-02T01:00:00+03:00'),
    );

    expect(
      AppFormatters.dateAndTime(event.startsAt),
      '02 Oct, 2026 · 01:00 AM',
    );
  });

  test('a Z (UTC) time is shown in the phone time zone', () {
    final EventModel event = EventModel.fromSummaryJson(
      _event('2026-10-01T08:00:00Z'),
    );

    expect(event.startsAt.isUtc, isFalse);
    expect(event.startsAt, DateTime.utc(2026, 10, 1, 8).toLocal());
  });

  test('no offset, compact offsets and fractions keep the stated time', () {
    for (final String value in <String>[
      '2026-10-01T08:00:00',
      '2026-10-01 08:00:00+0300',
      '2026-10-01T08:00:00.000+03:00',
    ]) {
      final EventModel event = EventModel.fromSummaryJson(_event(value));
      expect(event.startsAt, DateTime(2026, 10, 1, 8), reason: value);
    }
  });

  test('an unreadable start_at falls back instead of throwing', () {
    final EventModel event = EventModel.fromSummaryJson(_event('soon'));

    expect(event.startsAt, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
  });

  test('without an end time the range shows only the start time', () {
    final DateTime start = DateTime(2016, 11, 11, 14, 30);

    expect(AppFormatters.timeRange(start, start), '02:30 PM');
    expect(
      AppFormatters.timeRange(start, DateTime(2016, 11, 11, 18)),
      '02:30 PM - 06:00 PM',
    );
  });
}
