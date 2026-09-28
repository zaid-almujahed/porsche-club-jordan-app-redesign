import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/events/data/models/event_model.dart';

Map<String, dynamic> _details([Map<String, dynamic> extra = const {}]) =>
    <String, dynamic>{
      'id': 7,
      'title': 'Dead Sea Drive',
      'start_at': '2026-11-01T08:00:00',
      'capacity': 40,
      ...extra,
    };

void main() {
  test('Max_guest_count from the event details sets the guest limit', () {
    expect(
      EventModel.fromDetailsJson(_details({'Max_guest_count': 2})).guestLimit,
      2,
    );
    expect(
      EventModel.fromDetailsJson(_details({'max_guest_count': 3})).guestLimit,
      3,
    );
  });

  test('0 max guests means no guests can be added', () {
    expect(
      EventModel.fromDetailsJson(_details({'Max_guest_count': 0})).guestLimit,
      0,
    );
  });

  test('no Max_guest_count yet: no guests (not guessed from capacity)', () {
    final EventModel summary = EventModel.fromSummaryJson(_details());
    expect(summary.guestLimit, 0);
    expect(
      EventModel.fromDetailsJson(_details(), fallbackEvent: summary).guestLimit,
      0,
    );
  });
}
