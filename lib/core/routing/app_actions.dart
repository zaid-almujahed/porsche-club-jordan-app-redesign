import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/dependencies/app_dependencies.dart';
import 'package:pcj_v5/core/routing/app_back_navigation.dart';
import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pcj_v5/features/registration/presentation/controllers/registration_controller.dart';
import 'package:pcj_v5/features/registration/presentation/widgets/application_status_page_widgets.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/widgets/app_feedback.dart';
import 'package:pcj_v5/shared/widgets/otp_verification_dialog.dart';

/// What happens after the app's key actions: which data is reloaded and
/// where the member goes next. Pages only report what happened (e.g.
/// `onOrderPlaced`); the router connects those callbacks to these methods.
class AppActions {
  AppActions(this._dependencies, {required this.rootNavigatorKey});

  final AppDependencies _dependencies;

  /// Route builders sit above the root Navigator, so messages shown from
  /// here are attached to it.
  final GlobalKey<NavigatorState> rootNavigatorKey;

  BuildContext _overlayContext(BuildContext fallback) =>
      rootNavigatorKey.currentContext ?? fallback;

  /// Log Out, account deletion, and leaving an unpaid membership: clears the
  /// login and every member's data, then shows Welcome.
  Future<void> signOutToWelcome(BuildContext context) async {
    try {
      await _dependencies.signOut();
    } finally {
      if (context.mounted) context.go(AppRoutes.welcome);
    }
  }

  /// The applicant closed registration: forgets the form (and signs out an
  /// application session), then shows Welcome. Closing an edit of a
  /// submitted application only drops the edit and returns to its status.
  Future<void> cancelRegistration(BuildContext context) async {
    final RegistrationController registration =
        _dependencies.registrationController;
    if (registration.isEditingSubmittedApplication) {
      registration.cancelEditingSubmittedApplication();
      context.go(
        AppRoutes.applicationStatus,
        extra: registration.submittedUser,
      );
      return;
    }
    try {
      _dependencies.registrationController.reset();
      if (_dependencies.authController.currentUser != null) {
        await _dependencies.signOut();
      }
    } finally {
      _dependencies.registrationController.reset();
      if (context.mounted) context.go(AppRoutes.welcome);
    }
  }

  /// The application was approved while its status page was open (the
  /// re-check signed in and the code was emailed): explains the next steps,
  /// then signs the member in with the code; the router goes on to the
  /// membership payment.
  Future<void> continueApprovedApplication(BuildContext context) async {
    final AuthController auth = _dependencies.authController;
    final String? email = auth.signInOtpEmail;
    if (email == null) return;
    final BuildContext overlay = _overlayContext(context);
    if (!await showApplicationApprovedDialog(context: overlay, email: email) ||
        !overlay.mounted) {
      return;
    }
    final bool signedIn = await showOtpVerificationDialog(
      context: overlay,
      animation: auth,
      email: email,
      otpController: auth.otpController,
      onOtpChanged: auth.onOtpChanged,
      onVerify: auth.verifySignInOtp,
      onResend: auth.resendSignInOtp,
      isVerifying: () => auth.isVerifyingSignInOtp,
      isResending: () => auth.isResendingSignInOtp,
      errorText: () => auth.otpError,
      instructions: 'Enter it below to sign in.',
      verifyButtonLabel: 'Verify and Sign In',
    );
    if (signedIn) auth.completeSignIn();
  }

  /// A payment made the membership active: the first one, or renewing an
  /// expired membership. The refreshed status leads on, normally to Home.
  Future<void> afterMembershipPaid(
    BuildContext context, {
    required bool isRenewal,
  }) async {
    _dependencies.membershipController.load(force: true);
    _dependencies.profileController.load(force: true);
    if (isRenewal) {
      showAppSuccessPulse(
        _overlayContext(context),
        label: 'Membership Renewed',
      );
    }
    try {
      await _dependencies.authController.restoreSession();
    } finally {
      if (context.mounted) {
        final User? user = _dependencies.authController.currentUser;
        context.go(
          user == null ? AppRoutes.signIn : AppRoutes.destinationForUser(user),
          extra: user,
        );
      }
    }
  }

  /// An accepted gift / referral code always continues to Home.
  Future<void> afterMembershipCodeApplied(
    BuildContext context, {
    required bool isRenewal,
  }) async {
    _dependencies.membershipController.load(force: true);
    _dependencies.profileController.load(force: true);
    showAppSuccessPulse(
      _overlayContext(context),
      label: isRenewal ? 'Membership Renewed' : 'Membership Activated',
    );
    await _dependencies.authController.refreshSession();
    if (context.mounted) context.go(AppRoutes.home);
  }

  /// Refreshes My Orders and Home's tracking card, then returns to where the
  /// member came from (the cart is now empty); no jump to My Orders.
  void afterOrderPlaced(BuildContext context) {
    _dependencies.userOrdersController.load(force: true);
    _dependencies.homeController.load(force: true);
    context.goBack(fallback: AppRoutes.shop);
  }

  /// Refreshes everything that shows the member's RSVPs, then returns to
  /// the event's page.
  void afterEventRegistration(BuildContext context, String eventId) {
    afterRsvpCancelled();
    context.goBack(fallback: AppRoutes.eventDetailsLocation(eventId));
  }

  /// Refreshes My Events and the events' "Registered" tags.
  void afterRsvpCancelled() {
    _dependencies.userEventsController.load(force: true);
    _dependencies.eventsController.load(force: true);
    _dependencies.homeController.load(force: true);
  }
}
