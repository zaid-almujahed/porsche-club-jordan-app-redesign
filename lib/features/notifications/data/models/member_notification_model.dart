import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/features/notifications/domain/entities/member_notification.dart';

class MemberNotificationModel extends MemberNotification {
  const MemberNotificationModel({
    required super.id,
    required super.title,
    required super.message,
    required super.type,
    required super.isRead,
    required super.sentAt,
  });

  factory MemberNotificationModel.fromJson(Map<String, dynamic> json) {
    return MemberNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: _type(json['type']?.toString()),
      isRead: json['is_read'] == true,
      // Sent as UTC ("…T12:41:47.991Z"); shown in the phone's time.
      sentAt:
          firstDateTime(json, const <String>['sent_date'])?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static MemberNotificationType _type(String? value) {
    return switch (value?.toUpperCase()) {
      'EVENT' => MemberNotificationType.event,
      'MEMBERSHIP' => MemberNotificationType.membership,
      'MARKETPLACE' => MemberNotificationType.marketplace,
      'OFFER' => MemberNotificationType.offer,
      _ => MemberNotificationType.system,
    };
  }

}
