import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/services/image_picker_service.dart';
import 'package:pcj_v5/core/validation/password_rules.dart';
import 'package:pcj_v5/core/validation/vehicle_rules.dart';
import 'package:pcj_v5/features/registration/domain/repositories/registration_repository.dart';

import '../../domain/entities/registration_submission.dart';

import 'package:pcj_v5/shared/domain/entities/user.dart';

class RegistrationController extends ChangeNotifier {
  RegistrationController({
    required ImagePickerService imagePickerService,
    required RegistrationRepository registrationRepository,
  }) : _imagePickerService = imagePickerService,
       _registrationRepository = registrationRepository;

  static const int maximumImageSize = 5 * 1024 * 1024;

  /// The phone country selected until the applicant picks another (Jordan).
  static const String defaultPhoneCountryCode = 'JO';

  final ImagePickerService _imagePickerService;
  final RegistrationRepository _registrationRepository;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController vehicleYearController = TextEditingController();
  final TextEditingController vinController = TextEditingController();
  final TextEditingController licensePlateController = TextEditingController();
  final TextEditingController vehicleModelController = TextEditingController();

  XFile? _profilePhoto;
  XFile? _licensePhoto;
  DateTime? _dateOfBirth;
  Country _phoneCountry = Country.parse(defaultPhoneCountryCode);
  String? _profilePhotoError;
  String? _licensePhotoError;
  String? _personalFormError;
  String? _vehicleFormError;
  String? _passwordFormError;
  bool _isPickingProfilePhoto = false;
  bool _isPickingLicensePhoto = false;
  bool _isAgreementAccepted = false;
  bool _isSubmitting = false;
  bool _isVerifyingOtp = false;
  bool _isResendingOtp = false;
  bool _isEmailVerified = false;
  String? _submissionError;
  String? _otpError;
  User? _submittedUser;
  bool _isEditingSubmittedApplication = false;
  bool _profilePhotoChangedSinceSubmission = false;
  bool _licensePhotoChangedSinceSubmission = false;

  XFile? get profilePhoto => _profilePhoto;
  XFile? get licensePhoto => _licensePhoto;
  DateTime? get dateOfBirth => _dateOfBirth;
  Country get phoneCountry => _phoneCountry;

  /// The phone number as it will be submitted, e.g. "+962791234567".
  String get normalizedPhoneNumber => _normalizePhone(phoneController.text);
  String? get profilePhotoError => _profilePhotoError;
  String? get licensePhotoError => _licensePhotoError;
  String? get personalFormError => _personalFormError;
  String? get vehicleFormError => _vehicleFormError;
  String? get passwordFormError => _passwordFormError;
  bool get isPickingProfilePhoto => _isPickingProfilePhoto;
  bool get isPickingLicensePhoto => _isPickingLicensePhoto;
  bool get isAgreementAccepted => _isAgreementAccepted;
  bool get isSubmitting => _isSubmitting;
  bool get isVerifyingOtp => _isVerifyingOtp;
  bool get isResendingOtp => _isResendingOtp;
  bool get isEmailVerified => _isEmailVerified;
  String? get submissionError => _submissionError;
  String? get otpError => _otpError;
  User? get submittedUser => _submittedUser;
  bool get canEditSubmittedApplication =>
      _submittedUser?.id.trim().isNotEmpty ?? false;
  bool get isEditingSubmittedApplication => _isEditingSubmittedApplication;

  bool get hasMinimumPasswordLength =>
      PasswordRules.hasMinimumLength(passwordController.text);

  bool get hasPasswordNumber =>
      PasswordRules.hasNumber(passwordController.text);

  void onPasswordChanged(String _) {
    _passwordFormError = null;
    _submissionError = null;
    notifyListeners();
  }

  void onPasswordConfirmationChanged(String _) {
    _passwordFormError = null;
    _submissionError = null;
    notifyListeners();
  }

