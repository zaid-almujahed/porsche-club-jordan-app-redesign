import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/core/services/biometric_sign_in.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';
import 'package:pcj_v5/shared/widgets/otp_verification_dialog.dart';
import 'package:pcj_v5/shared/widgets/password_reset_dialog.dart';
import 'package:pcj_v5/shared/widgets/support_contact_sheet.dart';

import '../widgets/auth_backdrop.dart';
import '../widgets/biometric_sign_in_button.dart';
import '../widgets/help_button.dart';
import '../widgets/inline_link.dart';
import '../widgets/sign_in_field.dart';
import '../controllers/auth_controller.dart';
import '../controllers/password_controller.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({
    super.key,
    required this.controller,
    required this.passwordController,
    required this.biometricSignIn,
  });

  final AuthController controller;

  /// Forgot password.
  final PasswordController passwordController;

  /// The login saved for signing in with Face ID.
  final BiometricSignIn biometricSignIn;

  /// [viaBiometrics]: the email and password came from Face ID.
  Future<void> _signIn(
    BuildContext context, {
    bool viaBiometrics = false,
  }) async {
    passwordController.clearResetRequestError();
    // Cleared once the code is verified; kept for the Face ID offer.
    final String password = controller.passwordController.text;
    final bool otpWasRequested = await controller.requestSignInOtp();
    if (!context.mounted) return;
    if (!otpWasRequested && controller.emailToVerify != null) {
      if (await _verifyEmail(context) && context.mounted) {
        // Verified: sign in again with the same email and password.
        await _signIn(context, viaBiometrics: viaBiometrics);
      }
      return;
    }
    if (!otpWasRequested) {
      final Object? sessionError = controller.session.hasError
          ? controller.session.error
          : null;
      // The saved password no longer works (changed elsewhere, or the
      // account is gone): forget it.
      if (viaBiometrics &&
          sessionError is AppException &&
          (sessionError.statusCode == 401 || sessionError.statusCode == 404)) {
        await biometricSignIn.disable();
        controller.passwordController.clear();
        if (!context.mounted) return;
        showAppErrorPulse(
          context,
          'Your saved password no longer works. Sign in with your password.',
        );
        return;
      }
      final String? error =
          controller.validationError ??
          (sessionError == null ? null : readableError(sessionError));
      if (error != null) showAppErrorPulse(context, error);
      return;
    }

    final String? email = controller.signInOtpEmail;
    if (email == null) return;

    final bool wasVerified = await showOtpVerificationDialog(
      context: context,
      animation: controller,
      email: email,
      otpController: controller.otpController,
      onOtpChanged: controller.onOtpChanged,
      onVerify: controller.verifySignInOtp,
      onResend: controller.resendSignInOtp,
      onChangeEmail: controller.cancelSignInOtp,
      onCancel: controller.cancelSignInOtp,
      isVerifying: () => controller.isVerifyingSignInOtp,
      isResending: () => controller.isResendingSignInOtp,
      errorText: () => controller.otpError,
      instructions: 'Enter it below to complete sign in.',
      verifyButtonLabel: 'Verify and Sign In',
    );
    if (!context.mounted || !wasVerified) return;

    // Only a member who is now signed in (not an applicant) is offered it.
    if (!viaBiometrics &&
        controller.pendingSignInUser?.applicationStatus ==
            ApplicationStatus.approved) {
      await _offerBiometricSignIn(context, email: email, password: password);
      if (!context.mounted) return;
    }

    final User? user = controller.pendingSignInUser;
    // Suspended / deactivated accounts are turned away by completeSignIn and
    // get the "account deactivated" notice from the app shell instead.
    if (user?.applicationStatus == ApplicationStatus.approved &&
        user?.membershipStatus != MembershipStatus.active &&
        user?.membershipStatus != MembershipStatus.suspended) {
      final bool isExpired = user?.membershipStatus == MembershipStatus.expired;
      await showAppMessageDialog(
        context: context,
        title: isExpired
            ? 'Membership Renewal Required'
            : 'Complete Your Membership',
        message: isExpired
            ? 'Your Porsche Club Jordan membership has expired. Please renew '
                  'your subscription to continue using member features.'
            : 'Your application has been approved. Complete the membership '
                  'payment to start using member features.',
        buttonLabel: isExpired ? 'Renew Membership' : 'Continue to Payment',
        icon: Icons.workspace_premium_outlined,
        iconColor: AppColors.warning,
      );
      if (!context.mounted) return;
    }

    // Publishing the completed session wakes go_router's refreshListenable.
    // Its redirect is the single authority that selects home, application
    // status, or membership payment. A second context.go here can race that
    // redirect and was the source of the post-login black screen.
    controller.completeSignIn();
  }

  /// Registered but never verified: explains, then (if the applicant
  /// agrees) emails a new registration code and asks for it. True once the
  /// email is verified.
  Future<bool> _verifyEmail(BuildContext context) async {
    final String email = controller.emailToVerify!;
    final bool? sendCode = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) => AppDialog(
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.warning,
        title: 'Finish Your Application',
        message:
            'Your application is saved, but we can only review it once your '
            'email is verified. We will send a code to $email.',
        primaryLabel: 'Send Code',
        onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
        secondaryLabel: 'Not Now',
        onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
        onClose: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    if (sendCode != true) {
      controller.cancelEmailVerification();
      return false;
    }
    if (!context.mounted) return false;
    if (!await controller.sendEmailVerificationCode()) {
      if (context.mounted) {
        showAppErrorPulse(
          context,
          controller.otpError ?? 'The verification code could not be sent.',
        );
      }
      return false;
    }
    if (!context.mounted) return false;
    final bool verified = await showOtpVerificationDialog(
      context: context,
      animation: controller,
      email: email,
      otpController: controller.otpController,
      onOtpChanged: controller.onOtpChanged,
      onVerify: controller.verifyEmail,
      onResend: controller.sendEmailVerificationCode,
      onCancel: controller.cancelEmailVerification,
      isVerifying: () => controller.isVerifyingEmail,
      isResending: () => controller.isSendingEmailCode,
      errorText: () => controller.otpError,
      instructions: 'Enter it below to finish your application.',
      verifyButtonLabel: 'Verify Email',
    );
    if (verified && context.mounted) {
      showAppSuccessPulse(context, label: 'Email Verified');
    }
    return verified;
  }

  /// Fills in the login saved for Face ID, once Face ID confirms.
  Future<void> _signInWithBiometrics(BuildContext context) async {
    final ({String email, String password})? login = await biometricSignIn
        .unlock();
    if (login == null || !context.mounted) return;
    controller.identifierController.text = login.email;
    controller.passwordController.text = login.password;
    await _signIn(context, viaBiometrics: true);
  }

  /// After a sign in with a typed password: offers Face ID for next time,
  /// unless it is already on for this email.
  Future<void> _offerBiometricSignIn(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    final String? name = await biometricSignIn.availableName();
    if (name == null || password.isEmpty || !context.mounted) return;
    final String? saved = await biometricSignIn.savedEmail();
    if (saved != null && saved.toLowerCase() == email.trim().toLowerCase()) {
      // Typed anyway: keep the saved one current.
      await biometricSignIn.updatePassword(email: email, password: password);
      return;
    }
    if (!context.mounted) return;
    final bool accepted = await showAppConfirmationDialog(
      context: context,
      title: 'Sign in with $name?',
      message:
          'Next time, use $name instead of typing your password. Your '
          'password stays on this phone.',
      confirmLabel: 'Use $name',
      cancelLabel: 'Not Now',
      icon: name == 'Face ID'
          ? Icons.face_retouching_natural_rounded
          : Icons.fingerprint_rounded,
    );
    if (!accepted || !context.mounted) return;
    final bool enabled = await biometricSignIn.enable(
      email: email,
      password: password,
      name: name,
    );
    if (enabled && context.mounted) {
      showAppSuccessPulse(context, label: '$name Sign In On');
    }
  }

  Future<void> _forgotPassword(BuildContext context) async {
    final bool otpWasRequested = await passwordController.requestPasswordReset(
      controller.identifierController.text,
    );
    if (!context.mounted) return;
    if (!otpWasRequested) {
      final String? error = passwordController.resetRequestError;
      if (error != null) showAppErrorPulse(context, error);
      return;
    }
    final String? email = passwordController.passwordResetEmail;
    if (email == null) return;

    final bool otpWasVerified = await showOtpVerificationDialog(
      context: context,
      animation: passwordController,
      email: email,
      otpController: passwordController.passwordResetOtpController,
      onOtpChanged: passwordController.onPasswordResetOtpChanged,
      onVerify: passwordController.verifyPasswordResetOtp,
      onResend: passwordController.resendPasswordResetOtp,
      onChangeEmail: passwordController.cancelPasswordReset,
      onCancel: passwordController.cancelPasswordReset,
      isVerifying: () => passwordController.isVerifyingPasswordResetOtp,
      isResending: () => passwordController.isResendingPasswordResetOtp,
      errorText: () => passwordController.passwordResetError,
      instructions: 'Enter it below to continue resetting your password.',
      verifyButtonLabel: 'Verify Code',
    );
    if (!context.mounted || !otpWasVerified) return;

    final bool passwordWasReset = await showNewPasswordDialog(
      context: context,
      animation: passwordController,
      passwordController: passwordController.newPasswordController,
      confirmationController: passwordController.confirmNewPasswordController,
      onChanged: passwordController.onNewPasswordChanged,
      onSubmit: passwordController.resetPassword,
      onCancel: passwordController.cancelPasswordReset,
      // The code was used: leaving means asking for a new one.
      closeWarning: const DialogCloseWarning(
        title: 'Stop resetting your password?',
        message:
            'Your password stays the same. To reset it later, you will need '
            'a new code.',
        confirmLabel: 'Stop',
        cancelLabel: 'Keep Going',
      ),
      isSubmitting: () => passwordController.isResettingPassword,
      errorText: () => passwordController.passwordResetError,
    );
    if (!context.mounted || !passwordWasReset) return;
    showAppSnackBar(
      context,
      'Password reset successfully. You can now sign in.',
      type: AppFeedbackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBar,
      // Welcome's light trails, crossing between the welcome and the form.
      body: LightTrailsBackdrop(
        glowCenter: const Alignment(0, -0.48),
        trails: const <LightTrail>[
          LightTrail(startY: 0.54, endY: 0.42, width: 1.4, opacity: 0.85),
          LightTrail(startY: 0.58, endY: 0.47, width: 0.8, opacity: 0.5),
        ],
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            controller,
            passwordController,
          ]),
          builder: (BuildContext context, Widget? child) => LayoutBuilder(
            // The logo and welcome fill the space above the form panel; the
            // page scrolls when the keyboard leaves too little room.
            builder: (BuildContext context, BoxConstraints constraints) =>
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SafeArea(
                            bottom: false,
                            child: _SignInTopBar(
                              onHelp: () => showSupportContactSheet(
                                context: context,
                                senderEmail:
                                    controller.identifierController.text,
                                initialTopic: 'Account access',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.lg,
                              ),
                              child: AppFadeSlideIn(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const AuthLogo(maxHeight: 84),
                                    const SizedBox(height: AppSpacing.lg),
                                    Text(
                                      'Welcome back',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.pageTitle.copyWith(
                                        fontSize: 28,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    const Text(
                                      'Sign in to your member account.',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.body,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          AppFadeSlideIn(
                            delay: const Duration(milliseconds: 120),
                            child: _SignInPanel(child: _form(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SignInField(
            controller: controller.identifierController,
            hintText: 'Email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.username],
          ),
          const SizedBox(height: AppSpacing.md),
          SignInField(
            controller: controller.passwordController,
            hintText: 'Password',
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.password],
            onSubmitted: (_) => _signIn(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: InlineLink(
              label: 'Forgot Password?',
              onPressed: passwordController.isRequestingPasswordReset
                  ? null
                  : () => _forgotPassword(context),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryActionButton(
            label: 'Sign In',
            onPressed: controller.isRequestingSignInOtp
                ? null
                : () => _signIn(context),
            isLoading: controller.isRequestingSignInOtp,
            height: 56,
          ),
          BiometricSignInButton(
            biometricSignIn: biometricSignIn,
            enabled: !controller.isRequestingSignInOtp,
            onPressed: () => _signInWithBiometrics(context),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              const Expanded(child: Divider(color: AppColors.cardBorder)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  'New to the club?',
                  style: AppTextStyles.caption.copyWith(fontSize: 12.5),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.cardBorder)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: () => context.push(AppRoutes.registerPersonal),
              style: AppButtonStyles.outline(
                foregroundColor: AppColors.textPrimary,
                borderColor: const Color(0x33FFFFFF),
              ),
              child: const AppButtonLabel('Join the Club'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back (when there is a page to go back to) and Help.
class _SignInTopBar extends StatelessWidget {
  const _SignInTopBar({required this.onHelp});

  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 8, 0),
      child: SizedBox(
        height: 52,
        child: Row(
          children: <Widget>[
            if (context.canPop())
              AppBarButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => context.pop(),
                leading: true,
              ),
            const Spacer(),
            AuthHelpButton(onPressed: onHelp),
          ],
        ),
      ),
    );
  }
}

/// The form's panel along the bottom, with a thin red line on its top edge.
class _SignInPanel extends StatelessWidget {
  const _SignInPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: ColoredBox(
        color: AppColors.panelDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Color(0x00D5001C),
                    Color(0xCCEE1A30),
                    Color(0x00D5001C),
                  ],
                ),
              ),
              child: SizedBox(height: 1.5),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  26,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
