import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';

/// Short red rule used under section headings ("Event Overview").
class AppAccentBar extends StatelessWidget {
  const AppAccentBar({super.key, this.width = 28});

  final double width;

  @override
  Widget build(BuildContext context) {
    // Align keeps the rule short even inside stretched columns.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Container(
        width: width,
        height: 3,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class SectionTitleRow extends StatelessWidget {
  const SectionTitleRow({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionPressed,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  /// Shown at the end of the title row, e.g. a view switch.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
            if (actionLabel != null)
              TextButton(
                onPressed: onActionPressed,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      actionLabel!.replaceAll('›', '').trim(),
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryBright,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primaryBright,
                    ),
                  ],
                ),
              ),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const AppAccentBar(),
      ],
    );
  }
}
