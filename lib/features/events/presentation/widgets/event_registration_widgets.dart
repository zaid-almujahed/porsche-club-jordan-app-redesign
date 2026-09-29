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

/// The named guest list: one row per guest with a remove button, and an
/// add button under the list until [limit] is reached.
class GuestPanel extends StatelessWidget {
  const GuestPanel({
    super.key,
    required this.count,
    required this.limit,
    required this.guestFee,
    required this.currency,
    required this.nameControllers,
    required this.onIncrement,
    required this.onNameChanged,
    required this.onRemove,
  });

  final int count;
  final int limit;
  final double guestFee;
  final String currency;

  /// One per guest, in order.
  final List<TextEditingController> nameControllers;
  final VoidCallback onIncrement;
  final ValueChanged<String> onNameChanged;

  /// Removes the guest at the given index.
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final String guests = limit == 1 ? '1 guest' : '$limit guests';
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
                      'Your Guests',
                      style: AppTextStyles.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      guestFee <= 0
                          ? 'Up to $guests, free of charge.'
                          : 'Up to $guests, '
                                '${AppFormatters.money(guestFee, currency)} '
                                'each.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  '$count / $limit',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (int index = 0; index < nameControllers.length; index++)
            _GuestRow(
              key: ObjectKey(nameControllers[index]),
              number: index + 1,
              controller: nameControllers[index],
              isLast: index == nameControllers.length - 1,
              onChanged: onNameChanged,
              onRemove: () => onRemove(index),
            ),
          if (count < limit)
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: onIncrement,
                style: AppButtonStyles.outline(radius: AppRadii.medium),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                label: AppButtonLabel(
                  count == 0 ? 'Add a Guest' : 'Add Another Guest',
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          const AppInlineMessage(
            type: AppFeedbackType.info,
            animate: false,
            message:
                'Only the guests named here will be admitted to the event. '
                'Enter each guest’s full name.',
          ),
        ],
      ),
    );
  }
}

class _GuestRow extends StatelessWidget {
  const _GuestRow({
    super.key,
    required this.number,
    required this.controller,
    required this.isLast,
    required this.onChanged,
    required this.onRemove,
  });

  final int number;
  final TextEditingController controller;
  final bool isLast;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceRaised,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              '$number',
              style: AppTextStyles.title.copyWith(
                fontSize: 14,
                fontFeatures: AppTextStyles.tabularFigures,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              // A newly added guest's field opens the keyboard straight away.
              autofocus: controller.text.isEmpty,
              textCapitalization: TextCapitalization.words,
              textInputAction: isLast
                  ? TextInputAction.done
                  : TextInputAction.next,
              style: AppTextStyles.input,
              cursorColor: AppColors.primaryBright,
              decoration: const InputDecoration(
                hintText: 'Guest full name',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove guest $number',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
