import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/features/auth/domain/repositories/auth_repository.dart';
import 'package:pcj_v5/features/auth/presentation/controllers/password_controller.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';

void main() {
  late _FakeAuthRepository repository;
  late PasswordController controller;

  setUp(() {
    repository = _FakeAuthRepository();
    controller = PasswordController(repository: repository);
  });
  tearDown(() => controller.dispose());

  void typeNewPassword(String password, [String? confirmation]) {
    controller.newPasswordController.text = password;
    controller.confirmNewPasswordController.text = confirmation ?? password;
  }

  group('forgot password (Sign In)', () {
    test('needs an email before sending a code', () async {
      expect(await controller.requestPasswordReset('  '), isFalse);
      expect(controller.resetRequestError, 'Enter your email address first.');
      expect(repository.calls, isEmpty);
    });

    test('code, then new password, resets it', () async {
      expect(
        await controller.requestPasswordReset(' member@example.com '),
        isTrue,
      );
      expect(controller.passwordResetEmail, 'member@example.com');

      controller.passwordResetOtpController.text = '123456';
      expect(await controller.verifyPasswordResetOtp(), isTrue);

      typeNewPassword('newpass12');
      expect(await controller.resetPassword(), isTrue);

      expect(repository.calls, <String>[
        'forgot-password member@example.com',
        'verify member@example.com 123456',
        'reset reset-token newpass12',
      ]);
      // Everything is cleared for next time.
      expect(controller.passwordResetEmail, isNull);
      expect(controller.newPasswordController.text, isEmpty);
    });

    test('a failed request is shown on Sign In', () async {
      repository.error = const AppException('User not found.');

      expect(await controller.requestPasswordReset('x@example.com'), isFalse);
      expect(controller.resetRequestError, 'User not found.');

      controller.clearResetRequestError();
      expect(controller.resetRequestError, isNull);
    });

    test('a wrong code keeps the dialog open with a message', () async {
      await controller.requestPasswordReset('member@example.com');
      repository.error = const AppException('Invalid or expired OTP.');
      controller.passwordResetOtpController.text = '000000';

      expect(await controller.verifyPasswordResetOtp(), isFalse);
      expect(controller.passwordResetError, 'Invalid or expired OTP.');
    });

    test('the new password must follow the rules and match', () async {
      await controller.requestPasswordReset('member@example.com');
      controller.passwordResetOtpController.text = '123456';
      await controller.verifyPasswordResetOtp();

      typeNewPassword('short1');
      expect(await controller.resetPassword(), isFalse);
      expect(controller.passwordResetError, contains('at least 8'));

      typeNewPassword('newpass12', 'newpass13');
      expect(await controller.resetPassword(), isFalse);
      expect(controller.passwordResetError, 'The passwords do not match.');
      expect(repository.calls.last, startsWith('verify'));
    });
  });

  group('change password (Account Settings)', () {
    test('the current password is checked with a login request', () async {
      expect(
        await controller.verifyCurrentPasswordForChange(
          email: 'member@example.com',
          password: 'oldpass12',
        ),
        isTrue,
      );
      expect(repository.calls, <String>['login member@example.com']);

      repository.error = const AppException('Invalid email or password.');
      expect(
        await controller.verifyCurrentPasswordForChange(
          email: 'member@example.com',
          password: 'wrong',
        ),
        isFalse,
      );
      expect(controller.passwordResetError, 'Invalid email or password.');
    });

    test('new password first, then one step verifies and saves it', () async {
      typeNewPassword('newpass12');
      expect(
        await controller.requestPasswordChangeCode('member@example.com'),
        isTrue,
      );

      controller.passwordResetOtpController.text = '123456';
      expect(await controller.verifyAndResetPassword(), isTrue);
      expect(repository.calls, <String>[
        'forgot-password member@example.com',
        'verify member@example.com 123456',
        'reset reset-token newpass12',
      ]);
    });

    test('no code is sent for a password that breaks the rules', () async {
      typeNewPassword('nonumbers');
      expect(
        await controller.requestPasswordChangeCode('member@example.com'),
        isFalse,
      );
      expect(controller.passwordResetError, contains('number'));
      expect(repository.calls, isEmpty);
    });
  });

  test('cancel clears every step', () async {
    await controller.requestPasswordReset('member@example.com');
    controller.passwordResetOtpController.text = '123456';
    typeNewPassword('newpass12');

    controller.cancelPasswordReset();

    expect(controller.passwordResetEmail, isNull);
    expect(controller.passwordResetOtpController.text, isEmpty);
    expect(controller.newPasswordController.text, isEmpty);
    expect(controller.passwordResetError, isNull);
    expect(controller.resetRequestError, isNull);
  });
}

class _FakeAuthRepository implements AuthRepository {
  final List<String> calls = <String>[];

  /// Thrown by the next call, then cleared.
  Object? error;

  void _answer(String call) {
    final Object? failure = error;
    error = null;
    if (failure != null) throw failure;
    calls.add(call);
  }

  @override
  Future<void> requestSignInOtp({
    required String email,
    required String password,
  }) async => _answer('login $email');

  @override
  Future<void> requestPasswordReset(String email) async =>
      _answer('forgot-password $email');

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    _answer('verify $email $otp');
    return 'reset-token';
  }

  @override
  Future<void> resendPasswordResetOtp({required String email}) async =>
      _answer('resend $email');

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async => _answer('reset $resetToken $newPassword');

  @override
  Future<User?> restoreSession() => throw UnimplementedError();

  @override
  Future<User?> checkMembershipStatus(User user) => throw UnimplementedError();

  @override
  Future<User> verifySignInOtp({required String email, required String otp}) =>
      throw UnimplementedError();

  @override
  Future<void> resendSignInOtp({required String email}) =>
      throw UnimplementedError();

  @override
  Future<Object?> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) => throw UnimplementedError();

  @override
  Future<void> resendOtp({required String email, required String purpose}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}
