import 'package:flutter/material.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  AsyncState<User?> _session = const AsyncState<User?>.initial();
  String? _validationError;
  String? _otpError;
  String? _signInOtpEmail;
  User? _verifiedSignInUser;
  bool _isRequestingSignInOtp = false;
  bool _isVerifyingSignInOtp = false;
  bool _isResendingSignInOtp = false;
  // A startup restore may still be running when a member begins a new login.
  // Only the newest session operation is allowed to publish router state.
  int _sessionGeneration = 0;
  bool _isSigningOut = false;
  // Email of a SUSPENDED / DEACTIVATED member who was just turned away. The
  // app shell shows the "account deactivated" notice once, then clears it.
  String? _deactivatedAccountEmail;
  // Set when a signed-in member's account is deleted or deactivated while
  // the app is in use; the app shell shows "Something went wrong" once.
  bool _sessionEndedNotice = false;
  // Set when the backend rejected the token; Sign In says why once.
  bool _sessionExpiredNotice = false;
  // Set when the status check finds the membership made active by the club
  // (no payment in the app): true for a renewal.
  bool? _membershipActivatedNotice;
  bool _isCheckingStatus = false;
  // An applicant waiting for approval, in memory only: the application
  // status page asks again with it, since POST /auth/login answers 400 until
  // the application is approved.
  ({String email, String password})? _applicantLogin;

  AsyncState<User?> get session => _session;
  User? get currentUser => _session.data;
  String? get validationError => _validationError;
  String? get otpError => _otpError;
  String? get signInOtpEmail => _signInOtpEmail;
  User? get pendingSignInUser => _verifiedSignInUser;
  bool get isRequestingSignInOtp => _isRequestingSignInOtp;
  bool get isVerifyingSignInOtp => _isVerifyingSignInOtp;
  bool get isResendingSignInOtp => _isResendingSignInOtp;
  bool get hasDeactivatedAccountNotice => _deactivatedAccountEmail != null;

  /// Returns (and clears) whether the session just ended because the
  /// account was deleted or deactivated while in use.
  bool takeSessionEndedNotice() {
    final bool notice = _sessionEndedNotice;
    _sessionEndedNotice = false;
    return notice;
  }

  /// Whether the application status page can ask again for a decision.
  bool get canRecheckApplication => _applicantLogin != null;

  /// Keeps the login of an applicant who just submitted, for
  /// [recheckApplication].
  void rememberApplicantLogin({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || password.isEmpty) return;
    _applicantLogin = (email: email.trim(), password: password);
  }

  /// Asks again whether the waiting application was decided. Approval shows
  /// as the sign in going through: the code email is sent, and the applicant
  /// enters it as when signing in. Null when there is no answer (offline).
  Future<ApplicationStatus?> recheckApplication() async {
    final ({String email, String password})? login = _applicantLogin;
    if (login == null || _isRequestingSignInOtp || _isVerifyingSignInOtp) {
      return null;
    }
    try {
      await _repository.requestSignInOtp(
        email: login.email,
        password: login.password,
      );
      _applicantLogin = null;
      _signInOtpEmail = login.email;
      _otpError = null;
      otpController.clear();
      return ApplicationStatus.approved;
    } catch (error) {
      final User? applicant = _applicationUserFromError(
        error,
        email: login.email,
      );
      if (applicant?.applicationStatus == ApplicationStatus.denied) {
        _applicantLogin = null;
      }
      return applicant?.applicationStatus;
    }
  }

  /// Returns (and clears) whether the session just expired (the backend
  /// rejected the token).
  bool takeSessionExpiredNotice() {
    final bool notice = _sessionExpiredNotice;
    _sessionExpiredNotice = false;
    return notice;
  }

  /// Returns (and clears) whether the status check just found the
  /// membership made active by the club: true for a renewal, false for a
  /// first activation, null when nothing changed.
  bool? takeMembershipActivatedNotice() {
    final bool? notice = _membershipActivatedNotice;
    _membershipActivatedNotice = null;
    return notice;
  }

  /// Returns (and clears) the email of a member who was just signed out
  /// because their account is suspended or deactivated.
  String? takeDeactivatedAccountNotice() {
    final String? email = _deactivatedAccountEmail;
    _deactivatedAccountEmail = null;
    return email;
  }

  Future<void> restoreSession() async {
    final int generation = ++_sessionGeneration;
    final User? previousUser = currentUser;
    _session = AsyncState<User?>.loading(previousData: previousUser);
    notifyListeners();

    try {
      final User? restoredUser = await _repository.restoreSession();
      if (generation != _sessionGeneration) return;
      if (restoredUser != null && _isDeactivated(restoredUser)) {
        _turnAwayDeactivated(restoredUser);
        return;
      }
      _session = AsyncState<User?>.success(restoredUser);
    } catch (error, stackTrace) {
      if (generation != _sessionGeneration) return;
      // A rejected (or pending) application answers 400; show its page.
      final User? applicationUser = _applicationUserFromError(
        error,
        email: previousUser?.email ?? '',
      );
      // A network failure must not sign out a member who was already in.
      _session = applicationUser != null
          ? AsyncState<User?>.success(applicationUser)
          : AsyncState<User?>.failure(
              error,
              stackTrace,
              previousData: previousUser,
            );
    }
    notifyListeners();
  }

  /// Re-reads the member and membership status without a loading state
  /// (e.g. when the app returns to the foreground), so an expired or
  /// suspended membership is picked up by the router straight away.
  Future<void> refreshSession() async {
    if (currentUser == null || _session.isLoading || _isSigningOut) return;
    final int generation = ++_sessionGeneration;
    try {
      final User? user = await _repository.restoreSession();
      if (generation != _sessionGeneration) return;
      if (user != null && _isDeactivated(user)) {
        _turnAwayDeactivated(user);
        return;
      }
      _session = AsyncState<User?>.success(user);
      notifyListeners();
    } catch (error) {
      if (generation != _sessionGeneration) return;
      final User? applicationUser = _applicationUserFromError(
        error,
        email: currentUser?.email ?? '',
      );
      if (applicationUser == null) return;
      _session = AsyncState<User?>.success(applicationUser);
      notifyListeners();
      // Otherwise keep the current session on network errors; the next
      // resume retries.
    }
  }

  /// Re-checks a signed-in member's status with `GET /member/membership`
  /// (the app does this every few seconds). An expired membership is picked
  /// up by the router, which opens the renewal page, and one the club makes
  /// active again leads back to Home; a deactivated or deleted account ends
  /// the session with a notice.
  ///
  /// Only members who signed in are checked: applicants shown a status page
  /// after a 400 at sign in have no login to check with.
  Future<void> checkMembershipStatus() async {
    final User? current = currentUser;
    if (current == null ||
        current.applicationStatus != ApplicationStatus.approved ||
        _session.isLoading ||
        _isSigningOut ||
        _isCheckingStatus) {
      return;
    }
    final int generation = _sessionGeneration;
    _isCheckingStatus = true;
    try {
      final User? checked = await _repository.checkMembershipStatus(current);
      final User? latest = currentUser;
      if (generation != _sessionGeneration ||
          checked == null ||
          latest == null) {
        return;
      }
      if (_isDeactivated(checked)) {
        endSessionUnexpectedly();
        return;
      }
      if (checked.applicationStatus == latest.applicationStatus &&
          checked.membershipStatus == latest.membershipStatus &&
          checked.membershipValidUntil == latest.membershipValidUntil) {
        // Unchanged: no notification, so the router does not rebuild pages.
        return;
      }
      if (latest.membershipStatus != MembershipStatus.active &&
          checked.membershipStatus == MembershipStatus.active) {
        _membershipActivatedNotice =
            latest.membershipStatus == MembershipStatus.expired;
      }
      _session = AsyncState<User?>.success(
        latest.copyWith(
          applicationStatus: checked.applicationStatus,
          membershipStatus: checked.membershipStatus,
          membershipValidUntil: checked.membershipValidUntil,
        ),
      );
      notifyListeners();
    } catch (error) {
      if (generation != _sessionGeneration) return;
      // The membership itself is refused or gone: the account was
      // deactivated or deleted. Network errors keep the session; the next
      // check tries again.
      if (error is AppException &&
          <int?>[403, 404, 410].contains(error.statusCode)) {
        endSessionUnexpectedly();
      }
    } finally {
      _isCheckingStatus = false;
    }
  }

  /// Ends a live session because the account is no longer available
  /// (deleted or deactivated while in use). Returns false when there was no
  /// live session to end.
  bool endSessionUnexpectedly() {
    if (currentUser == null || _session.isLoading || _isSigningOut) {
      return false;
    }
    _sessionGeneration++;
    _session = const AsyncState<User?>.success(null);
    _sessionEndedNotice = true;
    notifyListeners();
    return true;
  }

  /// Ends the session after the backend rejected the token (it expires after
  /// one month). Returns false when there was no live session to end.
  bool expireSession() {
    if (currentUser == null || _session.isLoading || _isSigningOut) {
      return false;
    }
    _sessionGeneration++;
    _session = AsyncState<User?>.failure(
      const AuthenticationException(
        'Your session has expired. Please sign in again.',
      ),
      StackTrace.current,
    );
    _sessionExpiredNotice = true;
    notifyListeners();
    return true;
  }

  static bool _isDeactivated(User user) =>
      user.membershipStatus == MembershipStatus.suspended;

  void _turnAwayDeactivated(User user) {
    _session = const AsyncState<User?>.success(null);
    _deactivatedAccountEmail = user.email;
    notifyListeners();
  }

  Future<bool> requestSignInOtp() async {
    if (_isRequestingSignInOtp ||
        _isVerifyingSignInOtp ||
        _isResendingSignInOtp) {
      return false;
    }

    final String identifier = identifierController.text.trim();
    final String password = passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _validationError = 'Enter your email address and password.';
      notifyListeners();
      return false;
    }

    _validationError = null;
    _otpError = null;
    // This login attempt supersedes any startup restore still in flight.
    _sessionGeneration++;
    _session = AsyncState<User?>.success(currentUser);
    _isRequestingSignInOtp = true;
    notifyListeners();

    try {
      await _repository.requestSignInOtp(
        email: identifier,
        password: password,
      );
      _signInOtpEmail = identifier;
      otpController.clear();
      return true;
    } catch (error, stackTrace) {
      final User? applicationUser = _applicationUserFromError(
        error,
        email: identifier,
      );
      if (applicationUser != null) {
        _session = AsyncState<User?>.success(applicationUser);
        if (applicationUser.applicationStatus == ApplicationStatus.pending) {
          rememberApplicantLogin(email: identifier, password: password);
        }
        passwordController.clear();
        return false;
      }
      _session = AsyncState<User?>.failure(
        error,
        stackTrace,
        previousData: currentUser,
      );
      return false;
    } finally {
      _isRequestingSignInOtp = false;
      notifyListeners();
    }
  }

  Future<bool> verifySignInOtp() async {
    if (_isVerifyingSignInOtp || _isResendingSignInOtp) return false;

    final String? email = _signInOtpEmail;
    final String otp = otpController.text.trim();
    if (email == null || email.isEmpty) {
      _otpError = 'Return to sign in and enter your email address again.';
      notifyListeners();
      return false;
    }
    if (otp.isEmpty) {
      _otpError = 'Enter the verification code sent to your email.';
      notifyListeners();
      return false;
    }

    _isVerifyingSignInOtp = true;
    _otpError = null;
    notifyListeners();

    try {
      final User user = await _repository.verifySignInOtp(
        email: email,
        otp: otp,
      );
      // Do not publish the authenticated session while the OTP route is still
      // on the root navigator. Publishing here lets go_router remove the sign
      // in route before the dialog closes, which can pop the last page and
      // leave a black screen. SignInPage calls completeSignIn() only after the
      // dialog has returned.
      _verifiedSignInUser = user;
      passwordController.clear();
      otpController.clear();
      return true;
    } catch (error, stackTrace) {
      // The application can also be refused at this step ("Membership
      // application was rejected."): route to its status page after the
      // dialog closes, like a successful sign in.
      final User? applicationUser = _applicationUserFromError(
        error,
        email: email,
      );
      if (applicationUser != null) {
        _verifiedSignInUser = applicationUser;
        passwordController.clear();
        otpController.clear();
        return true;
      }
      _otpError = readableError(
        error,
        fallback: 'The verification code is incorrect or has expired.',
      );
      _session = AsyncState<User?>.failure(
        error,
        stackTrace,
        previousData: currentUser,
      );
      return false;
    } finally {
      _isVerifyingSignInOtp = false;
      notifyListeners();
    }
  }

  User? completeSignIn() {
    final User? user = _verifiedSignInUser;
    if (user == null) return null;
    _sessionGeneration++;
    _verifiedSignInUser = null;
    _signInOtpEmail = null;
    if (_isDeactivated(user)) {
      _turnAwayDeactivated(user);
      return null;
    }
    _session = AsyncState<User?>.success(user);
    notifyListeners();
    return user;
  }

  Future<bool> resendSignInOtp() async {
    if (_isVerifyingSignInOtp || _isResendingSignInOtp) return false;

    final String? email = _signInOtpEmail;
    if (email == null || email.isEmpty) {
      _otpError = 'Return to sign in and enter your email address again.';
      notifyListeners();
      return false;
    }

    _isResendingSignInOtp = true;
    _otpError = null;
    notifyListeners();

    try {
      await _repository.resendSignInOtp(email: email);
      otpController.clear();
      return true;
    } catch (error) {
      _otpError = readableError(
        error,
        fallback: 'A new verification code could not be sent.',
      );
      return false;
    } finally {
      _isResendingSignInOtp = false;
      notifyListeners();
    }
  }

  void onOtpChanged(String _) {
    _otpError = null;
    notifyListeners();
  }

  void cancelSignInOtp() {
    otpController.clear();
    _otpError = null;
    _signInOtpEmail = null;
    _verifiedSignInUser = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    _sessionGeneration++;
    _isSigningOut = true;
    try {
      await _repository.signOut();
    } catch (_) {
      // The local session is still cleared if the revoke request cannot reach
      // the server. The API client should also delete its locally stored token.
    } finally {
      // A failed revoke request must not keep a local authenticated session.
      _session = const AsyncState<User?>.success(null);
      identifierController.clear();
      passwordController.clear();
      otpController.clear();
      _signInOtpEmail = null;
      _verifiedSignInUser = null;
      _applicantLogin = null;
      _otpError = null;
      _isSigningOut = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.dispose();
  }

  /// The backend refuses members who cannot sign in yet with a 400:
  /// `{"detail": "Waiting for admin approval."}` (PENDING) or
  /// `{"detail": "Membership application was rejected."}` (REJECTED).
  /// Either becomes a session the router sends to the application status
  /// page (Under Review / Application Rejected).
  User? _applicationUserFromError(Object error, {required String email}) {
    if (error is! AppException || error.statusCode != 400) return null;
    final String message = error.message.toLowerCase().trim();
    final bool isPending =
        message == 'waiting for admin approval.' ||
        message == 'waiting for admin approval' ||
        message.contains('pending approval');
    final bool isDenied =
        message == 'membership application was rejected.' ||
        message.contains('rejected') ||
        message.contains('denied');
    if (!isPending && !isDenied) return null;
    return User(
      id: email,
      name: '',
      email: email,
      phoneNumber: '',
      applicationStatus:
          isDenied ? ApplicationStatus.denied : ApplicationStatus.pending,
      membershipStatus: MembershipStatus.inactive,
    );
  }
}
