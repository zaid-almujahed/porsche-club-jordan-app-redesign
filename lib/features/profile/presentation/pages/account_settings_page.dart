import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/features/auth/presentation/controllers/password_controller.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';
import 'package:pcj_v5/shared/widgets/otp_verification_dialog.dart';
import 'package:pcj_v5/shared/widgets/password_reset_dialog.dart';

import '../controllers/profile_controller.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({
    super.key,
    required this.controller,
    required this.passwordController,
    required this.onAccountDeleted,
  });

  final ProfileController controller;
  /// Change password.
  final PasswordController passwordController;
  final VoidCallback onAccountDeleted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: PorscheAppBar(title: 'Account Settings', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            topPadding: AppSpacing.xl,
            bottomPadding: 144,
            onRefresh: () => controller.load(force: true),
            child: AsyncStateView<User>(
              state: controller.profile,
              onRetry: () => controller.load(force: true),
              builder: (BuildContext context, User user) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Credentials',
                      style: _AccountSettingsStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppAccentBar(),
                    const SizedBox(height: AppSpacing.md),
                    AppFadeSlideIn(
                      child: _CredentialsPanel(
                        user: user,
                        onPhonePressed: () =>
                            _editPhone(context, user.phoneNumber),
                        onPasswordPressed: () =>
                            _changePassword(context, user.email),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    const Text(
                      'Security',
                      style: _AccountSettingsStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppAccentBar(),
                    const SizedBox(height: AppSpacing.md),
                    AppFadeSlideIn(
                      delay: const Duration(milliseconds: 90),
                      child: _DeleteAccountPanel(
                        onPressed: controller.isPerformingAccountAction
                            ? null
                            : () => _deleteAccount(context),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Current and new password on one form, then the emailed code. The new
  /// password is saved as soon as the code is confirmed, and the member
  /// stays signed in.
  Future<void> _changePassword(BuildContext context, String email) async {
    passwordController.cancelPasswordReset();
    final bool codeWasRequested = await showNewPasswordDialog(
      context: context,
      animation: passwordController,
      currentPasswordController: passwordController.currentPasswordController,
      onCurrentPasswordChanged: passwordController.onCurrentPasswordChanged,
      passwordController: passwordController.newPasswordController,
      confirmationController: passwordController.confirmNewPasswordController,
      onChanged: passwordController.onNewPasswordChanged,
      onSubmit: () => passwordController.requestPasswordChangeCode(email),
      onCancel: passwordController.cancelPasswordReset,
      isSubmitting: () => passwordController.isRequestingPasswordReset,
      errorText: () => passwordController.passwordResetError,
      title: 'Change Password',
      description:
          'Enter your current password, then the new one twice. We will '
          'email you a code to confirm the change.',
      submitLabel: 'Send Verification Code',
      cancelLabel: 'Cancel',
    );
    if (!context.mounted || !codeWasRequested) return;

    final bool passwordWasChanged = await showOtpVerificationDialog(
      context: context,
      animation: passwordController,
      email: email,
      otpController: passwordController.passwordResetOtpController,
      onOtpChanged: passwordController.onPasswordResetOtpChanged,
      onVerify: passwordController.verifyAndResetPassword,
      onResend: passwordController.resendPasswordResetOtp,
      onChangeEmail: passwordController.cancelPasswordReset,
      onCancel: passwordController.cancelPasswordReset,
      isVerifying: () =>
          passwordController.isVerifyingPasswordResetOtp ||
          passwordController.isResettingPassword,
      isResending: () => passwordController.isResendingPasswordResetOtp,
      errorText: () => passwordController.passwordResetError,
      instructions:
          'Enter the code from the most recent email. Your new password is '
          'saved as soon as the code is confirmed.',
      verifyButtonLabel: 'Confirm Code',
      dialogTitle: 'Enter Verification Code',
      backButtonLabel: 'Cancel Password Change',
    );
    if (!context.mounted || !passwordWasChanged) return;

    await showAppMessageDialog(
      context: context,
      title: 'Password Changed',
      message: 'Your new password is saved. Use it the next time you sign in.',
      buttonLabel: 'Done',
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.success,
    );
  }

  Future<void> _editPhone(BuildContext context, String current) async {
    final String? value = await showAppTextInputDialog(
      context: context,
      title: 'Phone Number',
      currentValue: current,
      confirmLabel: 'Save Number',
      hintText: 'Enter your phone number',
      keyboardType: TextInputType.phone,
    );
    if (!context.mounted || value == null) return;
    if (!await controller.updatePhoneNumber(value) && context.mounted) {
      _showError(context);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final bool confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Delete account?',
      message:
          'Deleting your account permanently removes your club profile and '
          'cancels your membership. If you change your mind later, you will '
          'need to submit a new membership application and wait for it to be '
          'reviewed again. This action cannot be undone.',
      confirmLabel: 'Delete Account',
      cancelLabel: 'Keep Account',
      icon: Icons.delete_forever_outlined,
      isDestructive: true,
    );
    if (!context.mounted || !confirmed) return;
    if (await controller.deleteAccount()) {
      onAccountDeleted();
    } else if (context.mounted) {
      _showError(context);
    }
  }

  void _showError(BuildContext context) {
    final Object? error = controller.actionError;
    if (error != null) showAppErrorPulse(context, error);
  }
}

class _CredentialsPanel extends StatelessWidget {
  const _CredentialsPanel({
    required this.user,
    required this.onPhonePressed,
    required this.onPasswordPressed,
  });

  final User user;
  final VoidCallback onPhonePressed;
  final VoidCallback onPasswordPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _AccountSettingsStyles.panelDecoration,
      child: Column(
        children: <Widget>[
          _CredentialRow(
            label: 'Email Address',
            value: user.email,
            onPressed: null,
            trailingIcon: Icons.lock_outline,
            icon: Icons.mail_outline_rounded,
            iconColor: AppColors.accentSteel,
          ),
          _CredentialRow(
            label: 'Phone Number',
            value: user.phoneNumber,
            onPressed: onPhonePressed,
            icon: Icons.phone_iphone_rounded,
            iconColor: AppColors.accentTeal,
          ),
          _CredentialRow(
            label: 'Password',
            value: '••••••••••',
            isPassword: true,
            showDivider: false,
            onPressed: onPasswordPressed,
            icon: Icons.key_rounded,
            iconColor: AppColors.accentGold,
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.value,
    this.isPassword = false,
    this.showDivider = true,
    this.onPressed,
    this.trailingIcon,
    this.icon,
    this.iconColor = AppColors.primaryBright,
  });

  final String label;
  final String value;
  final bool isPassword;
  final bool showDivider;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final IconData? icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.cardBorder))
              : null,
        ),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              AppIconBadge(
                icon: icon!,
                color: iconColor,
                size: 40,
                iconSize: 20,
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: _AccountSettingsStyles.credentialLabel),
                  const SizedBox(height: 4.5),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: isPassword
                        ? _AccountSettingsStyles.passwordValue
                        : _AccountSettingsStyles.credentialValue,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              trailingIcon ?? Icons.chevron_right_rounded,
              size: onPressed == null ? 18 : 24,
              color: onPressed == null
                  ? AppColors.textFaint
                  : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountPanel extends StatelessWidget {
  const _DeleteAccountPanel({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.large),
        child: Ink(
          decoration: AppDecorations.tintedPanel(
            AppColors.danger,
            radius: AppRadii.large,
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                AppIconBadge(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 40,
                  iconSize: 21,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Delete Account',
                        style: _AccountSettingsStyles.deleteTitle,
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Permanently remove your club data and access.',
                        style: _AccountSettingsStyles.deleteDescription,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.danger,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _AccountSettingsStyles {
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static final BoxDecoration panelDecoration = AppDecorations.panel(
    radius: AppRadii.large,
  );

  static const TextStyle credentialLabel = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.2,
  );

  static const TextStyle credentialValue = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle passwordValue = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 3,
  );

  static const TextStyle deleteTitle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.danger,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle deleteDescription = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
}
