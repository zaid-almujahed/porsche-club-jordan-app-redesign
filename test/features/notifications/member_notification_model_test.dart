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

  test('a sent_date without a zone is UTC, shown in the phone time zone', () {
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

    expect(notification.sentAt.isUtc, isFalse);
    expect(
      notification.sentAt,
      DateTime.utc(2026, 9, 17, 7, 28, 16, 625, 993).toLocal(),
    );
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

  MemberNotification parse(String type, String message) =>
      MemberNotificationModel.fromJson(<String, dynamic>{
        'id': 392,
        'title': 'New Event',
        'message': message,
        'type': type,
        'is_read': false,
        'sent_date': '2026-09-29T15:12:22.919478',
      });

  test('an EVENT message starts with the event id', () {
    final MemberNotification notification = parse(
      'EVENT',
      '39|yaser has been created. Check it out and join us!',
    );

    expect(notification.eventId, '39');
    expect(
      notification.message,
      'yaser has been created. Check it out and join us!',
    );
    expect(notification.copyWith(isRead: true).eventId, '39');
  });

  test('only a leading number on an EVENT is an event id', () {
    final MemberNotification offer = parse('OFFER', '12|Half price');
    expect(offer.eventId, isNull);
    expect(offer.message, '12|Half price');

    final MemberNotification event = parse('EVENT', 'Rally | Dead Sea');
    expect(event.eventId, isNull);
    expect(event.message, 'Rally | Dead Sea');
  });
}
