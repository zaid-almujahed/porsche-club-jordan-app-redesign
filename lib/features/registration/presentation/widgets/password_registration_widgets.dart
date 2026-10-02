import 'package:flutter/material.dart';

import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/otp_verification_dialog.dart';

import '../controllers/registration_controller.dart';
import 'form_widgets.dart';

Future<bool> showRegistrationOtpDialog({
  required BuildContext context,
  required RegistrationController controller,
}) async {
  return showOtpVerificationDialog(
    context: context,
    animation: controller,
    email: controller.emailController.text.trim(),
    otpController: controller.otpController,
    onOtpChanged: controller.onOtpChanged,
    onVerify: controller.verifyRegistrationOtp,
    onResend: controller.resendRegistrationOtp,
    isVerifying: () => controller.isVerifyingOtp,
    isResending: () => controller.isResendingOtp,
    errorText: () => controller.otpError,
    instructions: 'Enter it below to complete your application.',
    // The application is already sent; it waits on this email.
    closeWarning: const DialogCloseWarning(
      title: 'Leave without verifying?',
      message:
          'Your application has been sent, but it cannot be reviewed until '
          'your email is verified. You can verify it later: sign in with '
          'your email and password, and we will send you a new code.',
    ),
  );
}

class RegistrationSubmitActions extends StatelessWidget {
  const RegistrationSubmitActions({
    super.key,
    required this.onBack,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final VoidCallback? onBack;
  final VoidCallback? onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return RegistrationActions(
      nextLabel: 'Submit',
      onNext: isSubmitting ? null : onSubmit,
      onBack: onBack,
      isLoading: isSubmitting,
    );
  }
}
