import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_motion.dart';

enum AppFeedbackType { error, warning, success, info }

extension AppFeedbackTypeStyle on AppFeedbackType {
  Color get color => switch (this) {
    AppFeedbackType.error => AppColors.danger,
    AppFeedbackType.warning => AppColors.warning,
    AppFeedbackType.success => AppColors.success,
    AppFeedbackType.info => AppColors.accentSteel,
  };

  IconData get icon => switch (this) {
    AppFeedbackType.error => Icons.error_outline_rounded,
    AppFeedbackType.warning => Icons.warning_amber_rounded,
    AppFeedbackType.success => Icons.check_circle_outline_rounded,
    AppFeedbackType.info => Icons.info_outline_rounded,
  };
}

/// A calm, tinted message card used in place of raw red error text.
///
/// Slides in when it first appears and is announced to screen readers.
class AppInlineMessage extends StatelessWidget {
  const AppInlineMessage({
    super.key,
    required this.message,
    this.type = AppFeedbackType.error,
    this.title,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.onDismiss,
    this.textAlign = TextAlign.start,
    this.animate = true,
  });

  const AppInlineMessage.error(
    this.message, {
    super.key,
    this.title,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.onDismiss,
    this.textAlign = TextAlign.start,
    this.animate = true,
  }) : type = AppFeedbackType.error;

  final String message;
  final AppFeedbackType type;
  final String? title;
  final VoidCallback? onRetry;
  final String retryLabel;
  final VoidCallback? onDismiss;
  final TextAlign textAlign;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final Color color = type.color;

    final Widget card = Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          onDismiss == null ? AppSpacing.md : AppSpacing.xxs,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: 0.09),
            AppColors.panelDark,
          ),
          borderRadius: BorderRadius.circular(AppRadii.medium),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: AppDecorations.iconBadge(color, circle: true),
              child: Icon(type.icon, color: color, size: 17),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (title != null) ...<Widget>[
                      Text(
                        title!,
                        textAlign: textAlign,
                        style: AppTextStyles.title.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        message,
                        textAlign: textAlign,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (onRetry != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      InkWell(
                        onTap: onRetry,
                        borderRadius: BorderRadius.circular(AppRadii.small),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.refresh_rounded,
                                color: color,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                retryLabel,
                                style: AppTextStyles.label.copyWith(
                                  color: color,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );

    if (!animate) return card;
    return AppFadeSlideIn(
      key: ValueKey<String>('inline-message-$message'),
      duration: AppMotion.medium,
      offset: 6,
      child: card,
    );
  }
}

/// Full-section failure state: icon badge, heading, readable reason, retry.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon,
  });

  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final IconData? icon;

  bool get _looksLikeConnectionIssue {
    final String value = message.toLowerCase();
    return value.contains('internet') ||
        value.contains('connection') ||
        value.contains('network') ||
        value.contains('offline') ||
        value.contains('timed out') ||
        value.contains('timeout') ||
        value.contains('server');
  }

  @override
  Widget build(BuildContext context) {
    final bool isConnection = _looksLikeConnectionIssue;
    final IconData resolvedIcon =
        icon ??
        (isConnection ? Icons.cloud_off_rounded : Icons.error_outline_rounded);
    final String resolvedTitle =
        title ?? (isConnection ? 'Connection problem' : 'Something went wrong');

    return AppFadeSlideIn(
      duration: AppMotion.medium,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.section,
          horizontal: AppSpacing.md,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        AppColors.danger.withValues(alpha: 0.20),
                        AppColors.danger.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(resolvedIcon, color: AppColors.danger, size: 30),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  resolvedTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(fontSize: 19),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                if (onRetry != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: onRetry,
                      style: AppButtonStyles.outline(),
                      icon: const Icon(Icons.refresh_rounded, size: 19),
                      label: const Text('Try again'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Neutral "nothing here yet" state.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.title,
  });

  final String message;
  final IconData icon;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return AppFadeSlideIn(
      duration: AppMotion.medium,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxl,
          horizontal: AppSpacing.md,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Icon(icon, color: AppColors.textFaint, size: 26),
              ),
              const SizedBox(height: AppSpacing.md),
              if (title != null) ...<Widget>[
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: AppSpacing.xxs),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating snackbar with a typed icon; replaces bare `SnackBar(Text(...))`.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackBar(
  BuildContext context,
  String message, {
  AppFeedbackType type = AppFeedbackType.info,
  Duration duration = const Duration(seconds: 4),
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  final Color color = type.color;
  return messenger.showSnackBar(
    SnackBar(
      duration: duration,
      backgroundColor: Color.alphaBlend(
        color.withValues(alpha: 0.08),
        AppColors.surfaceRaised,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
      ),
      content: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: AppDecorations.iconBadge(color, circle: true),
            child: Icon(type.icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Brief, non-blocking confirmation ("Added to Cart", "Claimed"): a green
/// check and a short label that rise in, hold for a moment and fade away on
/// their own. It never takes focus or blocks taps.
void showAppSuccessPulse(
  BuildContext context, {
  required String label,
  String? message,
}) {
  final OverlayState? overlay =
      Overlay.maybeOf(context, rootOverlay: true) ??
      Navigator.maybeOf(context)?.overlay;
  if (overlay == null) return;
  HapticFeedback.lightImpact();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (BuildContext context) => _SuccessPulse(
      label: label,
      message: message,
      onDone: () {
        if (entry.mounted) entry.remove();
      },
    ),
  );
  overlay.insert(entry);
}

class _SuccessPulse extends StatefulWidget {
  const _SuccessPulse({
    required this.label,
    required this.onDone,
    this.message,
  });

  final String label;
  final String? message;
  final VoidCallback onDone;

  @override
  State<_SuccessPulse> createState() => _SuccessPulseState();
}

class _SuccessPulseState extends State<_SuccessPulse>
    with SingleTickerProviderStateMixin {
  // Long enough to read; a second line needs a little more time.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.message == null ? 1400 : 3200),
  );

  // In over the first ~15%, hold, then out over the last ~25%.
  late final Animation<double> _opacity =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 0,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 15,
        ),
        TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 60),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1,
            end: 0,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 25,
        ),
      ]).animate(_controller);

  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 0.22, curve: Curves.easeOutCubic),
        ),
      );

  late final Animation<double> _check = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.08, 0.38, curve: Curves.easeOutBack),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            // Clears the floating navigation bar and bottom action bars.
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 112),
            child: FadeTransition(
              opacity: _opacity,
              child: SlideTransition(
                position: _slide,
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 10, 18, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xF2141417),
                      borderRadius: BorderRadius.circular(
                        widget.message == null ? AppRadii.pill : AppRadii.large,
                      ),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.35),
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ScaleTransition(
                          scale: _check,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.label,
                                style: AppTextStyles.title.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              if (widget.message != null) ...<Widget>[
                                const SizedBox(height: 2),
                                Text(
                                  widget.message!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
