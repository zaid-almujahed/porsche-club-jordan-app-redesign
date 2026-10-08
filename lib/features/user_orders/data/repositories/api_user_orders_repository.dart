import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/features/user_orders/domain/repositories/user_orders_repository.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';

import '../models/order_model.dart';

/// An order's latest CliQ payment: its `payment_id` and `payment_status`.
typedef _Payment = ({String id, String status});

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
    final Map<String, _Payment> payments = await _latestPayments();
    final List<Order> orders = await Future.wait<Order>(
      requireJsonMapList(
        await _apiClient.get('/member/orders'),
        description: 'orders response',
      )
          .map<Order>(OrderModel.fromJson)
          .map((Order order) => _withPayment(order, payments))
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
    return _withPayment(
      OrderModel.fromJson(
        requireJsonMap(
          await _apiClient.get(
            '/member/orders/${Uri.encodeComponent(orderId)}',
          ),
          description: 'order response',
        ),
      ),
      await _latestPayments(),
    );
  }

  /// [order] with its latest CliQ payment, which its payment_status follows.
  static Order _withPayment(Order order, Map<String, _Payment> payments) {
    final _Payment? payment = payments[order.id];
    return payment == null
        ? order
        : order.copyWith(paymentStatus: payment.status, paymentId: payment.id);
  }

  /// The latest CliQ payment of each order, by its `order_id`, from
  /// `GET /member/payments`; none while they cannot be read.
  Future<Map<String, _Payment>> _latestPayments() async {
    try {
      return await _cache.getOrLoad<Map<String, _Payment>>(
        'order-payments',
        () async {
          final Map<String, (int, _Payment)> latest =
              <String, (int, _Payment)>{};
          for (final Map<String, dynamic> payment in requireJsonMapList(
            requireJsonMap(
              await _apiClient.get('/member/payments'),
              description: 'payments response',
            )['payments'],
            description: 'payments',
          )) {
            final String? orderId = firstString(payment, const <String>[
              'order_id',
            ]);
            final String? paymentId = firstString(payment, const <String>[
              'payment_id',
            ]);
            if (orderId == null || paymentId == null) continue;
            final int order = int.tryParse(paymentId) ?? 0;
            final (int, _Payment)? previous = latest[orderId];
            if (previous == null || order > previous.$1) {
              latest[orderId] = (
                order,
                (
                  id: paymentId,
                  status: '${payment['payment_status'] ?? ''}'
                      .trim()
                      .toUpperCase(),
                ),
              );
            }
          }
          return <String, _Payment>{
            for (final MapEntry<String, (int, _Payment)> entry
                in latest.entries)
              entry.key: entry.value.$2,
          };
        },
        // Only shared by the list and the details read in one refresh, so a
        // payment's new state shows on the next one.
        ttl: const Duration(seconds: 5),
      );
    } catch (_) {
      return const <String, _Payment>{};
    }
  }

  @override
  Future<OrderCancellationResult> cancelOrder(String orderId) async {
    final Map<String, dynamic> json = requireJsonMap(
      await _apiClient.patch(
        '/member/orders/${Uri.encodeComponent(orderId)}/cancel',
      ),
      description: 'order cancellation response',
    );
    _cache.remove('order-payments');
    return OrderCancellationResultModel.fromJson(json);
  }
}
