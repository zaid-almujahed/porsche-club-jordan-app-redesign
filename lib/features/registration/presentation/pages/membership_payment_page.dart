import 'package:flutter/material.dart';

import 'package:pcj_v4/core/errors/app_exception.dart';
import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/shared/domain/entities/membership.dart';
import 'package:pcj_v4/shared/domain/entities/user.dart';
import 'package:pcj_v4/shared/widgets/app_dialog.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

import '../controllers/membership_payment_controller.dart';
import '../widgets/payment_page_widgets.dart';

class MembershipPaymentPage extends StatelessWidget {
  const MembershipPaymentPage({
    super.key,
    required this.controller,
    required this.onClose,
    required this.onActivated,
  });

  final MembershipPaymentController controller;
  final ValueChanged<Membership> onActivated;
  final Future<void> Function() onClose;

  Future<void> _payAndActivate() async {
    final Membership? membership = await controller.pay();
    if (membership?.status == MembershipStatus.active) {
      onActivated(membership!);
    }
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
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _confirmClose(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () => _confirmClose(context),
            icon: const Icon(Icons.close_rounded, size: 28),
          ),
        ),
        body: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const AppAssetImage(
                  path: 'assets/images/membership_payment_texture.png',
                  fit: BoxFit.cover,
                ),
                const ColoredBox(color: Color(0xD90F0F11)),
                // Soft red glow behind the header, echoing the welcome page.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.9),
                      radius: 0.9,
                      colors: <Color>[Color(0x40D5001C), Color(0x00000000)],
                    ),
                  ),
                ),
                AppPageBody(
                  topPadding: AppSpacing.xxl,
                  bottomPadding: AppSpacing.xxs,
                  onRefresh: () => controller.load(force: true),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(
                        height: 70,
                        child: AppAssetImage(
                          path: 'assets/images/porsche_club_jordan_logo.png',
                          fit: BoxFit.contain,
                          fallbackIcon: Icons.shield_outlined,
                          fallbackLabel: 'PORSCHE CLUB JORDAN',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppFadeSlideIn(
                        child: Column(
                          children: <Widget>[
                            Text(
                              'Membership Payment Required',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.pageTitle.copyWith(
                                fontSize: 27,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Renew or activate your Porsche Club Jordan '
                              'membership to continue using member features.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const AppAccentBar(),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AsyncStateView<Membership>(
                        state: controller.state,
                        onRetry: () => controller.load(force: true),
                        builder: (BuildContext context, Membership membership) {
                          return GradientPanel(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            radius: AppRadii.large,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Text(
                                  'Membership Activation',
                                  style: AppTextStyles.sectionTitle.copyWith(
                                    fontSize: 19,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                const Divider(color: AppColors.cardBorder),
                                const SizedBox(height: AppSpacing.lg),
                                MembershipFee(
                                  amount: membership.annualFee,
                                  currency: membership.currency,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                const Text(
                                  'GIFT OR REFERRAL CODE',
                                  style: AppTextStyles.overline,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller:
                                            controller.referralCodeController,
                                        style: AppTextStyles.input,
                                        textInputAction: TextInputAction.done,
                                        decoration: const InputDecoration(
                                          hintText: '12-digit code',
                                          prefixIcon: Icon(
                                            Icons.redeem_outlined,
                                            size: 20,
                                          ),
                                        ),
                                        onChanged:
                                            controller.referralCodeChanged,
                                        onSubmitted: (_) {
                                          controller.applyReferralCode();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: SizedBox(
                                        height: 52,
                                        child: FilledButton(
                                          onPressed:
                                              controller.applyReferralCode,
                                          style:
                                              controller.hasAppliedReferralCode
                                              ? AppButtonStyles.outline(
                                                  foregroundColor:
                                                      AppColors.success,
                                                  borderColor: AppColors.success
                                                      .withValues(alpha: 0.5),
                                                  horizontalPadding: 8,
                                                )
                                              : AppButtonStyles.primary,
                                          child: AnimatedSwitcher(
                                            duration: AppMotion.fast,
                                            child: Text(
                                              controller.hasAppliedReferralCode
                                                  ? 'Applied'
                                                  : 'Apply',
                                              key: ValueKey<bool>(
                                                controller
                                                    .hasAppliedReferralCode,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                const Text(
                                  'PAYMENT METHOD',
                                  style: AppTextStyles.overline,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                PaymentMethodTile(
                                  label: 'Credit / Debit Card\n(MEPS)',
                                  selected:
                                      controller.paymentMethod == 'meps_card',
                                  onPressed: () => controller
                                      .selectPaymentMethod('meps_card'),
                                ),
                              ],
                            ),
                          );
                        },
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
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryActionButton(
                        icon: Icons.lock_outline_rounded,
                        height: 58,
                        isLoading: controller.isPaying,
                        label: controller.isPaying
                            ? 'Processing Payment...'
                            : 'Continue to Payment',
                        onPressed:
                            controller.isPaying || !controller.state.hasData
                            ? null
                            : _payAndActivate,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.verified_user_outlined,
                              size: 15,
                              color: AppColors.textFaint,
                            ),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Membership access begins only after the backend '
                              'confirms the payment or activation code.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
