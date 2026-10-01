import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/validation/password_rules.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

/// The new password, twice. With [currentPasswordController] (change
/// password) the current password is asked for first, on the same form.
Future<bool> showNewPasswordDialog({
  required BuildContext context,
  required Listenable animation,
  TextEditingController? currentPasswordController,
  ValueChanged<String>? onCurrentPasswordChanged,
  required TextEditingController passwordController,
  required TextEditingController confirmationController,
  required ValueChanged<String> onChanged,
  required Future<bool> Function() onSubmit,
  required bool Function() isSubmitting,
  required String? Function() errorText,
  VoidCallback? onCancel,
  String title = 'Create New Password',
  String description = 'Enter the new password twice to confirm it.',
  String submitLabel = 'Reset Password',
  String? cancelLabel,
}) async {
  final bool? completed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (BuildContext context) => _NewPasswordDialog(
      animation: animation,
      currentPasswordController: currentPasswordController,
      onCurrentPasswordChanged: onCurrentPasswordChanged,
      passwordController: passwordController,
      confirmationController: confirmationController,
      onChanged: onChanged,
      onSubmit: onSubmit,
      isSubmitting: isSubmitting,
      errorText: errorText,
      onCancel: onCancel,
      title: title,
      description: description,
      submitLabel: submitLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return completed ?? false;
}

class _NewPasswordDialog extends StatelessWidget {
  const _NewPasswordDialog({
    required this.animation,
    required this.currentPasswordController,
    required this.onCurrentPasswordChanged,
    required this.passwordController,
    required this.confirmationController,
    required this.onChanged,
    required this.onSubmit,
    required this.isSubmitting,
    required this.errorText,
    required this.onCancel,
    required this.title,
    required this.description,
    required this.submitLabel,
    required this.cancelLabel,
  });

  final Listenable animation;
  final TextEditingController? currentPasswordController;
  final ValueChanged<String>? onCurrentPasswordChanged;
  final TextEditingController passwordController;
  final TextEditingController confirmationController;
  final ValueChanged<String> onChanged;
  final Future<bool> Function() onSubmit;
  final bool Function() isSubmitting;
  final String? Function() errorText;
  final VoidCallback? onCancel;
  final String title;
  final String description;
  final String submitLabel;
  final String? cancelLabel;

  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final bool completed = await onSubmit();
    if (!context.mounted) return;
    if (!completed) {
      final String? error = errorText();
      if (error != null) showAppErrorPulse(context, error);
      return;
    }
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop(true);
  }

  void _cancel(BuildContext context) {
    onCancel?.call();
    Navigator.of(context, rootNavigator: true).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppDialogFrame(
        maxWidth: 440,
        child: AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            final String password = passwordController.text;
            final bool submitting = isSubmitting();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Center(
                  child: AppDialogIcon(icon: Icons.lock_reset_rounded),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 23),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.xl),
                if (currentPasswordController != null) ...<Widget>[
                  _PasswordField(
                    controller: currentPasswordController!,
                    label: 'CURRENT PASSWORD',
                    hintText: 'Enter current password',
                    autofillHint: AutofillHints.password,
                    onChanged: onCurrentPasswordChanged ?? onChanged,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _PasswordField(
                  controller: passwordController,
                  label: 'NEW PASSWORD',
                  onChanged: onChanged,
                ),
                const SizedBox(height: AppSpacing.lg),
                _PasswordField(
                  controller: confirmationController,
                  label: 'RE-ENTER PASSWORD',
                  onChanged: onChanged,
                  onSubmitted: (_) => _submit(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: <Widget>[
                      _Requirement(
                        label:
                            'At least ${PasswordRules.minimumLength} characters',
                        isMet: PasswordRules.hasMinimumLength(password),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _Requirement(
                        label: 'At least one number',
                        isMet: PasswordRules.hasNumber(password),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryActionButton(
                  label: submitLabel,
                  onPressed: submitting ? null : () => _submit(context),
                  isLoading: submitting,
                  height: 56,
                ),
                if (cancelLabel != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryActionButton(
                    label: cancelLabel!,
                    onPressed: submitting ? null : () => _cancel(context),
                    height: 52,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.hintText = 'Enter password',
    this.autofillHint = AutofillHints.newPassword,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final String hintText;
  final String autofillHint;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label, style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          obscureText: true,
          textInputAction: onSubmitted == null
              ? TextInputAction.next
              : TextInputAction.done,
          autofillHints: <String>[autofillHint],
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          style: AppTextStyles.input,
          cursorColor: AppColors.primaryBright,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final Color color = isMet ? AppColors.success : AppColors.textFaint;
    return Row(
      children: <Widget>[
        AnimatedSwitcher(
          duration: AppMotion.medium,
          transitionBuilder: (Widget child, Animation<double> animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            key: ValueKey<bool>(isMet),
            size: 19,
            color: color,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.medium,
            style: AppTextStyles.body.copyWith(color: color, fontSize: 14.5),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
