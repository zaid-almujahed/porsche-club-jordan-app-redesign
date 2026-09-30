import 'cart.dart';

/// Pickup orders:   PENDING → PROCESSING → READY_FOR_PICKUP → COMPLETED
/// Delivery orders: PENDING → PROCESSING → SHIPPED → DELIVERED
enum OrderStatus {
  pending,
  processing,
  readyForPickup,
  shipped,
  delivered,
  completed,
  cancelled,
  unknown,
}

extension OrderStatusLabel on OrderStatus {
  /// Display label, e.g. "Ready for Pickup".
  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.processing => 'Processing',
    OrderStatus.readyForPickup => 'Ready for Pickup',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.completed => 'Completed',
    OrderStatus.cancelled => 'Cancelled',
    OrderStatus.unknown => 'Unknown',
  };
}

class Order {
  const Order({
    required this.id,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.total,
    required this.currency,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.deliveryMethod,
    required this.deliveryFee,
  });

  final String id;
  final List<CartItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final double total;
  final String currency;
  final String paymentStatus;
  final String paymentMethod;
  final String deliveryMethod;
  final double deliveryFee;

  // Ready-for-pickup orders stay active until the member collects them.
  bool get isActive =>
      status == OrderStatus.pending ||
      status == OrderStatus.processing ||
      status == OrderStatus.readyForPickup ||
      status == OrderStatus.shipped;

  bool get isPickup => deliveryMethod.trim().toUpperCase() == 'PICKUP';

  /// Each item's photo, in order; empty for an item without one.
  List<String> get itemImagePaths => items
      .map((CartItem item) => item.product.primaryImageUrl ?? '')
      .toList(growable: false);

  Order copyWith({List<CartItem>? items}) {
    return Order(
      id: id,
      items: items ?? this.items,
      status: status,
      createdAt: createdAt,
      total: total,
      currency: currency,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      deliveryMethod: deliveryMethod,
      deliveryFee: deliveryFee,
    );
  }

  bool get canCancel =>
      status == OrderStatus.pending &&
      paymentMethod.trim().toUpperCase() == 'CASH';
}

class OrderCancellationResult {
  const OrderCancellationResult({
    required this.message,
    required this.orderId,
    required this.status,
  });

  final String message;
  final String orderId;
  final OrderStatus status;
}
