import 'package:flutter/material.dart';

import 'package:pcj_v5/shared/presentation/pages/cliq_transfer_page.dart';

import '../controllers/order_payment_controller.dart';

/// Paying for the cart with CliQ: the order is placed when the payment is
/// sent. An admin approves it, and the order is prepared then.
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
      intro: controller.payment.paymentId == null
          ? 'Send the order total from your bank app, then add the transfer '
                'number, your CliQ alias and a screenshot of the receipt. Your '
                'order is placed when you submit the payment.'
          : 'Send the order total from your bank app, then add the transfer '
                'number, your CliQ alias and a screenshot of the receipt.',
      refundNote:
          'Cancel while your order is processing and your payment is '
          'refunded here.',
      paidMessage:
          'Order placed. We prepare it once an admin confirms the payment.',
      note:
          'An admin confirms CliQ payments, usually within a day. You can '
          'track your order from My Orders.',
      onPaid: onPaid,
    );
  }
}
