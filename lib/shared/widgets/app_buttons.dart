import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';

/// Button text that shrinks to fit the button on small screens instead of
/// wrapping onto extra lines or being cut off.
class AppButtonLabel extends StatelessWidget {
  const AppButtonLabel(this.label, {super.key, this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height = 64,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Widget content = isLoading
        ? const SizedBox.square(
            key: ValueKey<String>('primary-loading'),
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              strokeCap: StrokeCap.round,
              color: Colors.white,
            ),
          )
        : Row(
            key: const ValueKey<String>('primary-label'),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: AppButtonLabel(label, style: AppTextStyles.button),
              ),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: isLoading
            ? AppButtonStyles.primary.copyWith(
                backgroundColor: const WidgetStatePropertyAll<Color>(
                  AppColors.primary,
                ),
              )
            : AppButtonStyles.primary,
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          layoutBuilder: AppMotion.switcherLayout,
          child: content,
        ),
      ),
    );
  }
}

class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = 64,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: AppButtonStyles.secondary,
        child: AppButtonLabel(label, style: AppTextStyles.button),
      ),
    );
  }
}
