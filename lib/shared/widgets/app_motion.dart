import 'package:flutter/material.dart';

import 'package:pcj_v4/core/theme/app_theme.dart';

/// Fades its child in while lifting it a few pixels into place. Runs once.
///
/// Use [AppFadeSlideIn.stagger] for list items; items past [maxStaggered]
/// appear immediately so long lists never feel slow.
class AppFadeSlideIn extends StatefulWidget {
  const AppFadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.offset = 12,
  });

  factory AppFadeSlideIn.stagger({
    Key? key,
    required int index,
    required Widget child,
    Duration step = const Duration(milliseconds: 55),
    Duration initialDelay = Duration.zero,
    double offset = 12,
  }) {
    if (index >= maxStaggered) {
      return AppFadeSlideIn(key: key, duration: Duration.zero, child: child);
    }
    return AppFadeSlideIn(
      key: key,
      delay: initialDelay + step * index,
      offset: offset,
      child: child,
    );
  }

  static const int maxStaggered = 8;

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<AppFadeSlideIn> createState() => _AppFadeSlideInState();
}

class _AppFadeSlideInState extends State<AppFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.curve,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion || widget.duration == Duration.zero) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double value = _curve.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Shrinks its child slightly while a pointer is down. It never consumes
/// gestures, so it can wrap cards that already contain an [InkWell].
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Grows its child from slightly smaller to full size once (dialogs, badges).
class AppScaleIn extends StatelessWidget {
  const AppScaleIn({
    super.key,
    required this.child,
    this.begin = 0.94,
    this.duration = AppMotion.medium,
    this.curve = AppMotion.curve,
  });

  final Widget child;
  final double begin;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduceMotion ? 1 : begin, end: 1),
      duration: reduceMotion ? Duration.zero : duration,
      curve: curve,
      child: child,
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.scale(scale: value, child: child);
      },
    );
  }
}

/// A small branded progress indicator with a faint red halo.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.size = 30, this.label});

  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x33D5001C),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SizedBox.square(
            dimension: size,
            child: const CircularProgressIndicator(
              color: AppColors.primaryBright,
              strokeWidth: 2.4,
              strokeCap: StrokeCap.round,
            ),
          ),
        ),
        if (label != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(label!, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}
