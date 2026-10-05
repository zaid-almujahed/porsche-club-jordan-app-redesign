import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

/// What to send and where, each with a Copy button, then the receipt.
class CliqPaymentForm extends StatelessWidget {
  const CliqPaymentForm({
    super.key,
    required this.payment,
    required this.receipt,
    required this.onCopy,
    required this.onAddReceipt,
    required this.onRemoveReceipt,
  });

  final CliqPayment payment;

  /// The screenshot picked so far.
  final CliqReceipt? receipt;
  final ValueChanged<String> onCopy;
  final VoidCallback onAddReceipt;
  final VoidCallback onRemoveReceipt;

  @override
  Widget build(BuildContext context) {
    final bool hasReference = payment.reference.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Pay with CliQ',
          style: AppTextStyles.pageTitle.copyWith(fontSize: 26),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Send the fee from your bank app, then upload a screenshot of the '
          'receipt.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.md),
        const AppAccentBar(),
        if (payment.receiptStatus == CliqReceiptStatus.rejected) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          AppInlineMessage(
            title: 'Receipt Not Accepted',
            message:
                payment.rejectionReason ??
                'Check the transfer, then send a new receipt.',
            type: AppFeedbackType.warning,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const _StepHeading(number: 1, title: 'SEND WITH CLIQ'),
        const SizedBox(height: AppSpacing.sm),
        _Panel(
          children: <Widget>[
            _DetailRow(
              label: 'Amount',
              value: AppFormatters.money(payment.amount, payment.currency),
              large: true,
              onCopy: () => onCopy(payment.amount.toStringAsFixed(2)),
            ),
            _DetailRow(
              label: 'CliQ alias',
              value: payment.alias,
              onCopy: () => onCopy(payment.alias),
            ),
            if (payment.accountName.isNotEmpty)
              _DetailRow(label: 'Name', value: payment.accountName),
            if (hasReference)
              _DetailRow(
                label: 'Transfer note',
                value: payment.reference,
                onCopy: () => onCopy(payment.reference),
              ),
          ],
        ),
        if (hasReference) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add the note to your transfer so we can match it to you.',
            style: AppTextStyles.caption,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const _StepHeading(number: 2, title: 'UPLOAD THE RECEIPT'),
        const SizedBox(height: AppSpacing.sm),
        _ReceiptPicker(
          receipt: receipt,
          onAdd: onAddReceipt,
          onRemove: onRemoveReceipt,
        ),
      ],
    );
  }
}

/// After the receipt is sent: waiting for an admin.
class CliqReceiptReview extends StatelessWidget {
  const CliqReceiptReview({
    super.key,
    required this.payment,
    required this.onSendDifferent,
    required this.onContactSupport,
  });

  final CliqPayment payment;
  final VoidCallback onSendDifferent;
  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context) {
    final DateTime? submittedAt = payment.submittedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.warning,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'PAYMENT\nUNDER REVIEW',
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'We received your receipt. An admin will confirm it, usually within '
          'a day, and we will notify you once your membership is active.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.xl),
        _Panel(
          children: <Widget>[
            _DetailRow(
              label: 'Amount',
              value: AppFormatters.money(payment.amount, payment.currency),
            ),
            _DetailRow(label: 'Sent to', value: payment.alias),
            if (submittedAt != null)
              _DetailRow(
                label: 'Submitted',
                value: AppFormatters.numericDate(submittedAt),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        SecondaryActionButton(
          label: 'Upload a Different Receipt',
          height: 54,
          onPressed: onSendDifferent,
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: onContactSupport,
            child: const Text('Contact Support'),
          ),
        ),
      ],
    );
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.number, required this.title});

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
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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

class _ReceiptPicker extends StatelessWidget {
  const _ReceiptPicker({
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
