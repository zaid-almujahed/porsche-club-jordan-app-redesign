import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

class PriceSummary extends StatelessWidget {
  const PriceSummary({
    super.key,
    required this.basePrice,
    required this.guestsPrice,
    required this.total,
    required this.currency,
    this.showGuests = true,
  });

  final double basePrice;
  final double guestsPrice;
  final double total;
  final String currency;
  final bool showGuests;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.panel(radius: AppRadii.large),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Thin red rule across the top of the receipt.
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[AppColors.primary, AppColors.primaryDeep],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: AppColors.primaryBright,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text('SUMMARY', style: AppTextStyles.overline),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SummaryRow(
                  label: 'Base Registration',
                  value: basePrice <= 0
                      ? 'FREE'
                      : AppFormatters.money(basePrice, currency),
                ),
                if (showGuests) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  SummaryRow(
                    label: 'Guests',
                    value: guestsPrice <= 0
                        ? 'FREE'
                        : AppFormatters.money(guestsPrice, currency),
                    muted: guestsPrice == 0,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.cardBorder),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Total',
                      style: AppTextStyles.title.copyWith(fontSize: 18),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: AnimatedSwitcher(
                          duration: AppMotion.medium,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                          child: Text(
                            total <= 0
                                ? 'FREE'
                                : AppFormatters.money(total, currency),
                            key: ValueKey<double>(total),
                            style: AppTextStyles.numeric.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 15.5,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.numeric.copyWith(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: muted ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class BasePriceBanner extends StatelessWidget {
  const BasePriceBanner({
    super.key,
    required this.amount,
    required this.currency,
  });

  final double amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: AppDecorations.tintedPanel(
        AppColors.primary,
        radius: AppRadii.medium + 2,
      ),
      child: Row(
        children: <Widget>[
          const AppIconBadge(
            icon: Icons.confirmation_number_outlined,
            size: 42,
            iconSize: 21,
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text('BASE REGISTRATION', style: AppTextStyles.overline),
          ),
          Text(
            amount <= 0 ? 'FREE' : AppFormatters.money(amount, currency),
            style: AppTextStyles.numeric.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class GuestPanel extends StatelessWidget {
  const GuestPanel({
    super.key,
    required this.count,
    required this.limit,
    required this.guestFee,
    required this.currency,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int count;
  final int limit;
  final double guestFee;
  final String currency;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return GradientPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppRadii.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const AppIconBadge(
                icon: Icons.group_add_outlined,
                size: 40,
                iconSize: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Number of Guests',
                      style: AppTextStyles.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      guestFee <= 0
                          ? 'You may register up to $limit guests at no '
                                'additional cost.'
                          : 'Up to $limit guests. Each guest costs '
                                '${AppFormatters.money(guestFee, currency)}.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: <Widget>[
                _StepperButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Remove guest',
                  onPressed: count == 0 ? null : onDecrement,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AnimatedSwitcher(
                        duration: AppMotion.fast,
                        transitionBuilder:
                            (Widget child, Animation<double> animation) =>
                                ScaleTransition(scale: animation, child: child),
                        child: Text(
                          '$count',
                          key: ValueKey<int>(count),
                          style: AppTextStyles.numeric.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        'of $limit',
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                _StepperButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Add guest',
                  onPressed: count >= limit ? null : onIncrement,
                  filled: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppInlineMessage(
            type: AppFeedbackType.info,
            animate: false,
            message:
                'For everyone’s safety, guests who are not included in this '
                'registration will not be permitted entry to the event.',
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return AnimatedOpacity(
      duration: AppMotion.fast,
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: filled ? AppColors.primary : AppColors.surfaceRaised,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          color: Colors.white,
          disabledColor: Colors.white,
          icon: Icon(icon, size: 22),
        ),
      ),
    );
  }
}
