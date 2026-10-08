import 'cart.dart';

/// Pickup orders:   PENDING → PROCESSING → READY_FOR_PICKUP → COMPLETED
/// Delivery orders: PENDING → PROCESSING → SHIPPED → DELIVERED
/// CliQ orders start as PENDING_PAYMENT until an admin confirms the payment.
/// A cancelled one that was paid is REFUND_PENDING while it is refunded, and
/// REFUNDED once it was. One whose payment an admin turned down is REJECTED
/// (its payment then reads FAILED).
enum OrderStatus {
  pendingPayment,
  pending,
  processing,
  readyForPickup,
  shipped,
  delivered,
  completed,
  cancelled,
  refundPending,
  refunded,
  rejected,
  unknown,
}

extension OrderStatusLabel on OrderStatus {
  /// Display label, e.g. "Ready for Pickup".
  String get label => switch (this) {
    OrderStatus.pendingPayment => 'Pending',
    OrderStatus.pending => 'Pending',
    OrderStatus.processing => 'Processing',
    OrderStatus.readyForPickup => 'Ready for Pickup',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.completed => 'Completed',
    OrderStatus.cancelled => 'Cancelled',
    OrderStatus.refundPending => 'Refund Pending',
    OrderStatus.refunded => 'Refunded',
    OrderStatus.rejected => 'Rejected',
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

  /// The CliQ payment a transfer is sent for.
  final String? paymentId;

  String get _payment => paymentStatus.trim().toUpperCase();

  /// Its CliQ payment was rejected, cancelled or is being refunded, which
  /// removes the order. A FAILED one did not go through and can be sent
  /// again.
  bool get isRemovedByPayment =>
      isPaidWithCliq &&
      switch (_payment) {
        'REJECTED' ||
        'CANCELLED' ||
        'CANCELED' ||
        'PENDING_REFUND' ||
        'REFUND_PENDING' ||
        'REFUNDED' ||
        'REJECT_REFUNDED' => true,
        _ => false,
      };

  /// The payment's state as a chip shows it: only for a CliQ order, never a
  /// cash one.
  bool get showsPaymentStatus => isPaidWithCliq;

  /// Its last CliQ payment did not go through.
  bool get hasFailedPayment => _payment == 'FAILED';

  /// Removed by its payment while its own status has not caught up: it
  /// reads REMOVED rather than, say, Pending.
  bool get readsRemoved =>
      isRemovedByPayment &&
      status != OrderStatus.cancelled &&
      status != OrderStatus.refundPending &&
      status != OrderStatus.refunded &&
      status != OrderStatus.rejected;

  // Ready-for-pickup orders stay active until the member collects them.
  bool get isActive =>
      !isRemovedByPayment &&
      (status == OrderStatus.pendingPayment ||
          status == OrderStatus.pending ||
          status == OrderStatus.processing ||
          status == OrderStatus.readyForPickup ||
          status == OrderStatus.shipped);

  bool get isPickup => deliveryMethod.trim().toUpperCase() == 'PICKUP';

  /// Each item's photo, in order; empty for an item without one.
  List<String> get itemImagePaths => items
      .map((CartItem item) => item.product.primaryImageUrl ?? '')
      .toList(growable: false);

  Order copyWith({
    List<CartItem>? items,
    String? paymentStatus,
    String? paymentId,
  }) {
    return Order(
      id: id,
      items: items ?? this.items,
      status: status,
      createdAt: createdAt,
      total: total,
      currency: currency,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod,
      deliveryMethod: deliveryMethod,
      deliveryFee: deliveryFee,
      paymentId: paymentId ?? this.paymentId,
    );
  }

  bool get isPaidWithCliq => paymentMethod.trim().toUpperCase() == 'CLIQ';

  /// An admin is checking the CliQ payment; no other one can be sent.
  bool get isPaymentUnderReview =>
      isActive && _payment == 'WAITING_ADMIN_APPROVAL';

  /// A CliQ payment can be sent for it: its payment is still PENDING, or
  /// FAILED.
  bool get canSendPayment =>
      isPaidWithCliq &&
      isActive &&
      (_payment == 'PENDING' || _payment == 'FAILED') &&
      (paymentId?.isNotEmpty ?? false);

  /// Orders can be cancelled until they are ready.
  bool get canCancel =>
      isActive &&
      (status == OrderStatus.pendingPayment ||
          status == OrderStatus.pending ||
          status == OrderStatus.processing);

  /// Cancelling refunds the CliQ payment: one was sent, and the order is
  /// not ready yet.
  bool get refundsOnCancel =>
      isPaidWithCliq &&
      canCancel &&
      (_payment == 'WAITING_ADMIN_APPROVAL' || _payment == 'COMPLETED');
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
