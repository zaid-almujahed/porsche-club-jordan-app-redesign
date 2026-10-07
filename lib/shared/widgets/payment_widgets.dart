import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_badges.dart';
import 'package:pcj_v5/shared/widgets/app_buttons.dart';
import 'package:pcj_v5/shared/widgets/coming_soon.dart';

// Choosing how to pay, and the pay bar (membership and events).

/// A payment option.
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.label,
    required this.selected,
    this.onPressed,
    this.subtitle,
    this.icon = Icons.credit_card_rounded,
    this.comingSoon = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  /// Second line, e.g. accepted cards and the processor.
  final String? subtitle;
  final IconData icon;

  /// Not offered yet: greyed out, and a tap shakes it and says "Coming Soon".
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    if (!comingSoon) return _tile(onTap: onPressed, showTag: false);
    return ComingSoonBuilder(
      builder: (BuildContext context, VoidCallback onTap, bool showTag) =>
          _tile(onTap: onTap, showTag: showTag),
    );
  }

  Widget _tile({required VoidCallback? onTap, required bool showTag}) {
    final double fade = comingSoon ? 0.4 : 1;
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
          onTap: onTap,
          child: SizedBox(
            height: 76,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Opacity(
                    opacity: fade,
                    child: AppIconBadge(
                      icon: icon,
                      color: selected
                          ? AppColors.primaryBright
                          : AppColors.textMuted,
                      size: 42,
                      iconSize: 21,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Opacity(
                      opacity: fade,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            label,
                            style: AppTextStyles.title.copyWith(fontSize: 16),
                          ),
                          if (subtitle != null) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  ComingSoonSwitch(
                    showTag: showTag,
                    child: Opacity(
                      opacity: fade,
                      child: AnimatedContainer(
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

/// Fixed bottom bar: the pay button and a note on how payment is
/// confirmed.
class PaymentCheckoutBar extends StatelessWidget {
  const PaymentCheckoutBar({
    super.key,
    required this.buttonLabel,
    required this.isLoading,
    required this.onPressed,
    this.note =
        'An admin confirms CliQ payments, usually within a day. Access starts '
        'once yours is confirmed.',
  });

  final String buttonLabel;
  final bool isLoading;
  final VoidCallback? onPressed;
  final String note;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.appBar,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              PrimaryActionButton(
                label: buttonLabel,
                height: 54,
                isLoading: isLoading,
                onPressed: onPressed,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: AppColors.textFaint,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      note,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
