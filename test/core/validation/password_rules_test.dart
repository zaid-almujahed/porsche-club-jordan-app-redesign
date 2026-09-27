import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/core/validation/password_rules.dart';

void main() {
  group('PasswordRules', () {
    test('accepts eight or more characters containing a number', () {
      expect(PasswordRules.isValid('porsche1'), isTrue);
      expect(PasswordRules.isValid('long password 7'), isTrue);
    });

    test('rejects a short password', () {
      expect(PasswordRules.isValid('pcj1'), isFalse);
      expect(
        PasswordRules.validationMessage('pcj1'),
        'Password must contain at least 8 characters.',
      );
    });

    test('rejects a password without a number', () {
      expect(PasswordRules.isValid('porscheclub'), isFalse);
      expect(
        PasswordRules.validationMessage('porscheclub'),
        'Password must contain at least one number.',
      );
    });
  });
}
