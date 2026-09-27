import 'package:flutter/material.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/core/validation/password_rules.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordResetOtpController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController =
      TextEditingController();

  AsyncState<User?> _session = const AsyncState<User?>.initial();
  String? _validationError;
  String? _otpError;
  String? _signInOtpEmail;
  User? _verifiedSignInUser;
  bool _isRequestingSignInOtp = false;
  bool _isVerifyingSignInOtp = false;
  bool _isResendingSignInOtp = false;
  String? _passwordResetEmail;
  String? _passwordResetToken;
  String? _passwordResetError;
  bool _isRequestingPasswordReset = false;
  bool _isVerifyingPasswordResetOtp = false;
  bool _isResendingPasswordResetOtp = false;
  bool _isResettingPassword = false;
  bool _isVerifyingCurrentPassword = false;
  // A startup restore may still be running when a member begins a new login.
  // Only the newest session operation is allowed to publish router state.
  int _sessionGeneration = 0;

  AsyncState<User?> get session => _session;
  User? get currentUser => _session.data;
  String? get validationError => _validationError;
  String? get otpError => _otpError;
  String? get signInOtpEmail => _signInOtpEmail;
  User? get pendingSignInUser => _verifiedSignInUser;
  bool get isAuthenticated => currentUser != null;
  bool get isRequestingSignInOtp => _isRequestingSignInOtp;
  bool get isVerifyingSignInOtp => _isVerifyingSignInOtp;
  bool get isResendingSignInOtp => _isResendingSignInOtp;
  String? get passwordResetEmail => _passwordResetEmail;
  String? get passwordResetError => _passwordResetError;
  bool get isRequestingPasswordReset => _isRequestingPasswordReset;
  bool get isVerifyingPasswordResetOtp => _isVerifyingPasswordResetOtp;
  bool get isResendingPasswordResetOtp => _isResendingPasswordResetOtp;
  bool get isResettingPassword => _isResettingPassword;
  bool get isVerifyingCurrentPassword => _isVerifyingCurrentPassword;
  bool get newPasswordHasMinimumLength =>
      PasswordRules.hasMinimumLength(newPasswordController.text);
  bool get newPasswordHasNumber =>
      PasswordRules.hasNumber(newPasswordController.text);

  Future<void> restoreSession() async {
    final int generation = ++_sessionGeneration;
    _session = AsyncState<User?>.loading(previousData: currentUser);
    notifyListeners();

    try {
      final User? restoredUser = await _repository.restoreSession();
      if (generation != _sessionGeneration) return;
      _session = AsyncState<User?>.success(restoredUser);
    } catch (error, stackTrace) {
      if (generation != _sessionGeneration) return;
      _session = AsyncState<User?>.failure(error, stackTrace);
    }
    notifyListeners();
  }

  Future<bool> requestSignInOtp() async {
    if (_isRequestingSignInOtp ||
        _isVerifyingSignInOtp ||
        _isResendingSignInOtp) {
      return false;
    }

    final String identifier = identifierController.text.trim();
    final String password = passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _validationError = 'Enter your email address and password.';
      notifyListeners();
      return false;
    }

    _validationError = null;
    _otpError = null;
    // This login attempt supersedes any startup restore still in flight.
    _sessionGeneration++;
    _session = AsyncState<User?>.success(currentUser);
    _isRequestingSignInOtp = true;
    notifyListeners();

    try {
      await _repository.requestSignInOtp(
        email: identifier,
        password: password,
      );
      _signInOtpEmail = identifier;
      otpController.clear();
      return true;
    } catch (error, stackTrace) {
      final User? applicationUser = _applicationUserFromError(
        error,
        email: identifier,
      );
      if (applicationUser != null) {
        _session = AsyncState<User?>.success(applicationUser);
        passwordController.clear();
        return false;
      }
      _session = AsyncState<User?>.failure(
        error,
        stackTrace,
        previousData: currentUser,
      );
      return false;
    } finally {
      _isRequestingSignInOtp = false;
      notifyListeners();
    }
  }

  Future<bool> verifySignInOtp() async {
    if (_isVerifyingSignInOtp || _isResendingSignInOtp) return false;

    final String? email = _signInOtpEmail;
    final String otp = otpController.text.trim();
    if (email == null || email.isEmpty) {
      _otpError = 'Return to sign in and enter your email address again.';
      notifyListeners();
      return false;
    }
    if (otp.isEmpty) {
      _otpError = 'Enter the verification code sent to your email.';
      notifyListeners();
      return false;
    }

    _isVerifyingSignInOtp = true;
    _otpError = null;
    notifyListeners();

    try {
      final User user = await _repository.verifySignInOtp(
        email: email,
        otp: otp,
      );
      // Do not publish the authenticated session while the OTP route is still
      // on the root navigator. Publishing here lets go_router remove the sign
      // in route before the dialog closes, which can pop the last page and
      // leave a black screen. SignInPage calls completeSignIn() only after the
      // dialog has returned.
      _verifiedSignInUser = user;
      passwordController.clear();
      otpController.clear();
      return true;
    } catch (error, stackTrace) {
      _otpError = readableError(
        error,
        fallback: 'The verification code is incorrect or has expired.',
      );
      _session = AsyncState<User?>.failure(
        error,
        stackTrace,
        previousData: currentUser,
      );
      return false;
    } finally {
      _isVerifyingSignInOtp = false;
      notifyListeners();
    }
  }

  User? completeSignIn() {
    final User? user = _verifiedSignInUser;
    if (user == null) return null;
    _sessionGeneration++;
    _verifiedSignInUser = null;
    _signInOtpEmail = null;
    _session = AsyncState<User?>.success(user);
    notifyListeners();
    return user;
  }

  Future<bool> resendSignInOtp() async {
    if (_isVerifyingSignInOtp || _isResendingSignInOtp) return false;

    final String? email = _signInOtpEmail;
    if (email == null || email.isEmpty) {
      _otpError = 'Return to sign in and enter your email address again.';
      notifyListeners();
      return false;
    }

    _isResendingSignInOtp = true;
    _otpError = null;
    notifyListeners();

    try {
      await _repository.resendSignInOtp(email: email);
      otpController.clear();
      return true;
    } catch (error) {
      _otpError = readableError(
        error,
        fallback: 'A new verification code could not be sent.',
      );
      return false;
    } finally {
      _isResendingSignInOtp = false;
      notifyListeners();
    }
  }

  void onOtpChanged(String _) {
    _otpError = null;
    notifyListeners();
  }

  void cancelSignInOtp() {
    otpController.clear();
    _otpError = null;
    _signInOtpEmail = null;
    _verifiedSignInUser = null;
    notifyListeners();
  }

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

  Future<bool> requestPasswordReset() async {
    final String identifier = identifierController.text.trim();
    if (identifier.isEmpty) {
      _validationError = 'Enter your email address first.';
      notifyListeners();
      return false;
    }

    _isRequestingPasswordReset = true;
    _passwordResetError = null;
    notifyListeners();
    try {
      await _repository.requestPasswordReset(identifier);
      _passwordResetEmail = identifier;
      _passwordResetToken = null;
      passwordResetOtpController.clear();
      newPasswordController.clear();
      confirmNewPasswordController.clear();
      return true;
    } catch (error, stackTrace) {
      _session = AsyncState<User?>.failure(
        AppException(readableError(error)),
        stackTrace,
        previousData: currentUser,
      );
      notifyListeners();
      return false;
    } finally {
      _isRequestingPasswordReset = false;
      notifyListeners();
    }
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

  void cancelPasswordReset() {
    passwordResetOtpController.clear();
    newPasswordController.clear();
    confirmNewPasswordController.clear();
    _passwordResetEmail = null;
    _passwordResetToken = null;
    _passwordResetError = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    _sessionGeneration++;
    try {
      await _repository.signOut();
    } catch (_) {
      // The local session is still cleared if the revoke request cannot reach
      // the server. The API client should also delete its locally stored token.
    } finally {
      // A failed revoke request must not keep a local authenticated session.
      _session = const AsyncState<User?>.success(null);
      identifierController.clear();
      passwordController.clear();
      otpController.clear();
      _signInOtpEmail = null;
      _verifiedSignInUser = null;
      cancelPasswordReset();
      _otpError = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    otpController.dispose();
    passwordResetOtpController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  User? _applicationUserFromError(Object error, {required String email}) {
    if (error is! AppException || error.statusCode != 400) return null;
    final String message = error.message.toLowerCase().trim();
    final bool isPending =
        message == 'waiting for admin approval.' ||
        message == 'waiting for admin approval' ||
        message.contains('pending approval');
    final bool isDenied =
        message.contains('rejected') || message.contains('denied');
    if (!isPending && !isDenied) return null;
    return User(
      id: email,
      name: '',
      email: email,
      phoneNumber: '',
      applicationStatus:
          isDenied ? ApplicationStatus.denied : ApplicationStatus.pending,
      membershipStatus: MembershipStatus.inactive,
    );
  }
}
