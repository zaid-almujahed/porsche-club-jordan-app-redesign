import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';

extension AppBackNavigation on BuildContext {
  /// Pops when there is history. Otherwise — for pages opened with
  /// `context.go`, e.g. after placing an order — goes to the page's logical
  /// parent instead of doing nothing or closing the app.
  ///
  /// Never push a shell location (/home, /profile, ...) to "go back": the
  /// shell is usually already in the stack and a second copy crashes the
  /// navigator with duplicate page keys.
  void goBack({String? fallback}) {
    final GoRouter router = GoRouter.of(this);
    if (router.canPop()) {
      router.pop();
      return;
    }
    router.go(fallback ?? AppRoutes.parentOf(router.state.uri.path));
  }
}

/// Makes Android's system back follow the same rule as the on-screen back
/// button: when the page has nothing underneath it, back goes to its parent
/// page instead of closing the app.
class AppBackScope extends StatelessWidget {
  const AppBackScope({
    super.key,
    required this.child,
    this.onBack,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onBack;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final GoRouter? router = GoRouter.maybeOf(context);
    if (!enabled || router == null) return child;

    return PopScope<Object?>(
      canPop: router.canPop(),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        final VoidCallback? handler = onBack;
        if (handler != null) {
          handler();
        } else {
          context.goBack();
        }
      },
      child: child,
    );
  }
}
