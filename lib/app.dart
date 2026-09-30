import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/dependencies/app_dependencies.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/domain/entities/user.dart';
import 'shared/widgets/account_deactivated_dialog.dart';
import 'shared/widgets/app_dialog.dart';
import 'shared/widgets/app_feedback.dart';
import 'shared/widgets/app_live_refresh.dart';

class PcjApp extends StatefulWidget {
  const PcjApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<PcjApp> createState() => _PcjAppState();
}

class _PcjAppState extends State<PcjApp> with WidgetsBindingObserver {
  // Membership status and notifications are re-read this often while the
  // app is open, so changes made on the backend show up almost at once.
  static const Duration _statusCheckInterval = AppLiveRefresh.interval;

  late final GoRouter _router;
  Timer? _statusTimer;

  /// The member this device is registered for pushes as.
  String? _pushUserId;

  /// A push was tapped before anyone was signed in (the app was closed).
  bool _openNotificationsWhenSignedIn = false;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(widget.dependencies);
    widget.dependencies.authController.addListener(_onAuthChanged);
    WidgetsBinding.instance.addObserver(this);
    widget.dependencies.pushNotifications
      ..onMessage = _onPushReceived
      ..onOpened = _onPushOpened;
    unawaited(widget.dependencies.pushNotifications.initialize());
    widget.dependencies.authController.restoreSession();
    _statusTimer = Timer.periodic(_statusCheckInterval, (_) => _checkStatus());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.dependencies.authController.removeListener(_onAuthChanged);
    _router.dispose();
    widget.dependencies.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _checkStatus();
    if (widget.dependencies.authController.currentUser != null) {
      unawaited(widget.dependencies.pushNotifications.retryRegistration());
    }
  }

  /// An expired membership sends the member to payment; a deactivated or
  /// deleted account ends the session. Only signed-in members are checked.
  void _checkStatus() {
    final AppLifecycleState? lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    final auth = widget.dependencies.authController;
    if (auth.currentUser?.applicationStatus != ApplicationStatus.approved) {
      return;
    }
    auth.checkMembershipStatus();
    // Keeps the bell's unread count current.
    widget.dependencies.notificationsController.load(force: true);
  }

  void _onAuthChanged() {
    final auth = widget.dependencies.authController;
    unawaited(_syncPushRegistration());
    if (auth.takeSessionEndedNotice()) {
      // Straight to Welcome, with the notice on top of it.
      _router.go(AppRoutes.welcome);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSessionEndedNotice();
      });
      return;
    }
    if (!auth.hasDeactivatedAccountNotice) return;
    final String email = auth.takeDeactivatedAccountNotice() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDeactivatedNotice(email);
    });
  }

  /// Registers this device for the signed-in member's pushes, and drops it
  /// when they sign out.
  Future<void> _syncPushRegistration() async {
    final String? userId = widget.dependencies.authController.currentUser?.id;
    if (userId == _pushUserId) return;
    final String? previous = _pushUserId;
    _pushUserId = userId;
    final push = widget.dependencies.pushNotifications;
    if (previous != null) await push.unregisterDevice();
    if (userId == null) return;
    if (_openNotificationsWhenSignedIn) {
      _openNotificationsWhenSignedIn = false;
      // The router sends members who may not see it elsewhere.
      _router.go(AppRoutes.notifications);
    }
    await push.registerDevice();
  }

  /// While the app is open: refresh the list and the bell. Android shows no
  /// banner for an open app, so a short message stands in for it (iOS shows
  /// its own).
  void _onPushReceived(RemoteMessage message) {
    if (widget.dependencies.authController.currentUser == null) return;
    widget.dependencies.notificationsController.load(force: true);
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final String title = message.notification?.title?.trim() ?? '';
    final BuildContext? navigatorContext =
        _router.routerDelegate.navigatorKey.currentContext;
    if (title.isEmpty || navigatorContext == null) return;
    showAppSnackBar(navigatorContext, title);
  }

  /// A tapped push opens Notifications, once someone is signed in.
  void _onPushOpened(RemoteMessage message) {
    if (widget.dependencies.authController.currentUser == null) {
      _openNotificationsWhenSignedIn = true;
      return;
    }
    widget.dependencies.notificationsController.load(force: true);
    _router.push(AppRoutes.notifications);
  }

  Future<void> _showDeactivatedNotice(String email) async {
    // Clear the token and any member data while the notice is up.
    unawaited(widget.dependencies.signOut());
    final BuildContext? navigatorContext =
        _router.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext != null && navigatorContext.mounted) {
      await showAccountDeactivatedDialog(
        context: navigatorContext,
        email: email,
      );
    }
    if (mounted) _router.go(AppRoutes.welcome);
  }

  Future<void> _showSessionEndedNotice() async {
    // Clear the token (if still stored) and any member data.
    unawaited(widget.dependencies.signOut());
    final BuildContext? navigatorContext =
        _router.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) return;
    await showAppMessageDialog(
      context: navigatorContext,
      title: 'Something Went Wrong',
      message:
          'We could not verify your account, so you have been signed out. '
          'If this keeps happening, please contact Porsche Club Jordan.',
      buttonLabel: 'OK',
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
