import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

/// Opacity per page index once animations settle.
Future<List<double>> _opacities(
  WidgetTester tester, {
  required int count,
  required int current,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppPageDots(count: count, current: current),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester
      .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
      .map((AnimatedOpacity o) => o.opacity)
      .toList();
}

void main() {
  testWidgets('few pages: every dot is fully visible', (
    WidgetTester tester,
  ) async {
    expect(await _opacities(tester, count: 3, current: 1), <double>[1, 1, 1]);
  });

  testWidgets('many pages: five visible, edge dots fade when more lie beyond', (
    WidgetTester tester,
  ) async {
    final List<double> middle = await _opacities(tester, count: 12, current: 6);
    expect(middle.where((double o) => o > 0).length, 5);
    // Window 4..8: both edges have hidden pages beyond them.
    expect(middle.sublist(4, 9), <double>[0.6, 1, 1, 1, 0.6]);

    final List<double> first = await _opacities(tester, count: 12, current: 0);
    // Window 0..4: nothing before it, so only the right edge fades.
    expect(first.sublist(0, 5), <double>[1, 1, 1, 1, 0.6]);
    expect(first.sublist(5).every((double o) => o == 0), isTrue);

    final List<double> last = await _opacities(tester, count: 12, current: 11);
    expect(last.sublist(7), <double>[0.6, 1, 1, 1, 1]);
  });

  testWidgets('a single page shows no dots', (WidgetTester tester) async {
    expect(await _opacities(tester, count: 1, current: 0), isEmpty);
  });
}
