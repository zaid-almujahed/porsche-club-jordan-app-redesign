import 'package:flutter/material.dart';
import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/core/utils/app_formatters.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

class MembershipFee extends StatelessWidget {
  const MembershipFee({
    super.key,
    required this.amount,
    required this.currency,
  });

  final double? amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const AppIconBadge(
          icon: Icons.workspace_premium_outlined,
          size: 46,
          iconSize: 23,
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('MEMBERSHIP FEE', style: AppTextStyles.overline),
              SizedBox(height: 4),
              Text('Annual Membership', style: AppTextStyles.title),
            ],
          ),
        ),
        Text(
          amount == null
              ? 'Fee\npending'
              : AppFormatters.money(amount!, currency).replaceFirst(' ', '\n'),
          textAlign: TextAlign.right,
          style: AppTextStyles.numeric.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.label,
    required this.selected,
    this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.curve,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: selected
            ? Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.07),
                AppColors.panelDark,
              )
            : AppColors.panelDark,
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.cardBorder,
        ),
        borderRadius: BorderRadius.circular(AppRadii.medium + 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 76,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: <Widget>[
                  AppIconBadge(
                    icon: Icons.credit_card_rounded,
                    color: selected
                        ? AppColors.primaryBright
                        : AppColors.textMuted,
                    size: 42,
                    iconSize: 21,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.title.copyWith(fontSize: 16),
                    ),
                  ),
                  AnimatedContainer(
                    duration: AppMotion.medium,
                    curve: AppMotion.curve,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryBright
                            : AppColors.textFaint,
                        width: selected ? 6.5 : 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
