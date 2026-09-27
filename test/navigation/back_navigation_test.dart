// Regression tests for back navigation.
//
// Boots the real app (real router, repositories and controllers) with only
// the network and secure storage faked, signs in a test member, then presses
// every back button the member can reach — after a normal push and after the
// page was opened directly (no history underneath).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pcj_v5/app.dart';
import 'package:pcj_v5/core/dependencies/app_dependencies.dart';
import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';

const MethodChannel _secureStorage = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: <String, String>{'content-type': 'application/json'},
);

/// Minimal backend: a signed-in active member; every other endpoint fails,
/// which is fine because these tests only exercise navigation.
Future<http.Response> _backend(http.Request request) async {
  switch (request.url.path) {
    case '/auth/me':
      return _json(<String, Object>{
        'id': '1',
        'name': 'Test Member',
        'email': 'member@example.com',
        'phone': '0790000000',
      });
    case '/member/membership':
      return _json(<String, Object>{
        'status': 'ACTIVE',
        'end_date': '2027-09-26',
      });
    default:
      return _json(<String, Object>{'message': 'Not available in tests.'}, 404);
  }
}

final DateTime _start = DateTime.now().add(const Duration(days: 7));

final Event _event = Event(
  id: 'e1',
  title: 'Test Drive',
  description: 'A test event.',
  location: 'Amman',
  startsAt: _start,
  endsAt: _start.add(const Duration(hours: 3)),
  category: 'Drive',
  posterUrl: '',
  capacity: 20,
  registeredCount: 2,
  guestLimit: 1,
  registrationFee: 0,
  guestFee: 0,
);

const Product _product = Product(
  id: 'p1',
  name: 'PCJ Cap',
  description: 'A cap.',
  category: 'Accessories',
  price: 25,
  currency: 'JOD',
  stock: 3,
  imageUrls: <String>[],
);

final EventBooking _booking = EventBooking(
  id: 'b1',
  event: _event,
  status: EventBookingStatus.confirmed,
  guestCount: 0,
);

Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<GoRouter> _launchSignedIn(WidgetTester tester) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorage, (MethodCall call) async {
        if (call.method == 'read') return 'test-token';
        if (call.method == 'readAll') return <String, String>{};
        return null;
      });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorage, null);
  });

  late final AppDependencies dependencies;
  http.runWithClient(
    () => dependencies = AppDependencies.create(),
    () => MockClient(_backend),
  );

  await tester.pumpWidget(PcjApp(dependencies: dependencies));
  await _settle(tester);

  final GoRouter router = GoRouter.of(
    tester.element(find.byType(Navigator).first),
  );
  expect(
    router.state.uri.path,
    AppRoutes.home,
    reason: 'the fake member should be signed in and land on home',
  );
  return router;
}

Future<void> _pressBack(WidgetTester tester) async {
  final Finder back = find.byTooltip('Back');
  expect(back, findsWidgets, reason: 'page should show a back button');
  await tester.tap(back.last);
  await _settle(tester);
}

