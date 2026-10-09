import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/features/notifications/data/models/member_notification_model.dart';
import 'package:pcj_v5/features/notifications/domain/entities/member_notification.dart';
import 'package:pcj_v5/features/notifications/domain/entities/tapped_push.dart';
import 'package:pcj_v5/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:pcj_v5/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:pcj_v5/features/notifications/presentation/pages/notifications_page.dart';

MemberNotification _notification(
  int id,
  String type,
  String title,
  String message, {
  int daysAgo = 0,
}) => MemberNotificationModel.fromJson(<String, dynamic>{
  'id': id,
  'title': title,
  'message': message,
  'type': type,
  'is_read': false,
  'sent_date': DateTime(
    2026,
    10,
    9,
  ).subtract(Duration(days: daysAgo)).toIso8601String(),
});

final List<MemberNotification> _list = <MemberNotification>[
  _notification(
    12,
    'EVENT',
    'Event Reminder',
    '39|Dead Sea Drive is tomorrow.',
  ),
  _notification(11, 'MARKETPLACE', 'Order Update', 'Your order #20 shipped.'),
  _notification(
    10,
    'EVENT',
    'Event Reminder',
    '31|Dead Sea Drive is tomorrow.',
    daysAgo: 30,
  ),
];

class _Notifications implements NotificationsRepository {
  final List<String> read = <String>[];

  @override
  Future<List<MemberNotification>> getNotifications() async => _list;

  @override
  Future<void> markAsRead(String notificationId) async =>
      read.add(notificationId);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('a push carrying its id finds that notification', () {
    expect(
      const TappedPush(notificationId: '11', title: 'Anything').findIn(_list),
      same(_list[1]),
    );
  });

  test('otherwise it is found by its words, the newest first', () {
    // The push text may keep the event id in front.
    final MemberNotification? found = const TappedPush(
      title: 'Event Reminder',
      body: '39|Dead Sea Drive  is tomorrow.',
    ).findIn(_list);
    expect(found, same(_list[0]));
    expect(found!.eventId, '39');
  });

  test('a push that is not in the list finds nothing', () {
    expect(
      const TappedPush(title: 'Welcome', body: 'Hello.').findIn(_list),
      isNull,
    );
    expect(const TappedPush().findIn(_list), isNull);
  });

  testWidgets('a tapped push opens its event over Notifications', (
    WidgetTester tester,
  ) async {
    final _Notifications repository = _Notifications();
    final NotificationsController controller = NotificationsController(
      repository: repository,
    );
    final GoRouter router = GoRouter(
      initialLocation: '/home',
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (_, _) => const Text('Home')),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (_, _) => NotificationsPage(controller: controller),
        ),
        GoRoute(
          path: AppRoutes.eventDetails,
          builder: (_, GoRouterState state) =>
              Text('Event ${state.pathParameters['eventId']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // As the app does when a push is tapped.
    controller
      ..openWhenLoaded(
        const TappedPush(
          title: 'Event Reminder',
          body: 'Dead Sea Drive is tomorrow.',
        ),
      )
      ..load(force: true);
    router.push(AppRoutes.notifications);
    await tester.pumpAndSettle();

    expect(find.text('Event 39'), findsOneWidget);
    expect(repository.read, <String>['12']);
    // Back returns to the list.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Event Reminder'), findsWidgets);
  });
}
