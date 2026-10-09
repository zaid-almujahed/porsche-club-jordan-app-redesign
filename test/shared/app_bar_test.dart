import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester,
    PorscheAppBar bar, {
    Widget child = const SizedBox(height: 40),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: bar,
          body: AppPageBody(child: child),
        ),
      ),
    );
  }

  testWidgets('a main tab shows only its actions, grouped', (
    WidgetTester tester,
  ) async {
    await pumpPage(
      tester,
      PorscheAppBar(
        title: 'Shop',
        showCart: true,
        showNotifications: true,
        cartItemCount: ValueNotifier<int>(2),
        unreadNotificationCount: ValueNotifier<int>(1),
      ),
    );

    // The bottom bar names the tab.
    expect(find.text('Shop'), findsNothing);
    expect(find.byTooltip('Back'), findsNothing);
    expect(find.byTooltip('Cart, 2 items'), findsOneWidget);
    expect(find.byTooltip('Notifications, 1 unread'), findsOneWidget);
    // The cart leads, across from the bell.
    expect(
      tester.getCenter(find.byTooltip('Cart, 2 items')).dx,
      lessThan(400 / 2),
    );
    expect(
      tester.getCenter(find.byTooltip('Notifications, 1 unread')).dx,
      greaterThan(800 / 2),
    );
  });

  testWidgets('an inner page names itself in a pill that goes back', (
    WidgetTester tester,
  ) async {
    int backs = 0;
    await pumpPage(
      tester,
      PorscheAppBar(title: 'My Orders', showBack: true, onBack: () => backs++),
    );

    expect(find.text('My Orders'), findsOneWidget);
    await tester.tap(find.text('My Orders'));
    expect(backs, 1);
  });

  testWidgets('a flow that closes keeps its name and a close button', (
    WidgetTester tester,
  ) async {
    int closes = 0;
    await pumpPage(
      tester,
      PorscheAppBar(
        title: 'Membership Application',
        showClose: true,
        onClose: () => closes++,
      ),
    );

    expect(find.text('Membership Application'), findsOneWidget);
    expect(find.byTooltip('Back'), findsNothing);
    await tester.tap(find.byTooltip('Cancel registration'));
    expect(closes, 1);
  });

  testWidgets('content starts below the controls and is revealed below them', (
    WidgetTester tester,
  ) async {
    const Key target = Key('target');
    await pumpPage(
      tester,
      const PorscheAppBar(title: 'Checkout', showBack: true),
      child: const Column(
        children: <Widget>[
          SizedBox(key: target, height: 40),
          SizedBox(height: 2000),
        ],
      ),
    );
    final double controlsBottom = tester
        .getBottomLeft(find.byType(PorscheAppBar))
        .dy;
    expect(
      tester.getTopLeft(find.byKey(target)).dy,
      greaterThan(controlsBottom),
    );

    // Scrolled out of sight, then brought back into view: not under them.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(target));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(target)).dy,
      greaterThanOrEqualTo(controlsBottom),
    );
  });
}
