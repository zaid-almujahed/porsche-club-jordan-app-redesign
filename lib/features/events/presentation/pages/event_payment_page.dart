import 'package:flutter/material.dart';

import 'package:pcj_v5/shared/presentation/pages/cliq_transfer_page.dart';

import '../controllers/event_payment_controller.dart';

/// Paying for an event with CliQ. An admin approves it, and the ticket
/// appears then.
class EventPaymentPage extends StatelessWidget {
  const EventPaymentPage({
    super.key,
    required this.controller,
    required this.onPaid,
  });

  final EventPaymentController controller;
  final VoidCallback onPaid;

  @override
  Widget build(BuildContext context) {
    return CliqTransferPage(
      controller: controller,
      intro:
          'Send the amount for ${controller.payment.eventTitle} from your '
          'bank app, then add the transfer number, your CliQ alias and a '
          'screenshot of the receipt.',
      refundNote:
          'Cancel before the event starts and your payment is refunded '
          'here.',
      paidMessage: 'Your ticket appears once an admin confirms it.',
      note:
          'An admin confirms CliQ payments, usually within a day. Your '
          'ticket appears once yours is confirmed.',
      onPaid: onPaid,
      notice: controller.renewsRegistration
          ? 'Submitting cancels your unpaid registration and registers you '
                'again together with this payment, with the same guests.'
          : null,
    );
  }
}
