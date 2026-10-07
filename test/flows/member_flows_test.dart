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
import 'package:image_picker/image_picker.dart';
import 'package:pcj_v5/app.dart';
import 'package:pcj_v5/core/dependencies/app_dependencies.dart';
import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/services/biometric_sign_in.dart';
import 'package:pcj_v5/core/services/image_picker_service.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/features/auth/presentation/pages/launch_page.dart';
import 'package:pcj_v5/features/auth/presentation/pages/welcome_page.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/features/events/presentation/widgets/event_details_widgets.dart';
import 'package:pcj_v5/features/events/presentation/widgets/event_page_widgets.dart';
import 'package:pcj_v5/features/events/presentation/widgets/featured_event.dart';
import 'package:pcj_v5/features/shop/presentation/widgets/product_details_widgets.dart';
import 'package:pcj_v5/features/user_orders/presentation/widgets/order_thumbnail.dart';
import 'package:pcj_v5/features/user_orders/presentation/widgets/user_orders_widgets.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

  /// Everything else kept in secure storage, such as saved ticket QRs.
  final Map<String, String> values = <String, String>{};

  /// Simulates secure storage that throws on every read.
  bool unreadable;
}

/// Stands in for the phone's Face ID.
class _FaceId implements BiometricPrompt {
  bool approve = true;
  int prompts = 0;

  @override
  Future<String?> availableName() async => 'Face ID';

  @override
  Future<bool> confirm(String reason) async {
    prompts++;
    return approve;
  }
}

class _Backend {
  _Backend({this.membershipStatus = 'ACTIVE', String? endDate})
    : endDate = endDate ?? _day(365);

  String membershipStatus;
  String? endDate;
  bool offline = false;
  bool rejectToken = false;

  /// The 401 message while [rejectToken] is set; anything other than an
  /// expired token means the account is gone.
  String rejectTokenMessage = 'Token has expired.';

  /// `Max_guest_count` on /member/events/e7; null leaves the field out.
  int? maxGuestCount;

  /// How far ahead /member/events/e7 starts.
  int eventStartsInDays = 20;

  /// Set: e7 is a paid event at this price (per member and per guest).
  double? eventPrice;

  /// GET /member/CLIQ answers with this alias; null answers 404.
  String? cliqAlias;

  /// The last CliQ payment form (event, order or membership) and where it
  /// went.
  Map<String, String>? cliqFields;
  bool cliqHadPhoto = false;
  String? cliqPath;

  /// While set, every CliQ payment is refused.
  bool cliqFails = false;

  /// While set, /weather answers 500.
  bool weatherFails = false;

  /// Where event e7 takes place, and the place the last GET /weather asked
  /// about.
  String eventLocation = 'Amman';
  String? weatherLocation;

  /// A status for /auth/login to refuse every password with (e.g. 401).
  int? loginStatus;

  /// While set, /auth/login answers 400 "Please verify your email address
  /// first." (registered, code never entered).
  bool emailUnverified = false;

  /// While set, /auth/login answers 400 "Waiting for admin approval.".
  bool pendingApproval = false;

  /// While set, /auth/login answers 404 "User not found." (the account was
  /// removed).
  bool accountRemoved = false;

  /// Where the backend answers 400 "Membership application was rejected."
  /// ('login', 'otp' or 'me'); null for a normal member.
  String? rejectAt;

  static final http.Response _rejected = _json(<String, Object>{
    'detail': 'Membership application was rejected.',
  }, 400);
  final List<String> calls = <String>[];
  final List<Map<String, Object?>> cart = <Map<String, Object?>>[];
  final List<Map<String, Object?>> orders = <Map<String, Object?>>[];

  /// The items GET /member/orders/55 adds to that order.
  final List<Map<String, Object?>> orderItems = <Map<String, Object?>>[];
  final List<Map<String, Object?>> rsvps = <Map<String, Object?>>[];

  /// The member's cars, listed by GET /member/cars.
  final List<Map<String, Object?>> cars = <Map<String, Object?>>[];

  /// Text fields and whether a photo came with the last car request.
  Map<String, String> lastCarFields = <String, String>{};
  bool lastCarHadPhoto = false;

  void _readCarForm(http.Request request) {
    final String body = latin1.decode(request.bodyBytes);
    lastCarFields = <String, String>{
      for (final RegExpMatch m in RegExp(
        r'name="([^"]+)"\r\n\r\n([^\r]*)',
      ).allMatches(body))
        m.group(1)!: m.group(2)!,
    };
    lastCarHadPhoto = body.contains('name="license_plate_photo"; filename=');
  }

  /// Stock of the cap's only variant, and of the tee in M.
  int capStock = 5;
  int teeMediumStock = 5;

  /// While set, checkout leaves the ordered items in the cart.
  bool checkoutKeepsCart = false;

  Map<String, Object?> get _cap => <String, Object?>{
    'id': 1,
    'name': 'PCJ Cap',
    'price': 25,
    'variants': <Map<String, Object?>>[
      <String, Object?>{'id': 11, 'stock': capStock, 'color': 'Black'},
    ],
  };

  Map<String, Object?> get _tee => <String, Object?>{
    'id': 2,
    'name': 'PCJ Tee',
    'price': 30,
    'variants': <Map<String, Object?>>[
      <String, Object?>{'id': 21, 'stock': 5, 'color': 'Black', 'size': 'S'},
      <String, Object?>{
        'id': 22,
        'stock': teeMediumStock,
        'color': 'Black',
        'size': 'M',
      },
    ],
  };

  int count(String call) => calls.where((String c) => c == call).length;

  /// Fields of the last checkout request.
  Map<String, String>? checkoutFields;

  /// The last POST /auth/login and POST /auth/reset-password fields.
  Map<String, String>? loginFields;
  Map<String, String>? resetFields;

  /// The last RSVP body sent to POST /member/events/e7/rsvp.
  Map<String, Object?>? rsvpBody;

  /// GET /member/notifications.
  final List<Map<String, Object?>> notifications = <Map<String, Object?>>[];

  static bool _isForm(http.Request request) =>
      request.headers['content-type']?.startsWith(
        'application/x-www-form-urlencoded',
      ) ??
      false;

