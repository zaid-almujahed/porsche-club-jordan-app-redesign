import 'package:pcj_v5/shared/domain/entities/user.dart';

import '../entities/registration_submission.dart';

abstract interface class RegistrationRepository {
  Future<User> submitApplication(RegistrationSubmission submission);

  Future<User> updateApplication({
    required String userId,
    required RegistrationSubmission submission,
    required bool includeProfilePhoto,
    required bool includeLicensePhoto,
  });

  Future<void> verifyEmailOtp({required String email, required String otp});

  Future<void> resendEmailOtp({required String email});
}