  void onEmailChanged(String _) {
    _passwordFormError = null;
    _submissionError = null;
    _otpError = null;
    _isEmailVerified = false;
    notifyListeners();
  }

  void onOtpChanged(String _) {
    _otpError = null;
    notifyListeners();
  }

  Future<void> pickProfilePhoto() async {
    _isPickingProfilePhoto = true;
    _profilePhotoError = null;
    notifyListeners();

    try {
      final XFile? image = await _imagePickerService.pickFromGallery();

      if (image == null) return;

      if (await image.length() > maximumImageSize) {
        _profilePhotoError = 'The selected image must be smaller than 5MB.';
        return;
      }

      _profilePhoto = image;
      if (_submittedUser != null) {
        _profilePhotoChangedSinceSubmission = true;
      }
      _personalFormError = null;
    } catch (_) {
      _profilePhotoError = 'The image could not be selected. Please try again.';
    } finally {
      _isPickingProfilePhoto = false;
      notifyListeners();
    }
  }

  Future<void> pickLicensePhoto() async {
    _isPickingLicensePhoto = true;
    _licensePhotoError = null;
    notifyListeners();

    try {
      final XFile? image = await _imagePickerService.pickFromGallery();

      if (image == null) return;

      if (await image.length() > maximumImageSize) {
        _licensePhotoError = 'The selected image must be smaller than 5MB.';
        return;
      }

      _licensePhoto = image;
      if (_submittedUser != null) {
        _licensePhotoChangedSinceSubmission = true;
      }
      _vehicleFormError = null;
    } catch (_) {
      _licensePhotoError = 'The image could not be selected. Please try again.';
    } finally {
      _isPickingLicensePhoto = false;
      notifyListeners();
    }
  }

  void setDateOfBirth(DateTime value) {
    _dateOfBirth = value;
    dateOfBirthController.text =
        '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
    _personalFormError = null;
    notifyListeners();
  }

  void setAgreementAccepted(bool value) {
    _isAgreementAccepted = value;
    _submissionError = null;
    notifyListeners();
  }

  void selectPhoneCountry(Country country) {
    _phoneCountry = country;
    _personalFormError = null;
    notifyListeners();
  }

  bool validatePersonalInformation() {
    if (_profilePhoto == null ||
        fullNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        _dateOfBirth == null) {
      _personalFormError =
          'Add a profile photo and complete every personal information field.';
      notifyListeners();
      return false;
    }
    if (!isValidPhoneNumber(normalizedPhoneNumber)) {
      _personalFormError =
          'Enter a valid phone number for ${_phoneCountry.name} '
          '(+${_phoneCountry.phoneCode}).';
      notifyListeners();
      return false;
    }

    _personalFormError = null;
    notifyListeners();
    return true;
  }

  bool validateVehicleInformation() {
    if (_licensePhoto == null ||
        VehicleRules.validationMessage(
              model: vehicleModelController.text,
              year: vehicleYearController.text,
              vin: vinController.text,
            ) !=
            null ||
        licensePlateController.text.trim().isEmpty) {
      _vehicleFormError =
          'Add a license photo and enter a valid model, year, '
          '10- or 17-character VIN, and license plate.';
      notifyListeners();
      return false;
    }

    _vehicleFormError = null;
    notifyListeners();
    return true;
  }

  bool validateReview() {
    if (!_isAgreementAccepted) {
      _submissionError =
          'You must accept the Rules and Regulations before continuing.';
      notifyListeners();
      return false;
    }

    _submissionError = null;
    notifyListeners();
    return true;
  }

  bool validateAccountDetails() {
    final String email = emailController.text.trim();
    final String password = passwordController.text;
    final String confirmation = confirmPasswordController.text;

    if (!_isValidEmail(email)) {
      _passwordFormError = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }

    if (password.isEmpty || confirmation.isEmpty) {
      _passwordFormError = 'Enter and re-enter your password.';
      notifyListeners();
      return false;
    }

    if (!PasswordRules.isValid(password)) {
      _passwordFormError = 'Your password must meet every requirement.';
      notifyListeners();
      return false;
    }

    if (password != confirmation) {
      _passwordFormError = 'The passwords do not match.';
      notifyListeners();
      return false;
    }

    _passwordFormError = null;
    notifyListeners();
    return true;
  }

