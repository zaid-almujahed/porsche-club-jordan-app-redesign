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
}
