import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/events/data/models/event_model.dart';
import 'package:pcj_v5/features/events/presentation/widgets/event_tags.dart';

Event _startingAt(DateTime start) =>
    EventModel.fromSummaryJson(<String, dynamic>{
      'id': 1,
      'title': 'Dead Sea Drive',
      'start_at': start.toIso8601String(),
    });

void main() {
  final DateTime now = DateTime(2026, 9, 29, 10);

  test('events starting within three calendar days are tagged', () {
    String? label(DateTime start) =>
        EventTags.startsSoonLabel(_startingAt(start), now);

    expect(label(DateTime(2026, 9, 29, 18)), 'Today');
    expect(label(DateTime(2026, 9, 30, 9)), 'Tomorrow');
    expect(label(DateTime(2026, 10, 1, 23)), 'In 2 days');
    expect(label(DateTime(2026, 10, 2, 8)), 'In 3 days');
    expect(label(DateTime(2026, 10, 3, 8)), isNull);
    // Started: no longer "soon".
    expect(label(DateTime(2026, 9, 29, 9)), isNull);
  });

  testWidgets('no tags, nothing shown; registered shows its tag', (
    WidgetTester tester,
  ) async {
    final Event later = _startingAt(
      DateTime.now().add(const Duration(days: 30)),
    );
    await tester.pumpWidget(MaterialApp(home: EventTags(event: later)));
    expect(find.byType(Wrap), findsNothing);

    await tester.pumpWidget(
      MaterialApp(home: EventTags(event: later, isRegistered: true)),
    );
    expect(find.text('REGISTERED'), findsOneWidget);
  });
}
