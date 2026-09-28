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

  Future<Object?> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  });

  Future<void> resendOtp({
    required String email,
    required String purpose,
  });

  Future<void> signOut();
}
