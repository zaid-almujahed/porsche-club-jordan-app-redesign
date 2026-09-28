import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';

/// Page dots that never grow past [maxVisible]: a window follows the current
/// page, and the dots at its edges shrink and fade when more pages lie beyond
/// them. The window slides smoothly as the page changes.
class AppPageDots extends StatelessWidget {
  const AppPageDots({
    super.key,
    required this.count,
    required this.current,
    this.onSelected,
    this.activeColor = AppColors.primaryBright,
    this.inactiveColor = AppColors.textFaint,
    this.maxVisible = 5,
    this.dotSize = 7,
    this.activeWidth = 22,
    this.gap = 8,
  });

  final int count;
  final int current;
  final ValueChanged<int>? onSelected;
  final Color activeColor;
  final Color inactiveColor;
  final int maxVisible;
  final double dotSize;
  final double activeWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    final int visible = count < maxVisible ? count : maxVisible;
    final int selected = current.clamp(0, count - 1);
    final int start = (selected - visible ~/ 2).clamp(0, count - visible);
    final int end = start + visible - 1;
    final double slot = dotSize + gap;
    // The active pill is always inside the window, so its width is constant.
    final double windowWidth = visible * slot + (activeWidth - dotSize);

    return SizedBox(
      width: windowWidth,
      height: dotSize + 12,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: start * slot),
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          builder: (BuildContext context, double offset, Widget? child) {
            return Transform.translate(
              offset: Offset(-offset, 0),
              child: child,
            );
          },
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(count, (int index) {
                final bool isActive = index == selected;
                final bool isOutside = index < start || index > end;
                // An edge dot with more pages beyond it.
                final bool isEdge =
                    (index == start && start > 0) ||
                    (index == end && end < count - 1);
                final Widget dot = AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  width: isActive ? activeWidth : dotSize,
                  height: dotSize,
                  margin: EdgeInsets.symmetric(
                    horizontal: gap / 2,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                );
                final ValueChanged<int>? select = onSelected;
                return AnimatedOpacity(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  opacity: isOutside
                      ? 0
                      : isEdge
                      ? 0.6
                      : 1,
                  child: AnimatedScale(
                    duration: AppMotion.medium,
                    curve: AppMotion.curve,
                    scale: isEdge ? 0.7 : 1,
                    child: select == null
                        ? dot
                        : GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => select(index),
                            child: dot,
                          ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
