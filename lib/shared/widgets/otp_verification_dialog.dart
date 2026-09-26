import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/shared/widgets/app_dialog.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

Future<bool> showOtpVerificationDialog({
  required BuildContext context,
  required Listenable animation,
  required String email,
  required TextEditingController otpController,
  required ValueChanged<String> onOtpChanged,
  required Future<bool> Function() onVerify,
  required Future<bool> Function() onResend,
  required VoidCallback onChangeEmail,
  required bool Function() isVerifying,
  required bool Function() isResending,
  required String? Function() errorText,
  required String instructions,
  String verifyButtonLabel = 'Verify Email',
  String dialogTitle = 'Verify Your Email',
  String backButtonLabel = 'Go Back and Change Email',
}) async {
  final bool? wasVerified = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (BuildContext context) {
      return OtpVerificationDialog(
        animation: animation,
        email: email,
        otpController: otpController,
        onOtpChanged: onOtpChanged,
        onVerify: onVerify,
        onResend: onResend,
        onChangeEmail: onChangeEmail,
        isVerifying: isVerifying,
        isResending: isResending,
        errorText: errorText,
        instructions: instructions,
        verifyButtonLabel: verifyButtonLabel,
        dialogTitle: dialogTitle,
        backButtonLabel: backButtonLabel,
      );
    },
  );

  return wasVerified ?? false;
}

class OtpVerificationDialog extends StatefulWidget {
  const OtpVerificationDialog({
    super.key,
    required this.animation,
    required this.email,
    required this.otpController,
    required this.onOtpChanged,
    required this.onVerify,
    required this.onResend,
    required this.onChangeEmail,
    required this.isVerifying,
    required this.isResending,
    required this.errorText,
    required this.instructions,
    required this.verifyButtonLabel,
    required this.dialogTitle,
    required this.backButtonLabel,
  });

  final Listenable animation;
  final String email;
  final TextEditingController otpController;
  final ValueChanged<String> onOtpChanged;
  final Future<bool> Function() onVerify;
  final Future<bool> Function() onResend;
  final VoidCallback onChangeEmail;
  final bool Function() isVerifying;
  final bool Function() isResending;
  final String? Function() errorText;
  final String instructions;
  final String verifyButtonLabel;
  final String dialogTitle;
  final String backButtonLabel;

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  static const Duration _otpLifetime = Duration(minutes: 5);
  static const Duration _resendCooldown = Duration(minutes: 1);

  late DateTime _expiresAt;
  late DateTime _resendAvailableAt;
  late final Timer _ticker;
  String? _notice;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _restartTimers();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  int get _otpSecondsRemaining => _remainingSeconds(_expiresAt);

  int get _resendSecondsRemaining => _remainingSeconds(_resendAvailableAt);

  bool get _hasExpired => _otpSecondsRemaining == 0;

  void _restartTimers() {
    final DateTime now = DateTime.now();
    _expiresAt = now.add(_otpLifetime);
    _resendAvailableAt = now.add(_resendCooldown);
  }

  int _remainingSeconds(DateTime deadline) {
    final int milliseconds = deadline.difference(DateTime.now()).inMilliseconds;
    if (milliseconds <= 0) return 0;
    return (milliseconds / Duration.millisecondsPerSecond).ceil();
  }

  String _formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    if (_hasExpired) {
      setState(() {
        _notice = 'This code has expired. Request a new code to continue.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    final bool wasVerified = await widget.onVerify();
    if (!wasVerified || !mounted) return;

    setState(() => _allowPop = true);
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop(true);
  }

  Future<void> _resend() async {
    if (_resendSecondsRemaining > 0) return;

    FocusScope.of(context).unfocus();
    final bool wasSent = await widget.onResend();
    if (!wasSent || !mounted) return;

    setState(() {
      _restartTimers();
      _notice = 'A new verification code was sent.';
    });
  }

  void _changeEmail() {
    widget.onChangeEmail();
    setState(() => _allowPop = true);
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      child: AppDialogFrame(
        maxWidth: 440,
        child: AnimatedBuilder(
          animation: widget.animation,
          builder: (BuildContext context, Widget? child) {
            final bool verifying = widget.isVerifying();
            final bool resending = widget.isResending();
            final bool isBusy = verifying || resending;
            final String? error = widget.errorText();
            final bool isRunningLow =
                !_hasExpired && _otpSecondsRemaining <= 60;
            final Color timerColor = _hasExpired
                ? AppColors.danger
                : isRunningLow
                ? AppColors.warning
                : AppColors.textSecondary;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Center(
                  child: AppDialogIcon(icon: Icons.mark_email_read_outlined),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.dialogTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 23),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      const TextSpan(
                        text: 'We sent a one-time verification code to\n',
                      ),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: '.\n${widget.instructions}'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: AnimatedContainer(
                    duration: AppMotion.medium,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: timerColor.withValues(alpha: 0.10),
                      border: Border.all(
                        color: timerColor.withValues(alpha: 0.30),
                      ),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.timer_outlined, size: 17, color: timerColor),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _hasExpired
                              ? 'Code expired'
                              : 'Code expires in '
                                    '${_formatDuration(_otpSecondsRemaining)}',
                          style: AppTextStyles.body.copyWith(
                            color: timerColor,
                            fontSize: 14,
                            fontFeatures: AppTextStyles.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text.rich(
                  const TextSpan(
                    children: <InlineSpan>[
                      TextSpan(text: 'VERIFICATION CODE'),
                      TextSpan(
                        text: '  *',
                        style: TextStyle(
                          color: AppColors.required,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  style: AppTextStyles.overline,
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: widget.otpController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  textAlign: TextAlign.center,
                  autofillHints: const <String>[AutofillHints.oneTimeCode],
                  onChanged: widget.onOtpChanged,
                  onFieldSubmitted: (_) => _verify(),
                  style: AppTextStyles.input.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 6,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                  cursorColor: AppColors.primaryBright,
                  decoration: InputDecoration(
                    hintText: 'Enter code',
                    hintStyle: AppTextStyles.input.copyWith(
                      color: AppColors.textFaint,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  alignment: Alignment.topCenter,
                  child: error != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: AppInlineMessage.error(error),
                        )
                      : _notice != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: AppInlineMessage(
                            message: _notice!,
                            type: _hasExpired
                                ? AppFeedbackType.warning
                                : AppFeedbackType.success,
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryActionButton(
                  label: widget.verifyButtonLabel,
                  onPressed: _hasExpired || isBusy ? null : _verify,
                  isLoading: verifying,
                  height: 56,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _resendSecondsRemaining == 0 && !isBusy
                      ? _resend
                      : null,
                  child: Text(
                    resending
                        ? 'Sending...'
                        : _resendSecondsRemaining > 0
                        ? 'Resend available in '
                              '${_formatDuration(_resendSecondsRemaining)}'
                        : 'Resend code',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: AppTextStyles.tabularFigures,
                      color: _resendSecondsRemaining == 0 && !isBusy
                          ? AppColors.primaryBright
                          : AppColors.textFaint,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: isBusy ? null : _changeEmail,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(widget.backButtonLabel),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    textStyle: AppTextStyles.body,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
