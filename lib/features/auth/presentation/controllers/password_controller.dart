import 'package:flutter/material.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/validation/password_rules.dart';

import '../../domain/repositories/auth_repository.dart';

/// Forgot password (from Sign In) and change password (from Account
/// Settings). Both end with the same email code and reset request:
///
/// 1. `POST /auth/forgot-password` sends a code to the email.
/// 2. `POST /auth/verify-otp` (purpose `forgot_password`) returns a reset
///    token.
/// 3. `POST /auth/reset-password` saves the new password.
///
/// Changing the password first checks the current one (see
/// [verifyCurrentPasswordForChange]) and collects the new password before
/// the code is sent.
class PasswordController extends ChangeNotifier {
  PasswordController({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  final TextEditingController passwordResetOtpController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController =
      TextEditingController();

  String? _passwordResetEmail;
  String? _passwordResetToken;
  String? _passwordResetError;
  String? _resetRequestError;
  bool _isRequestingPasswordReset = false;
  bool _isVerifyingPasswordResetOtp = false;
  bool _isResendingPasswordResetOtp = false;
  bool _isResettingPassword = false;
  bool _isVerifyingCurrentPassword = false;

  String? get passwordResetEmail => _passwordResetEmail;

  /// Shown inside the password dialogs.
  String? get passwordResetError => _passwordResetError;

  /// Why "forgot password" could not send a code; shown on Sign In.
  String? get resetRequestError => _resetRequestError;
  bool get isRequestingPasswordReset => _isRequestingPasswordReset;
  bool get isVerifyingPasswordResetOtp => _isVerifyingPasswordResetOtp;
  bool get isResendingPasswordResetOtp => _isResendingPasswordResetOtp;
  bool get isResettingPassword => _isResettingPassword;
  bool get isVerifyingCurrentPassword => _isVerifyingCurrentPassword;

  Future<bool> verifyCurrentPasswordForChange({
    required String email,
    required String password,
  }) async {
    if (_isVerifyingCurrentPassword) return false;
    if (password.isEmpty) {
      _passwordResetError = 'Enter your current password.';
      notifyListeners();
      return false;
    }

    _isVerifyingCurrentPassword = true;
    _passwordResetError = null;
    notifyListeners();
    try {
      // The available API has no dedicated credential-check endpoint. Login
      // validates the supplied password without changing the active session,
      // because its OTP is deliberately not verified or stored here.
      await _repository.requestSignInOtp(
        email: email.trim(),
        password: password,
      );
      return true;
    } catch (error) {
      _passwordResetError = readableError(
        error,
        fallback: 'The current password is incorrect.',
      );
      return false;
    } finally {
      _isVerifyingCurrentPassword = false;
      notifyListeners();
    }
  }

  void onCurrentPasswordChanged(String _) {
    _passwordResetError = null;
    notifyListeners();
  }

  Future<bool> prepareNewPasswordForChange() async {
    final String password = newPasswordController.text;
    final String confirmation = confirmNewPasswordController.text;
    final String? policyError = PasswordRules.validationMessage(password);
    if (policyError != null) {
      _passwordResetError = policyError;
      notifyListeners();
      return false;
    }
    if (password != confirmation) {
      _passwordResetError = 'The passwords do not match.';
      notifyListeners();
      return false;
    }
    _passwordResetError = null;
    notifyListeners();
    return true;
  }

  Future<bool> requestPasswordChangeCode(String email) async {
    if (_isRequestingPasswordReset) return false;
    if (!await prepareNewPasswordForChange()) return false;

    final String normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      _passwordResetError = 'No email address is available for this account.';
      notifyListeners();
      return false;
    }

    _isRequestingPasswordReset = true;
    _passwordResetError = null;
    notifyListeners();
    try {
      await _repository.requestPasswordReset(normalizedEmail);
      _passwordResetEmail = normalizedEmail;
      _passwordResetToken = null;
      passwordResetOtpController.clear();
      return true;
    } catch (error) {
      _passwordResetError = readableError(
        error,
        fallback: 'The confirmation code could not be sent.',
      );
      return false;
    } finally {
      _isRequestingPasswordReset = false;
      notifyListeners();
    }
  }

  /// "Forgot password" on Sign In, for the [email] typed there.
  Future<bool> requestPasswordReset(String email) async {
    final String identifier = email.trim();
    if (identifier.isEmpty) {
      _resetRequestError = 'Enter your email address first.';
      notifyListeners();
      return false;
    }

    _isRequestingPasswordReset = true;
    _passwordResetError = null;
    _resetRequestError = null;
    notifyListeners();
    try {
      await _repository.requestPasswordReset(identifier);
      _passwordResetEmail = identifier;
      _passwordResetToken = null;
      passwordResetOtpController.clear();
      newPasswordController.clear();
      confirmNewPasswordController.clear();
      return true;
    } catch (error) {
      _resetRequestError = readableError(error);
      return false;
    } finally {
      _isRequestingPasswordReset = false;
      notifyListeners();
    }
  }

  void clearResetRequestError() {
    if (_resetRequestError == null) return;
    _resetRequestError = null;
    notifyListeners();
  }

  Future<bool> verifyPasswordResetOtp() async {
    if (_isVerifyingPasswordResetOtp || _isResendingPasswordResetOtp) {
      return false;
    }
    final String? email = _passwordResetEmail;
    final String otp = passwordResetOtpController.text.trim();
    if (email == null || email.isEmpty) {
      _passwordResetError = 'Return to sign in and enter your email again.';
      notifyListeners();
      return false;
    }
    if (otp.isEmpty) {
      _passwordResetError = 'Enter the verification code sent to your email.';
      notifyListeners();
      return false;
    }

    _isVerifyingPasswordResetOtp = true;
    _passwordResetError = null;
    notifyListeners();
    try {
      _passwordResetToken = await _repository.verifyPasswordResetOtp(
        email: email,
        otp: otp,
      );
      return true;
    } catch (error) {
      _passwordResetError = readableError(
        error,
        fallback: 'The verification code is incorrect or has expired.',
      );
      return false;
    } finally {
      _isVerifyingPasswordResetOtp = false;
      notifyListeners();
    }
  }

  Future<bool> resendPasswordResetOtp() async {
    if (_isVerifyingPasswordResetOtp || _isResendingPasswordResetOtp) {
      return false;
    }
    final String? email = _passwordResetEmail;
    if (email == null || email.isEmpty) {
      _passwordResetError = 'Return to sign in and enter your email again.';
      notifyListeners();
      return false;
    }

    _isResendingPasswordResetOtp = true;
    _passwordResetToken = null;
    _passwordResetError = null;
    notifyListeners();
    try {
      await _repository.resendPasswordResetOtp(email: email);
      passwordResetOtpController.clear();
      return true;
    } catch (error) {
      _passwordResetError = readableError(
        error,
        fallback: 'A new verification code could not be sent.',
      );
      return false;
    } finally {
      _isResendingPasswordResetOtp = false;
      notifyListeners();
    }
  }

  void onPasswordResetOtpChanged(String _) {
    _passwordResetError = null;
    notifyListeners();
  }

  void onNewPasswordChanged(String _) {
    _passwordResetError = null;
    notifyListeners();
  }

  Future<bool> resetPassword() async {
    if (_isResettingPassword) return false;
    final String? resetToken = _passwordResetToken;
    final String password = newPasswordController.text;
    final String confirmation = confirmNewPasswordController.text;
    if (resetToken == null || resetToken.isEmpty) {
      _passwordResetError = 'Verify the email code before resetting password.';
      notifyListeners();
      return false;
    }
    final String? policyError = PasswordRules.validationMessage(password);
    if (policyError != null) {
      _passwordResetError = policyError;
      notifyListeners();
      return false;
    }
    if (password != confirmation) {
      _passwordResetError = 'The passwords do not match.';
      notifyListeners();
      return false;
    }

    _isResettingPassword = true;
    _passwordResetError = null;
    notifyListeners();
    try {
      await _repository.resetPassword(
        resetToken: resetToken,
        newPassword: password,
      );
      cancelPasswordReset();
      return true;
    } catch (error) {
      _passwordResetError = readableError(
        error,
        fallback: 'The password could not be reset. Please try again.',
      );
      return false;
    } finally {
      _isResettingPassword = false;
      notifyListeners();
    }
  }

  Future<bool> verifyAndResetPassword() async {
    if (_passwordResetToken == null || _passwordResetToken!.isEmpty) {
      final bool wasVerified = await verifyPasswordResetOtp();
      if (!wasVerified) return false;
    }
    return resetPassword();
  }

  /// Clears every step (also used on sign-out).
  void cancelPasswordReset() {
    passwordResetOtpController.clear();
    newPasswordController.clear();
    confirmNewPasswordController.clear();
    _passwordResetEmail = null;
    _passwordResetToken = null;
    _passwordResetError = null;
    _resetRequestError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    passwordResetOtpController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }
}
