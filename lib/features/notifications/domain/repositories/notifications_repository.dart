import '../entities/member_notification.dart';

abstract interface class NotificationsRepository {
  Future<List<MemberNotification>> getNotifications();

  Future<void> markAsRead(String notificationId);

  /// `POST /notifications/token`. Not called yet: it is the hook for push
  /// notifications, to be sent the device token after sign in once Firebase
  /// Cloud Messaging is set up.
  Future<void> registerDeviceToken(String token);
}
