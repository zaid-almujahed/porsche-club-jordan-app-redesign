import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

/// What to send and where, each with a Copy button, then the transfer
/// number, the member's alias for a refund and the receipt.
class CliqPaymentForm extends StatelessWidget {
  const CliqPaymentForm({
    super.key,
    required this.payment,
    required this.amount,
    required this.currency,
    required this.transactionController,
    required this.refundNameController,
    required this.receipt,
    required this.onCopy,
    required this.onAddReceipt,
    required this.onRemoveReceipt,
  });

  final CliqPayment payment;

  /// The membership fee; null while the backend does not send it.
  final double? amount;
  final String currency;
  final TextEditingController transactionController;
  final TextEditingController refundNameController;

  /// The screenshot picked so far.
  final CliqReceipt? receipt;
  final ValueChanged<String> onCopy;
  final VoidCallback onAddReceipt;
  final VoidCallback onRemoveReceipt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Pay with CliQ',
          style: AppTextStyles.pageTitle.copyWith(fontSize: 26),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Send the fee from your bank app, then add the transfer number, '
          'your CliQ alias and a screenshot of the receipt.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.md),
        const AppAccentBar(),
        const SizedBox(height: AppSpacing.xl),
        CliqTransferSteps(
          amount: amount,
          currency: currency,
          alias: payment.alias,
          transactionController: transactionController,
          refundNameController: refundNameController,
          refundNote: 'If your payment is ever refunded, it is sent here.',
          receipt: receipt,
          onCopy: onCopy,
          onAddReceipt: onAddReceipt,
          onRemoveReceipt: onRemoveReceipt,
        ),
      ],
    );
  }
}

/// After the receipt is sent: waiting for an admin, who takes no other
/// payment meanwhile; or turned down, with a refund through support (the
/// page's support row) and a new payment.
class CliqReceiptReview extends StatelessWidget {
  const CliqReceiptReview({
    super.key,
    required this.payment,
    required this.amount,
    required this.currency,
    required this.onSendDifferent,
  });

  final CliqPayment payment;

  /// The membership fee; null while the backend does not send it.
  final double? amount;
  final String currency;

  /// Sends a new payment once the receipt was rejected.
  final VoidCallback onSendDifferent;

  @override
  Widget build(BuildContext context) {
    final bool rejected = payment.receiptStatus == CliqReceiptStatus.rejected;
    final Color tone = rejected ? AppColors.danger : AppColors.accentSteel;
    final DateTime? submittedAt = payment.submittedAt;
    final double? amount = this.amount;
    final String? reason = payment.rejectionReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: tone.withValues(alpha: 0.4)),
            ),
            child: Icon(
              rejected ? Icons.close_rounded : Icons.hourglass_top_rounded,
              color: tone,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          rejected ? 'PAYMENT\nREJECTED' : 'PAYMENT\nUNDER REVIEW',
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          rejected
              ? 'An admin rejected your transfer. Contact support to get a '
                    'refund for it, or send a new payment.'
              : 'We received your receipt. An admin will confirm it, usually '
                    'within a day, and we will notify you once your '
                    'membership is active.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.xl),
        CliqPanel(
          children: <Widget>[
            if (amount != null)
              CliqDetailRow(
                label: 'Amount',
                value: AppFormatters.money(amount, currency),
              ),
            CliqDetailRow(label: 'Sent to', value: payment.alias),
            if (submittedAt != null)
              CliqDetailRow(
                label: 'Submitted',
                value: AppFormatters.numericDate(submittedAt),
              ),
            if (rejected && reason != null)
              CliqDetailRow(label: 'Reason', value: reason),
          ],
        ),
        if (rejected) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          SecondaryActionButton(
            label: 'Send a New Payment',
            height: 54,
            onPressed: onSendDifferent,
          ),
        ],
      ],
    );
  }
}
