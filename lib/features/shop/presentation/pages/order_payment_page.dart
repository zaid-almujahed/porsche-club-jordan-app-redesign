import 'package:flutter/material.dart';

import 'package:pcj_v5/shared/presentation/pages/cliq_transfer_page.dart';

import '../controllers/order_payment_controller.dart';

/// Paying for an order with CliQ. An admin approves it, and the order is
/// prepared then.
class OrderPaymentPage extends StatelessWidget {
  const OrderPaymentPage({
    super.key,
    required this.controller,
    required this.onPaid,
  });

  final OrderPaymentController controller;
  final VoidCallback onPaid;

  @override
  Widget build(BuildContext context) {
    return CliqTransferPage(
      controller: controller,
      intro:
          'Send the amount for order #${controller.payment.orderId} from '
          'your bank app, then add the transfer number, your CliQ alias and '
          'a screenshot of the receipt.',
      refundNote:
          'Cancel while your order is processing and your payment is '
          'refunded here.',
      paidMessage: 'We prepare your order once an admin confirms it.',
      note:
          'An admin confirms CliQ payments, usually within a day. You can '
          'track your order from My Orders.',
      onPaid: onPaid,
    );
  }
}
