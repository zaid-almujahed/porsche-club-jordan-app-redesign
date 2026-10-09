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
    super.eventId,
    super.orderId,
  });

  /// The event id in front of an EVENT message: "39|…".
  static final RegExp _eventIdPrefix = RegExp(r'^\s*(\d+)\s*\|\s*');

  /// The order number in a MARKETPLACE text: "#20".
  static final RegExp _orderNumber = RegExp(r'#\s*(\d+)');

  factory MemberNotificationModel.fromJson(Map<String, dynamic> json) {
    final MemberNotificationType type = _type(json['type']?.toString());
    final String message = json['message']?.toString() ?? '';
    final Match? eventId = type == MemberNotificationType.event
        ? _eventIdPrefix.firstMatch(message)
        : null;
    final String title = json['title']?.toString() ?? '';
    final Match? orderId = type == MemberNotificationType.marketplace
        ? _orderNumber.firstMatch('$title $message')
        : null;
    return MemberNotificationModel(
      id: json['id']?.toString() ?? '',
      title: title,
      message: eventId == null ? message : message.substring(eventId.end),
      type: type,
      eventId: eventId?.group(1),
      orderId: orderId?.group(1),
      isRead: json['is_read'] == true,
      sentAt:
          firstServerDateTime(json, const <String>['sent_date']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static MemberNotificationType _type(String? value) {
    return switch (value?.toUpperCase()) {
      'EVENT' => MemberNotificationType.event,
      'MEMBERSHIP' => MemberNotificationType.membership,
      'MARKETPLACE' => MemberNotificationType.marketplace,
      'OFFER' => MemberNotificationType.offer,
      'SYSTEM' => MemberNotificationType.system,
      _ => MemberNotificationType.general,
    };
  }

}