  Future<bool> submitApplication() async {
    if (_isSubmitting) return false;

    final bool personalInformationIsValid = validatePersonalInformation();
    final bool vehicleInformationIsValid = validateVehicleInformation();
    final bool accountDetailsAreValid = validateAccountDetails();

    if (!personalInformationIsValid ||
        !vehicleInformationIsValid ||
        !accountDetailsAreValid) {
      _submissionError =
          !personalInformationIsValid || !vehicleInformationIsValid
          ? 'Please return to the previous steps and complete every field.'
          : null;
      notifyListeners();
      return false;
    }

    if (!validateReview()) return false;

    _isSubmitting = true;
    _isEmailVerified = false;
    _otpError = null;
    _submissionError = null;
    notifyListeners();

    try {
      final XFile profilePhoto = _profilePhoto!;
      final XFile licensePhoto = _licensePhoto!;

      final RegistrationSubmission submission = RegistrationSubmission(
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: _normalizePhone(phoneController.text),
        city: cityController.text.trim(),
        password: passwordController.text,
        dateOfBirth: _dateOfBirth!,
        vehicleModel: vehicleModelController.text.trim(),
        vehicleYear: int.parse(vehicleYearController.text.trim()),
        vin: vinController.text.trim(),
        licensePlate: licensePlateController.text.trim(),
        profilePhotoName: profilePhoto.name,
        profilePhotoBytes: await profilePhoto.readAsBytes(),
        licensePhotoName: licensePhoto.name,
        licensePhotoBytes: await licensePhoto.readAsBytes(),
      );

      _submittedUser = await _registrationRepository.submitApplication(
        submission,
      );
      _isEditingSubmittedApplication = false;
      _profilePhotoChangedSinceSubmission = false;
      _licensePhotoChangedSinceSubmission = false;
      passwordController.clear();
      confirmPasswordController.clear();
      otpController.clear();
      return true;
    } catch (error) {
      _submissionError = readableError(
        error,
        fallback: 'The application could not be submitted. Please try again.',
      );
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void beginEditingSubmittedApplication() {
    if (!canEditSubmittedApplication) return;
    _isEditingSubmittedApplication = true;
    _submissionError = null;
    notifyListeners();
  }

  Future<bool> updateSubmittedApplication() async {
    if (_isSubmitting || !canEditSubmittedApplication) return false;

    final bool personalInformationIsValid = validatePersonalInformation();
    final bool vehicleInformationIsValid = validateVehicleInformation();
    if (!personalInformationIsValid || !vehicleInformationIsValid) {
      _submissionError =
          'Please return to the previous steps and complete every field.';
      notifyListeners();
      return false;
    }
    if (!validateReview()) return false;

    _isSubmitting = true;
    _submissionError = null;
    notifyListeners();
    try {
      final XFile profilePhoto = _profilePhoto!;
      final XFile licensePhoto = _licensePhoto!;
      final RegistrationSubmission submission = RegistrationSubmission(
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: _normalizePhone(phoneController.text),
        city: cityController.text.trim(),
        password: '',
        dateOfBirth: _dateOfBirth!,
        vehicleModel: vehicleModelController.text.trim(),
        vehicleYear: int.parse(vehicleYearController.text.trim()),
        vin: vinController.text.trim(),
        licensePlate: licensePlateController.text.trim(),
        profilePhotoName: profilePhoto.name,
        profilePhotoBytes: await profilePhoto.readAsBytes(),
        licensePhotoName: licensePhoto.name,
        licensePhotoBytes: await licensePhoto.readAsBytes(),
      );
      _submittedUser = await _registrationRepository.updateApplication(
        userId: _submittedUser!.id,
        submission: submission,
        includeProfilePhoto: _profilePhotoChangedSinceSubmission,
        includeLicensePhoto: _licensePhotoChangedSinceSubmission,
      );
      _isEditingSubmittedApplication = false;
      _profilePhotoChangedSinceSubmission = false;
      _licensePhotoChangedSinceSubmission = false;
      return true;
    } catch (error) {
      _submissionError = readableError(
        error,
        fallback: 'The application changes could not be saved.',
      );
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> verifyRegistrationOtp() async {
    if (_isVerifyingOtp || _isResendingOtp || _isEmailVerified) {
      return _isEmailVerified;
    }

    final String otp = otpController.text.trim();
    if (otp.isEmpty) {
      _otpError = 'Enter the verification code sent to your email.';
      notifyListeners();
      return false;
    }

    _isVerifyingOtp = true;
    _otpError = null;
    notifyListeners();

    try {
      await _registrationRepository.verifyEmailOtp(
        email: emailController.text.trim(),
        otp: otp,
      );
      _isEmailVerified = true;
      otpController.clear();
      return true;
    } catch (error) {
      _otpError = readableError(
        error,
        fallback: 'The verification code is incorrect or has expired.',
      );
      return false;
    } finally {
      _isVerifyingOtp = false;
      notifyListeners();
    }
  }

  Future<bool> resendRegistrationOtp() async {
    if (_isVerifyingOtp || _isResendingOtp) return false;

    _isResendingOtp = true;
    _isEmailVerified = false;
    _otpError = null;
    notifyListeners();

    try {
      await _registrationRepository.resendEmailOtp(
        email: emailController.text.trim(),
      );
      otpController.clear();
      return true;
    } catch (error) {
      _otpError = readableError(
        error,
        fallback: 'A new verification code could not be sent.',
      );
      return false;
    } finally {
      _isResendingOtp = false;
      notifyListeners();
    }
  }

  void cancelRegistrationOtp() {
    otpController.clear();
    _otpError = null;
    _isEmailVerified = false;
    notifyListeners();
  }

  /// Adds the selected country code to a local number ("0791234567" with
  /// Jordan → "+962791234567"). A number typed in international form
  /// ("+44…" or "0044…") is kept as it is.
  String _normalizePhone(String value) {
    String phone = value.replaceAll(RegExp(r'[\s().-]'), '');
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('00')) return '+${phone.substring(2)}';
    if (phone.startsWith('0')) phone = phone.substring(1);
    return '+${_phoneCountry.phoneCode}$phone';
  }

  /// International (E.164) form: "+", then 8 to 15 digits in total.
  static bool isValidPhoneNumber(String value) =>
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value);

  static bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  void reset() {
    fullNameController.clear();
    emailController.clear();
    phoneController.clear();
    cityController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    otpController.clear();
    dateOfBirthController.clear();
    vehicleYearController.clear();
    vinController.clear();
    licensePlateController.clear();
    vehicleModelController.clear();

    _profilePhoto = null;
    _licensePhoto = null;
    _dateOfBirth = null;
    _phoneCountry = Country.parse(defaultPhoneCountryCode);
    _profilePhotoError = null;
    _licensePhotoError = null;
    _personalFormError = null;
    _vehicleFormError = null;
    _passwordFormError = null;
    _isAgreementAccepted = false;
    _isSubmitting = false;
    _isVerifyingOtp = false;
    _isResendingOtp = false;
    _isEmailVerified = false;
    _submissionError = null;
    _otpError = null;
    _submittedUser = null;
    _isEditingSubmittedApplication = false;
    _profilePhotoChangedSinceSubmission = false;
    _licensePhotoChangedSinceSubmission = false;
    notifyListeners();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    dateOfBirthController.dispose();
    vehicleYearController.dispose();
    vinController.dispose();
    licensePlateController.dispose();
    vehicleModelController.dispose();
    super.dispose();
  }
}
