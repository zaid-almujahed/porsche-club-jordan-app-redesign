import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/features/registration/domain/entities/registration_submission.dart';
import 'package:pcj_v5/features/registration/domain/repositories/registration_repository.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';

import '../models/registration_submission_model.dart';

class ApiRegistrationRepository implements RegistrationRepository {
  ApiRegistrationRepository({required PcjApiClient apiClient})
    : _apiClient = apiClient;

  final PcjApiClient _apiClient;

  // Exact purpose value supplied for registration OTP verification/resend.
  static const String _registrationOtpPurpose = 'register';

  @override
  Future<User> submitApplication(RegistrationSubmission submission) async {
    final RegistrationSubmissionModel request =
        RegistrationSubmissionModel.fromEntity(submission);
    final Object? response = await _apiClient.multipart(
      '/auth/register',
      method: 'POST',
      fields: request.toFields(),
      files: <ApiUpload>[
        ApiUpload(
          field: 'userphoto',
          fileName: request.profilePhotoName,
          bytes: request.profilePhotoBytes,
        ),
        ApiUpload(
          // This spelling intentionally matches the published API contract.
          field: 'licens_plate_photo',
          fileName: request.licensePhotoName,
          bytes: request.licensePhotoBytes,
        ),
      ],
      authenticated: false,
    );

    // /auth/register completes the application by itself. Its `id` is only
    // retained so this application can be edited during the current
    // registration session.
    final Object? registrationData = unwrapApiData(response);
    final Map<String, dynamic>? registration = registrationData is Map
        ? Map<String, dynamic>.from(registrationData)
        : null;
    final String userId = registration == null
        ? ''
        : firstString(registration, const <String>['id']) ?? '';

    return _pendingUser(userId: userId, submission: submission);
  }

  @override
  Future<User> updateApplication({
    required String userId,
    required RegistrationSubmission submission,
    required bool includeProfilePhoto,
    required bool includeLicensePhoto,
  }) async {
    final RegistrationSubmissionModel request =
        RegistrationSubmissionModel.fromEntity(submission);
    await _apiClient.multipart(
      '/auth/membership/application/${Uri.encodeComponent(userId)}',
      method: 'PUT',
      fields: request.toApplicationFields(),
      files: _applicationFiles(
        request,
        includeProfilePhoto: includeProfilePhoto,
        includeLicensePhoto: includeLicensePhoto,
      ),
      authenticated: false,
    );
    return _pendingUser(userId: userId, submission: submission);
  }

  static List<ApiUpload> _applicationFiles(
    RegistrationSubmissionModel request, {
    required bool includeProfilePhoto,
    required bool includeLicensePhoto,
  }) {
    return <ApiUpload>[
      if (includeProfilePhoto)
        ApiUpload(
          field: 'userphoto',
          fileName: request.profilePhotoName,
          bytes: request.profilePhotoBytes,
        ),
      if (includeLicensePhoto)
        ApiUpload(
          field: 'licens_plate_photo',
          fileName: request.licensePhotoName,
          bytes: request.licensePhotoBytes,
        ),
    ];
  }

  static User _pendingUser({
    required String userId,
    required RegistrationSubmission submission,
  }) {
    return User(
      id: userId,
      name: submission.fullName,
      email: submission.email,
      phoneNumber: submission.phoneNumber,
      city: submission.city,
      dateOfBirth: submission.dateOfBirth,
      applicationStatus: ApplicationStatus.pending,
      membershipStatus: MembershipStatus.inactive,
      vehicles: <Vehicle>[
        Vehicle(
          id: submission.vin,
          model: submission.vehicleModel,
          year: submission.vehicleYear,
          exteriorColor: '',
          vin: submission.vin,
          licensePlate: submission.licensePlate,
        ),
      ],
    );
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    await _apiClient.postForm(
      '/auth/verify-otp',
      fields: <String, Object?>{
        'email': email.trim(),
        'otp': otp.trim(),
        'purpose': _registrationOtpPurpose,
      },
      authenticated: false,
    );
  }

  @override
  Future<void> resendEmailOtp({required String email}) async {
    await _apiClient.post(
      '/auth/resend-otp',
      query: <String, Object?>{
        'email': email.trim(),
        'purpose': _registrationOtpPurpose,
      },
      authenticated: false,
    );
  }
}
