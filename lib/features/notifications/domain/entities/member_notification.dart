enum MemberNotificationType { event, membership, marketplace, offer, system }

class MemberNotification {
  const MemberNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.sentAt,
    this.eventId,
    this.orderId,
  });

  final String id;
  final String title;
  final String message;
  final MemberNotificationType type;
  final bool isRead;
  final DateTime sentAt;

  /// EVENT notifications: the event they are about. The backend sends it
  /// before a "|" in the message ("39|Track Day has been created."); the
  /// [message] no longer includes it.
  final String? eventId;

  /// Order Update notifications: the order they are about, from its
  /// number in the text ("Your order #20 …").
  final String? orderId;

  /// A MARKETPLACE notification about one of the member's orders: only
  /// those are titled "Order Update". Other MARKETPLACE ones are about the
  /// shop.
  bool get isOrderUpdate =>
      type == MemberNotificationType.marketplace &&
      title.trim().toLowerCase() == 'order update';

  MemberNotification copyWith({bool? isRead}) {
    return MemberNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt,
      eventId: eventId,
      orderId: orderId,
    );
  }
}
