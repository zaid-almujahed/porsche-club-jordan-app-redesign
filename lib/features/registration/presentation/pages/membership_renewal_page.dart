import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/features/profile/presentation/widgets/member_card.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/membership_payment_controller.dart';
import '../widgets/payment_page_widgets.dart';

/// Where an expired member lands: their expired club card, what renewing
/// brings back, and how to pay. Unlike the first payment, it speaks to a
/// returning member. The only other way out is signing out.
class MembershipRenewalPage extends StatelessWidget {
  const MembershipRenewalPage({
    super.key,
    required this.controller,
    required this.memberName,
    required this.onClose,
    required this.onRenewed,
    this.onCodeApplied,
  });

  final MembershipPaymentController controller;

  /// The signed-in member, shown on their card.
  final String memberName;
  final Future<void> Function() onClose;
  final ValueChanged<Membership> onRenewed;

  /// Called once a gift / referral code is accepted; defaults to
  /// [onRenewed].
  final ValueChanged<Membership>? onCodeApplied;

  Future<void> _renew(BuildContext context) async {
    final Membership? membership = await controller.pay();
    if (membership != null) {
      onRenewed(membership);
    } else if (context.mounted) {
      _showPaymentError(context);
    }
  }

  Future<void> _applyCode(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final Membership? membership = await controller.applyReferralCode();
    if (membership != null) {
      (onCodeApplied ?? onRenewed)(membership);
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
      title: 'Sign Out?',
      message:
          'Your membership stays expired until you renew. Signing out returns '
          'you to Welcome.',
      confirmLabel: 'Sign Out',
      cancelLabel: 'Stay Here',
      icon: Icons.logout_rounded,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await onClose();
  }

  @override
  Widget build(BuildContext context) {
    final String firstName = memberName.trim().split(RegExp(r'\s+')).first;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _confirmClose(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: PorscheAppBar(
          title: 'Renew Membership',
          showClose: true,
          closeTooltip: 'Sign out',
          onClose: () => _confirmClose(context),
        ),
        body: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            return AppPageBody(
              topPadding: AppSpacing.xl,
              bottomPadding: AppSpacing.xl,
              onRefresh: () => controller.load(force: true),
              child: AsyncStateView<Membership>(
                state: controller.state,
                onRetry: () => controller.load(force: true),
                builder: (BuildContext context, Membership membership) {
                  final DateTime? ended = membership.validUntil;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AppFadeSlideIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              firstName.isEmpty
                                  ? 'Welcome back'
                                  : 'Welcome back, $firstName',
                              style: AppTextStyles.pageTitle.copyWith(
                                fontSize: 26,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              ended == null
                                  ? 'Your membership has expired. Renew to '
                                        'pick up where you left off.'
                                  : 'Your membership expired on '
                                        '${AppFormatters.date(ended)}. Renew '
                                        'to pick up where you left off.',
                              style: AppTextStyles.body,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const AppAccentBar(),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppFadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: MemberCard(
                          memberName: memberName,
                          memberId: membership.memberId,
                          isExpired: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      const Text(
                        'RENEWING BRINGS BACK',
                        style: AppTextStyles.overline,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Row(
                        children: <Widget>[
                          Expanded(
                            child: _Benefit(
                              icon: Icons.event_available_rounded,
                              label: 'Events',
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _Benefit(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Shop',
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _Benefit(
                              icon: Icons.local_offer_outlined,
                              label: 'Offers',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        membership.annualFee == null
                            ? 'Another year of membership, from the day '
                                  'payment is confirmed.'
                            : '${AppFormatters.money(membership.annualFee!, membership.currency)} '
                                  'for another year, from the day payment is '
                                  'confirmed.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.section),
                      const Text('RENEW WITH', style: AppTextStyles.overline),
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
            );
          },
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            return PaymentCheckoutBar(
              buttonLabel: controller.isPaying
                  ? 'Processing Payment...'
                  : 'Renew Membership',
              isLoading: controller.isPaying,
              onPressed:
                  controller.isPaying ||
                      controller.isApplyingCode ||
                      controller.state.data == null
                  ? null
                  : () => _renew(context),
            );
          },
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: AppDecorations.panel(radius: AppRadii.medium),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 22, color: AppColors.primaryBright),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
