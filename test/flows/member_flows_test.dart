// End-to-end checks for session, membership-status, cart, offer and payment
// flows. Boots the real app (router, repositories, controllers) with only the
// network and secure storage faked.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pcj_v5/app.dart';
import 'package:pcj_v5/core/dependencies/app_dependencies.dart';
import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/features/auth/presentation/pages/launch_page.dart';
import 'package:pcj_v5/features/auth/presentation/pages/welcome_page.dart';
import 'package:pcj_v5/features/user_orders/presentation/widgets/user_orders_widgets.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

const MethodChannel _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: <String, String>{'content-type': 'application/json'},
);

String _day(int offsetDays) {
  final DateTime date = DateTime.now().add(Duration(days: offsetDays));
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _Storage {
  _Storage(this.token, {this.unreadable = false});

  String? token;

  /// Simulates secure storage that throws on every read.
  bool unreadable;
}

class _Backend {
  _Backend({this.membershipStatus = 'ACTIVE', String? endDate})
    : endDate = endDate ?? _day(365);

  String membershipStatus;
  String? endDate;
  bool offline = false;
  bool rejectToken = false;

  /// `Max_guest_count` on /member/events/e7; null leaves the field out.
  int? maxGuestCount;

  /// Where the backend answers 400 "Membership application was rejected."
  /// ('login', 'otp' or 'me'); null for a normal member.
  String? rejectAt;

  static final http.Response _rejected = _json(<String, Object>{
    'detail': 'Membership application was rejected.',
  }, 400);
  final List<String> calls = <String>[];
  final List<Map<String, Object?>> cart = <Map<String, Object?>>[];
  final List<Map<String, Object?>> orders = <Map<String, Object?>>[];

  static const Map<String, Object?> _cap = <String, Object?>{
    'id': 1,
    'name': 'PCJ Cap',
    'price': 25,
    'variants': <Map<String, Object?>>[
      <String, Object?>{'id': 11, 'stock': 5, 'color': 'Black'},
    ],
  };

  static const Map<String, Object?> _tee = <String, Object?>{
    'id': 2,
    'name': 'PCJ Tee',
    'price': 30,
    'variants': <Map<String, Object?>>[
      <String, Object?>{'id': 21, 'stock': 5, 'color': 'Black', 'size': 'S'},
      <String, Object?>{'id': 22, 'stock': 5, 'color': 'Black', 'size': 'M'},
    ],
  };

  int count(String call) => calls.where((String c) => c == call).length;

  Future<http.Response> handle(http.Request request) async {
    final String call = '${request.method} ${request.url.path}';
    calls.add(call);
    if (offline) throw http.ClientException('offline');
    if (rejectToken && request.headers.containsKey('Authorization')) {
      return _json(<String, Object>{'detail': 'Token has expired.'}, 401);
    }
    switch (call) {
      case 'POST /auth/login':
        if (rejectAt == 'login') return _rejected;
        return _json(<String, Object>{'message': 'OTP sent.'});
      case 'POST /auth/verify-otp':
        if (rejectAt == 'otp') return _rejected;
        return _json(<String, Object>{
          'access_token': 'new-token',
          'refresh_token': 'refresh',
        });
      case 'GET /auth/me' when rejectAt == 'me':
        return _rejected;
      case 'GET /auth/me':
        return _json(<String, Object>{
          'id': '1',
          'name': 'Test Member',
          'email': 'member@example.com',
          'phone': '0790000000',
        });
      case 'GET /member/profile':
        return _json(<String, Object>{
          'id': '1',
          'name': 'Test Member',
          'email': 'member@example.com',
          'phone': '0790000000',
        });
      case 'GET /member/membership':
        return _json(<String, Object?>{
          'member_id': 'PCJ-200033',
          'status': membershipStatus,
          'start_date': _day(-300),
          'end_date': ?endDate,
        });
      case 'POST /member/pay-membership':
        membershipStatus = 'ACTIVE';
        endDate = _day(400);
        return _json(<String, Object>{'message': 'Membership activated.'});
      case 'GET /member/events/e7':
        return _json(<String, Object?>{
          'id': 'e7',
          'title': 'Dead Sea Drive',
          'start_at': DateTime.now()
              .add(const Duration(days: 20))
              .toIso8601String(),
          'capacity': 40,
          'location': 'Amman',
          'Max_guest_count': ?maxGuestCount,
        });
      case 'GET /weather':
        // Sample response supplied by the backend.
        return _json(<String, Object>{
          'location': 'Amman',
          'country': 'Jordan',
          'date': '2026-09-26',
          'hour': '11:00',
          'weather': <String, Object>{
            'code': 0,
            'temperature': 25.1,
            'humidity': 46,
            'precipitation_probability': 0,
            'wind_speed': 7.2,
          },
        });
      case 'GET /member/allevents':
        return _json(<Object>[
          for (int i = 1; i <= 8; i++)
            <String, Object?>{
              'id': 'u$i',
              'title': 'Upcoming Drive $i',
              'start_at': DateTime.now()
                  .add(Duration(days: 3 * i))
                  .toIso8601String(),
              'capacity': 20,
            },
          for (int i = 1; i <= 3; i++)
            <String, Object?>{
              'id': 'p$i',
              'title': 'Past Meet $i',
              'start_at': DateTime.now()
                  .subtract(Duration(days: 5 * i))
                  .toIso8601String(),
              'capacity': 20,
            },
        ]);
      case 'GET /member/items':
        return _json(<Object>[_cap, _tee]);
      case 'GET /member/items/2':
        return _json(_tee);
      case 'GET /member/cart':
        return _json(<String, Object>{'items': cart});
      case 'POST /member/cart':
        final Map<String, dynamic> body =
            jsonDecode(request.body) as Map<String, dynamic>;
        cart.add(<String, Object?>{
          'cart_item_id': cart.length + 1,
          'item_id': body['variant_id'] == 11 ? 1 : 2,
          'variant_id': body['variant_id'],
          'quantity': body['quantity'],
          'name': 'Item',
          'price': 25,
        });
        return _json(<String, Object>{'message': 'Added.'});
      case 'POST /member/cart/checkout':
        cart.clear();
        orders.insert(0, <String, Object?>{
          'order_id': 55,
          'status': 'PENDING',
          'total': 25,
          'payment_method': 'CASH',
          'payment_status': 'PENDING',
          'delivery_method': 'PICKUP',
          'created_at': DateTime.now().toIso8601String(),
        });
        return _json(<String, Object?>{
          ...orders.first,
          'message': 'Order placed successfully.',
        });
      case 'GET /member/orders':
        return _json(orders);
      case 'GET /member/orders/55':
        return _json(orders.first);
      case 'GET /member/offers':
        return _json(<Object>[
          <String, Object>{
            'offer_id': 6,
            'partner': 'yaser',
            'title': 'sad',
            'Logo':
                'https://pub-011fb422a61d4225885f96ace4bd9aca.r2.dev/'
                'partners_logo/download (1).png',
            'offer_details': 'asd',
            'discount': 25,
            'expiry_date': '2026-10-29',
          },
        ]);
      case 'POST /member/offers/6/claim':
        return _json(<String, Object>{'message': 'Offer claimed.'});
      case 'POST /auth/logout':
        return _json(<String, Object>{'message': 'Logged out.'});
      default:
        return _json(<String, Object>{'message': 'Not in tests.'}, 404);
    }
  }
}

Future<void> _settle(WidgetTester tester, [int steps = 14]) async {
  for (int i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Boots the app. Returns the router once start-up has settled. Records
/// whether Welcome was ever on screen while starting.
Future<GoRouter> _launch(
  WidgetTester tester,
  _Backend backend, {
  _Storage? storage,
  List<bool>? welcomeSeen,
}) async {
  final _Storage store = storage ?? _Storage('test-token');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorageChannel, (MethodCall call) async {
        final Object? arguments = call.arguments;
        final String? key = arguments is Map
            ? arguments['key'] as String?
            : null;
        switch (call.method) {
          case 'read':
            if (store.unreadable) {
              throw PlatformException(code: 'read_error');
            }
            return key == 'pcj_access_token' ? store.token : null;
          case 'write':
            if (key == 'pcj_access_token') {
              store.token = (arguments! as Map)['value'] as String?;
            }
            return null;
          case 'delete':
            if (key == 'pcj_access_token') store.token = null;
            return null;
          case 'readAll':
            return <String, String>{};
          default:
            return null;
        }
      });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  late final AppDependencies dependencies;
  http.runWithClient(
    () => dependencies = AppDependencies.create(),
    () => MockClient(backend.handle),
  );

  await tester.pumpWidget(PcjApp(dependencies: dependencies));
  for (int i = 0; i < 14; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(WelcomePage).evaluate().isNotEmpty) {
      welcomeSeen?.add(true);
    }
  }
  return GoRouter.of(tester.element(find.byType(Navigator).first));
}

String _path(GoRouter router) => router.state.uri.path;

/// Real glyph metrics (Roboto standing in for Inter) so overflow checks
/// behave like a phone instead of the wide square test font.
Future<void> _loadRealFonts() async {
  final String root =
      Platform.environment['FLUTTER_ROOT'] ??
      'C:/flutter_windows_3.41.2-stable/flutter';
  final Directory dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return;
  Future<ByteData> read(String file) async => ByteData.view(
    Uint8List.fromList(await File('${dir.path}/$file').readAsBytes()).buffer,
  );
  for (final String family in <String>[AppTextStyles.fontFamily, 'Roboto']) {
    await (FontLoader(family)
          ..addFont(read('roboto-regular.ttf'))
          ..addFont(read('roboto-medium.ttf'))
          ..addFont(read('roboto-bold.ttf'))
          ..addFont(read('roboto-black.ttf')))
        .load();
  }
  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('materialicons-regular.otf'))).load();
}

