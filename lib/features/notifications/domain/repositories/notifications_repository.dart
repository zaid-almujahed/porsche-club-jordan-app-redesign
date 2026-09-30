import '../entities/member_notification.dart';

abstract interface class NotificationsRepository {
  Future<List<MemberNotification>> getNotifications();

  Future<void> markAsRead(String notificationId);

  /// `POST /notifications/token`: sends this device's Firebase Cloud
  /// Messaging token after sign in (see `PushNotificationsService`).
  Future<void> registerDeviceToken(String token);
}
