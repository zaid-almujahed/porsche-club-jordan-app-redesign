import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_badges.dart';

/// Invites the member to contact support about something, e.g. a rejected
/// payment.
class SupportHelpRow extends StatelessWidget {
  const SupportHelpRow({
    super.key,
    required this.onPressed,
    this.title = 'Questions about this payment?',
  });

  final VoidCallback? onPressed;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(AppRadii.medium),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              const AppIconBadge(
                icon: Icons.support_agent_rounded,
                size: 38,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTextStyles.title.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    const Text('Contact Support', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
