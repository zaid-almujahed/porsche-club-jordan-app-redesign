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

import '../widgets/auth_backdrop.dart';
import '../widgets/biometric_sign_in_button.dart';
import '../widgets/inline_link.dart';
import '../widgets/sign_in_field.dart';
import '../widgets/support_link.dart';
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
      //Safe area guarantees that the page is visible if the device has a camera notch
      body: AuthBackdrop(
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            controller,
            passwordController,
          ]),
          builder: (BuildContext context, Widget? child) => SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double horizontalPadding = AppLayout.horizontalPadding(
                  constraints.maxWidth,
                );
                final double verticalPadding = constraints.maxHeight < 700
                    ? AppSpacing.xl
                    : AppSpacing.xxl;
                final double minimumHeight =
                    constraints.maxHeight > verticalPadding * 2
                    ? constraints.maxHeight - verticalPadding * 2
                    : 0;

                return Stack(
                  children: <Widget>[
                    SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minimumHeight),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: AutofillGroup(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  //LOGO
                                  const AppFadeSlideIn(
                                    child: AuthLogo(maxHeight: 130),
                                  ),
                                  const SizedBox(height: AppSpacing.xxl),
                                  AppFadeSlideIn(
                                    delay: const Duration(milliseconds: 100),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Welcome back',
                                          style: AppTextStyles.pageTitle
                                              .copyWith(fontSize: 28),
                                        ),
                                        const SizedBox(height: AppSpacing.xxs),
                                        const Text(
                                          'Sign in to your member account.',
                                          style: AppTextStyles.body,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),

                                  //Sign in fields
                                  AppFadeSlideIn(
                                    delay: const Duration(milliseconds: 180),
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.lg,
                                      ),
                                      decoration: AppDecorations.panel(
                                        radius: AppRadii.large,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          SignInField(
                                            controller:
                                                controller.identifierController,
                                            label: 'EMAIL ADDRESS',
                                            hintText:
                                                'Enter your email address',
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            textInputAction:
                                                TextInputAction.next,
                                            autofillHints: <String>[
                                              AutofillHints.username,
                                            ],
                                          ),
                                          const SizedBox(height: AppSpacing.lg),
                                          SignInField(
                                            controller:
                                                controller.passwordController,
                                            label: 'PASSWORD',
                                            hintText: 'Enter your password',
                                            obscureText: true,
                                            textInputAction:
                                                TextInputAction.done,
                                            autofillHints: const <String>[
                                              AutofillHints.password,
                                            ],
                                            labelTrailing: InlineLink(
                                              label: 'Forgot Password?',
                                              onPressed:
                                                  passwordController
                                                      .isRequestingPasswordReset
                                                  ? null
                                                  : () => _forgotPassword(
                                                      context,
                                                    ),
                                            ),
                                            onSubmitted: (_) =>
                                                _signIn(context),
                                          ),
                                          const SizedBox(height: AppSpacing.xl),

                                          //Action Buttons
                                          PrimaryActionButton(
                                            label: 'Sign In',
                                            onPressed:
                                                controller.isRequestingSignInOtp
                                                ? null
                                                : () => _signIn(context),
                                            isLoading: controller
                                                .isRequestingSignInOtp,
                                            height: 56,
                                          ),
                                          BiometricSignInButton(
                                            biometricSignIn: biometricSignIn,
                                            enabled: !controller
                                                .isRequestingSignInOtp,
                                            onPressed: () =>
                                                _signInWithBiometrics(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  AppFadeSlideIn(
                                    delay: const Duration(milliseconds: 260),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xs,
                                      children: <Widget>[
                                        Text(
                                          "Don't have an account?",
                                          style: AppTextStyles.body.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        InlineLink(
                                          label: 'Join the Club',
                                          onPressed: () => context.push(
                                            AppRoutes.registerPersonal,
                                          ),
                                          textStyle: AppTextStyles.body
                                              .copyWith(
                                                color: AppColors.primaryBright,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  AppFadeSlideIn(
                                    delay: const Duration(milliseconds: 300),
                                    child: SupportLink(
                                      senderEmail:
                                          controller.identifierController.text,
                                      initialTopic: 'Account access',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (context.canPop())
                      Positioned(
                        top: 10,
                        left: 0,
                        child: AppBarButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          onPressed: () => context.pop(),
                          leading: true,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
