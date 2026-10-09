import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/membership_payment_controller.dart';
import '../widgets/payment_page_widgets.dart';

class MembershipPaymentPage extends StatelessWidget {
  const MembershipPaymentPage({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onActivated,
    this.onCodeApplied,
    this.onPayWithCliq,
  });

  final MembershipPaymentController controller;
  final ValueChanged<Membership> onActivated;

  /// Called once a gift / referral code is accepted; defaults to
  /// [onActivated].
  final ValueChanged<Membership>? onCodeApplied;
  final Future<void> Function() onClose;

  /// Opens the CliQ page, where the member pays and sends the receipt.
  final VoidCallback? onPayWithCliq;

  Future<void> _payAndActivate(BuildContext context) async {
    if (controller.paysWithCliq && onPayWithCliq != null) {
      onPayWithCliq!();
      return;
    }
    final Membership? membership = await controller.pay();
    if (membership != null) {
      onActivated(membership);
    } else if (context.mounted) {
      _showPaymentError(context);
    }
  }

  Future<void> _applyCode(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final Membership? membership = await controller.applyReferralCode();
    if (membership != null) {
      (onCodeApplied ?? onActivated)(membership);
    } else if (context.mounted) {
      _showPaymentError(context);
    }
  }

  void _showPaymentError(BuildContext context) {
    final Object? error = controller.paymentError;
    if (error != null) showAppErrorPulse(context, error);
  }

  Future<void> _confirmClose(BuildContext context) async {
    final bool confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Return to Welcome?',
      message:
          'Your membership will remain inactive until payment is completed. '
          'Returning to Welcome will sign you out.',
      confirmLabel: 'Return to Welcome',
      cancelLabel: 'Stay Here',
      icon: Icons.logout_rounded,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await onClose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // Leaving asks before signing out.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _confirmClose(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        extendBodyBehindAppBar: true,
        appBar: PorscheAppBar(
          title: 'Membership',
          showClose: true,
          closeTooltip: 'Close',
          onClose: () => _confirmClose(context),
        ),
        // Redesigned as a standard subscription checkout: plan, payment
        // method, code, order summary and a fixed pay bar.
        body: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -1.1),
                      radius: 0.9,
                      colors: <Color>[Color(0x33D5001C), Color(0x00000000)],
                    ),
                  ),
                ),
                AppPageBody(
                  topPadding: AppSpacing.xl,
                  bottomPadding: AppSpacing.xl,
                  onRefresh: () => controller.load(force: true),
                  child: AsyncStateView<Membership>(
                    state: controller.state,
                    onRetry: () => controller.load(force: true),
                    builder: (BuildContext context, Membership membership) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppFadeSlideIn(child: const _CheckoutHeader()),
                          const SizedBox(height: AppSpacing.xl),
                          AppFadeSlideIn(
                            delay: const Duration(milliseconds: 60),
                            child: MembershipPlanCard(membership: membership),
                          ),
                          const SizedBox(height: AppSpacing.section),
                          const Text(
                            'PAYMENT METHOD',
                            style: AppTextStyles.overline,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          PaymentMethodTile(
                            label: 'CliQ',
                            subtitle: 'Instant transfer from your bank app',
                            icon: Icons.account_balance_rounded,
                            selected: controller.paymentMethod == 'cliq',
                            onPressed: () =>
                                controller.selectPaymentMethod('cliq'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const PaymentMethodTile(
                            label: 'Credit or debit card',
                            subtitle: 'Visa & Mastercard · processed by MEPS',
                            selected: false,
                            comingSoon: true,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PromoCodeSection(
                            controller: controller.referralCodeController,
                            isApplying: controller.isApplyingCode,
                            enabled: !controller.isPaying,
                            onApply: () => _applyCode(context),
                          ),
                          if (controller.paymentNotice != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            AppInlineMessage(
                              message: controller.paymentNotice!,
                              type: AppFeedbackType.warning,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            final Membership? membership = controller.state.data;
            final double? amount = membership?.annualFee;
            final String? amountLabel = amount == null
                ? null
                : AppFormatters.money(amount, membership!.currency);
            return PaymentCheckoutBar(
              buttonLabel: controller.isPaying
                  ? 'Processing Payment...'
                  : controller.hasTransferWithClub
                  ? 'View Payment Status'
                  : amountLabel == null
                  ? 'Continue to Payment'
                  : 'Pay $amountLabel',
              isLoading: controller.isPaying,
              onPressed:
                  controller.isPaying ||
                      controller.isApplyingCode ||
                      membership == null
                  ? null
                  : () => _payAndActivate(context),
            );
          },
        ),
      ),
    );
  }
}

/// Title and one line of context for the first payment.
class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Complete Your Membership',
          style: AppTextStyles.pageTitle.copyWith(fontSize: 26),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Your application has been approved. Complete payment to activate '
          'your membership.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.md),
        const AppAccentBar(),
      ],
    );
  }
}
