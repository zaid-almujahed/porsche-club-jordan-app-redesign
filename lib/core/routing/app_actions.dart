import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/dependencies/app_dependencies.dart';
import 'package:pcj_v5/core/routing/app_back_navigation.dart';
import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/widgets/app_feedback.dart';

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
  /// application session), then shows Welcome.
  Future<void> cancelRegistration(BuildContext context) async {
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

  /// A payment made the membership active. A renewal returns to Manage
  /// Membership; a first or expired payment goes wherever the refreshed
  /// status leads (normally Home).
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
      await _dependencies.authController.refreshSession();
      if (context.mounted) {
        context.goBack(fallback: AppRoutes.membershipSettings);
      }
      return;
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
