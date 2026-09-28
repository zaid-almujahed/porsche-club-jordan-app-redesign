import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';

/// Horizontally scrolling pill filters (categories). Selection animates.
class AppFilterChips extends StatelessWidget {
  const AppFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (BuildContext context, int index) {
          final bool isSelected = index == selectedIndex;
          return Semantics(
            selected: isSelected,
            button: true,
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.curve,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.panelDark,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryBright
                        : AppColors.cardBorder,
                  ),
                  boxShadow: isSelected
                      ? const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x40D5001C),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
                child: AnimatedDefaultTextStyle(
                  duration: AppMotion.medium,
                  style: AppTextStyles.label.copyWith(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.9,
                  ),
                  child: Text(labels[index].toUpperCase()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Segmented two-or-more option switcher with a sliding red thumb.
class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 48,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.panelDark,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth / labels.length;
          return Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: AppMotion.medium,
                curve: AppMotion.curve,
                left: width * selectedIndex,
                top: 0,
                bottom: 0,
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        AppColors.primaryBright,
                        AppColors.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.medium - 4),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x40D5001C),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (int index = 0; index < labels.length; index++)
                    Expanded(
                      child: Semantics(
                        selected: index == selectedIndex,
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: index == selectedIndex
                              ? null
                              : () => onSelected(index),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: AppMotion.medium,
                              style: AppTextStyles.label.copyWith(
                                color: index == selectedIndex
                                    ? Colors.white
                                    : AppColors.textMuted,
                                letterSpacing: 1.0,
                              ),
                              child: Text(
                                labels[index].toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
