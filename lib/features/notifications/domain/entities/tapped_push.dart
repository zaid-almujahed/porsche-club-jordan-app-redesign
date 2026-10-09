import 'member_notification.dart';

/// A push notification the member tapped, to open what it is about as the
/// Notifications list would. The backend stores every push it sends; this
/// finds that stored notification, by its id when the push carries one
/// (`notification_id` in its data), otherwise by its title and text.
class TappedPush {
  const TappedPush({this.notificationId, this.title = '', this.body = ''});

  final String? notificationId;
  final String title;
  final String body;

  /// The event id in front of an EVENT message: "39|…".
  static final RegExp _eventIdPrefix = RegExp(r'^\s*\d+\s*\|\s*');
  static final RegExp _spaces = RegExp(r'\s+');

  static String _words(String value) =>
      value.replaceFirst(_eventIdPrefix, '').replaceAll(_spaces, ' ').trim();

  /// The stored notification this push is, from [notifications] listed
  /// newest first; the newest when several read the same. Null when none
  /// matches.
  MemberNotification? findIn(List<MemberNotification> notifications) {
    final String? id = notificationId;
    if (id != null) {
      for (final MemberNotification notification in notifications) {
        if (notification.id == id) return notification;
      }
    }
    final String title = _words(this.title);
    final String body = _words(this.body);
    if (title.isEmpty && body.isEmpty) return null;
    for (final MemberNotification notification in notifications) {
      if (_words(notification.title) == title &&
          _words(notification.message) == body) {
        return notification;
      }
    }
    return null;
  }
}
