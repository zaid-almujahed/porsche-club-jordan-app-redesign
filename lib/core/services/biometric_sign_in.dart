import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Face ID, Touch ID or a fingerprint, as the phone offers it.
abstract interface class BiometricPrompt {
  /// "Face ID", "Touch ID", "Fingerprint" or "Biometrics"; null when the
  /// phone has none set up.
  Future<String?> availableName();

  /// Asks the phone's owner to confirm with it; false when declined.
  Future<bool> confirm(String reason);
}

class DeviceBiometricPrompt implements BiometricPrompt {
  DeviceBiometricPrompt({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<String?> availableName() =>
      // Never hold up signing in on a phone that does not answer.
      _availableName().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );

  Future<String?> _availableName() async {
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) {
        return null;
      }
      final List<BiometricType> types = await _auth.getAvailableBiometrics();
      if (types.isEmpty) return null;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return types.contains(BiometricType.face) ? 'Face ID' : 'Touch ID';
      }
      return types.contains(BiometricType.fingerprint)
          ? 'Fingerprint'
          : 'Biometrics';
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> confirm(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}

/// Sign in with Face ID: the member's email and password kept on this phone
/// only (Keychain / Keystore, not synced), read after Face ID confirms. The
/// emailed code is still asked for.
class BiometricSignIn extends ChangeNotifier {
  BiometricSignIn({
    required BiometricPrompt prompt,
    FlutterSecureStorage? storage,
  }) : _prompt = prompt,
       _storage = storage ?? const FlutterSecureStorage();

  final BiometricPrompt _prompt;
  final FlutterSecureStorage _storage;

  static const String _emailKey = 'pcj_biometric_email';
  static const String _passwordKey = 'pcj_biometric_password';

  // This phone only, and readable only while it is unlocked.
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
  );

  /// See [BiometricPrompt.availableName].
  Future<String?> availableName() => _prompt.availableName();

  /// The email saved for signing in with Face ID; reading it needs no Face
  /// ID.
  Future<String?> savedEmail() async {
    try {
      final String? email = await _storage.read(
        key: _emailKey,
        iOptions: _iosOptions,
      );
      return email == null || email.isEmpty ? null : email;
    } catch (_) {
      return null;
    }
  }

  /// Saves the login once [name] (Face ID…) confirms the phone's owner.
  Future<bool> enable({
    required String email,
    required String password,
    required String name,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) return false;
    if (!await _prompt.confirm('Turn on $name sign in')) return false;
    try {
      await _storage.write(
        key: _passwordKey,
        value: password,
        iOptions: _iosOptions,
      );
      await _storage.write(
        key: _emailKey,
        value: email.trim(),
        iOptions: _iosOptions,
      );
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The saved login, once Face ID confirms; null when there is none or it
  /// was declined.
  Future<({String email, String password})?> unlock() async {
    final String? email = await savedEmail();
    if (email == null) return null;
    if (!await _prompt.confirm('Sign in to Porsche Club Jordan')) return null;
    try {
      final String? password = await _storage.read(
        key: _passwordKey,
        iOptions: _iosOptions,
      );
      if (password == null || password.isEmpty) return null;
      return (email: email, password: password);
    } catch (_) {
      return null;
    }
  }

  /// Keeps a saved login working after its password changed.
  Future<void> updatePassword({
    required String email,
    required String password,
  }) async {
    final String? saved = await savedEmail();
    if (saved == null ||
        saved.toLowerCase() != email.trim().toLowerCase() ||
        password.isEmpty) {
      return;
    }
    try {
      await _storage.write(
        key: _passwordKey,
        value: password,
        iOptions: _iosOptions,
      );
    } catch (_) {
      // The next Face ID sign in fails and forgets the login.
    }
  }

  /// Forgets the saved login.
  Future<void> disable() async {
    try {
      await _storage.delete(key: _passwordKey, iOptions: _iosOptions);
      await _storage.delete(key: _emailKey, iOptions: _iosOptions);
    } catch (_) {
      // Nothing more to do.
    }
    notifyListeners();
  }
}
