import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/user_orders/data/models/order_model.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';

void main() {
  test('pickup statuses: PENDING, PROCESSING, READY_FOR_PICKUP', () {
    expect(OrderModel.parseStatus('PENDING'), OrderStatus.pending);
    expect(OrderModel.parseStatus('PROCESSING'), OrderStatus.processing);
    expect(
      OrderModel.parseStatus('READY_FOR_PICKUP'),
      OrderStatus.readyForPickup,
    );
    expect(OrderStatus.readyForPickup.label, 'Ready for Pickup');
  });

  test('delivery statuses: PENDING, PROCESSING, SHIPPED, DELIVERED', () {
    expect(OrderModel.parseStatus('CANCELLED'), OrderStatus.cancelled);
    expect(OrderModel.parseStatus('SHIPPED'), OrderStatus.shipped);
    expect(OrderModel.parseStatus('DELIVERED'), OrderStatus.delivered);
    expect(OrderModel.parseStatus('SOMETHING ELSE'), OrderStatus.unknown);
    expect(OrderModel.parseStatus('READY FOR PICKUP'), OrderStatus.unknown);
  });

  test('a collected pickup order is COMPLETED and no longer active', () {
    final Order order = OrderModel.fromJson(<String, dynamic>{
      'order_id': 21,
      'status': 'COMPLETED',
      'delivery_method': 'PICKUP',
    });

    expect(order.status, OrderStatus.completed);
    expect(order.status.label, 'Completed');
    expect(order.isActive, isFalse);
  });

  test('parses a My Orders row', () {
    final Order order = OrderModel.fromJson(<String, dynamic>{
      'order_id': 21,
      'total': 10,
      'status': 'READY_FOR_PICKUP',
      'payment_status': 'PENDING',
      'payment_method': 'CASH',
      'delivery_method': 'PICKUP',
      'delivery_fee': 0,
      'created_at': '2026-09-29T13:11:55.386650',
    });

    expect(order.id, '21');
    expect(order.total, 10);
    expect(order.status, OrderStatus.readyForPickup);
    expect(order.isActive, isTrue);
    expect(order.paymentStatus, 'PENDING');
    expect(order.paymentMethod, 'CASH');
    expect(order.isPickup, isTrue);
    expect(order.deliveryFee, 0);
    expect(order.createdAt, DateTime(2026, 9, 29, 13, 11, 55, 386, 650));
    expect(order.items, isEmpty);
  });

  test('order details add the items', () {
    final Order order = OrderModel.fromJson(<String, dynamic>{
      'order_id': 21,
      'status': 'READY_FOR_PICKUP',
      'created_at': '2026-09-29T13:11:55.386650',
      'delivery_method': 'PICKUP',
      'payment_method': 'CASH',
      'payment_status': 'PENDING',
      'delivery_fee': 0,
      'total': 10,
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'variant_id': 6,
          'item_id': 6,
          'name': 'dsf',
          'color': 'red',
          'size': 's',
          'price': 10,
          'quantity': 1,
          'subtotal': 10,
          'image':
              'https://pub-011fb422a61d4225885f96ace4bd9aca.r2.dev/items/images.png',
        },
      ],
    });

    final CartItem item = order.items.single;
    expect(item.product.name, 'dsf');
    expect(item.variantId, '6');
    expect(item.selectedSize, 's');
    expect(item.quantity, 1);
    expect(item.reportedSubtotal, 10);
    expect(order.itemImagePaths, <String>[
      'https://pub-011fb422a61d4225885f96ace4bd9aca.r2.dev/items/images.png',
    ]);
  });
}
