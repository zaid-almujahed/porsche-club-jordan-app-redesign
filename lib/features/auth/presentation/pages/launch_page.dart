import 'package:flutter/material.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/auth_controller.dart';
import '../widgets/auth_backdrop.dart';

/// Shown only while a stored session is being checked at start-up, so a
/// signed-in member goes straight to Home without seeing Welcome first.
/// If the check fails for a network reason, it offers a retry instead of
/// signing the member out.
class LaunchPage extends StatelessWidget {
  const LaunchPage({super.key, required this.controller});

  final AuthController controller;

  // Same size as the native splash logo (Android launch_logo, iOS
  // LaunchImage: 262x49), centred on the full screen like it, so the
  // hand-over from the OS splash has no jump.
  static const Size _logoSize = Size(262, 49);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBar,
      body: AuthBackdrop(
        glowCenter: const Alignment(0, -0.2),
        child: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            final bool failed = controller.session.hasError;
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                // Status (spinner or retry) always starts below the logo.
                final double statusTop =
                    constraints.maxHeight / 2 +
                    _logoSize.height / 2 +
                    AppSpacing.xxl;
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Center(
                      child: SizedBox.fromSize(
                        size: _logoSize,
                        child: AuthLogo(maxHeight: _logoSize.height),
                      ),
                    ),
                    Positioned(
                      top: statusTop,
                      left: AppSpacing.xl,
                      right: AppSpacing.xl,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: AnimatedSwitcher(
                            duration: AppMotion.medium,
                            layoutBuilder: AppMotion.switcherLayout,
                            child: failed
                                ? _LaunchError(
                                    key: const ValueKey<String>('launch-error'),
                                    message: readableError(
                                      controller.session.error!,
                                      fallback:
                                          'We couldn’t check your session.',
                                    ),
                                    onRetry: controller.restoreSession,
                                  )
                                : const SizedBox.square(
                                    key: ValueKey<String>('launch-loading'),
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      strokeCap: StrokeCap.round,
                                      color: AppColors.primaryBright,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LaunchError extends StatelessWidget {
  const _LaunchError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppInlineMessage.error(message, title: 'Connection problem'),
        const SizedBox(height: AppSpacing.lg),
        PrimaryActionButton(label: 'Try Again', height: 54, onPressed: onRetry),
      ],
    );
  }
}
