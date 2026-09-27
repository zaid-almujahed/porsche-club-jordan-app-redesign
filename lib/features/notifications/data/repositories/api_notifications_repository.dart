import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/features/notifications/domain/entities/member_notification.dart';
import 'package:pcj_v5/features/notifications/domain/repositories/notifications_repository.dart';

import '../models/member_notification_model.dart';

class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository({required PcjApiClient apiClient})
    : _apiClient = apiClient;

  final PcjApiClient _apiClient;

  @override
  Future<List<MemberNotification>> getNotifications() async {
    return requireJsonMapList(
          await _apiClient.get('/member/notifications'),
          description: 'notifications response',
        )
        .map<MemberNotification>(MemberNotificationModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _apiClient.patch(
      '/notifications/${Uri.encodeComponent(notificationId)}/read',
    );
  }

  @override
  Future<void> registerDeviceToken(String token) async {
    await _apiClient.postJson(
      '/notifications/token',
      body: <String, Object?>{'token': token.trim()},
    );
  }
}
