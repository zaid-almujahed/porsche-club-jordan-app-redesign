import 'cart.dart';

/// Pickup orders:   PENDING → PROCESSING → READY_FOR_PICKUP → COMPLETED
/// Delivery orders: PENDING → PROCESSING → SHIPPED → DELIVERED
/// CliQ orders start as PENDING_PAYMENT until an admin confirms the payment.
enum OrderStatus {
  pendingPayment,
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
    OrderStatus.pendingPayment => 'Awaiting Payment',
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
    this.paymentId,
    this.hasPaymentProof = false,
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

  /// The payment a CliQ transfer is sent for.
  final String? paymentId;

  /// The member sent the CliQ transfer number and receipt.
  final bool hasPaymentProof;

  // Ready-for-pickup orders stay active until the member collects them.
  bool get isActive =>
      status == OrderStatus.pendingPayment ||
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
      paymentId: paymentId,
      hasPaymentProof: hasPaymentProof,
    );
  }

  bool get isPaidWithCliq => paymentMethod.trim().toUpperCase() == 'CLIQ';

  /// A CliQ order whose payment was not sent yet.
  bool get awaitsPayment =>
      status == OrderStatus.pendingPayment && !hasPaymentProof;

  /// The CliQ payment was sent and an admin is checking it.
  bool get isPaymentUnderReview =>
      status == OrderStatus.pendingPayment && hasPaymentProof;

  /// Orders can be cancelled until they are ready.
  bool get canCancel =>
      status == OrderStatus.pendingPayment ||
      status == OrderStatus.pending ||
      status == OrderStatus.processing;

  /// Cancelling a paid CliQ order while it is processing refunds it.
  bool get refundsOnCancel =>
      isPaidWithCliq && status == OrderStatus.processing;
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
