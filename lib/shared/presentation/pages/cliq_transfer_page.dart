import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/cliq_transfer_controller.dart';

/// Paying with CliQ (an event or an order): send the amount from a bank
/// app, then the transfer number, the member's alias for a refund and a
/// screenshot of the receipt. An admin approves it.
class CliqTransferPage extends StatelessWidget {
  const CliqTransferPage({
    super.key,
    required this.controller,
    required this.intro,
    required this.refundNote,
    required this.paidMessage,
    required this.note,
    required this.onPaid,
    this.notice,
  });

  final CliqTransferController controller;

  /// Under the title: what the payment is for.
  final String intro;

  /// When the payment is refunded.
  final String refundNote;

  /// Shown once the payment is sent.
  final String paidMessage;

  /// Above the button: what happens next.
  final String note;
  final VoidCallback onPaid;

  /// Shown above the steps, e.g. what submitting does besides paying.
  final String? notice;

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) showAppSuccessPulse(context, label: 'Copied');
  }

  Future<void> _addReceipt(BuildContext context) async {
    final PhotoSource? source = await showPhotoSourceSheet(context);
    if (source != null) await controller.pickReceipt(source);
  }

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final bool sent = await controller.submit();
    if (!context.mounted) return;
    if (!sent) {
      final Object? error = controller.error;
      if (error != null) showAppErrorPulse(context, error);
      return;
    }
    showAppSuccessPulse(context, label: 'Payment Sent', message: paidMessage);
    onPaid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const PorscheAppBar(title: 'Payment', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            topPadding: AppSpacing.xl,
            bottomPadding: AppSpacing.xl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Pay with CliQ',
                  style: AppTextStyles.pageTitle.copyWith(fontSize: 26),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(intro, style: AppTextStyles.body),
                const SizedBox(height: AppSpacing.md),
                const AppAccentBar(),
                if (notice != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  AppInlineMessage(
                    type: AppFeedbackType.info,
                    message: notice!,
                    animate: false,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                CliqTransferSteps(
                  amount: controller.amount,
                  currency: controller.currency,
                  alias: controller.alias,
                  transactionController: controller.transactionController,
                  refundNameController: controller.refundNameController,
                  refundNote: refundNote,
                  receipt: controller.receipt,
                  onCopy: (String value) => _copy(context, value),
                  onAddReceipt: () => _addReceipt(context),
                  onRemoveReceipt: controller.removeReceipt,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) => PaymentCheckoutBar(
          buttonLabel: controller.isSubmitting
              ? 'Sending Payment...'
              : 'Submit Payment',
          isLoading: controller.isSubmitting,
          onPressed: controller.canSubmit ? () => _submit(context) : null,
          note: note,
        ),
      ),
    );
  }
}
