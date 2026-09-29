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

  MemberNotification copyWith({bool? isRead}) {
    return MemberNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt,
      eventId: eventId,
    );
  }
}
