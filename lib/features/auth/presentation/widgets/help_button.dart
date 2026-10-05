import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';

/// "Help" at the top of the signed-out pages; opens the support form.
class AuthHelpButton extends StatelessWidget {
  const AuthHelpButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.help_outline_rounded, size: 18),
      label: const Text('Help'),
      style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
    );
  }
}
