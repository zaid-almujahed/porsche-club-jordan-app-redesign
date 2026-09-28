import 'package:country_picker/country_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/core/services/image_picker_service.dart';
import 'package:pcj_v5/features/registration/domain/entities/registration_submission.dart';
import 'package:pcj_v5/features/registration/domain/repositories/registration_repository.dart';
import 'package:pcj_v5/features/registration/presentation/controllers/registration_controller.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';

void main() {
  late RegistrationController controller;

  setUp(() {
    controller = RegistrationController(
      imagePickerService: ImagePickerService(),
      registrationRepository: _UnusedRegistrationRepository(),
    );
  });
  tearDown(() => controller.dispose());

  String submitted(String typed) {
    controller.phoneController.text = typed;
    return controller.normalizedPhoneNumber;
  }

  test('Jordan is selected until the applicant picks another country', () {
    expect(controller.phoneCountry.countryCode, 'JO');
    expect(submitted('079 123 4567'), '+962791234567');
    expect(submitted('791234567'), '+962791234567');
  });

  test('any country can be picked', () {
    controller.selectPhoneCountry(Country.parse('GB'));
    expect(submitted('07700 900123'), '+447700900123');

    controller.selectPhoneCountry(Country.parse('US'));
    expect(submitted('(202) 555-0147'), '+12025550147');
  });

  test('a number typed in international form is kept as typed', () {
    controller.selectPhoneCountry(Country.parse('GB'));
    expect(submitted('+971 50 123 4567'), '+971501234567');
    expect(submitted('00971501234567'), '+971501234567');
  });

  test('only complete international numbers are valid', () {
    expect(RegistrationController.isValidPhoneNumber('+962791234567'), isTrue);
    expect(RegistrationController.isValidPhoneNumber('+9627912'), isFalse);
    expect(
      RegistrationController.isValidPhoneNumber('+9627912345678901'),
      isFalse,
    );
    expect(RegistrationController.isValidPhoneNumber('0791234567'), isFalse);
  });

  test('reset goes back to Jordan', () {
    controller.selectPhoneCountry(Country.parse('GB'));
    controller.reset();
    expect(controller.phoneCountry.countryCode, 'JO');
  });
}

class _UnusedRegistrationRepository implements RegistrationRepository {
  @override
  Future<User> submitApplication(RegistrationSubmission submission) =>
      throw UnimplementedError();

  @override
  Future<User> updateApplication({
    required String userId,
    required RegistrationSubmission submission,
    required bool includeProfilePhoto,
    required bool includeLicensePhoto,
  }) => throw UnimplementedError();

  @override
  Future<void> verifyEmailOtp({required String email, required String otp}) =>
      throw UnimplementedError();

  @override
  Future<void> resendEmailOtp({required String email}) =>
      throw UnimplementedError();
}
