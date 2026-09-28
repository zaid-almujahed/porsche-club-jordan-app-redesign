import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/features/auth/domain/repositories/auth_repository.dart';
import 'package:pcj_v5/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';

void main() {
  const User activeUser = User(
    id: 'member-1',
    name: 'Member',
    email: 'member@example.com',
    phoneNumber: '+962790000000',
    applicationStatus: ApplicationStatus.approved,
    membershipStatus: MembershipStatus.active,
  );

  test('a stale startup restore cannot overwrite a newer login attempt', () async {
    final _FakeAuthRepository repository = _FakeAuthRepository();
    final AuthController controller = AuthController(repository: repository);
    addTearDown(controller.dispose);

    final Future<void> restore = controller.restoreSession();
    controller.identifierController.text = 'member@example.com';
    controller.passwordController.text = 'password1';

    expect(await controller.requestSignInOtp(), isTrue);
    repository.restoreCompleter.complete(activeUser);
    await restore;

    expect(controller.currentUser, isNull);
    expect(controller.signInOtpEmail, 'member@example.com');
  });

  test('verified login is published only after the OTP dialog completes', () async {
    final _FakeAuthRepository repository = _FakeAuthRepository(
      verifiedUser: activeUser,
    );
    final AuthController controller = AuthController(repository: repository);
    addTearDown(controller.dispose);
    controller.identifierController.text = 'member@example.com';
    controller.passwordController.text = 'password1';

    expect(await controller.requestSignInOtp(), isTrue);
    controller.otpController.text = '123456';
    expect(await controller.verifySignInOtp(), isTrue);
    expect(controller.currentUser, isNull);

    expect(controller.completeSignIn(), activeUser);
    expect(controller.currentUser, activeUser);
  });

  test('exact waiting-for-approval response creates a pending session', () async {
    final _FakeAuthRepository repository = _FakeAuthRepository(
      requestError: const AppException(
        'Waiting for admin approval.',
        statusCode: 400,
      ),
    );
    final AuthController controller = AuthController(repository: repository);
    addTearDown(controller.dispose);
    controller.identifierController.text = 'pending@example.com';
    controller.passwordController.text = 'password1';

    expect(await controller.requestSignInOtp(), isFalse);
    expect(
      controller.currentUser?.applicationStatus,
      ApplicationStatus.pending,
    );
    expect(controller.currentUser?.email, 'pending@example.com');
  });

  test('a suspended / deactivated member is turned away at sign in', () async {
    final _FakeAuthRepository repository = _FakeAuthRepository(
      verifiedUser: activeUser.copyWith(
        membershipStatus: MembershipStatus.suspended,
      ),
    );
    final AuthController controller = AuthController(repository: repository);
    addTearDown(controller.dispose);
    controller.identifierController.text = 'member@example.com';
    controller.passwordController.text = 'password1';

    expect(await controller.requestSignInOtp(), isTrue);
    controller.otpController.text = '123456';
    expect(await controller.verifySignInOtp(), isTrue);

    expect(controller.completeSignIn(), isNull);
    expect(controller.currentUser, isNull);
    expect(controller.hasDeactivatedAccountNotice, isTrue);
    expect(controller.takeDeactivatedAccountNotice(), 'member@example.com');
    expect(controller.hasDeactivatedAccountNotice, isFalse);
  });

  test('an expired token ends a live session with a clear message', () async {
    final _FakeAuthRepository repository = _FakeAuthRepository();
    final AuthController controller = AuthController(repository: repository);
    addTearDown(controller.dispose);

    // Nothing to expire before sign in.
    expect(controller.expireSession(), isFalse);

    final Future<void> restore = controller.restoreSession();
    repository.restoreCompleter.complete(activeUser);
    await restore;
    expect(controller.currentUser, activeUser);

    expect(controller.expireSession(), isTrue);
    expect(controller.currentUser, isNull);
    expect(
      readableError(controller.session.error!),
      'Your session has expired. Please sign in again.',
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.verifiedUser, this.requestError});

  final Completer<User?> restoreCompleter = Completer<User?>();
  final User? verifiedUser;
  final Object? requestError;

  @override
  Future<User?> restoreSession() => restoreCompleter.future;

  @override
  Future<void> requestSignInOtp({
    required String email,
    required String password,
  }) async {
    if (requestError != null) throw requestError!;
  }

  @override
  Future<User> verifySignInOtp({
    required String email,
    required String otp,
  }) async {
    return verifiedUser!;
  }

  @override
  Future<void> resendSignInOtp({required String email}) async {}

  @override
  Future<void> requestPasswordReset(String email) async {}

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    return 'reset-token';
  }

  @override
  Future<void> resendPasswordResetOtp({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {}

  @override
  Future<Object?> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    return null;
  }

  @override
  Future<void> resendOtp({
    required String email,
    required String purpose,
  }) async {}

  @override
  Future<void> signOut() async {}
}
