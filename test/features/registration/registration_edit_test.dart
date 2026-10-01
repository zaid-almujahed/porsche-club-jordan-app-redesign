import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pcj_v5/core/services/image_picker_service.dart';
import 'package:pcj_v5/features/registration/domain/entities/registration_submission.dart';
import 'package:pcj_v5/features/registration/domain/repositories/registration_repository.dart';
import 'package:pcj_v5/features/registration/presentation/controllers/registration_controller.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';

class _Picker extends ImagePickerService {
  @override
  Future<XFile?> pickFromGallery() async =>
      XFile.fromData(Uint8List.fromList(<int>[1, 2, 3]), name: 'photo.png');
}

class _Registration implements RegistrationRepository {
  @override
  Future<User> submitApplication(RegistrationSubmission submission) async =>
      User(
        id: '40',
        name: submission.fullName,
        email: submission.email,
        phoneNumber: submission.phoneNumber,
        applicationStatus: ApplicationStatus.pending,
        membershipStatus: MembershipStatus.inactive,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('cancelling an edit keeps the submitted application', () async {
    final RegistrationController controller = RegistrationController(
      imagePickerService: _Picker(),
      registrationRepository: _Registration(),
    );
    controller.fullNameController.text = 'Lina Haddad';
    controller.phoneController.text = '0791234567';
    controller.cityController.text = 'Amman';
    controller.setDateOfBirth(DateTime(1990, 5, 1));
    await controller.pickProfilePhoto();
    controller.vehicleModelController.text = '911 Carrera';
    controller.vehicleYearController.text = '2021';
    controller.vinController.text = 'WP0ZZZ99ZMS251234';
    controller.licensePlateController.text = '12-34567';
    await controller.pickLicensePhoto();
    controller.emailController.text = 'lina@example.com';
    controller.passwordController.text = 'Password1';
    controller.confirmPasswordController.text = 'Password1';
    controller.setAgreementAccepted(true);
    expect(await controller.submitApplication(), isTrue);
    expect(controller.submittedLogin?.email, 'lina@example.com');

    controller.beginEditingSubmittedApplication();
    controller.fullNameController.text = 'Someone Else';
    controller.cityController.text = 'Irbid';
    controller.cancelEditingSubmittedApplication();

    expect(controller.isEditingSubmittedApplication, isFalse);
    expect(controller.fullNameController.text, 'Lina Haddad');
    expect(controller.cityController.text, 'Amman');
    expect(controller.submittedUser?.id, '40');
  });
}
