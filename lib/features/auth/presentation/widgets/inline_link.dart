import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';

class InlineLink extends StatelessWidget {
  const InlineLink({
    super.key,
    required this.label,
    this.onPressed,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadii.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Text(
          label,
          style:
              textStyle ??
              AppTextStyles.label.copyWith(
                color: AppColors.primaryBright,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
        ),
      ),
    );
  }
}
