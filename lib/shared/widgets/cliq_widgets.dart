import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/widgets/app_badges.dart';
import 'package:pcj_v5/shared/widgets/app_feedback.dart';

// The pieces of a CliQ payment page (membership, events and orders).

/// A numbered step of a CliQ payment.
class CliqStepHeading extends StatelessWidget {
  const CliqStepHeading({super.key, required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.overline),
      ],
    );
  }
}

/// Rows separated by thin lines on a panel.
class CliqPanel extends StatelessWidget {
  const CliqPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: AppDecorations.panel(radius: AppRadii.large),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, color: AppColors.cardBorder),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A label and its value, with a Copy button when [onCopy] is set.
class CliqDetailRow extends StatelessWidget {
  const CliqDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.onCopy,
    this.large = false,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label.toUpperCase(), style: AppTextStyles.overline),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: large
                      ? AppTextStyles.numeric.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        )
                      : AppTextStyles.title.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          if (onCopy != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            _CopyButton(label: label, onPressed: onCopy!),
          ],
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Copy $label',
      child: Material(
        color: const Color(0x12FFFFFF),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Copy',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The screenshot of the CliQ transfer: a box to add it, then its preview
/// with Replace and Remove.
class CliqReceiptPicker extends StatelessWidget {
  const CliqReceiptPicker({
    super.key,
    required this.receipt,
    required this.onAdd,
    required this.onRemove,
  });

  final CliqReceipt? receipt;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  static final ButtonStyle _pill = OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    shape: const StadiumBorder(),
    side: const BorderSide(color: Color(0x33FFFFFF)),
    foregroundColor: AppColors.textSecondary,
    textStyle: AppTextStyles.label,
  );

  @override
  Widget build(BuildContext context) {
    final CliqReceipt? picked = receipt;
    if (picked == null) {
      return Material(
        color: const Color(0x08FFFFFF),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0x33FFFFFF)),
          borderRadius: BorderRadius.circular(AppRadii.large),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onAdd,
          child: SizedBox(
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const AppIconBadge(
                  icon: Icons.add_photo_alternate_outlined,
                  size: 46,
                  iconSize: 23,
                ),
                const SizedBox(height: 10),
                Text(
                  'Upload Receipt Screenshot',
                  style: AppTextStyles.title.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Take a photo or choose from your library',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.panel(radius: AppRadii.large),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.small),
            child: SizedBox(
              width: 70,
              height: 112,
              child: Image.memory(
                picked.bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.surfaceRaised,
                  child: Center(
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Receipt Added',
                      style: AppTextStyles.title.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check the amount and date are readable.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton(
                      style: _pill,
                      onPressed: onAdd,
                      child: const Text('Replace'),
                    ),
                    OutlinedButton(
                      style: _pill,
                      onPressed: onRemove,
                      child: const Text('Remove'),
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

/// The steps of a CliQ payment: what to send and where, the transfer
/// number, the member's own alias for a refund, then the receipt.
class CliqTransferSteps extends StatelessWidget {
  const CliqTransferSteps({
    super.key,
    required this.amount,
    required this.currency,
    required this.alias,
    required this.transactionController,
    required this.refundNameController,
    required this.refundNote,
    required this.receipt,
    required this.onCopy,
    required this.onAddReceipt,
    required this.onRemoveReceipt,
  });

  /// Null while the amount is not known.
  final double? amount;
  final String currency;

  /// The club's alias; null while it is not known.
  final String? alias;
  final TextEditingController transactionController;
  final TextEditingController refundNameController;

  /// When the payment is refunded, e.g. after cancelling in time.
  final String refundNote;
  final CliqReceipt? receipt;
  final ValueChanged<String> onCopy;
  final VoidCallback onAddReceipt;
  final VoidCallback onRemoveReceipt;

  @override
  Widget build(BuildContext context) {
    final double? amount = this.amount;
    final String? alias = this.alias;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const CliqStepHeading(number: 1, title: 'SEND WITH CLIQ'),
        const SizedBox(height: AppSpacing.sm),
        if (amount != null || alias != null)
          CliqPanel(
            children: <Widget>[
              if (amount != null)
                CliqDetailRow(
                  label: 'Amount',
                  value: AppFormatters.money(amount, currency),
                  large: true,
                  onCopy: () => onCopy(amount.toStringAsFixed(2)),
                ),
              if (alias != null)
                CliqDetailRow(
                  label: 'CliQ alias',
                  value: alias,
                  onCopy: () => onCopy(alias),
                ),
            ],
          ),
        if (alias == null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          const Text(
            "Send it to the club's CliQ alias.",
            style: AppTextStyles.caption,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const CliqStepHeading(number: 2, title: 'TRANSFER NUMBER'),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: transactionController,
          textInputAction: TextInputAction.next,
          style: AppTextStyles.input,
          cursorColor: AppColors.primaryBright,
          decoration: const InputDecoration(
            hintText: "As shown on your bank's receipt",
            prefixIcon: Icon(Icons.tag_rounded, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const CliqStepHeading(number: 3, title: 'REFUND ALIAS'),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: refundNameController,
          textInputAction: TextInputAction.done,
          style: AppTextStyles.input,
          cursorColor: AppColors.primaryBright,
          decoration: const InputDecoration(
            hintText: 'Your own CliQ alias',
            prefixIcon: Icon(Icons.replay_rounded, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppInlineMessage(
          type: AppFeedbackType.info,
          title: 'Refunds go to this alias',
          message: refundNote,
          animate: false,
        ),
        const SizedBox(height: AppSpacing.xl),
        const CliqStepHeading(number: 4, title: 'UPLOAD THE RECEIPT'),
        const SizedBox(height: AppSpacing.sm),
        CliqReceiptPicker(
          receipt: receipt,
          onAdd: onAddReceipt,
          onRemove: onRemoveReceipt,
        ),
      ],
    );
  }
}
