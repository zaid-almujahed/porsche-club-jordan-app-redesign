import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/membership_payment_controller.dart';
import '../widgets/cliq_payment_widgets.dart';
import '../widgets/payment_page_widgets.dart';

/// Paying the membership with CliQ: the member sends the amount to the
/// club's alias from their bank app and uploads a screenshot of the receipt.
/// Until an admin confirms it, the page shows the review.
class CliqPaymentPage extends StatelessWidget {
  const CliqPaymentPage({
    super.key,
    required this.controller,
    required this.onContactSupport,
  });

  final MembershipPaymentController controller;
  final VoidCallback onContactSupport;

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) showAppSuccessPulse(context, label: 'Copied');
  }

  Future<void> _addReceipt(BuildContext context) async {
    final PhotoSource? source = await showPhotoSourceSheet(context);
    if (source != null) await controller.pickReceipt(source);
  }

  Future<void> _submit(BuildContext context) async {
    final bool sent = await controller.submitReceipt();
    if (!context.mounted) return;
    if (sent) {
      showAppSuccessPulse(context, label: 'Receipt Sent');
    } else {
      final Object? error = controller.paymentError;
      if (error != null) showAppErrorPulse(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // A receipt that was not sent is not kept.
        if (didPop) controller.discardReceipt();
      },
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          final CliqPayment? payment = controller.cliqPayment;
          final bool inReview = controller.showsReceiptReview;
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: const PorscheAppBar(title: 'Membership', showBack: true),
            body: payment == null
                ? const SizedBox.shrink()
                : AppPageBody(
                    topPadding: AppSpacing.xl,
                    bottomPadding: AppSpacing.xl,
                    onRefresh: () => controller.load(force: true),
                    child: AnimatedSwitcher(
                      duration: AppMotion.medium,
                      layoutBuilder: (Widget? current, List<Widget> previous) =>
                          AppMotion.switcherLayout(
                            current,
                            previous,
                            alignment: Alignment.topCenter,
                          ),
                      child: inReview
                          ? CliqReceiptReview(
                              key: const ValueKey<String>('review'),
                              payment: payment,
                              onSendDifferent: controller.replaceReceipt,
                              onContactSupport: onContactSupport,
                            )
                          : CliqPaymentForm(
                              key: const ValueKey<String>('form'),
                              payment: payment,
                              receipt: controller.receipt,
                              onCopy: (String value) => _copy(context, value),
                              onAddReceipt: () => _addReceipt(context),
                              onRemoveReceipt: controller.removeReceipt,
                            ),
                    ),
                  ),
            bottomNavigationBar: payment == null || inReview
                ? null
                : PaymentCheckoutBar(
                    buttonLabel: controller.isSendingReceipt
                        ? 'Sending Receipt...'
                        : 'Submit for Review',
                    isLoading: controller.isSendingReceipt,
                    onPressed:
                        controller.receipt == null ||
                            controller.isSendingReceipt
                        ? null
                        : () => _submit(context),
                  ),
          );
        },
      ),
    );
  }
}
