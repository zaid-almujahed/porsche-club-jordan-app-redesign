import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_badges.dart';

/// An option that is not offered yet. [builder] gets the option's `onTap`,
/// which shakes it and says "Coming Soon" for two seconds (`showTag` is true
/// meanwhile); the option is never selected.
class ComingSoonBuilder extends StatefulWidget {
  const ComingSoonBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, VoidCallback onTap, bool showTag)
  builder;

  @override
  State<ComingSoonBuilder> createState() => _ComingSoonBuilderState();
}

class _ComingSoonBuilderState extends State<ComingSoonBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  Timer? _hideTag;
  bool _showTag = false;

  void _tap() {
    HapticFeedback.selectionClick();
    _shake.forward(from: 0);
    _hideTag?.cancel();
    setState(() => _showTag = true);
    _hideTag = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showTag = false);
    });
  }

  @override
  void dispose() {
    _hideTag?.cancel();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      hint: 'Coming soon',
      child: AnimatedBuilder(
        animation: _shake,
        builder: (BuildContext context, Widget? child) {
          final double t = _shake.value;
          return Transform.translate(
            offset: Offset(math.sin(t * math.pi * 6) * 6 * (1 - t), 0),
            child: child,
          );
        },
        child: widget.builder(context, _tap, _showTag),
      ),
    );
  }
}

/// Swaps [child] (an option's radio) for the "Coming Soon" tag while
/// [showTag] is true.
class ComingSoonSwitch extends StatelessWidget {
  const ComingSoonSwitch({
    super.key,
    required this.showTag,
    required this.child,
  });

  final bool showTag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      layoutBuilder: (Widget? current, List<Widget> previous) =>
          AppMotion.switcherLayout(
            current,
            previous,
            alignment: Alignment.centerRight,
          ),
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
      child: showTag
          ? const AppTagPill(
              key: ValueKey<String>('soon'),
              label: 'Coming Soon',
              color: AppColors.accentSteel,
            )
          : KeyedSubtree(key: const ValueKey<String>('option'), child: child),
    );
  }
}
