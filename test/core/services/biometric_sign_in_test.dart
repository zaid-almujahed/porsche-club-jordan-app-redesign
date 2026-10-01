import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/core/services/biometric_sign_in.dart';

class _FaceId implements BiometricPrompt {
  bool approve = true;

  @override
  Future<String?> availableName() async => 'Face ID';

  @override
  Future<bool> confirm(String reason) async => approve;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Map<String, String> stored = <String, String>{};

  setUp(() {
    stored.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (MethodCall call) async {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            final String key = arguments['key']! as String;
            switch (call.method) {
              case 'read':
                return stored[key];
              case 'write':
                stored[key] = arguments['value']! as String;
              case 'delete':
                stored.remove(key);
            }
            return null;
          },
        );
  });

  test('the login is saved and read only after Face ID', () async {
    final _FaceId faceId = _FaceId();
    final BiometricSignIn signIn = BiometricSignIn(prompt: faceId);

    faceId.approve = false;
    expect(
      await signIn.enable(
        email: 'a@b.com',
        password: 'secret1',
        name: 'Face ID',
      ),
      isFalse,
    );
    expect(await signIn.savedEmail(), isNull);

    faceId.approve = true;
    expect(
      await signIn.enable(
        email: 'a@b.com',
        password: 'secret1',
        name: 'Face ID',
      ),
      isTrue,
    );
    expect(await signIn.savedEmail(), 'a@b.com');

    faceId.approve = false;
    expect(await signIn.unlock(), isNull);
    faceId.approve = true;
    expect(await signIn.unlock(), (email: 'a@b.com', password: 'secret1'));
  });

  test(
    'a changed password updates the saved one; disable forgets it',
    () async {
      final BiometricSignIn signIn = BiometricSignIn(prompt: _FaceId());
      await signIn.enable(
        email: 'a@b.com',
        password: 'secret1',
        name: 'Face ID',
      );

      await signIn.updatePassword(email: 'other@b.com', password: 'nope');
      await signIn.updatePassword(email: 'A@B.com', password: 'secret2');
      expect((await signIn.unlock())?.password, 'secret2');

      await signIn.disable();
      expect(await signIn.savedEmail(), isNull);
      expect(stored, isEmpty);
    },
  );
}