  Future<http.Response> handle(http.Request request) async {
    final String call = '${request.method} ${request.url.path}';
    calls.add(call);
    if (offline) throw http.ClientException('offline');
    if (rejectToken && request.headers.containsKey('Authorization')) {
      return _json(<String, Object>{'detail': rejectTokenMessage}, 401);
    }
    switch (call) {
      case 'POST /auth/login':
        loginFields = request.bodyFields;
        if (loginStatus != null) {
          return _json(<String, Object>{
            'detail': 'Incorrect password.',
          }, loginStatus!);
        }
        if (rejectAt == 'login') return _rejected;
        if (accountRemoved) {
          return _json(<String, Object>{'detail': 'User not found.'}, 404);
        }
        if (emailUnverified) {
          return _json(<String, Object>{
            'detail': 'Please verify your email address first.',
          }, 400);
        }
        if (pendingApproval) {
          return _json(<String, Object>{
            'detail': 'Waiting for admin approval.',
          }, 400);
        }
        return _json(<String, Object>{'message': 'OTP sent.'});
      case 'POST /auth/resend-otp':
        return _json(<String, Object>{'message': 'OTP sent.'});
      case 'POST /auth/verify-otp':
        if (rejectAt == 'otp') return _rejected;
        if (request.bodyFields['purpose'] == 'register') {
          emailUnverified = false;
          return _json(<String, Object>{'message': 'Email verified.'});
        }
        if (request.bodyFields['purpose'] == 'forgot_password') {
          return _json(<String, Object>{'reset_token': 'reset-abc'});
        }
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
      case 'POST /member/membership/payment':
        // Stands in for a payment the backend confirms straight away.
        membershipStatus = 'ACTIVE';
        endDate = _day(400);
        return _json(<String, Object>{'message': 'Payment confirmed.'});
      case 'POST /member/pay-membership':
        membershipStatus = 'ACTIVE';
        endDate = _day(400);
        return _json(<String, Object>{'message': 'Membership activated.'});
      case 'GET /member/events/e7':
        return _json(<String, Object?>{
          'id': 'e7',
          'title': 'Dead Sea Drive',
          'start_at': DateTime.now()
              .add(Duration(days: eventStartsInDays))
              .toIso8601String(),
          'capacity': 40,
          'location': eventLocation,
          'Max_guest_count': ?maxGuestCount,
          'is_paid': eventPrice != null,
          'price': eventPrice ?? 0,
        });
      case 'GET /member/CLIQ' when cliqAlias != null:
        return _json(<String, Object?>{'CLIQ': cliqAlias});
      case final String key
          when key == 'POST /member/cliq' ||
              key == 'POST /member/membership/cliq' ||
              (key.startsWith('POST /member/events/') && key.endsWith('/cliq')):
        final String form = latin1.decode(request.bodyBytes);
        cliqPath = request.url.path;
        cliqFields = <String, String>{
          for (final RegExpMatch m in RegExp(
            r'name="([^"]+)"\r\n\r\n([^\r]*)',
          ).allMatches(form))
            m.group(1)!: m.group(2)!,
        };
        cliqHadPhoto = form.contains('name="photo"; filename=');
        if (cliqFails) {
          return _json(<String, Object>{'detail': 'Payment failed.'}, 500);
        }
        // A paid RSVP waits for an admin once its payment is sent.
        if (cliqPath!.startsWith('/member/events/')) {
          final String rsvpId = cliqPath!.split('/')[3];
          for (final Map<String, Object?> row in rsvps) {
            if ('${row['rsvp_id']}' == rsvpId) {
              row['rsvp_status'] = 'WAITING_ADMIN_APPROVAL';
            }
          }
          return _json(<String, Object?>{
            'message': 'CLIQ payment submitted successfully.',
            'rsvp_id': int.parse(rsvpId),
            'payment_status': 'PENDING',
            'rsvp_status': 'WAITING_ADMIN_APPROVAL',
          });
        }
        return _json(<String, Object?>{
          'message':
              'CLIQ payment submitted successfully. Waiting for admin '
              'approval.',
          'payment_id': 90,
          'payment_method': 'CLIQ',
          'payment_status': 'PENDING',
          'transaction_number': cliqFields!['transaction_number'],
          'cliq_refund_name': cliqFields!['cliq_refund_name'],
        });
      case 'GET /weather':
        weatherLocation = request.url.queryParameters['location'];
        if (weatherFails) {
          return _json(<String, Object>{'detail': 'Location not found'}, 404);
        }
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
      case 'GET /member/items/1':
        return _json(_cap);
      case 'GET /member/items/2':
        return _json(_tee);
      case 'GET /member/cart':
        return _json(<String, Object>{'items': cart});
      // Form endpoints, as documented in /openapi.json: JSON is refused.
      case 'POST /member/cart' || 'POST /member/cart/checkout'
          when !_isForm(request):
        return _json(<String, Object>{'detail': 'Form data expected.'}, 422);
      case 'POST /member/cart':
        final Map<String, String> body = request.bodyFields;
        cart.add(<String, Object?>{
          'cart_item_id': cart.length + 1,
          'item_id': body['variant_id'] == '11' ? 1 : 2,
          'variant_id': int.parse(body['variant_id']!),
          'quantity': int.parse(body['quantity']!),
          'name': 'Item',
          'price': 25,
        });
        return _json(<String, Object>{'message': 'Added.'});
      case 'POST /member/cart/checkout':
        checkoutFields = request.bodyFields;
        if (!checkoutKeepsCart) cart.clear();
        final bool payByCliq = checkoutFields!['payment_method'] == 'CLIQ';
        orders.insert(0, <String, Object?>{
          'order_id': 55,
          'status': payByCliq ? 'PENDING_PAYMENT' : 'PENDING',
          'total': 25,
          'payment_method': payByCliq ? 'CLIQ' : 'CASH',
          'payment_status': 'PENDING',
          'delivery_method': 'PICKUP',
          'created_at': DateTime.now().toIso8601String(),
          if (payByCliq) 'payment_id': 90,
        });
        if (payByCliq) {
          // Sample response supplied by the backend.
          return _json(<String, Object?>{
            'message': 'Order created. Please submit your CLIQ payment.',
            'order_id': 55,
            'payment_id': 90,
            'total': 25,
            'delivery_fee': 0,
            'payment_method': 'CLIQ',
            'payment_status': 'PENDING',
            'order_status': 'PENDING_PAYMENT',
            'requires_cliq_payment': true,
          });
        }
        return _json(<String, Object?>{
          ...orders.first,
          'message': 'Order placed successfully.',
        });
      case 'GET /member/orders':
        return _json(orders);
      case 'PATCH /member/orders/55/cancel':
        orders.first['status'] = 'CANCELLED';
        return _json(<String, Object?>{
          'message': 'Order cancelled.',
          'order_id': 55,
          'status': 'CANCELLED',
        });
      case 'GET /member/orders/55':
        return _json(<String, Object?>{...orders.first, 'items': orderItems});
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
          <String, Object>{
            'offer_id': 7,
            'partner': 'NUQUL',
            'title': 'Nuqul Member Deal',
            'offer_details': 'For club members.',
            'discount': 10,
            'expiry_date': '2026-10-29',
          },
        ]);
      case 'POST /member/offers/6/claim':
        return _json(<String, Object>{'message': 'Offer claimed.'});
      case 'POST /auth/logout':
        return _json(<String, Object>{'message': 'Logged out.'});
      case 'POST /auth/forgot-password':
        return _json(<String, Object>{'message': 'OTP sent.'});
      case 'GET /member/notifications':
        return _json(notifications);
      case final String patch when patch.startsWith('PATCH /notifications/'):
        final String id = patch.split('/')[2];
        for (final Map<String, Object?> item in notifications) {
          if ('${item['id']}' == id) item['is_read'] = true;
        }
        return _json(<String, Object>{'message': 'Marked as read.'});
      case 'POST /auth/reset-password':
        resetFields = request.bodyFields;
        return _json(<String, Object>{'message': 'Password reset.'});
      case 'POST /member/events/e7/rsvp':
        rsvpBody = Map<String, Object?>.from(jsonDecode(request.body) as Map);
        // Row shape of GET /member/events, as supplied by the backend.
        rsvps.add(<String, Object?>{
          'event_id': 'e7',
          'title': 'Dead Sea Drive',
          'location': 'Amman',
          'start_at': DateTime.now()
              .add(const Duration(days: 20))
              .toIso8601String(),
          'capacity': 40,
          'rsvp_status': eventPrice == null ? 'CONFIRMED' : 'PENDING_PAYMENT',
          'guest_count': rsvpBody!['guest_count'],
          'guest_names': rsvpBody!['guest_names'],
          'is_paid': true,
          'attendance_status': 'Not Checked In',
          if (eventPrice != null) ...<String, Object?>{
            'rsvp_id': 104,
            'payment_status': 'PENDING_PAYMENT',
            'price': eventPrice,
            'amount': eventPrice! * (1 + (rsvpBody!['guest_count']! as int)),
          },
        });
        return _json(rsvps.last);
      case 'GET /member/events':
        return _json(rsvps);
      case 'DELETE /member/events/e7/rsvp':
        rsvps.removeWhere(
          (Map<String, Object?> row) => row['event_id'] == 'e7',
        );
        return _json(<String, Object>{'message': 'RSVP cancelled.'});
      case 'GET /member/events/e7/qr':
        // Issuing the QR marks the ticket as opened.
        if (rsvps.isNotEmpty &&
            rsvps.last['attendance_status'] == 'Not Checked In') {
          rsvps.last['attendance_status'] = 'PARTIALLY_CHECKED_IN';
        }
        // As the backend sends it for an event in My Events.
        return _json(<String, Object?>{
          'event_id': 38,
          'event_name': 'Dead Sea Drive',
          'status': 'CONFIRMED',
          'attendance_status': rsvps.isEmpty
              ? 'Not Checked In'
              : rsvps.last['attendance_status'],
          'is_paid': true,
          'qr_token': 'signed-ticket-token',
        });
      case 'GET /member/cars':
        return _json(<String, Object?>{'cars': cars});
      case 'PUT /member/cars/1':
        _readCarForm(request);
        cars[0] = <String, Object?>{
          ...cars[0],
          'VIN_Number': lastCarFields['VIN_Number'],
          'model': lastCarFields['model'],
          'year': int.parse(lastCarFields['year']!),
          'License_Plate': lastCarFields['License_Plate'],
        };
        return _json(<String, Object>{'message': 'Car updated.'});
      case 'DELETE /member/cars/1':
        cars.removeWhere((Map<String, Object?> car) => car['id'] == 1);
        return _json(<String, Object>{'message': 'Car deleted.'});
      case final String delete when delete.startsWith('DELETE /member/cart/'):
        final String id = delete.split('/').last;
        cart.removeWhere(
          (Map<String, Object?> item) => '${item['cart_item_id']}' == id,
        );
        return _json(<String, Object>{'message': 'Removed.'});
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

/// A My Events row for a paid event.
Map<String, Object?> _paidRow({
  required String eventId,
  required String title,
  required String status,
  required String payment,
}) => <String, Object?>{
  'event_id': eventId,
  'rsvp_id': 200 + int.parse(eventId.substring(1)),
  'title': title,
  'location': 'Amman',
  'start_at': DateTime.now().add(const Duration(days: 20)).toIso8601String(),
  'capacity': 40,
  'price': 10,
  'rsvp_status': status,
  'payment_status': payment,
  'guest_count': 0,
  'guest_names': <Object?>[],
  'is_paid': true,
  'attendance_status': 'Not Checked In',
};

/// Hands back a small PNG, as if picked from the library.
class _Picker extends ImagePickerService {
  @override
  Future<XFile?> pickFromGallery() async => XFile.fromData(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
      '60e6kgAAAABJRU5ErkJggg==',
    ),
    name: 'receipt.png',
  );
}

