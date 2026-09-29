import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/user_orders/presentation/widgets/order_thumbnail.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

void main() {
  Future<void> pump(WidgetTester tester, int items, {double size = 76}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: OrderThumbnail(
            imagePaths: List<String>.filled(items, ''),
            size: size,
          ),
        ),
      ),
    );
  }

  for (final (int items, int tiles) in <(int, int)>[
    (0, 1),
    (1, 1),
    (2, 2),
    (3, 3),
    (5, 3),
  ]) {
    testWidgets('$items items: $tiles photos', (WidgetTester tester) async {
      await pump(tester, items);

      expect(find.byType(AppAssetImage), findsNWidgets(tiles));
      expect(find.text('+2'), items == 5 ? findsOneWidget : findsNothing);
    });
  }

  testWidgets('three items fit the small Home thumbnail', (
    WidgetTester tester,
  ) async {
    await pump(tester, 4, size: 52);

    expect(tester.takeException(), isNull);
    expect(find.text('+1'), findsOneWidget);
  });
}
