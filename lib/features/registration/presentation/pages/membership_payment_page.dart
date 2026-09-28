import 'package:flutter/material.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
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
    this.isRenewal = false,
  });

  final MembershipPaymentController controller;
  final ValueChanged<Membership> onActivated;
  final Future<void> Function() onClose;

  /// An active member renewing early (from Manage Membership): back simply
  /// returns, instead of signing out.
  final bool isRenewal;

  Future<void> _payAndActivate() async {
    final Membership? membership = await controller.pay(isRenewal: isRenewal);
    if (membership != null) onActivated(membership);
  }

  Future<void> _applyCode(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final Membership? membership = await controller.applyReferralCode(
      isRenewal: isRenewal,
    );
    if (membership != null) onActivated(membership);
  }

  Future<void> _confirmClose(BuildContext context) async {
    if (isRenewal) {
      await onClose();
      return;
    }
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
      // Renewal uses the app bar's back handling; first-time / expired
      // payment asks before signing out.
      canPop: isRenewal,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && !isRenewal) _confirmClose(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: isRenewal
            ? PorscheAppBar(
                title: 'Membership',
                showBack: true,
                onBack: () => _confirmClose(context),
              )
            : PorscheAppBar(
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
                          AppFadeSlideIn(
                            child: _CheckoutHeader(
                              membership: membership,
                              isRenewal: isRenewal,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppFadeSlideIn(
                            delay: const Duration(milliseconds: 60),
                            child: MembershipPlanCard(
                              membership: membership,
                              isRenewal: isRenewal,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.section),
                          const Text(
                            'PAYMENT METHOD',
                            style: AppTextStyles.overline,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          PaymentMethodTile(
                            label: 'Credit or debit card',
                            subtitle: 'Visa & Mastercard · processed by MEPS',
                            selected: controller.paymentMethod == 'meps_card',
                            onPressed: () =>
                                controller.selectPaymentMethod('meps_card'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PromoCodeSection(
                            controller: controller.referralCodeController,
                            isApplying: controller.isApplyingCode,
                            isApplied: controller.hasAppliedReferralCode,
                            enabled: !controller.isPaying,
                            onApply: () => _applyCode(context),
                            onChanged: controller.referralCodeChanged,
                          ),
                          if (controller.paymentError != null) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            AppInlineMessage.error(
                              readableError(controller.paymentError!),
                            ),
                          ],
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
                  : amountLabel == null
                  ? 'Continue to Payment'
                  : 'Pay $amountLabel',
              isLoading: controller.isPaying,
              onPressed:
                  controller.isPaying ||
                      controller.isApplyingCode ||
                      membership == null
                  ? null
                  : _payAndActivate,
            );
          },
        ),
      ),
    );
  }
}

/// Title and one line of context: renewal, expired or first payment.
class _CheckoutHeader extends StatelessWidget {
  const _CheckoutHeader({required this.membership, required this.isRenewal});

  final Membership membership;
  final bool isRenewal;

  @override
  Widget build(BuildContext context) {
    final DateTime? end = membership.validUntil;
    final bool isExpired = membership.status == MembershipStatus.expired;
    final String title = isRenewal || isExpired
        ? 'Renew Your Membership'
        : 'Complete Your Membership';
    final String subtitle = isRenewal && end != null
        ? 'Your membership is valid until ${AppFormatters.date(end)}.'
        : isExpired && end != null
        ? 'Your membership expired on ${AppFormatters.date(end)}. '
              'Renew to regain access.'
        : isExpired
        ? 'Your membership has expired. Renew to regain access.'
        : 'Your application has been approved. Complete payment to '
              'activate your membership.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppTextStyles.pageTitle.copyWith(fontSize: 26)),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.md),
        const AppAccentBar(),
      ],
    );
  }
}
