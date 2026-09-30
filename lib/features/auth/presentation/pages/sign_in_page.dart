import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';
import 'package:pcj_v5/shared/widgets/otp_verification_dialog.dart';
import 'package:pcj_v5/shared/widgets/password_reset_dialog.dart';

import '../widgets/auth_backdrop.dart';
import '../widgets/inline_link.dart';
import '../widgets/sign_in_field.dart';
import '../controllers/auth_controller.dart';
import '../controllers/password_controller.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({
    super.key,
    required this.controller,
    required this.passwordController,
  });

  final AuthController controller;

  /// Forgot password.
  final PasswordController passwordController;

  Future<void> _signIn(BuildContext context) async {
    passwordController.clearResetRequestError();
    final bool otpWasRequested = await controller.requestSignInOtp();
    if (!context.mounted || !otpWasRequested) return;

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
      isVerifying: () => controller.isVerifyingSignInOtp,
      isResending: () => controller.isResendingSignInOtp,
      errorText: () => controller.otpError,
      instructions: 'Enter it below to complete sign in.',
      verifyButtonLabel: 'Verify and Sign In',
    );
    if (!context.mounted || !wasVerified) return;

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

  Future<void> _forgotPassword(BuildContext context) async {
    final bool otpWasRequested = await passwordController.requestPasswordReset(
      controller.identifierController.text,
    );
    if (!context.mounted || !otpWasRequested) return;
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
                final String? errorMessage =
                    controller.validationError ??
                    passwordController.resetRequestError ??
                    (controller.session.hasError
                        ? readableError(controller.session.error!)
                        : null);

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
                                          AnimatedSize(
                                            duration: AppMotion.medium,
                                            curve: AppMotion.curve,
                                            alignment: Alignment.topCenter,
                                            child: errorMessage == null
                                                ? const SizedBox(
                                                    width: double.infinity,
                                                  )
                                                : Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: AppSpacing.lg,
                                                        ),
                                                    child:
                                                        AppInlineMessage.error(
                                                          errorMessage,
                                                        ),
                                                  ),
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
