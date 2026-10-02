import 'package:pcj_v5/shared/domain/entities/user.dart';

abstract interface class AuthRepository {
  Future<User?> restoreSession();

  /// Re-reads only the membership status (`GET /member/membership`) and
  /// returns [user] updated with it, or null when no login is stored.
  Future<User?> checkMembershipStatus(User user);

  /// Validates the email/password and requests a login OTP.
  Future<void> requestSignInOtp({
    required String email,
    required String password,
  });

  /// Verifies the login OTP and returns the authenticated user.
  Future<User> verifySignInOtp({
    required String email,
    required String otp,
  });

  /// Requests another login OTP.
  Future<void> resendSignInOtp({
    required String email,
  });

  /// Emails a new registration code to an applicant whose email is not
  /// verified yet (sign in answered "Please verify your email address
  /// first.").
  Future<void> resendEmailVerificationOtp({required String email});

  /// Verifies the registration code, completing the application.
  Future<void> verifyEmailOtp({required String email, required String otp});

  Future<void> requestPasswordReset(String email);

  /// Verifies the forgot-password OTP and returns the short-lived reset token.
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  });

  Future<void> resendPasswordResetOtp({required String email});

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  });

  Future<void> signOut();
}
