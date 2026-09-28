import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/notifications/data/models/member_notification_model.dart';
import 'package:pcj_v5/features/notifications/domain/entities/member_notification.dart';

void main() {
  test('parses the member notification contract', () {
    final MemberNotification notification = MemberNotificationModel.fromJson(
      <String, dynamic>{
        'id': 7,
        'title': 'Membership Approved',
        'message': 'Welcome to Porsche Club Jordan.',
        'type': 'MEMBERSHIP',
        'is_read': false,
        'sent_date': '2026-09-17T07:28:16.625993',
      },
    );

    expect(notification.id, '7');
    expect(notification.type, MemberNotificationType.membership);
    expect(notification.isRead, isFalse);
    expect(notification.sentAt.year, 2026);
    expect(notification.copyWith(isRead: true).isRead, isTrue);
  });

  test('a UTC sent_date is shown in the phone time zone', () {
    final MemberNotification notification = MemberNotificationModel.fromJson(
      <String, dynamic>{
        'id': 0,
        'title': 'string',
        'message': 'string',
        'type': 'EVENT',
        'is_read': true,
        'sent_date': '2026-09-28T12:41:47.991Z',
      },
    );

    expect(notification.sentAt.isUtc, isFalse);
    expect(
      notification.sentAt,
      DateTime.utc(2026, 9, 28, 12, 41, 47, 991).toLocal(),
    );
  });
}