/// Boots the app. Returns the router once start-up has settled. Records
/// whether Welcome was ever on screen while starting.
Future<GoRouter> _launch(
  WidgetTester tester,
  _Backend backend, {
  _Storage? storage,
  List<bool>? welcomeSeen,
  BiometricPrompt? biometrics,
  ImagePickerService? picker,
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
            return key == 'pcj_access_token' ? store.token : store.values[key];
          case 'write':
            final String? value = (arguments! as Map)['value'] as String?;
            if (key == 'pcj_access_token') {
              store.token = value;
            } else if (key != null && value != null) {
              store.values[key] = value;
            }
            return null;
          case 'delete':
            if (key == 'pcj_access_token') store.token = null;
            store.values.remove(key);
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
    () => dependencies = AppDependencies.create(
      biometricPrompt: biometrics,
      imagePicker: picker,
    ),
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
    testWidgets('EXPIRED goes straight to the renewal page', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(
        tester,
        _Backend(membershipStatus: 'EXPIRED', endDate: _day(-3)),
      );

      expect(_path(router), AppRoutes.membershipRenewal);
      expect(find.text('Welcome back, Test'), findsOneWidget);
      expect(find.text('EXPIRED'), findsOneWidget);
      expect(find.text('Complete Your Membership'), findsNothing);
    });

    testWidgets('renewing an expired membership opens Home', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(
        membershipStatus: 'EXPIRED',
        endDate: _day(-3),
      );
      final GoRouter router = await _launch(tester, backend);

      await tester.ensureVisible(find.text('CliQ'));
      await tester.pump();
      await tester.tap(find.text('CliQ'));
      await tester.pump();
      await tester.tap(find.text('Renew Membership'));
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Membership Renewed'), findsOneWidget);
      await _settle(tester, 30);

      expect(backend.count('POST /member/membership/payment'), 1);
      expect(_path(router), AppRoutes.home);
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
        // In the notice; Welcome underneath has its own support link.
        expect(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.text('Contact Support'),
          ),
          findsOneWidget,
        );
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
      // Offers are cached; the next status check is refused.
      await tester.pump(const Duration(seconds: 11));
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

    testWidgets('a sold-out item is tagged and cannot be added', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..capStock = 0;
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.shop);
      await _settle(tester);

      expect(find.text('SOLD OUT'), findsOneWidget);
      await tester.tap(find.byTooltip('Add to cart').first);
      await _settle(tester);
      expect(backend.count('POST /member/cart'), 0);

      router.push(AppRoutes.productDetailsLocation('1'));
      await _settle(tester);
      expect(find.text('Sold Out'), findsOneWidget);
      expect(find.text('Add to Cart'), findsNothing);
    });

    testWidgets('quantity stops at the stock not already in the cart', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..capStock = 3;
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
      router.push(AppRoutes.productDetailsLocation('1'));
      await _settle(tester);

      // 3 in stock, 1 already in the cart: 2 at most.
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byTooltip('Increase quantity'));
        await _settle(tester);
      }
      expect(
        find.descendant(
          of: find.byType(QuantitySelector),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Add to Cart'));
      await _settle(tester, 20);
      expect(backend.cart.last['quantity'], 2);

      // All 3 are in the cart now.
      expect(find.text('All in Your Cart'), findsOneWidget);
      expect(find.text('Add to Cart'), findsNothing);
    });
  });

  group('swipe back on iOS', () {
    testWidgets('a page opened on top swipes back', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(tester, _Backend());
      router.go(AppRoutes.shop);
      await _settle(tester);
      router.push(AppRoutes.productDetailsLocation('2'));
      await _settle(tester);
      expect(_path(router), AppRoutes.productDetailsLocation('2'));

      await tester.dragFrom(const Offset(4, 400), const Offset(380, 0));
      await _settle(tester);

      expect(_path(router), AppRoutes.shop);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('the payment page does not swipe away', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(
        tester,
        _Backend(membershipStatus: 'APPROVED'),
      );
      expect(_path(router), AppRoutes.membershipPayment);

      await tester.dragFrom(const Offset(4, 400), const Offset(380, 0));
      await _settle(tester);

      expect(_path(router), AppRoutes.membershipPayment);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('checkout', () {
    testWidgets('the cart is emptied after an order, even if the server '
        'keeps it', (WidgetTester tester) async {
      final _Backend backend = _Backend()..checkoutKeepsCart = true;
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
      router.push(AppRoutes.checkout);
      await _settle(tester);
      await tester.ensureVisible(find.text('Place Order').last);
      await tester.pump();
      await tester.tap(find.text('Place Order').last);
      await _settle(tester);
      await tester.tap(find.text('Place Order').last);
      await _settle(tester, 40);

      expect(backend.count('DELETE /member/cart/1'), 1);
      expect(backend.cart, isEmpty);
      expect(find.byTooltip('Cart'), findsOneWidget);
    });

    testWidgets('a sold-out size shows but cannot be chosen', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..teeMediumStock = 0;
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.shop);
      await _settle(tester);
      router.push(AppRoutes.productDetailsLocation('2'));
      await _settle(tester);

      expect(find.text('M'), findsOneWidget);
      await tester.tap(find.text('M'));
      await _settle(tester);
      await tester.tap(find.text('Add to Cart'));
      await _settle(tester, 20);

      // Still size S.
      expect(backend.cart.last['variant_id'], 21);
    });

    testWidgets('delivery adds 2 JOD; a CliQ order is paid next', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..cliqAlias = 'PCJCLUB';
      backend.cart.add(<String, Object?>{
        'cart_item_id': 1,
        'item_id': 1,
        'variant_id': 11,
        'quantity': 1,
        'name': 'PCJ Cap',
        'price': 25,
      });
      final GoRouter router = await _launch(tester, backend, picker: _Picker());
      router.go(AppRoutes.shop);
      await _settle(tester);
      router.push(AppRoutes.checkout);
      await _settle(tester);

      // Picked up: free.
      expect(find.text('Pick up'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('25.00 JOD'), findsWidgets);

      await tester.tap(find.text('DELIVERY'));
      await _settle(tester);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('2.00 JOD'), findsOneWidget);
      expect(find.text('27.00 JOD'), findsOneWidget);

      // Online is not offered yet.
      await tester.tap(find.text('PICK UP'));
      await _settle(tester);
      await tester.ensureVisible(find.text('ONLINE'));
      await tester.pump();
      await tester.tap(find.text('ONLINE'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('COMING SOON'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 400));

      // Paying with CliQ: nothing is ordered until the payment is sent.
      await tester.ensureVisible(find.text('CLIQ'));
      await tester.pump();
      await tester.tap(find.text('CLIQ'));
      await _settle(tester);
      await tester.ensureVisible(find.text('Continue to Payment'));
      await tester.pump();
      await tester.tap(find.text('Continue to Payment'));
      await _settle(tester, 20);

      expect(_path(router), AppRoutes.orderPayment);
      expect(backend.count('POST /member/cart/checkout'), 0);
      expect(find.text('PCJCLUB'), findsOneWidget);
      expect(find.text('25.00 JOD'), findsOneWidget);
      expect(find.text('Refunds go to this alias'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'TX-31');
      await tester.enterText(find.byType(TextField).at(1), 'MEMBER1');
      for (final String label in <String>[
        'Upload Receipt Screenshot',
        'Choose from Library',
        'Submit Payment',
      ]) {
        await tester.ensureVisible(find.text(label).last);
        await tester.pump();
        await tester.tap(find.text(label).last);
        await _settle(tester, 20);
      }

      expect(backend.checkoutFields, <String, String>{
        'delivery_method': 'PICKUP',
        'payment_method': 'CLIQ',
      });
      expect(backend.cliqPath, '/member/cliq');
      expect(backend.cliqFields, <String, String>{
        'payment_id': '90',
        'transaction_number': 'TX-31',
        'cliq_refund_name': 'MEMBER1',
      });
      expect(backend.cliqHadPhoto, isTrue);
      expect(_path(router), AppRoutes.shop);

      // The order stays PENDING_PAYMENT until an admin confirms it.
      router.push(AppRoutes.userOrders);
      await _settle(tester);
      expect(find.text('PAYMENT UNDER REVIEW'), findsOneWidget);
    });

    testWidgets('a failed CliQ payment cancels the order', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()
        ..cliqAlias = 'PCJCLUB'
        ..cliqFails = true;
      backend.cart.add(<String, Object?>{
        'cart_item_id': 1,
        'item_id': 1,
        'variant_id': 11,
        'quantity': 2,
        'name': 'PCJ Cap',
        'price': 25,
      });
      final GoRouter router = await _launch(tester, backend, picker: _Picker());
      router.go(AppRoutes.shop);
      await _settle(tester);
      router.push(AppRoutes.checkout);
      await _settle(tester);
      await tester.ensureVisible(find.text('CLIQ'));
      await tester.pump();
      await tester.tap(find.text('CLIQ'));
      await _settle(tester);
      await tester.ensureVisible(find.text('Continue to Payment'));
      await tester.pump();
      await tester.tap(find.text('Continue to Payment'));
      await _settle(tester, 20);

      await tester.enterText(find.byType(TextField).at(0), 'TX-31');
      await tester.enterText(find.byType(TextField).at(1), 'MEMBER1');
      for (final String label in <String>[
        'Upload Receipt Screenshot',
        'Choose from Library',
      ]) {
        await tester.ensureVisible(find.text(label).last);
        await tester.pump();
        await tester.tap(find.text(label).last);
        await _settle(tester, 20);
      }
      await tester.ensureVisible(find.text('Submit Payment'));
      await tester.pump();
      await tester.tap(find.text('Submit Payment'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Cancelled at once; the cap is back in the cart.
      expect(backend.count('POST /member/cart/checkout'), 1);
      expect(backend.count('PATCH /member/orders/55/cancel'), 1);
      expect(backend.orders.first['status'], 'CANCELLED');
      expect(backend.cart.single['variant_id'], 11);
      expect(backend.cart.single['quantity'], 2);
      expect(
        find.text(
          'Your payment could not be sent, so your order was not placed. '
          'Please try again.',
        ),
        findsOneWidget,
      );
      expect(_path(router), AppRoutes.orderPayment);
      await _settle(tester, 20);
    });

    testWidgets('cancelling a processing CliQ order mentions the refund', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      backend.orders.add(<String, Object?>{
        'order_id': 55,
        'status': 'PROCESSING',
        'total': 25,
        'payment_method': 'CLIQ',
        'payment_status': 'PAID',
        'delivery_method': 'PICKUP',
        'created_at': DateTime.now().toIso8601String(),
      });
      final GoRouter router = await _launch(tester, backend);
      router.push(AppRoutes.userOrders);
      await _settle(tester);
      await tester.tap(find.text('#55'));
      await _settle(tester);
      await tester.ensureVisible(find.text('Cancel Order'));
      await tester.pump();
      await tester.tap(find.text('Cancel Order'));
      await _settle(tester);

      expect(
        find.text(
          'Order #55 will be cancelled, and your payment refunded to the '
          'CliQ alias you gave when paying.',
        ),
        findsOneWidget,
      );
    });
  });

  group('paid events', () {
    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text).last);
      await tester.pump();
      await tester.tap(find.text(text).last);
      await _settle(tester);
    }

    testWidgets('a paid RSVP is paid with CliQ, then waits for an admin', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()
        ..eventPrice = 10
        ..maxGuestCount = 1
        ..cliqAlias = 'PCJCLUB';
      final GoRouter router = await _launch(tester, backend, picker: _Picker());
      router.go(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);
      router.push(AppRoutes.eventRegistrationLocation('e7'));
      await _settle(tester);

      // The member and a guest, 10 JOD each; cards are not offered yet.
      await tapText(tester, 'Add a Guest');
      await tester.enterText(find.byType(TextField).at(0), 'Lina Haddad');
      await _settle(tester);
      expect(find.text('20.00 JOD'), findsWidgets);
      expect(find.text('CliQ'), findsOneWidget);
      expect(find.text('Credit or debit card'), findsOneWidget);
      await tapText(tester, 'Continue to Payment');
      await tapText(tester, 'I Understand');
      await _settle(tester, 20);

      // Nothing is sent until the payment is.
      expect(_path(router), AppRoutes.eventPaymentLocation('e7'));
      expect(backend.count('POST /member/events/e7/rsvp'), 0);
      expect(find.text('Pay with CliQ'), findsOneWidget);
      expect(find.text('PCJCLUB'), findsOneWidget);
      expect(find.text('20.00 JOD'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), 'TX-778');
      await tester.enterText(find.byType(TextField).at(1), 'MEMBER1');
      await tapText(tester, 'Upload Receipt Screenshot');
      await tapText(tester, 'Choose from Library');
      await tapText(tester, 'Submit Payment');
      await _settle(tester, 20);

      expect(backend.rsvpBody, <String, Object?>{
        'guest_count': 1,
        'guest_names': <Object?>['Lina Haddad'],
      });
      expect(backend.cliqFields, <String, String>{
        'transaction_number': 'TX-778',
        'cliq_refund_name': 'MEMBER1',
      });
      expect(backend.cliqHadPhoto, isTrue);
      expect(_path(router), AppRoutes.eventDetailsLocation('e7'));
      expect(find.text('Payment under review'), findsOneWidget);
      expect(find.text('View Ticket'), findsNothing);

      // The row still says PENDING_PAYMENT: it is under review.
      router.go(AppRoutes.userEvents);
      await _settle(tester, 20);
      expect(find.text('PAYMENT UNDER REVIEW'), findsOneWidget);
    });

    testWidgets('a failed CliQ payment cancels the RSVP', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()
        ..eventPrice = 10
        ..cliqAlias = 'PCJCLUB'
        ..cliqFails = true;
      final GoRouter router = await _launch(tester, backend, picker: _Picker());
      router.go(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);
      router.push(AppRoutes.eventRegistrationLocation('e7'));
      await _settle(tester);
      await tapText(tester, 'Continue to Payment');
      await _settle(tester, 20);

      await tester.enterText(find.byType(TextField).at(0), 'TX-1');
      await tester.enterText(find.byType(TextField).at(1), 'MEMBER1');
      await tapText(tester, 'Upload Receipt Screenshot');
      await tapText(tester, 'Choose from Library');
      await tester.ensureVisible(find.text('Submit Payment'));
      await tester.pump();
      await tester.tap(find.text('Submit Payment'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(backend.count('POST /member/events/e7/rsvp'), 1);
      expect(backend.count('DELETE /member/events/e7/rsvp'), 1);
      expect(backend.rsvps, isEmpty);
      expect(
        find.text(
          'Your payment could not be sent, so you were not registered. '
          'Please try again.',
        ),
        findsOneWidget,
      );
      expect(_path(router), AppRoutes.eventPaymentLocation('e7'));
      await _settle(tester, 20);
    });

    testWidgets('a rejected payment says so, with support', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..eventPrice = 10;
      backend.rsvps.add(
        _paidRow(
          eventId: 'e7',
          title: 'Dead Sea Drive',
          status: 'REJECTED',
          payment: 'REJECTED',
        ),
      );
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);

      expect(find.text('Payment Rejected'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Contact Support'),
        ),
      );
      await _settle(tester);
      expect(find.text('MESSAGE'), findsOneWidget);
    });

    testWidgets('after a rejected payment the member registers again', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()
        ..eventPrice = 10
        ..cliqAlias = 'PCJCLUB';
      backend.rsvps.add(
        _paidRow(
          eventId: 'e7',
          title: 'Dead Sea Drive',
          status: 'REJECTED',
          payment: 'REJECTED',
        ),
      );
      final GoRouter router = await _launch(tester, backend, picker: _Picker());
      router.go(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);
      await tester.tap(find.byTooltip('Close'));
      await _settle(tester);

      expect(find.text('Payment rejected'), findsOneWidget);
      expect(find.text('Cancel RSVP'), findsNothing);
      await tapText(tester, 'Register for Event');
      await _settle(tester, 20);
      await tapText(tester, 'Continue to Payment');
      await _settle(tester, 20);
      await tester.enterText(find.byType(TextField).at(0), 'TX-7');
      await tester.enterText(find.byType(TextField).at(1), 'MEMBER1');
      await tapText(tester, 'Upload Receipt Screenshot');
      await tapText(tester, 'Choose from Library');
      await tapText(tester, 'Submit Payment');
      await _settle(tester, 20);

      // A new RSVP, paid at once; the new one is what the page shows.
      expect(backend.count('POST /member/events/e7/rsvp'), 1);
      expect(backend.cliqPath, '/member/events/104/cliq');
      expect(_path(router), AppRoutes.eventDetailsLocation('e7'));
      expect(find.text('Payment under review'), findsOneWidget);
    });

    testWidgets('My Events lists a rejected RSVP under Past, with support', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..eventPrice = 10;
      backend.rsvps.add(
        _paidRow(
          eventId: 'e7',
          title: 'Dead Sea Drive',
          status: 'REJECTED',
          payment: 'REJECTED',
        ),
      );
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.userEvents);
      await _settle(tester, 20);
      expect(find.text('Dead Sea Drive'), findsNothing);

      await tapText(tester, 'PAST');
      await _settle(tester, 20);
      expect(find.text('Payment Rejected'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await _settle(tester);

      expect(find.text('PAYMENT REJECTED'), findsOneWidget);
      expect(find.text('CANCEL RSVP'), findsNothing);
      await tapText(tester, 'CONTACT SUPPORT');
      await _settle(tester);
      expect(find.text('MESSAGE'), findsOneWidget);
    });

    testWidgets('My Events: an unpaid RSVP is paid from there; cancelled ones '
        'are under Past', (WidgetTester tester) async {
      final _Backend backend = _Backend()
        ..eventPrice = 10
        ..cliqAlias = 'PCJCLUB';
      backend.rsvps.addAll(<Map<String, Object?>>[
        _paidRow(
          eventId: 'e7',
          title: 'Dead Sea Drive',
          status: 'WAITING_ADMIN_APPROVAL',
          payment: 'PENDING',
        ),
        _paidRow(
          eventId: 'e8',
          title: 'Track Day',
          status: 'CANCELLED',
          payment: 'REFUNDED',
        ),
        _paidRow(
          eventId: 'e9',
          title: 'Sunset Run',
          status: 'PENDING_PAYMENT',
          payment: 'PENDING_PAYMENT',
        ),
      ]);
      final GoRouter router = await _launch(tester, backend, picker: _Picker());
      router.go(AppRoutes.userEvents);
      await _settle(tester, 20);

      expect(find.text('PAYMENT UNDER REVIEW'), findsOneWidget);
      expect(find.text('PAYMENT NEEDED'), findsOneWidget);
      expect(find.text('COMPLETE PAYMENT'), findsOneWidget);
      // Only the one under review can be cancelled; the unpaid one is paid.
      expect(find.text('CANCEL RSVP'), findsOneWidget);
      expect(find.text('VIEW TICKET'), findsNothing);
      // Cancelled RSVPs are only under Past.
      expect(find.text('Track Day'), findsNothing);

      // The unpaid one is paid from here; no new RSVP is sent.
      await tapText(tester, 'COMPLETE PAYMENT');
      await _settle(tester, 20);
      expect(_path(router), AppRoutes.eventPaymentLocation('e9'));
      await tester.enterText(find.byType(TextField).at(0), 'TX-9');
      await tester.enterText(find.byType(TextField).at(1), 'MEMBER1');
      await tapText(tester, 'Upload Receipt Screenshot');
      await tapText(tester, 'Choose from Library');
      await tapText(tester, 'Submit Payment');
      await _settle(tester, 20);
      expect(backend.cliqPath, '/member/events/209/cliq');
      expect(backend.count('POST /member/events/e9/rsvp'), 0);
      expect(_path(router), AppRoutes.userEvents);
      expect(find.text('PAYMENT UNDER REVIEW'), findsNWidgets(2));
      expect(find.text('PAYMENT NEEDED'), findsNothing);

      await tapText(tester, 'PAST');
      await _settle(tester, 20);
      expect(find.text('Track Day'), findsOneWidget);
      expect(find.text('CANCELLED'), findsOneWidget);
    });
  });

  group('offers', () {
    testWidgets('an offer can be claimed again after five seconds', (
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

        // Tapping again straight away does nothing.
        await tester.tap(find.text('sad'));
        await _settle(tester);
        expect(backend.count('POST /member/offers/6/claim'), claim);
        await tester.pump(const Duration(seconds: 5));
      }
    });
  });

  group('after an action', () {
    testWidgets('an RSVP returns to the event, which can now be cancelled', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.eventRegistrationLocation('e7'));
      await _settle(tester);

      await tester.ensureVisible(find.text('Submit RSVP'));
      await tester.pump();
      await tester.tap(find.text('Submit RSVP'));
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // A short confirmation, not a dialog to dismiss.
      expect(find.text('RSVP Confirmed'), findsOneWidget);
      expect(find.text('Check My Events for your ticket.'), findsOneWidget);
      await _settle(tester, 30);

      expect(backend.count('POST /member/events/e7/rsvp'), 1);
      expect(backend.rsvpBody, <String, Object?>{
        'guest_count': 0,
        'guest_names': <Object?>[],
      });
      expect(_path(router), AppRoutes.eventDetailsLocation('e7'));
      expect(find.text('REGISTERED'), findsOneWidget);
      expect(find.text('Cancel RSVP'), findsOneWidget);
      expect(find.text('Register for Event'), findsNothing);
    });

    testWidgets('an RSVP is cancelled from the event\'s page', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      backend.rsvps.add(<String, Object?>{
        'event_id': 'e7',
        'title': 'Dead Sea Drive',
        'location': 'Amman',
        'start_at': DateTime.now()
            .add(const Duration(days: 20))
            .toIso8601String(),
        'capacity': 40,
        'rsvp_status': 'CONFIRMED',
        'guest_count': 0,
        'guest_names': <Object?>[],
        'is_paid': true,
        'attendance_status': 'Not Checked In',
      });
      final GoRouter router = await _launch(tester, backend);
      router.push(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);

      await tester.ensureVisible(find.text('Cancel RSVP'));
      await tester.pump();
      await tester.tap(find.text('Cancel RSVP'));
      await _settle(tester);
      expect(find.text('Cancel RSVP?'), findsOneWidget);
      // The dialog's button, above the page's.
      await tester.tap(find.text('Cancel RSVP').last);
      await _settle(tester, 20);

      expect(backend.count('DELETE /member/events/e7/rsvp'), 1);
      expect(find.text('REGISTERED'), findsNothing);
      expect(find.text('Register for Event'), findsOneWidget);
    });

    testWidgets('guests must be named, and the names are sent', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..maxGuestCount = 2;
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.eventRegistrationLocation('e7'));
      await _settle(tester);

      Future<void> tapText(String text) async {
        await tester.ensureVisible(find.text(text));
        await tester.pump();
        await tester.tap(find.text(text));
        await _settle(tester);
      }

      await tapText('Add a Guest');
      await tapText('Add Another Guest');
      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('Add Another Guest'), findsNothing);

      await tester.enterText(find.byType(TextField).at(0), 'Lina Haddad');
      await tapText('Submit RSVP');
      expect(find.text('Enter a name for each guest.'), findsOneWidget);
      expect(find.text('Guest Admission Notice'), findsNothing);

      await tester.tap(find.byTooltip('Remove guest 2'));
      await _settle(tester);
      await tapText('Submit RSVP');
      await tapText('I Understand');
      await _settle(tester, 20);

      expect(backend.rsvpBody, <String, Object?>{
        'guest_count': 1,
        'guest_names': <Object?>['Lina Haddad'],
      });
      expect(_path(router), AppRoutes.eventDetailsLocation('e7'));

      // The ticket lists the guests from the My Events row.
      router.push(AppRoutes.ticketLocation('e7'));
      await _settle(tester, 20);
      expect(find.text('GUESTS'), findsOneWidget);
      expect(find.text('Lina Haddad'), findsOneWidget);
      expect(find.text('Guest 1'), findsOneWidget);
      // The member's own details are not on the ticket.
      expect(find.text('Test Member'), findsNothing);
      expect(find.text('MEMBER'), findsNothing);
    });

    testWidgets('the ticket QR is replaced once the member is checked in', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.eventRegistrationLocation('e7'));
      await _settle(tester);
      await tester.ensureVisible(find.text('Submit RSVP'));
      await tester.pump();
      await tester.tap(find.text('Submit RSVP'));
      await _settle(tester, 20);

      router.push(AppRoutes.ticketLocation('e7'));
      await _settle(tester, 20);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(backend.count('GET /member/events/e7/qr'), 1);

      // The first view is confirmed with the backend.
      expect(backend.rsvps.single['attendance_status'], 'PARTIALLY_CHECKED_IN');
      expect(find.text('Share Ticket'), findsOneWidget);

      // Staff scan the code at the event.
      backend.rsvps.single['attendance_status'] = 'CHECKED_IN';
      await tester.pump(const Duration(seconds: 11));
      await _settle(tester);

      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('YOU ARE CHECKED IN'), findsOneWidget);
      // The code is never requested again.
      expect(backend.count('GET /member/events/e7/qr'), 1);
    });

    testWidgets('an opened ticket shows its saved QR, never a new one', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.eventRegistrationLocation('e7'));
      await _settle(tester);
      await tester.ensureVisible(find.text('Submit RSVP'));
      await tester.pump();
      await tester.tap(find.text('Submit RSVP'));
      await _settle(tester, 20);

      router.push(AppRoutes.ticketLocation('e7'));
      await _settle(tester, 20);
      router.pop();
      await _settle(tester);
      // Opened again: the saved QR shows.
      router.push(AppRoutes.ticketLocation('e7'));
      await _settle(tester, 20);

      expect(find.byType(QrImageView), findsOneWidget);
      expect(backend.count('GET /member/events/e7/qr'), 1);
    });

    testWidgets('a QR issued elsewhere is not requested again', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      backend.rsvps.add(<String, Object?>{
        'event_id': 'e7',
        'title': 'Dead Sea Drive',
        'location': 'Amman',
        'start_at': DateTime.now()
            .add(const Duration(days: 20))
            .toIso8601String(),
        'capacity': 40,
        'rsvp_status': 'CONFIRMED',
        'guest_count': 0,
        'is_paid': true,
        'attendance_status': 'PARTIALLY_CHECKED_IN',
      });
      final GoRouter router = await _launch(tester, backend);
      router.push(AppRoutes.ticketLocation('e7'));
      await _settle(tester, 20);

      expect(find.text('QR CODE ALREADY ISSUED'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(backend.count('GET /member/events/e7/qr'), 0);
    });

    // iOS keeps saved QRs even when the app is deleted, so one can outlive
    // its RSVP (cancelled and registered again, or reset by the club).
    testWidgets('a QR saved for an earlier RSVP is replaced', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      backend.rsvps.add(<String, Object?>{
        'event_id': 'e7',
        'title': 'Dead Sea Drive',
        'location': 'Amman',
        'start_at': DateTime.now()
            .add(const Duration(days: 20))
            .toIso8601String(),
        'capacity': 40,
        'rsvp_status': 'CONFIRMED',
        'guest_count': 0,
        'is_paid': true,
        'attendance_status': 'Not Checked In',
      });
      final _Storage storage = _Storage('test-token');
      storage.values['pcj_ticket_qr_1_e7'] = 'token-from-an-earlier-rsvp';
      final GoRouter router = await _launch(tester, backend, storage: storage);
      router.push(AppRoutes.ticketLocation('e7'));
      await _settle(tester, 20);

      expect(find.byType(QrImageView), findsOneWidget);
      expect(backend.count('GET /member/events/e7/qr'), 1);
      expect(storage.values['pcj_ticket_qr_1_e7'], 'signed-ticket-token');
    });

    testWidgets('past events have no ticket button', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      backend.rsvps.add(<String, Object?>{
        'event_id': 'e7',
        'title': 'Dead Sea Drive',
        'location': 'Amman',
        'start_at': DateTime.now()
            .subtract(const Duration(days: 3))
            .toIso8601String(),
        'capacity': 40,
        'rsvp_status': 'CONFIRMED',
        'guest_count': 0,
        'is_paid': true,
        'attendance_status': 'CHECKED_IN',
      });
      final GoRouter router = await _launch(tester, backend);
      router.push(AppRoutes.userEvents);
      await _settle(tester);
      await tester.tap(find.text('PAST'));
      await _settle(tester);

      expect(find.text('Dead Sea Drive'), findsOneWidget);
      expect(find.text('VIEW TICKET'), findsNothing);
      // The tab and the card's status.
      expect(find.text('PAST'), findsNWidgets(2));
      expect(find.text('CONFIRMED'), findsNothing);
    });

    testWidgets('My Events shows the check-in status in the backend wording', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      backend.rsvps.add(<String, Object?>{
        'event_id': 'e7',
        'title': 'Dead Sea Drive',
        'location': 'Amman',
        'start_at': DateTime.now()
            .add(const Duration(days: 20))
            .toIso8601String(),
        'capacity': 40,
        'rsvp_status': 'CONFIRMED',
        'guest_count': 0,
        'is_paid': true,
        'attendance_status': 'PARTIALLY_CHECKED_IN',
      });
      final GoRouter router = await _launch(tester, backend);
      router.push(AppRoutes.userEvents);
      await _settle(tester);

      expect(find.text('PARTIALLY CHECKED IN'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsNothing);
    });

    testWidgets('a registered event opens its ticket from the event page', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      backend.rsvps.add(<String, Object?>{
        'event_id': 'e7',
        'title': 'Dead Sea Drive',
        'location': 'Amman',
        'start_at': DateTime.now()
            .add(const Duration(days: 20))
            .toIso8601String(),
        'capacity': 40,
        'rsvp_status': 'CONFIRMED',
        'guest_count': 0,
        'is_paid': true,
        'attendance_status': 'Not Checked In',
      });
      final GoRouter router = await _launch(tester, backend);
      router.push(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);

      // View Ticket sits above Cancel RSVP.
      expect(
        tester.getTopLeft(find.text('View Ticket')).dy,
        lessThan(tester.getTopLeft(find.text('Cancel RSVP')).dy),
      );
      await tester.ensureVisible(find.text('View Ticket'));
      await tester.pump();
      await tester.tap(find.text('View Ticket'));
      await _settle(tester, 20);

      expect(_path(router), AppRoutes.ticketLocation('e7'));
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('a deleted event says it is no longer available', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(tester, _Backend());
      // Not in the fake backend: it answers 404, as for a deleted event.
      router.push(AppRoutes.eventDetailsLocation('e404'));
      await _settle(tester, 20);

      expect(find.text('This event is no longer available'), findsOneWidget);
      await tester.tap(find.text('Browse Events'));
      await _settle(tester);
      expect(_path(router), AppRoutes.events);
    });

    testWidgets('a gallery photo opens full screen', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(tester, _Backend());
      router.push(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);

      await tester.tap(find.byType(EventGallery));
      await _settle(tester);
      expect(find.byTooltip('Close'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await _settle(tester);
      expect(find.byTooltip('Close'), findsNothing);
    });

    testWidgets('a confirmed first payment opens Home', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(membershipStatus: 'APPROVED');
      final GoRouter router = await _launch(tester, backend);
      expect(_path(router), AppRoutes.membershipPayment);

      await tester.tap(find.text('CliQ'));
      await tester.pump();
      await tester.ensureVisible(find.text('Continue to Payment'));
      await tester.pump();
      await tester.tap(find.text('Continue to Payment'));
      await _settle(tester, 20);

      expect(backend.count('POST /member/membership/payment'), 1);
      expect(_path(router), AppRoutes.home);
    });

    testWidgets('card payment is not offered yet', (WidgetTester tester) async {
      final _Backend backend = _Backend(membershipStatus: 'APPROVED');
      await _launch(tester, backend);

      // Tapping it only says so; it is not selected.
      await tester.tap(find.text('Credit or debit card'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('COMING SOON'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('COMING SOON'), findsNothing);

      await tester.ensureVisible(find.text('Continue to Payment'));
      await tester.pump();
      await tester.tap(find.text('Continue to Payment'));
      await tester.pump();
      expect(find.text('Choose a payment method to continue.'), findsOneWidget);
      await _settle(tester, 40);
      expect(backend.count('POST /member/membership/payment'), 0);
    });

    testWidgets('paying with CliQ sends the receipt for review', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(membershipStatus: 'APPROVED')
        ..cliqAlias = 'CLUBALIAS';
      final GoRouter router = await _launch(tester, backend, picker: _Picker());

      await tester.tap(find.text('CliQ'));
      await tester.pump();
      await tester.ensureVisible(find.text('Continue to Payment'));
      await tester.pump();
      await tester.tap(find.text('Continue to Payment'));
      await _settle(tester);
      expect(_path(router), AppRoutes.cliqPayment);
      expect(find.text('CLUBALIAS'), findsOneWidget);
      expect(backend.count('POST /member/membership/payment'), 0);

      // Copy puts the alias on the clipboard.
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.tap(find.byTooltip('Copy CliQ alias'));
      await tester.pump();
      expect(copied, 'CLUBALIAS');

      await tester.ensureVisible(find.text('Upload Receipt Screenshot'));
      await tester.pump();
      await tester.tap(find.text('Upload Receipt Screenshot'));
      await _settle(tester);
      await tester.tap(find.text('Choose from Library'));
      await _settle(tester);
      expect(find.text('Receipt Added'), findsOneWidget);

      // Not sent without the transfer number and the refund alias.
      await tester.tap(find.text('Submit for Review'));
      await _settle(tester);
      expect(backend.count('POST /member/membership/cliq'), 0);
      await tester.enterText(find.byType(TextField).at(0), 'TX-12');
      await tester.enterText(find.byType(TextField).at(1), 'MEMBER1');
      await tester.pump();

      await tester.tap(find.text('Submit for Review'));
      await _settle(tester, 20);
      expect(backend.count('POST /member/membership/cliq'), 1);
      expect(backend.cliqFields, <String, String>{
        'transaction_number': 'TX-12',
        'cliq_refund_name': 'MEMBER1',
      });
      expect(backend.cliqHadPhoto, isTrue);
      expect(find.text('PAYMENT\nUNDER REVIEW'), findsOneWidget);

      // Back on the payment page, the button leads to the status.
      await tester.tap(find.byTooltip('Back'));
      await _settle(tester);
      expect(_path(router), AppRoutes.membershipPayment);
      await tester.tap(find.text('View Payment Status'));
      await _settle(tester);
      expect(find.text('PAYMENT\nUNDER REVIEW'), findsOneWidget);
    });

    testWidgets('Log Out on Profile returns to Welcome and forgets the login', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final _Storage storage = _Storage('test-token');
      final GoRouter router = await _launch(tester, backend, storage: storage);
      router.go(AppRoutes.profile);
      await _settle(tester);

      await tester.ensureVisible(find.text('Log Out'));
      await tester.pump();
      await tester.tap(find.text('Log Out'));
      await _settle(tester);

      expect(_path(router), AppRoutes.welcome);
      expect(backend.count('POST /auth/logout'), 1);
      expect(storage.token, isNull);
    });

    testWidgets('cancelling registration returns to Welcome', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(
        tester,
        _Backend(),
        storage: _Storage(null),
      );
      router.push(AppRoutes.registerPersonal);
      await _settle(tester);

      await tester.tap(find.byTooltip('Cancel registration'));
      await _settle(tester);
      await tester.tap(find.text('Cancel Registration'));
      await _settle(tester);

      expect(_path(router), AppRoutes.welcome);
    });
  });

  group('garage', () {
    // As GET /member/cars lists a car.
    Map<String, Object?> carrera() => <String, Object?>{
      'id': 1,
      'VIN_Number': 'WP0ZZZ99ZTS392124',
      'model': '911 Carrera',
      'year': 2020,
      'License_Plate': '12-34567',
      'photo_url': 'https://example.com/plates/1.jpg',
    };

    Future<void> openEditProfile(WidgetTester tester, _Backend backend) async {
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.profile);
      await _settle(tester);
      router.push(AppRoutes.profileEdit);
      await _settle(tester);
    }

    Finder sheetField(int index) => find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        )
        .at(index);

    Future<void> tapInSheet(WidgetTester tester, String label) async {
      final Finder button = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(label),
      );
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await _settle(tester, 20);
    }

    testWidgets('a car is edited without a new photo', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..cars.add(carrera());
      await openEditProfile(tester, backend);

      await tester.ensureVisible(find.text('Edit'));
      await tester.pump();
      await tester.tap(find.text('Edit'));
      await _settle(tester);
      expect(find.text('Edit Vehicle'), findsOneWidget);
      // The plate photo from /member/cars is kept unless replaced.
      expect(
        find.text('Current photo is kept · tap to replace'),
        findsOneWidget,
      );

      await tester.enterText(sheetField(0), '911 Turbo S');
      await tapInSheet(tester, 'Save Vehicle');

      expect(backend.count('PUT /member/cars/1'), 1);
      expect(backend.lastCarFields, <String, String>{
        'VIN_Number': 'WP0ZZZ99ZTS392124',
        'model': '911 Turbo S',
        'year': '2020',
        'License_Plate': '12-34567',
      });
      expect(backend.lastCarHadPhoto, isFalse);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('911 Turbo S'), findsOneWidget);
    });

    testWidgets('invalid details are caught before anything is sent', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..cars.add(carrera());
      await openEditProfile(tester, backend);
      await tester.ensureVisible(find.text('Edit'));
      await tester.pump();
      await tester.tap(find.text('Edit'));
      await _settle(tester);

      await tester.enterText(sheetField(1), '2020');
      await tester.enterText(sheetField(2), 'WP0ZZZ');
      await tapInSheet(tester, 'Save Vehicle');

      expect(find.text('The VIN must be 10 or 17 characters.'), findsOneWidget);
      expect(backend.count('PUT /member/cars/1'), 0);
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('a car is removed after confirmation', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..cars.add(carrera());
      await openEditProfile(tester, backend);

      await tester.ensureVisible(find.text('Remove'));
      await tester.pump();
      await tester.tap(find.text('Remove'));
      await _settle(tester);
      expect(find.text('Remove Vehicle?'), findsOneWidget);
      // The dialog's button, above the card's.
      await tester.tap(find.text('Remove').last);
      await _settle(tester, 20);

      expect(backend.count('DELETE /member/cars/1'), 1);
      expect(find.text('No vehicles are registered.'), findsOneWidget);
    });

    testWidgets('the card shows the plate and its photo, and copies the VIN', (
      WidgetTester tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final _Backend backend = _Backend()..cars.add(carrera());
      await openEditProfile(tester, backend);

      expect(find.text('12-34567'), findsOneWidget);
      await tester.ensureVisible(find.text('LICENCE PLATE PHOTO'));
      await tester.pump();
      await tester.tap(find.text('LICENCE PLATE PHOTO'));
      await _settle(tester);
      expect(find.byTooltip('Close'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await _settle(tester);

      await tester.ensureVisible(find.byTooltip('Copy VIN'));
      await tester.pump();
      await tester.tap(find.byTooltip('Copy VIN'));
      await _settle(tester);

      expect(copied, 'WP0ZZZ99ZTS392124');
      expect(find.text('VIN copied.'), findsOneWidget);
    });
  });

  group('notifications', () {
    Map<String, Object?> notification(
      int id,
      String type,
      String title,
      String message,
    ) => <String, Object?>{
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': false,
      'sent_date': '2026-09-29T15:12:22.919478',
    };

    testWidgets('each type opens its page and is marked read', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      backend.notifications.addAll(<Map<String, Object?>>[
        notification(
          392,
          'EVENT',
          'New Event',
          '39|yaser has been created. Check it out and join us!',
        ),
        notification(387, 'MEMBERSHIP', 'Membership Approved', 'Welcome.'),
        notification(
          385,
          'MARKETPLACE',
          'Order Update',
          'Your order #55 is ready. Pick it up today.',
        ),
        notification(383, 'MARKETPLACE', 'New Arrival', 'Fresh club caps.'),
        notification(380, 'OFFER', 'New Offer', '10% off at NUQUL.'),
        notification(370, 'SYSTEM', 'Maintenance', 'Back soon.'),
      ]);
      final GoRouter router = await _launch(tester, backend);
      router.push(AppRoutes.notifications);
      await _settle(tester);

      // The event id is not part of the message.
      expect(
        find.text('yaser has been created. Check it out and join us!'),
        findsOneWidget,
      );
      expect(find.text('Maintenance'), findsOneWidget);

      Future<void> open(String action) async {
        await tester.ensureVisible(find.text(action));
        await tester.pump();
        await tester.tap(find.text(action));
        await _settle(tester);
      }

      await open('View Event');
      expect(_path(router), '/events/39');
      expect(backend.count('PATCH /notifications/392/read'), 1);

      router.pop();
      await _settle(tester);
      await open('Membership Status');
      expect(_path(router), AppRoutes.membershipSettings);
      expect(backend.count('PATCH /notifications/387/read'), 1);

      router.pop();
      await _settle(tester);
      // That exact order, over the list.
      await open('View Order #55');
      expect(find.text('Order #55'), findsOneWidget);
      expect(_path(router), AppRoutes.notifications);
      expect(backend.count('PATCH /notifications/385/read'), 1);
      Navigator.of(
        tester.element(find.text('Order #55')),
        rootNavigator: true,
      ).pop();
      await _settle(tester);
      await open('Browse Shop');
      expect(_path(router), AppRoutes.shop);
      expect(backend.count('PATCH /notifications/383/read'), 1);

      router.push(AppRoutes.notifications);
      await _settle(tester);

      await open('See Offers');
      expect(_path(router), AppRoutes.offers);
    });

    testWidgets('a system notification is only marked read', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      backend.notifications.add(
        notification(370, 'SYSTEM', 'Maintenance', 'Back soon.'),
      );
      final GoRouter router = await _launch(tester, backend);
      router.push(AppRoutes.notifications);
      await _settle(tester);

      await tester.tap(find.text('Maintenance'));
      await _settle(tester);

      expect(_path(router), AppRoutes.notifications);
      expect(backend.count('PATCH /notifications/370/read'), 1);
      expect(find.text('You are all caught up.'), findsOneWidget);
    });
  });

  group('change password', () {
    testWidgets('one form, then the code saves it; still signed in', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final _Storage storage = _Storage('stored-token');
      final GoRouter router = await _launch(tester, backend, storage: storage);
      router.go(AppRoutes.profile);
      await _settle(tester);
      router.push(AppRoutes.accountSettings);
      await _settle(tester);

      await tester.tap(find.text('Password'));
      await _settle(tester);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('CURRENT PASSWORD'), findsOneWidget);

      Finder dialogField(int index) => find
          .descendant(of: find.byType(Dialog), matching: find.byType(TextField))
          .at(index);
      Future<void> tapInDialog(String label) async {
        final Finder button = find.descendant(
          of: find.byType(Dialog),
          matching: find.text(label),
        );
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await _settle(tester);
      }

      await tester.enterText(dialogField(0), 'oldpass12');
      await tester.enterText(dialogField(1), 'newpass34');
      await tester.enterText(dialogField(2), 'newpass34');
      await tapInDialog('Send Verification Code');

      expect(backend.loginFields, <String, String>{
        'email': 'member@example.com',
        'password': 'oldpass12',
      });
      expect(backend.count('POST /auth/forgot-password'), 1);
      expect(find.text('Enter Verification Code'), findsOneWidget);

      await tester.enterText(dialogField(0), '123456');
      await tapInDialog('Confirm Code');

      expect(backend.resetFields, <String, String>{
        'reset_token': 'reset-abc',
        'new_password': 'newpass34',
      });
      expect(find.text('Password Changed'), findsOneWidget);
      await tapInDialog('Done');

      expect(_path(router), AppRoutes.accountSettings);
      expect(backend.count('POST /auth/logout'), 0);
      expect(storage.token, 'stored-token');
    });
  });

  group('forgot password', () {
    testWidgets('asks for the email first, then sends a code', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final GoRouter router = await _launch(
        tester,
        backend,
        storage: _Storage(null),
      );
      router.go(AppRoutes.signIn);
      await _settle(tester);

      await tester.tap(find.text('Forgot Password?'));
      await _settle(tester);
      expect(find.text('Enter your email address first.'), findsOneWidget);
      expect(backend.count('POST /auth/forgot-password'), 0);
      // The pop-up fades on its own.
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Enter your email address first.'), findsNothing);

      await tester.enterText(
        find.byType(TextField).at(0),
        'member@example.com',
      );
      await tester.tap(find.text('Forgot Password?'));
      await _settle(tester);

      expect(backend.count('POST /auth/forgot-password'), 1);
      expect(find.text('Verify Code'), findsOneWidget);
      expect(find.text('Enter your email address first.'), findsNothing);
    });
  });

  group('live updates', () {
    // The status check and on-screen pages refresh this often.
    Future<void> waitForRefresh(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 11));
      await _settle(tester);
    }

    testWidgets('a membership that expires mid-session opens renewal', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final GoRouter router = await _launch(tester, backend);
      expect(_path(router), AppRoutes.home);

      backend.membershipStatus = 'EXPIRED';
      backend.endDate = _day(-1);
      await waitForRefresh(tester);

      expect(_path(router), AppRoutes.membershipRenewal);
      expect(find.text('Welcome back, Test'), findsOneWidget);
    });

    testWidgets('a membership the club renews leaves the renewal page', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(
        membershipStatus: 'EXPIRED',
        endDate: _day(-3),
      );
      final GoRouter router = await _launch(tester, backend);
      expect(_path(router), AppRoutes.membershipRenewal);

      backend.membershipStatus = 'ACTIVE';
      backend.endDate = _day(365);
      await tester.pump(const Duration(seconds: 11));
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Membership Renewed'), findsOneWidget);
      await _settle(tester);
      expect(_path(router), AppRoutes.home);
    });

    testWidgets('a used gift code does not come back', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(
        membershipStatus: 'EXPIRED',
        endDate: _day(-3),
      );
      final GoRouter router = await _launch(tester, backend);

      Finder codeField() => find.widgetWithText(TextField, '12-digit code');
      Future<void> openCodeSection() async {
        await tester.ensureVisible(find.text('Have a gift or referral code?'));
        await tester.pump();
        await tester.tap(find.text('Have a gift or referral code?'));
        await _settle(tester);
      }

      await openCodeSection();
      // The keyboard must not learn or suggest it.
      expect(
        tester.widget<TextField>(codeField()).enableIMEPersonalizedLearning,
        isFalse,
      );
      await tester.enterText(codeField(), 'GIFT12345678');
      await tester.ensureVisible(find.text('Apply'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await _settle(tester, 30);
      expect(backend.count('POST /member/pay-membership'), 1);
      expect(_path(router), AppRoutes.home);

      // A year on, the renewal page starts without it.
      backend.membershipStatus = 'EXPIRED';
      backend.endDate = _day(-1);
      await waitForRefresh(tester);
      expect(_path(router), AppRoutes.membershipRenewal);
      await openCodeSection();
      expect(tester.widget<TextField>(codeField()).controller!.text, isEmpty);
      expect(find.text('GIFT12345678'), findsNothing);
    });

    for (final String status in <String>['SUSPENDED', 'DEACTIVATED']) {
      testWidgets('$status mid-session shows Something went wrong', (
        WidgetTester tester,
      ) async {
        final _Backend backend = _Backend();
        final _Storage storage = _Storage('test-token');
        final GoRouter router = await _launch(
          tester,
          backend,
          storage: storage,
        );
        router.go(AppRoutes.offers);
        await _settle(tester);

        backend.membershipStatus = status;
        await waitForRefresh(tester);

        expect(find.text('Something Went Wrong'), findsOneWidget);
        expect(find.text('Account Deactivated'), findsNothing);
        expect(_path(router), AppRoutes.welcome);
        expect(storage.token, isNull);

        await tester.tap(find.text('OK'));
        await _settle(tester);
        expect(find.text('Something Went Wrong'), findsNothing);
        expect(_path(router), AppRoutes.welcome);
      });
    }

    testWidgets('an account deleted mid-session returns to Welcome', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final _Storage storage = _Storage('test-token');
      final GoRouter router = await _launch(tester, backend, storage: storage);

      backend
        ..rejectToken = true
        ..rejectTokenMessage = 'User not found.';
      router.go(AppRoutes.offers);
      await waitForRefresh(tester);

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(_path(router), AppRoutes.welcome);
      expect(storage.token, isNull);
    });

    testWidgets('the page on screen refreshes itself; covered pages do not', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.profile);
      await _settle(tester);

      final int profileReads = backend.count('GET /member/profile');
      await waitForRefresh(tester);
      expect(backend.count('GET /member/profile'), greaterThan(profileReads));

      // Membership Status now covers Profile: only it keeps refreshing.
      router.push(AppRoutes.membershipSettings);
      await _settle(tester);
      final int coveredReads = backend.count('GET /member/profile');
      await waitForRefresh(tester);
      await waitForRefresh(tester);
      expect(backend.count('GET /member/profile'), coveredReads);
      expect(_path(router), AppRoutes.membershipSettings);
    });

    testWidgets('Home offers are NUQUL offers only', (
      WidgetTester tester,
    ) async {
      await _launch(tester, _Backend());

      expect(find.text('Exclusive NUQUL Offers'), findsOneWidget);
      expect(find.text('Nuqul Member Deal'), findsOneWidget);
      expect(find.text('sad'), findsNothing);
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
      await tester.ensureVisible(find.text('Have a gift or referral code?'));
      await tester.pump();
      await tester.tap(find.text('Have a gift or referral code?'));
      // Opens, then scrolls itself above the pay bar.
      await _settle(tester, 10);
      await tester.enterText(find.byType(TextField), '123456789012');
      await tester.tap(find.text('Apply'));
      await _settle(tester, 20);

      expect(backend.count('POST /member/pay-membership'), 1);
      expect(_path(router), AppRoutes.home);
    });

    testWidgets('Membership Status has no renew option', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(
        tester,
        _Backend(endDate: _day(10)),
      );
      router.go(AppRoutes.profile);
      await _settle(tester);
      await tester.ensureVisible(find.text('Membership Status'));
      await tester.pump();
      await tester.tap(find.text('Membership Status'));
      await _settle(tester);

      expect(_path(router), AppRoutes.membershipSettings);
      expect(find.text('MEMBERSHIP STATUS'), findsOneWidget);
      // The card shows the signed-in member.
      expect(find.text('Test Member'), findsOneWidget);
      expect(find.text('Renew Membership'), findsNothing);
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

  group('an unverified email at sign in', () {
    testWidgets('is verified with a new code, then sign in goes on', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(membershipStatus: 'APPROVED')
        ..emailUnverified = true
        ..pendingApproval = true;
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

      // Why, before any code is sent.
      expect(find.text('Finish Your Application'), findsOneWidget);
      expect(backend.count('POST /auth/resend-otp'), 0);
      await tester.tap(find.text('Send Code'));
      await _settle(tester);
      expect(backend.count('POST /auth/resend-otp'), 1);
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.tap(find.text('Verify Email'));
      await _settle(tester, 20);

      // Verified, so sign in goes on: still under review.
      expect(backend.emailUnverified, isFalse);
      expect(backend.count('POST /auth/login'), 2);
      expect(_path(router), AppRoutes.applicationStatus);
      expect(find.text('APPLICATION\nUNDER REVIEW'), findsOneWidget);
    });

    testWidgets('Not Now sends no code and stays on Sign In', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..emailUnverified = true;
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

      await tester.tap(find.text('Not Now'));
      await _settle(tester);

      expect(find.text('Finish Your Application'), findsNothing);
      expect(backend.count('POST /auth/resend-otp'), 0);
      expect(_path(router), AppRoutes.signIn);
    });
  });

  group('an application decided while its status page is open', () {
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

    testWidgets('approval leads to sign in, then payment', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend(membershipStatus: 'APPROVED')
        ..pendingApproval = true;
      final GoRouter router = await signIn(tester, backend);
      expect(_path(router), AppRoutes.applicationStatus);
      expect(find.text('APPLICATION\nUNDER REVIEW'), findsOneWidget);

      // Still waiting at the first check, 10 seconds in.
      await tester.pump(const Duration(seconds: 10));
      await _settle(tester);
      expect(find.text('Application Approved'), findsNothing);
      expect(backend.count('POST /auth/login'), 2);

      backend.pendingApproval = false;
      await tester.pump(const Duration(seconds: 10));
      await _settle(tester);
      expect(backend.count('POST /auth/login'), 3);
      expect(find.text('Application Approved'), findsOneWidget);

      await tester.tap(find.text('Enter Code'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.tap(find.text('Verify and Sign In'));
      await _settle(tester, 20);

      expect(_path(router), AppRoutes.membershipPayment);
      // No more checks once decided.
      await tester.pump(const Duration(seconds: 31));
      expect(backend.count('POST /auth/login'), 3);
    });

    testWidgets('a rejection updates the page', (WidgetTester tester) async {
      final _Backend backend = _Backend()..pendingApproval = true;
      final GoRouter router = await signIn(tester, backend);
      expect(find.text('APPLICATION\nUNDER REVIEW'), findsOneWidget);

      backend
        ..pendingApproval = false
        ..rejectAt = 'login';
      await tester.pump(const Duration(seconds: 10));
      await _settle(tester);

      expect(_path(router), AppRoutes.applicationStatus);
      expect(find.text('APPLICATION\nREJECTED'), findsOneWidget);
    });

    testWidgets('a removed account signs the applicant out', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..pendingApproval = true;
      final GoRouter router = await signIn(tester, backend);
      expect(find.text('APPLICATION\nUNDER REVIEW'), findsOneWidget);

      backend.accountRemoved = true;
      await tester.pump(const Duration(seconds: 10));
      await _settle(tester);

      expect(_path(router), AppRoutes.welcome);
      expect(find.text('Something Went Wrong'), findsOneWidget);
      // No more checks.
      final int checks = backend.count('POST /auth/login');
      await tester.pump(const Duration(seconds: 31));
      expect(backend.count('POST /auth/login'), checks);
    });
  });

  group('Face ID sign in', () {
    Future<void> typeLogin(WidgetTester tester) async {
      await tester.enterText(
        find.byType(TextField).at(0),
        'member@example.com',
      );
      await tester.enterText(find.byType(TextField).at(1), 'password1');
      await tester.ensureVisible(find.text('Sign In'));
      await tester.pump();
      await tester.tap(find.text('Sign In'));
      await _settle(tester);
    }

    Future<void> enterCode(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.tap(find.text('Verify and Sign In'));
      await _settle(tester, 20);
    }

    testWidgets('offered after a sign in, then used to sign in', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      final _Storage storage = _Storage(null);
      final _FaceId faceId = _FaceId();
      final GoRouter router = await _launch(
        tester,
        backend,
        storage: storage,
        biometrics: faceId,
      );
      router.go(AppRoutes.signIn);
      await _settle(tester);
      // Nothing saved yet: no Face ID button.
      expect(find.text('Sign in with Face ID'), findsNothing);

      await typeLogin(tester);
      await enterCode(tester);
      expect(find.text('Sign in with Face ID?'), findsOneWidget);
      await tester.tap(find.text('Use Face ID'));
      await _settle(tester, 20);
      expect(_path(router), AppRoutes.home);
      expect(faceId.prompts, 1);
      expect(storage.values['pcj_biometric_email'], 'member@example.com');
      expect(storage.values['pcj_biometric_password'], 'password1');

      // Signed out, the saved login stays.
      router.go(AppRoutes.profile);
      await _settle(tester);
      await tester.ensureVisible(find.text('Log Out'));
      await tester.pump();
      await tester.tap(find.text('Log Out'));
      await _settle(tester);
      expect(_path(router), AppRoutes.welcome);
      router.go(AppRoutes.signIn);
      await _settle(tester);

      backend.loginFields = null;
      await tester.ensureVisible(find.text('Sign in with Face ID'));
      await tester.pump();
      await tester.tap(find.text('Sign in with Face ID'));
      await _settle(tester);
      expect(faceId.prompts, 2);
      expect(backend.loginFields?['email'], 'member@example.com');
      expect(backend.loginFields?['password'], 'password1');
      expect(find.text('Verify and Sign In'), findsOneWidget);
      // Not offered again after a Face ID sign in.
      await enterCode(tester);
      expect(find.text('Sign in with Face ID?'), findsNothing);
    });

    testWidgets('a saved password that no longer works is forgotten', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..loginStatus = 401;
      final _Storage storage = _Storage(null)
        ..values['pcj_biometric_email'] = 'member@example.com'
        ..values['pcj_biometric_password'] = 'old-password';
      final GoRouter router = await _launch(
        tester,
        backend,
        storage: storage,
        biometrics: _FaceId(),
      );
      router.go(AppRoutes.signIn);
      await _settle(tester);

      await tester.ensureVisible(find.text('Sign in with Face ID'));
      await tester.pump();
      await tester.tap(find.text('Sign in with Face ID'));
      await _settle(tester);

      expect(
        find.text(
          'Your saved password no longer works. Sign in with your password.',
        ),
        findsOneWidget,
      );
      expect(storage.values.containsKey('pcj_biometric_password'), isFalse);
      expect(find.text('Sign in with Face ID'), findsNothing);
    });
  });

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
          // One request, sent as the documented form fields.
          expect(backend.count('POST /member/cart/checkout'), 1);
          expect(backend.checkoutFields, <String, String>{
            'delivery_method': 'PICKUP',
            'payment_method': 'CASH',
          });
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

    testWidgets('My Orders shows the first three items; read once', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      backend.orders.add(<String, Object?>{
        'order_id': 55,
        'total': 40,
        'status': 'PROCESSING',
        'payment_status': 'PENDING',
        'payment_method': 'CASH',
        'delivery_method': 'PICKUP',
        'delivery_fee': 0,
        'created_at': '2026-09-29T13:11:55.386650',
      });
      for (final String name in <String>['Cap', 'Mug', 'Key Ring', 'Pen']) {
        backend.orderItems.add(<String, Object?>{
          'variant_id': 6,
          'item_id': 6,
          'name': name,
          'color': 'red',
          'size': 's',
          'price': 10,
          'quantity': 1,
          'subtotal': 10,
          'image': 'https://example.com/items/$name.png',
        });
      }
      final GoRouter router = await _launch(tester, backend);
      router.push(AppRoutes.userOrders);
      await _settle(tester);

      expect(find.text('4 products'), findsOneWidget);
      final Finder thumbnail = find.byType(OrderThumbnail);
      expect(
        find.descendant(of: thumbnail, matching: find.byType(AppAssetImage)),
        findsNWidgets(3),
      );
      expect(
        find.descendant(of: thumbnail, matching: find.text('+1')),
        findsOneWidget,
      );

      // The list refreshes; the items are not read again.
      final int listReads = backend.count('GET /member/orders');
      await tester.pump(const Duration(seconds: 11));
      await _settle(tester);
      expect(backend.count('GET /member/orders'), greaterThan(listReads));
      expect(backend.count('GET /member/orders/55'), 1);
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
    testWidgets('the compact view lists events by month and opens them', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _launch(tester, _Backend());
      router.go(AppRoutes.events);
      await _settle(tester, 20);

      // Cards are the default.
      expect(find.byType(UpcomingEventsCarousel), findsOneWidget);
      expect(find.byType(CompactEventList), findsNothing);

      await tester.ensureVisible(find.byTooltip('Compact view'));
      await tester.pump();
      await tester.tap(find.byTooltip('Compact view'));
      await _settle(tester);
      expect(find.byType(UpcomingEventsCarousel), findsNothing);
      final DateTime first = DateTime.now().add(const Duration(days: 3));
      expect(
        find.text(AppFormatters.monthYear(first).toUpperCase()),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Upcoming Drive 5'));
      await tester.pump();
      await tester.tap(find.text('Upcoming Drive 5'));
      await _settle(tester);
      expect(_path(router), AppRoutes.eventDetailsLocation('u5'));
    });

    testWidgets('cards show "In 3 days" and "Registered", not "Event"', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend();
      // Upcoming Drive 1 starts in three days; the member has RSVP'd to it.
      backend.rsvps.add(<String, Object?>{
        'event_id': 'u1',
        'title': 'Upcoming Drive 1',
        'location': 'Amman',
        'start_at': DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String(),
        'capacity': 20,
        'rsvp_status': 'CONFIRMED',
        'guest_count': 0,
        'is_paid': true,
        'attendance_status': 'Not Checked In',
      });
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.events);
      await _settle(tester, 20);

      expect(find.text('EVENT'), findsNothing);
      expect(find.text('IN 3 DAYS'), findsWidgets);
      expect(find.text('REGISTERED'), findsWidgets);
    });

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
      // Within the 16-day forecast.
      final _Backend backend = _Backend()
        ..maxGuestCount = 2
        ..eventStartsInDays = 5;
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
      // The whole location card opens Google Maps.
      expect(find.bySemanticsLabel(RegExp('in Google Maps')), findsOneWidget);
    });

    testWidgets('a failed forecast says no information is available', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()
        ..eventStartsInDays = 5
        ..weatherFails = true;
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);

      expect(find.text('WEATHER'), findsOneWidget);
      expect(find.text('No information available'), findsOneWidget);
      expect(find.text('--°'), findsNothing);
    });

    testWidgets('a place not on the list is still asked about', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()
        ..eventStartsInDays = 5
        ..eventLocation = 'PCJ Garage'
        ..weatherFails = true;
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);

      expect(backend.weatherLocation, 'PCJ Garage');
      expect(find.text('WEATHER'), findsOneWidget);
      expect(find.text('No information available'), findsOneWidget);
    });

    testWidgets('more than 16 days ahead the forecast is awaited', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()
        ..eventStartsInDays = 20
        ..eventLocation = 'PCJ Garage';
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);

      // Also for a place not on the weather list.
      expect(find.text('Awaiting forecast'), findsOneWidget);
      expect(find.textContaining('Available from'), findsOneWidget);
      expect(find.text('TIME'), findsOneWidget);
      expect(backend.count('GET /weather'), 0);
    });

    testWidgets('a past event shows a recap, nothing to register for', (
      WidgetTester tester,
    ) async {
      final _Backend backend = _Backend()..eventStartsInDays = -3;
      final GoRouter router = await _launch(tester, backend);
      router.go(AppRoutes.eventDetailsLocation('e7'));
      await _settle(tester, 20);

      expect(find.text('PAST'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Place'), findsOneWidget);
      expect(find.text('Event Overview'), findsOneWidget);
      expect(find.text('TOTAL SPOTS'), findsNothing);
      expect(find.text('WEATHER'), findsNothing);
      expect(find.text('Registration Closed'), findsNothing);
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
        expect(find.text('Add a Guest'), shown ? findsOneWidget : findsNothing);
      });
    }
  });
}
