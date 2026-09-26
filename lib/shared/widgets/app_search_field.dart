import 'package:flutter/material.dart';

import 'package:pcj_v4/core/theme/app_theme.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    const OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadii.medium)),
      borderSide: BorderSide(color: AppColors.cardBorder),
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.input,
      cursorColor: AppColors.primaryBright,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textFaint),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textMuted,
          size: 22,
        ),
        suffixIcon: AnimatedSwitcher(
          duration: AppMotion.fast,
          transitionBuilder: (Widget child, Animation<double> animation) =>
              ScaleTransition(scale: animation, child: child),
          child: controller.text.isEmpty
              ? const SizedBox.shrink(key: ValueKey<String>('search-empty'))
              : IconButton(
                  key: const ValueKey<String>('search-clear'),
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.cancel_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
        ),
        filled: true,
        fillColor: AppColors.panelDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.medium)),
          borderSide: BorderSide(color: AppColors.primaryBright, width: 1.4),
        ),
      ),
    );
  }
}
