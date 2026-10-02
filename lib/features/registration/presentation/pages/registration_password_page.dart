import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/registration_controller.dart';
import '../widgets/form_widgets.dart';
import '../widgets/password_registration_widgets.dart';
import '../widgets/registration_cancel_dialog.dart';

class RegistrationPasswordPage extends StatelessWidget {
  const RegistrationPasswordPage({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onCancel,
  });

  final RegistrationController controller;
  final VoidCallback onSubmitted;
  final Future<void> Function() onCancel;

  Future<void> _submit(BuildContext context) async {
    final bool wasSubmitted = await controller.submitApplication();
    if (!context.mounted) return;
    if (!wasSubmitted) {
      final String? error =
          controller.passwordFormError ?? controller.submissionError;
      if (error != null) showAppErrorPulse(context, error);
      return;
    }

    final bool wasVerified = await showRegistrationOtpDialog(
      context: context,
      controller: controller,
    );
    // Closed without verifying (after the warning): leave registration.
    if (!wasVerified) {
      if (context.mounted) await onCancel();
      return;
    }

    if (wasVerified && controller.isEmailVerified && context.mounted) {
      await showAppMessageDialog(
        context: context,
        title: 'Application Submitted',
        message:
            'Your membership application was submitted successfully. You may '
            'edit it while this app session remains open. After leaving this '
            'session or signing in again, the edit option will no longer be '
            'available.',
        buttonLabel: 'View Application Status',
        icon: Icons.check_circle_outline_rounded,
        iconColor: AppColors.success,
      );
      if (!context.mounted) return;
      onSubmitted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: PorscheAppBar(
        title: 'Membership Application',
        showClose: true,
        onClose: () => confirmRegistrationCancellation(
          context: context,
          onCancel: onCancel,
          isEditing: controller.isEditingSubmittedApplication,
        ),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            topPadding: AppSpacing.lg,
            bottomPadding: AppSpacing.section,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const ProgressHeader(
                  pageNo: '04',
                  title: 'Account Setup',
                  desc:
                      'Enter the email address you will use to sign in and '
                      'create a secure password. We will verify your email '
                      'before completing the application.',
                ),
                const SizedBox(height: AppSpacing.xl),
                RegistrationFormPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      RegistrationTextField(
                        controller: controller.emailController,
                        label: 'EMAIL ADDRESS',
                        hintText: 'e.g. name@domain.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.email],
                        onChanged: controller.onEmailChanged,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      RegistrationTextField(
                        controller: controller.passwordController,
                        label: 'ENTER PASSWORD',
                        hintText: 'Enter your password',
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[
                          AutofillHints.newPassword,
                        ],
                        obscureText: true,
                        onChanged: controller.onPasswordChanged,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      RegistrationTextField(
                        controller: controller.confirmPasswordController,
                        label: 'RE-ENTER PASSWORD',
                        hintText: 'Re-enter your password',
                        textInputAction: TextInputAction.done,
                        autofillHints: const <String>[
                          AutofillHints.newPassword,
                        ],
                        obscureText: true,
                        onChanged: controller.onPasswordConfirmationChanged,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(color: AppColors.cardBorder),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'PASSWORD MUST INCLUDE',
                        style: AppTextStyles.overline,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildRequirement(
                        label: 'At least 8 characters',
                        isMet: controller.hasMinimumPasswordLength,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildRequirement(
                        label: 'At least one number',
                        isMet: controller.hasPasswordNumber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                RegistrationSubmitActions(
                  isSubmitting: controller.isSubmitting,
                  onBack: () => context.go(AppRoutes.registerReview),
                  onSubmit: () => _submit(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequirement({required String label, required bool isMet}) {
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
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.medium,
            style: AppTextStyles.body.copyWith(color: color),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
