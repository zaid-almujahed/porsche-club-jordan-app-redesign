import 'package:pcj_v5/shared/domain/entities/order.dart';

abstract interface class UserOrdersRepository {
  Future<List<Order>> getOrders({required bool active});

  Future<Order> getOrder(String orderId);

  Future<OrderCancellationResult> cancelOrder(String orderId);
}