void main() {
  setUpAll(_loadRealFonts);

  setUp(() {
    // Phone-sized surface so layouts match a real device.
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1170,
      2532,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 3;
  });

  group('start-up with a stored token', () {
    testWidgets('a valid token opens Home without ever showing Welcome', (
      WidgetTester tester,
    ) async {
      final List<bool> welcomeSeen = <bool>[];
      final GoRouter router = await _launch(
        tester,
        _Backend(),
        welcomeSeen: welcomeSeen,
      );

      expect(_path(router), AppRoutes.home);
      expect(welcomeSeen, isEmpty);
    });

    testWidgets('unreadable secure storage falls back to Welcome', (
      WidgetTester tester,
    ) async {
      final _Storage storage = _Storage('test-token', unreadable: true);
      final GoRouter router = await _launch(
        tester,
        _Backend(),
        storage: storage,
      );

      expect(_path(router), AppRoutes.welcome);
      expect(find.text('Try Again'), findsNothing);
      // The unreadable login was cleared.
      expect(storage.token, isNull);
    });

    testWidgets('no token shows Welcome', (WidgetTester tester) async {
      final GoRouter router = await _launch(
        tester,
        _Backend(),
        storage: _Storage(null),
      );

      expect(_path(router), AppRoutes.welcome);
      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('offline start-up waits on the launch screen with a retry', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..offline = true;
      final GoRouter router = await _launch(tester, backend);

      expect(_path(router), AppRoutes.launch);
      expect(find.byType(LaunchPage), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      backend.offline = false;
      await tester.tap(find.text('Try Again'));
      await _settle(tester);
      expect(_path(router), AppRoutes.home);
    });

    testWidgets('an expired token (401) goes to Welcome, not Home', (
      WidgetTester tester,
    ) async {
      final _Storage storage = _Storage('old-token');
      final GoRouter router = await _launch(
        tester,
        _Backend()..rejectToken = true,
        storage: storage,
      );

      expect(_path(router), AppRoutes.welcome);
      expect(storage.token, isNull);
    });
  });

  group('membership status routing', () {
    testWidgets('EXPIRED goes straight to the payment page', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(
        tester,
        _Backend(membershipStatus: 'EXPIRED', endDate: _day(-3)),
      );

      expect(_path(router), AppRoutes.membershipPayment);
      expect(find.text('Renew Your Membership'), findsOneWidget);
    });

    testWidgets('APPROVED (not paid) goes to the payment page', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(
        tester,
        _Backend(membershipStatus: 'APPROVED'),
      );

      expect(_path(router), AppRoutes.membershipPayment);
    });

    testWidgets('PENDING shows the application under review', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(
        tester,
        _Backend(membershipStatus: 'PENDING'),
      );

      expect(_path(router), AppRoutes.applicationStatus);
      expect(find.text('APPLICATION\nUNDER REVIEW'), findsOneWidget);
    });

    testWidgets(
      'REJECTED shows Application Rejected with support and log out only',
      (WidgetTester tester) async {
        final GoRouter router = await _launch(
          tester,
          _Backend(membershipStatus: 'REJECTED'),
        );

        expect(_path(router), AppRoutes.applicationStatus);
        expect(find.text('APPLICATION\nREJECTED'), findsOneWidget);
        expect(find.text('Log Out'), findsOneWidget);
        expect(find.text('Contact Support'), findsOneWidget);

        await tester.ensureVisible(find.text('Contact Support'));
        await tester.pump();
        await tester.tap(find.text('Contact Support'));
        await _settle(tester);
        expect(find.text('MESSAGE'), findsOneWidget);
        // Members must not learn the draft is addressed to themselves.
        expect(find.textContaining('your own'), findsNothing);
        expect(find.textContaining('member@example.com'), findsNothing);
      },
    );

    for (final String status in <String>['SUSPENDED', 'DEACTIVATED']) {
      testWidgets('$status shows the deactivated notice and signs out', (
        WidgetTester tester,
      ) async {
        final _Storage storage = _Storage('test-token');
        final GoRouter router = await _launch(
          tester,
          _Backend(membershipStatus: status),
          storage: storage,
        );

        expect(find.text('Account Deactivated'), findsOneWidget);
        expect(find.text('Contact Support'), findsOneWidget);
        expect(storage.token, isNull);

        await tester.tap(find.text('OK'));
        await _settle(tester);
        expect(find.text('Account Deactivated'), findsNothing);
        expect(_path(router), AppRoutes.welcome);
      });
    }

    testWidgets('a token rejected mid-session returns to Sign In', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final _Storage storage = _Storage('test-token');
      final GoRouter router = await _launch(tester, backend, storage: storage);
      expect(_path(router), AppRoutes.home);

      backend.rejectToken = true;
      router.go(AppRoutes.offers);
      await _settle(tester);

      expect(_path(router), AppRoutes.signIn);
      expect(
        find.text('Your session has expired. Please sign in again.'),
        findsOneWidget,
      );
      expect(storage.token, isNull);
    });
  });

  group('cart', () {
    testWidgets('quick add from the shop stays on the shop and counts items', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.shop);
      await _settle(tester);

      // Single-variant product: added straight away.
      await tester.tap(find.byTooltip('Add to cart').first);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Added to Cart'), findsOneWidget);
      await _settle(tester, 20);
      expect(find.text('Added to Cart'), findsNothing);
      expect(_path(router), AppRoutes.shop);
      expect(backend.count('POST /member/cart'), 1);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('cart-count-badge')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );

      // Two sizes: a sheet asks which one first.
      await tester.tap(find.byTooltip('Add to cart').at(1));
      await _settle(tester);
      expect(find.text('SIZE'), findsOneWidget);
      await tester.tap(find.text('M'));
      await tester.pump();
      await tester.tap(find.text('Add to Cart'));
      await _settle(tester, 20);

      expect(_path(router), AppRoutes.shop);
      expect(backend.count('POST /member/cart'), 2);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('cart-count-badge')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('adding on product details stays on the page', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.shop);
      await _settle(tester);
      router.push(AppRoutes.productDetailsLocation('2'));
      await _settle(tester);

      await tester.tap(find.text('Add to Cart'));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Added to Cart'), findsOneWidget);
      await _settle(tester, 20);

      expect(_path(router), AppRoutes.productDetailsLocation('2'));
      expect(backend.count('POST /member/cart'), 1);
    });
  });

  group('offers', () {
    testWidgets('an offer can be claimed repeatedly', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.offers);
      await _settle(tester);
      // 'yaser' is a partner offer (the NUQUL tab is selected first).
      await tester.tap(find.text('PARTNERS'));
      await _settle(tester);

      for (int claim = 1; claim <= 2; claim++) {
        await tester.tap(find.text('sad'));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.text('Claimed'), findsOneWidget);
        await _settle(tester, 20);
        expect(find.text('Claimed'), findsNothing);
        expect(backend.count('POST /member/offers/6/claim'), claim);
      }
    });
  });

  group('membership payment', () {
    testWidgets('no payment method is pre-selected', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(membershipStatus: 'APPROVED');
      await _launch(tester, backend);

      await tester.ensureVisible(find.text('Continue to Payment'));
      await tester.pump();
      await tester.tap(find.text('Continue to Payment'));
      await _settle(tester);

      expect(find.text('Choose a payment method to continue.'), findsOneWidget);
      expect(backend.count('POST /member/membership/payment'), 0);
    });

    testWidgets('Apply submits the code immediately', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(membershipStatus: 'APPROVED');
      final GoRouter router = await _launch(tester, backend);

      // The code field sits behind its own row until opened.
      await tester.tap(find.text('Have a gift or referral code?'));
      // Opens, then scrolls itself above the pay bar.
      await _settle(tester, 10);
      await tester.enterText(find.byType(TextField), '123456789012');
      await tester.tap(find.text('Apply'));
      await _settle(tester, 20);

      expect(backend.count('POST /member/pay-membership'), 1);
      expect(_path(router), AppRoutes.home);
    });

    testWidgets('Renew stays locked until two weeks before the end date', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(
        tester,
        _Backend(endDate: _day(30)),
      );
      router.go(AppRoutes.profile);
      await _settle(tester);
      router.push(AppRoutes.membershipSettings);
      await _settle(tester);

      expect(find.textContaining('Available from'), findsOneWidget);
      await tester.tap(find.text('Renew Membership'));
      await _settle(tester, 6);
      // Not in the window yet: a short message instead of the payment page.
      expect(find.text('Your membership is already active'), findsOneWidget);
      expect(find.textContaining('You can renew from'), findsOneWidget);
      expect(_path(router), AppRoutes.membershipSettings);
      await _settle(tester, 40);
    });

    testWidgets('Renew opens the payment page in renewal mode', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(
        tester,
        _Backend(endDate: _day(10)),
      );
      router.go(AppRoutes.profile);
      await _settle(tester);
      router.push(AppRoutes.membershipSettings);
      await _settle(tester);

      await tester.tap(find.text('Renew Membership'));
      await _settle(tester);
      expect(_path(router), AppRoutes.membershipPayment);
      expect(find.text('Renew Your Membership'), findsOneWidget);

      // Back returns to Manage Membership; the member stays signed in.
      await tester.tap(find.byTooltip('Back'));
      await _settle(tester);
      expect(_path(router), AppRoutes.membershipSettings);
    });
  });

  group(
    'rejected application (400 "Membership application was rejected.")',
    () {
      Future<GoRouter> signIn(WidgetTester tester, _Backend backend) async {
        final GoRouter router = await _launch(
          tester,
          backend,
          storage: _Storage(null),
        );
        router.go(AppRoutes.signIn);
        await _settle(tester);
        await tester.enterText(
          find.byType(TextField).at(0),
          'member@example.com',
        );
        await tester.enterText(find.byType(TextField).at(1), 'password1');
        await tester.ensureVisible(find.text('Sign In'));
        await tester.pump();
        await tester.tap(find.text('Sign In'));
        await _settle(tester);
        return router;
      }

      void expectRejectedPage(GoRouter router) {
        expect(_path(router), AppRoutes.applicationStatus);
        expect(find.text('APPLICATION\nREJECTED'), findsOneWidget);
        expect(find.text('Contact Support'), findsOneWidget);
        expect(find.text('Log Out'), findsOneWidget);
      }

      testWidgets('at sign in', (WidgetTester tester) async {
        final GoRouter router = await signIn(
          tester,
          _Backend()..rejectAt = 'login',
        );
        expectRejectedPage(router);
      });

      testWidgets('at the verification code step', (WidgetTester tester) async {
        final GoRouter router = await signIn(
          tester,
          _Backend()..rejectAt = 'otp',
        );
        await tester.enterText(find.byType(TextField).last, '123456');
        await tester.tap(find.text('Verify and Sign In'));
        await _settle(tester);
        expectRejectedPage(router);
      });

      testWidgets('when reopening the app', (WidgetTester tester) async {
        final GoRouter router = await _launch(
          tester,
          _Backend()..rejectAt = 'me',
        );
        expectRejectedPage(router);
      });

      testWidgets('Log Out returns to Welcome', (WidgetTester tester) async {
        final GoRouter router = await signIn(
          tester,
          _Backend()..rejectAt = 'login',
        );
        await tester.ensureVisible(find.text('Log Out'));
        await tester.pump();
        await tester.tap(find.text('Log Out'));
        await _settle(tester);
        expect(_path(router), AppRoutes.welcome);
      });
    },
  );

  group('checkout', () {
    for (final double scale in <double>[1.0, 1.15, 1.3]) {
      testWidgets(
        'placing an order stays in the shop and confirms @ text x$scale',
        (WidgetTester tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final List<String> errors = <String>[];
          final void Function(FlutterErrorDetails)? previous =
              FlutterError.onError;
          FlutterError.onError = (FlutterErrorDetails details) {
            errors.add(details.toString());
          };
          addTearDown(() => FlutterError.onError = previous);
          final _Backend backend = _Backend();
          backend.cart.add(<String, Object?>{
            'cart_item_id': 1,
            'item_id': 1,
            'variant_id': 11,
            'quantity': 1,
            'name': 'PCJ Cap',
            'price': 25,
          });
          final GoRouter router = await _launch(tester, backend);
          router.go(AppRoutes.shop);
          await _settle(tester);
          await tester.tap(find.byTooltip('Cart, 1 items'));
          await _settle(tester);
          expect(_path(router), AppRoutes.checkout);

          await tester.ensureVisible(find.text('Place Order').last);
          await tester.pump();
          await tester.tap(find.text('Place Order').last);
          await _settle(tester);
          // Confirm.
          await tester.tap(find.text('Place Order').last);
          await _settle(tester, 6);
          expect(find.text('Order placed successfully'), findsOneWidget);
          expect(
            find.text('You can track it from My Orders in your Profile.'),
            findsOneWidget,
          );
          await _settle(tester, 40);
          expect(find.text('Order placed successfully'), findsNothing);

          // No automatic jump to My Orders: back in the shop, cart emptied.
          expect(_path(router), AppRoutes.shop);
          expect(backend.count('POST /member/cart/checkout'), 1);
          expect(
            find.byKey(const ValueKey<String>('cart-count-badge')),
            findsOneWidget,
          );
          expect(find.byTooltip('Cart'), findsOneWidget);

          // The order is tracked from Profile -> My Orders.
          router.go(AppRoutes.profile);
          await _settle(tester);
          router.push(AppRoutes.userOrders);
          await _settle(tester, 20);
          expect(_path(router), AppRoutes.userOrders);
          await tester.tap(find.byType(OrderCard).first);
          await _settle(tester, 20);
          await tester.tapAt(const Offset(20, 20));
          await _settle(tester, 20);
          await tester.tap(find.byTooltip('Back'));
          await _settle(tester, 20);
          expect(_path(router), AppRoutes.profile);
          FlutterError.onError = previous;
          for (final String e in errors) {
            // ignore: avoid_print
            print('CAPTURED @$scale: ${e.split('\n').take(40).join('\n')}');
          }
          expect(errors, isEmpty);
        },
      );
    }
  });

  group('fast navigation', () {
    testWidgets('rapid tab switches, pushes and backs do not throw', (
      WidgetTester tester,
    ) async {
      final List<String> errors = <String>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details.toString());
      };
      addTearDown(() => FlutterError.onError = previous);

      final _Backend backend = _Backend();
      backend.orders.add(<String, Object?>{
        'order_id': 55,
        'status': 'PROCESSING',
        'total': 25,
        'payment_method': 'CASH',
        'delivery_method': 'PICKUP',
        'created_at': DateTime.now().toIso8601String(),
      });
      final GoRouter router = await _launch(tester, backend);

      // Deliberately short pumps: taps land mid-transition, like a fast
      // or impatient member.
      Future<void> quick([int frames = 2]) async {
        for (int i = 0; i < frames; i++) {
          await tester.pump(const Duration(milliseconds: 60));
        }
      }

      Finder nav(String label) => find.descendant(
        of: find.byType(AppBottomNavigation),
        matching: find.text(label),
      );
      Finder tooltipStarting(String prefix) => find.byWidgetPredicate(
        (Widget w) => w is Tooltip && (w.message ?? '').startsWith(prefix),
      );
      Future<void> tapIfPresent(Finder finder) async {
        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder.first, warnIfMissed: false);
        }
      }

      for (int round = 0; round < 3; round++) {
        for (final String tab in <String>[
          'SHOP',
          'EVENTS',
          'OFFERS',
          'PROFILE',
          'HOME',
          'SHOP',
        ]) {
          await tapIfPresent(nav(tab));
          await quick(1);
        }
        await quick(4);

        // Shop -> cart -> back, twice in a row.
        await tapIfPresent(tooltipStarting('Cart'));
        await quick();
        await tapIfPresent(find.byTooltip('Back'));
        await tapIfPresent(find.byTooltip('Back'));
        await quick(4);

        // Product -> add to cart -> leave before it finishes.
        await tapIfPresent(find.text('PCJ Cap'));
        await quick(4);
        await tapIfPresent(find.text('Add to Cart'));
        await quick(1);
        await tapIfPresent(find.byTooltip('Back'));
        await quick(4);

        // Quick add from the grid, then switch tab straight away.
        await tapIfPresent(find.byTooltip('Add to cart'));
        await quick(1);
        await tapIfPresent(nav('PROFILE'));
        await quick(4);

        // Profile -> Order History -> order details -> back, fast.
        await tapIfPresent(find.text('Order History'));
        await quick(4);
        await tapIfPresent(find.byType(OrderCard));
        await quick(2);
        await tester.tapAt(const Offset(20, 20));
        await quick(2);
        await tapIfPresent(find.byTooltip('Back'));
        await tapIfPresent(find.byTooltip('Back'));
        await quick(4);

        // Notifications from Home and straight back.
        await tapIfPresent(nav('HOME'));
        await quick(2);
        await tapIfPresent(tooltipStarting('Notifications'));
        await quick(2);
        await tapIfPresent(find.byTooltip('Back'));
        await quick(4);

        // Android system back a few times.
        await tester.binding.handlePopRoute();
        await quick(2);
        await tester.binding.handlePopRoute();
        await quick(4);
      }
      await _settle(tester, 40);

      FlutterError.onError = previous;
      for (final String e in errors) {
        // ignore: avoid_print
        print('CAPTURED: ${e.split('\n').take(60).join('\n')}');
      }
      expect(router, isNotNull);
      expect(errors, isEmpty);
    });
  });

  group('home order tracking', () {
    testWidgets('an order in progress shows on Home and opens its details', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      backend.orders.add(<String, Object?>{
        'order_id': 55,
        'status': 'PROCESSING',
        'total': 25,
        'payment_method': 'CASH',
        'delivery_method': 'PICKUP',
        'created_at': DateTime.now().toIso8601String(),
      });
      await _launch(tester, backend);
      await _settle(tester);

      expect(find.text('Track Your Order'), findsOneWidget);
      expect(find.text('ORDER #55'), findsOneWidget);
      expect(find.text('Next: Ready for Pickup'), findsOneWidget);

      await tester.tap(find.text('ORDER #55'));
      await _settle(tester);
      expect(find.text('Order #55'), findsOneWidget);
    });

    testWidgets('no order in progress: no tracking card', (
      WidgetTester tester,
    ) async {
      await _launch(tester, _Backend());
      await _settle(tester);
      expect(find.text('Track Your Order'), findsNothing);
    });
  });

  group('events page', () {
    testWidgets('past events have no featured event; dots stay at five', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(tester, _Backend());
      router.go(AppRoutes.events);
      await _settle(tester, 20);

      // Upcoming: featured event shown; 8 events but only 5 dots visible.
      expect(find.byType(FeaturedEvent), findsOneWidget);
      final Iterable<AnimatedOpacity> dots = tester.widgetList<AnimatedOpacity>(
        find.descendant(
          of: find.byType(AppPageDots),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(dots.length, 8);
      expect(dots.where((AnimatedOpacity o) => o.opacity > 0).length, 5);

      await tester.tap(find.text('PAST EVENTS'));
      await _settle(tester, 20);
      expect(find.byType(FeaturedEvent), findsNothing);
      expect(find.text('Past Meet 1'), findsWidgets);
    });
  });

  group('help and support', () {
    testWidgets(
      'the sheet opens above the nav bar and its button is tappable',
      (WidgetTester tester) async {
        final GoRouter router = await _launch(tester, _Backend());
        router.go(AppRoutes.profile);
        await _settle(tester, 20);
        await tester.ensureVisible(find.text('Help & Support'));
        await tester.pump();
        await tester.tap(find.text('Help & Support'));
        await _settle(tester, 20);

        expect(find.text('Contact Support'), findsOneWidget);
        // With an empty message, a tap that reaches the button shows the
        // validation message; a tap blocked by the nav bar would not.
        await tester.tap(find.text('Open Email'));
        await _settle(tester);
        expect(find.text('Please enter a message.'), findsOneWidget);
      },
    );
  });

  group('event details', () {
    testWidgets('weather shows temperature, rain chance and wind', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..maxGuestCount = 2;
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);

      expect(find.text('WEATHER'), findsOneWidget);
      expect(find.text('CURRENT'), findsNothing);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('7 km/h'), findsOneWidget);
      expect(find.text('TOTAL SPOTS'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('GUESTS PER MEMBER'), findsOneWidget);
      expect(find.text('Open in Google Maps'), findsOneWidget);
    });

    testWidgets('no guests: members only', (WidgetTester tester) async {
      final _Backend backend = _Backend()..maxGuestCount = 0;
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);

      expect(find.text('Members only'), findsOneWidget);
    });
  });

  group('event guests', () {
    for (final (int? max, bool shown) in <(int?, bool)>[
      (0, false),
      (null, false),
      (2, true),
    ]) {
      final String state = shown ? 'shown' : 'hidden';
      testWidgets('Max_guest_count ${max ?? 'missing'}: Add Guests $state', (
        WidgetTester tester,
      ) async {
        final _Backend backend = _Backend()..maxGuestCount = max;
        final GoRouter router = await _launch(tester, backend);
        router.go(AppRoutes.eventRegistrationLocation('e7'));
        await _settle(tester);

        expect(find.text('DEAD SEA DRIVE'), findsOneWidget);
        expect(
          find.text('Additional Guests'),
          shown ? findsOneWidget : findsNothing,
        );
        expect(
          find.byTooltip('Add guest'),
          shown ? findsOneWidget : findsNothing,
        );
      });
    }
  });
}