void main() {
  group('back button after a normal push returns to the previous page', () {
    final Map<String, String> fromProfile = <String, String>{
      'orders': AppRoutes.userOrders,
      'my events': AppRoutes.userEvents,
      'membership': AppRoutes.membershipSettings,
      'account settings': AppRoutes.accountSettings,
      'edit profile': AppRoutes.profileEdit,
      'notifications': AppRoutes.notifications,
    };

    for (final MapEntry<String, String> page in fromProfile.entries) {
      testWidgets(page.key, (WidgetTester tester) async {
        final GoRouter router = await _launchSignedIn(tester);
        router.go(AppRoutes.profile);
        await _settle(tester);

        router.push(page.value);
        await _settle(tester);
        expect(router.state.uri.path, page.value);

        await _pressBack(tester);
        expect(tester.takeException(), isNull);
        expect(router.state.uri.path, AppRoutes.profile);
      });
    }

    testWidgets('event details and registration', (WidgetTester tester) async {
      final GoRouter router = await _launchSignedIn(tester);
      router.go(AppRoutes.events);
      await _settle(tester);

      router.push(AppRoutes.eventDetailsLocation(_event.id), extra: _event);
      await _settle(tester);
      router.push(
        AppRoutes.eventRegistrationLocation(_event.id),
        extra: _event,
      );
      await _settle(tester);

      await _pressBack(tester);
      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, AppRoutes.eventDetailsLocation(_event.id));

      await _pressBack(tester);
      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, AppRoutes.events);
    });

    testWidgets('product details and checkout', (WidgetTester tester) async {
      final GoRouter router = await _launchSignedIn(tester);
      router.go(AppRoutes.shop);
      await _settle(tester);

      router.push(
        AppRoutes.productDetailsLocation(_product.id),
        extra: _product,
      );
      await _settle(tester);
      router.push(AppRoutes.checkout);
      await _settle(tester);

      await _pressBack(tester);
      expect(tester.takeException(), isNull);
      expect(
        router.state.uri.path,
        AppRoutes.productDetailsLocation(_product.id),
      );

      await _pressBack(tester);
      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, AppRoutes.shop);
    });

    testWidgets('virtual ticket', (WidgetTester tester) async {
      final GoRouter router = await _launchSignedIn(tester);
      router.go(AppRoutes.profile);
      await _settle(tester);
      router.push(AppRoutes.userEvents);
      await _settle(tester);
      router.push(AppRoutes.ticketLocation(_booking.id), extra: _booking);
      await _settle(tester);

      await _pressBack(tester);
      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, AppRoutes.userEvents);
    });
  });

  group('back button on a page opened with no history does not crash', () {
    final Map<String, (String, Object?)> direct = <String, (String, Object?)>{
      'orders (after placing an order)': (AppRoutes.userOrders, null),
      'my events (after registering)': (AppRoutes.userEvents, null),
      'membership': (AppRoutes.membershipSettings, null),
      'account settings': (AppRoutes.accountSettings, null),
      'edit profile': (AppRoutes.profileEdit, null),
      'notifications': (AppRoutes.notifications, null),
      'checkout': (AppRoutes.checkout, null),
      'event details': (AppRoutes.eventDetailsLocation(_event.id), _event),
      'event registration': (
        AppRoutes.eventRegistrationLocation(_event.id),
        _event,
      ),
      'product details': (
        AppRoutes.productDetailsLocation(_product.id),
        _product,
      ),
      'ticket': (AppRoutes.ticketLocation(_booking.id), _booking),
    };

    for (final MapEntry<String, (String, Object?)> page in direct.entries) {
      testWidgets(page.key, (WidgetTester tester) async {
        final GoRouter router = await _launchSignedIn(tester);
        router.go(page.value.$1, extra: page.value.$2);
        await _settle(tester);

        await _pressBack(tester);
        expect(tester.takeException(), isNull);
        expect(
          router.state.uri.path,
          isNot(page.value.$1),
          reason: 'back should leave the page instead of doing nothing',
        );
      });
    }
  });

  group('Android system back', () {
    final Map<String, String> pages = <String, String>{
      'orders': AppRoutes.userOrders,
      'my events': AppRoutes.userEvents,
      'membership': AppRoutes.membershipSettings,
      'account settings': AppRoutes.accountSettings,
      'edit profile': AppRoutes.profileEdit,
      'notifications': AppRoutes.notifications,
      'checkout': AppRoutes.checkout,
    };
    for (final MapEntry<String, String> page in pages.entries) {
      testWidgets(page.key, (WidgetTester tester) async {
        final GoRouter router = await _launchSignedIn(tester);
        router.go(AppRoutes.profile);
        await _settle(tester);
        router.push(page.value);
        await _settle(tester);

        await tester.binding.handlePopRoute();
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(router.state.uri.path, AppRoutes.profile);
      });
    }
  });

  group('end-to-end flows', () {
    testWidgets('home -> event -> register -> back -> back', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launchSignedIn(tester);
      router.push(AppRoutes.eventDetailsLocation(_event.id), extra: _event);
      await _settle(tester);
      router.push(
        AppRoutes.eventRegistrationLocation(_event.id),
        extra: _event,
      );
      await _settle(tester);
      await _pressBack(tester);
      await _pressBack(tester);
      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, AppRoutes.home);
    });

    testWidgets('after an order, orders back goes to profile', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launchSignedIn(tester);
      router.go(AppRoutes.shop);
      await _settle(tester);
      router.push(AppRoutes.checkout);
      await _settle(tester);
      router.go(AppRoutes.userOrders); // what onOrderPlaced does
      await _settle(tester);
      await _pressBack(tester);
      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, AppRoutes.profile);
      // And the shell still works afterwards.
      router.push(AppRoutes.userOrders);
      await _settle(tester);
      await _pressBack(tester);
      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, AppRoutes.profile);
    });

    testWidgets('after registering, my events -> ticket -> back -> back', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launchSignedIn(tester);
      router.go(AppRoutes.userEvents); // what onRegistered does
      await _settle(tester);
      router.push(AppRoutes.ticketLocation(_booking.id), extra: _booking);
      await _settle(tester);
      await _pressBack(tester);
      expect(router.state.uri.path, AppRoutes.userEvents);
      await _pressBack(tester);
      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, AppRoutes.profile);
    });

    testWidgets('double-tapping back does not crash', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launchSignedIn(tester);
      router.go(AppRoutes.profile);
      await _settle(tester);
      router.push(AppRoutes.membershipSettings);
      await _settle(tester);
      // Two taps land before the first one has rebuilt the page.
      final Offset button = tester.getCenter(find.byTooltip('Back').last);
      await tester.tapAt(button);
      await tester.tapAt(button);
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(router.state.uri.path, AppRoutes.profile);
    });
  });
}
