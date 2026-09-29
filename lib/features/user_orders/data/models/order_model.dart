import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/features/shop/data/models/cart_model.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.items,
    required super.status,
    required super.createdAt,
    required super.total,
    required super.currency,
    required super.paymentStatus,
    required super.paymentMethod,
    required super.deliveryMethod,
    required super.deliveryFee,
    super.message,
  });

  factory OrderModel.fromJson(
    Map<String, dynamic> json, {
    List<CartItem> fallbackItems = const <CartItem>[],
    String fallbackDeliveryMethod = '',
    String fallbackPaymentMethod = '',
    DateTime? fallbackCreatedAt,
  }) {
    final Object? rawItems = json['items'];
    final List<CartItem> parsedItems = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map<CartItem>((Map item) {
                return CartItemModel.fromJson(Map<String, dynamic>.from(item));
              })
              .toList(growable: false)
        : const <CartItem>[];
    final List<CartItem> items = parsedItems.isEmpty
        ? fallbackItems
        : parsedItems;

    return OrderModel(
      id: firstString(json, const <String>['order_id']) ?? '',
      items: items,
      status: parseStatus(json['status'] ?? json['order_status']),
      createdAt:
          firstDateTime(json, const <String>['created_at']) ??
          fallbackCreatedAt ??
          DateTime.fromMillisecondsSinceEpoch(0),
      total: firstDouble(json, const <String>['total']) ??
          items.fold<double>(
            0,
            (double total, CartItem item) => total + item.total,
          ),
      currency: 'JOD',
      paymentStatus:
          firstString(json, const <String>['payment_status']) ?? '',
      paymentMethod:
          firstString(json, const <String>['payment_method']) ??
          fallbackPaymentMethod,
      deliveryMethod:
          firstString(json, const <String>['delivery_method']) ??
          fallbackDeliveryMethod,
      deliveryFee:
          firstDouble(json, const <String>['delivery_fee']) ?? 0,
      message: firstString(json, const <String>['message']),
    );
  }

  static OrderStatus parseStatus(Object? value) {
    final String normalized = (value?.toString() ?? '').trim().toUpperCase();
    return switch (normalized) {
      'PENDING' => OrderStatus.pending,
      'PROCESSING' => OrderStatus.processing,
      'READY FOR PICKUP' => OrderStatus.readyForPickup,
      'SHIPPED' => OrderStatus.shipped,
      'DELIVERED' => OrderStatus.delivered,
      'CANCELLED' => OrderStatus.cancelled,
      _ => OrderStatus.unknown,
    };
  }
}

class OrderCancellationResultModel extends OrderCancellationResult {
  const OrderCancellationResultModel({
    required super.message,
    required super.orderId,
    required super.status,
  });

  factory OrderCancellationResultModel.fromJson(Map<String, dynamic> json) {
    return OrderCancellationResultModel(
      message: firstString(json, const <String>['message']) ?? '',
      orderId: firstString(json, const <String>['order_id']) ?? '',
      status: OrderModel.parseStatus(json['status']),
    );
  }
}
