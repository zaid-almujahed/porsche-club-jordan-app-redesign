import 'cart.dart';

/// Pickup orders:   PENDING → PROCESSING → READY FOR PICKUP
/// Delivery orders: PENDING → PROCESSING → SHIPPED → DELIVERED
enum OrderStatus {
  pending,
  processing,
  readyForPickup,
  shipped,
  delivered,
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
    this.message,
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
  final String? message;

  // Ready-for-pickup orders stay active until the member collects them.
  bool get isActive =>
      status == OrderStatus.pending ||
      status == OrderStatus.processing ||
      status == OrderStatus.readyForPickup ||
      status == OrderStatus.shipped;

  bool get isPickup => deliveryMethod.trim().toUpperCase() == 'PICKUP';

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
