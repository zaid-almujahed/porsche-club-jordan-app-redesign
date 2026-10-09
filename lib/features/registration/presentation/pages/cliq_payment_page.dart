import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/membership_payment_controller.dart';
import '../widgets/cliq_payment_widgets.dart';

/// Paying the membership with CliQ: the member sends the fee to the club's
/// alias from their bank app, then gives the transfer number, their alias
/// for a refund and a screenshot of the receipt. While an admin checks it,
/// the member is held on its status, as on the application's: no way back,
/// only support or signing out, until it is approved (on to Home) or
/// rejected.
class CliqPaymentPage extends StatelessWidget {
  const CliqPaymentPage({
    super.key,
    required this.controller,
    required this.onContactSupport,
    required this.onLogOut,
  });

  final MembershipPaymentController controller;
  final VoidCallback onContactSupport;
  final VoidCallback onLogOut;

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
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final CliqPayment? payment = controller.cliqPayment;
        final bool inReview = controller.showsReceiptReview;
        final bool locked = controller.hasPendingReceipt;
        final Membership? membership = controller.state.data;
        return PopScope<Object?>(
          canPop: !locked,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            // A receipt that was not sent is not kept.
            if (didPop) controller.discardReceipt();
          },
          child: Scaffold(
            backgroundColor: AppColors.canvas,
            extendBodyBehindAppBar: true,
            appBar: PorscheAppBar(title: 'Membership', showBack: !locked),
            body: payment == null
                ? const SizedBox.shrink()
                : AppPageBody(
                    topPadding: AppSpacing.xl,
                    bottomPadding: AppSpacing.xl,
                    onRefresh: () => controller.load(force: true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AnimatedSwitcher(
                          duration: AppMotion.medium,
                          layoutBuilder:
                              (Widget? current, List<Widget> previous) =>
                                  AppMotion.switcherLayout(
                                    current,
                                    previous,
                                    alignment: Alignment.topCenter,
                                  ),
                          child: inReview
                              ? CliqReceiptReview(
                                  key: const ValueKey<String>('review'),
                                  payment: payment,
                                  amount: membership?.annualFee,
                                  currency: membership?.currency ?? 'JOD',
                                  onSendDifferent: controller.replaceReceipt,
                                )
                              : CliqPaymentForm(
                                  key: const ValueKey<String>('form'),
                                  payment: payment,
                                  amount: membership?.annualFee,
                                  currency: membership?.currency ?? 'JOD',
                                  transactionController:
                                      controller.transactionController,
                                  refundNameController:
                                      controller.refundNameController,
                                  receipt: controller.receipt,
                                  onCopy: (String value) =>
                                      _copy(context, value),
                                  onAddReceipt: () => _addReceipt(context),
                                  onRemoveReceipt: controller.removeReceipt,
                                ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SupportHelpRow(onPressed: onContactSupport),
                        if (locked) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          SecondaryActionButton(
                            label: 'Log Out',
                            onPressed: onLogOut,
                          ),
                        ],
                      ],
                    ),
                  ),
            bottomNavigationBar: payment == null || inReview
                ? null
                : PaymentCheckoutBar(
                    buttonLabel: controller.isSendingReceipt
                        ? 'Sending Receipt...'
                        : 'Submit for Review',
                    isLoading: controller.isSendingReceipt,
                    onPressed: controller.canSubmitReceipt
                        ? () => _submit(context)
                        : null,
                  ),
          ),
        );
      },
    );
  }
}
