import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/user_orders/data/models/order_model.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';

void main() {
  test('pickup statuses: PENDING, PROCESSING, READY FOR PICKUP', () {
    expect(OrderModel.parseStatus('PENDING'), OrderStatus.pending);
    expect(OrderModel.parseStatus('PROCESSING'), OrderStatus.processing);
    for (final String value in <String>[
      'READY FOR PICKUP',
      'READY_FOR_PICKUP',
      'ready-for-pickup',
    ]) {
      expect(
        OrderModel.parseStatus(value),
        OrderStatus.readyForPickup,
        reason: value,
      );
    }
    expect(OrderStatus.readyForPickup.label, 'Ready for Pickup');
  });

  test('delivery statuses: PENDING, PROCESSING, SHIPPED, DELIVERED', () {
    expect(OrderModel.parseStatus('SHIPPED'), OrderStatus.shipped);
    expect(OrderModel.parseStatus('DELIVERED'), OrderStatus.delivered);
    expect(OrderModel.parseStatus('SOMETHING ELSE'), OrderStatus.unknown);
  });
}
