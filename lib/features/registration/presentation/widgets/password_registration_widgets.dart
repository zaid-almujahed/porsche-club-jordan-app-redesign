import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';
import 'package:pcj_v5/shared/widgets/otp_verification_dialog.dart';

import '../controllers/registration_controller.dart';

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
    onChangeEmail: controller.cancelRegistrationOtp,
    isVerifying: () => controller.isVerifyingOtp,
    isResending: () => controller.isResendingOtp,
    errorText: () => controller.otpError,
    instructions: 'Enter it below to complete your application.',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(color: AppColors.cardBorder),
        const SizedBox(height: AppSpacing.lg),
        PrimaryActionButton(
          label: 'Submit Application',
          icon: Icons.send_rounded,
          height: 58,
          onPressed: isSubmitting ? null : onSubmit,
          isLoading: isSubmitting,
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryActionButton(
          label: 'Back',
          height: 54,
          onPressed: isSubmitting ? null : onBack,
        ),
      ],
    );
  }
}
