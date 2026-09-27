import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/features/user_orders/domain/repositories/user_orders_repository.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';

import '../models/order_model.dart';

class ApiUserOrdersRepository implements UserOrdersRepository {
  ApiUserOrdersRepository({required PcjApiClient apiClient})
    : _apiClient = apiClient;

  final PcjApiClient _apiClient;

  @override
  Future<List<Order>> getOrders({required bool active}) async {
    final List<Order> orders = requireJsonMapList(
      await _apiClient.get('/member/orders'),
      description: 'orders response',
    )
        .map<Order>(OrderModel.fromJson)
        .where((Order order) => order.isActive == active)
        .toList(growable: false);
    orders.sort((Order a, Order b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  @override
  Future<Order> getOrder(String orderId) async {
    return OrderModel.fromJson(
      requireJsonMap(
        await _apiClient.get('/member/orders/${Uri.encodeComponent(orderId)}'),
        description: 'order response',
      ),
    );
  }

  @override
  Future<OrderCancellationResult> cancelOrder(String orderId) async {
    final Map<String, dynamic> json = requireJsonMap(
      await _apiClient.patch(
        '/member/orders/${Uri.encodeComponent(orderId)}/cancel',
      ),
      description: 'order cancellation response',
    );
    return OrderCancellationResultModel.fromJson(json);
  }
}
