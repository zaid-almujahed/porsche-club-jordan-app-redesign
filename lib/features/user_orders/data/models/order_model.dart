import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/features/shop/data/models/cart_model.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';

/// An order as `GET /member/orders` lists it:
///
/// ```json
/// {
///   "order_id": 21,
///   "total": 10,
///   "status": "READY_FOR_PICKUP",
///   "payment_status": "PENDING",
///   "payment_method": "CASH",
///   "delivery_method": "PICKUP",
///   "delivery_fee": 0,
///   "created_at": "2026-09-29T13:11:55.386650"
/// }
/// ```
///
/// The list has no items; `GET /member/orders/{order_id}` adds them. A CliQ
/// order also needs `payment_id` to be paid from My Orders, and its
/// `transaction_number` once the payment is sent.
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
    super.paymentId,
    super.hasPaymentProof,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final Object? items = json['items'];
    return OrderModel(
      id: firstString(json, const <String>['order_id']) ?? '',
      items: items is List
          ? items
                .whereType<Map>()
                .map<CartItem>(
                  (Map item) =>
                      CartItemModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const <CartItem>[],
      status: parseStatus(json['status']),
      createdAt:
          firstServerDateTime(json, const <String>['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      total: firstDouble(json, const <String>['total']) ?? 0,
      currency: 'JOD',
      paymentStatus: firstString(json, const <String>['payment_status']) ?? '',
      paymentMethod: firstString(json, const <String>['payment_method']) ?? '',
      deliveryMethod:
          firstString(json, const <String>['delivery_method']) ?? '',
      deliveryFee: firstDouble(json, const <String>['delivery_fee']) ?? 0,
      paymentId: firstString(json, const <String>['payment_id']),
      hasPaymentProof:
          firstString(json, const <String>[
            'transaction_number',
            'proof_url',
          ]) !=
          null,
    );
  }

  static OrderStatus parseStatus(Object? value) {
    final String normalized = (value?.toString() ?? '').trim().toUpperCase();
    return switch (normalized) {
      'PENDING_PAYMENT' => OrderStatus.pendingPayment,
      'PENDING' => OrderStatus.pending,
      'PROCESSING' => OrderStatus.processing,
      'READY_FOR_PICKUP' => OrderStatus.readyForPickup,
      'SHIPPED' => OrderStatus.shipped,
      'DELIVERED' => OrderStatus.delivered,
      'COMPLETED' => OrderStatus.completed,
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
