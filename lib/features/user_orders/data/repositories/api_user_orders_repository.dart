import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/features/user_orders/domain/repositories/user_orders_repository.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';

import '../models/order_model.dart';

class ApiUserOrdersRepository implements UserOrdersRepository {
  ApiUserOrdersRepository({
    required PcjApiClient apiClient,
    required MemoryCache cache,
  }) : _apiClient = apiClient,
       _cache = cache;

  final PcjApiClient _apiClient;
  final MemoryCache _cache;

  @override
  Future<List<Order>> getOrders({required bool active}) async {
    final List<Order> orders = await Future.wait<Order>(
      requireJsonMapList(
        await _apiClient.get('/member/orders'),
        description: 'orders response',
      )
          .map<Order>(OrderModel.fromJson)
          .where((Order order) => order.isActive == active)
          .map(_withItems),
    );
    orders.sort((Order a, Order b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  /// The list has no items, so they come from each order's details. Items
  /// never change, so each order's are read once and kept until sign-out;
  /// if the read fails the order is shown without them.
  Future<Order> _withItems(Order order) async {
    if (order.id.isEmpty) return order;
    try {
      return order.copyWith(
        items: await _cache.getOrLoad<List<CartItem>>(
          'order-items:${order.id}',
          () async => (await getOrder(order.id)).items,
          ttl: const Duration(hours: 12),
        ),
      );
    } catch (_) {
      return order;
    }
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
