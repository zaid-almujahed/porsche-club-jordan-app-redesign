import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/dependencies/app_dependencies.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/account_deactivated_dialog.dart';

class PcjApp extends StatefulWidget {
  const PcjApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<PcjApp> createState() => _PcjAppState();
}

class _PcjAppState extends State<PcjApp> with WidgetsBindingObserver {
  // Re-checking membership on every resume would be wasteful; a few minutes
  // is enough to pick up an expiry or suspension promptly.
  static const Duration _statusCheckInterval = Duration(minutes: 5);

  late final GoRouter _router;
  DateTime _lastStatusCheck = DateTime.now();

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(widget.dependencies);
    widget.dependencies.authController.addListener(_onAuthChanged);
    WidgetsBinding.instance.addObserver(this);
    widget.dependencies.authController.restoreSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.dependencies.authController.removeListener(_onAuthChanged);
    _router.dispose();
    widget.dependencies.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final DateTime now = DateTime.now();
    if (now.difference(_lastStatusCheck) < _statusCheckInterval) return;
    _lastStatusCheck = now;
    // An expired membership sends the member to payment; a suspended one
    // signs them out with a notice.
    widget.dependencies.authController.refreshSession();
  }

  void _onAuthChanged() {
    final auth = widget.dependencies.authController;
    if (!auth.hasDeactivatedAccountNotice) return;
    final String email = auth.takeDeactivatedAccountNotice() ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDeactivatedNotice(email);
    });
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
