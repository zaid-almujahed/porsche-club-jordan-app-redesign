import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';

enum AppSection { home, events, shop, offers, profile }

/// Floating navigation bar: a rounded glass capsule that hovers above the
/// content (from the reference), keeping the app's labelled tabs, with
/// Events as the raised red button in the middle. Slim, slightly
/// see-through, no drop shadows.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selected,
    this.onSelected,
  });

  final AppSection selected;
  final ValueChanged<AppSection>? onSelected;

  static const Map<AppSection, IconData> _icons = <AppSection, IconData>{
    AppSection.home: Icons.home_outlined,
    AppSection.events: Icons.calendar_month_outlined,
    AppSection.shop: Icons.shopping_bag_outlined,
    AppSection.offers: Icons.card_giftcard_outlined,
    AppSection.profile: Icons.person_outline_rounded,
  };

  static const Map<AppSection, IconData> _selectedIcons =
      <AppSection, IconData>{
        AppSection.home: Icons.home_rounded,
        AppSection.events: Icons.calendar_month_rounded,
        AppSection.shop: Icons.shopping_bag_rounded,
        AppSection.offers: Icons.card_giftcard_rounded,
        AppSection.profile: Icons.person_rounded,
      };

  /// Visual order, left to right, with Events in the middle. Branch indexes
  /// (and routes) are unchanged.
  static const List<AppSection> _order = <AppSection>[
    AppSection.home,
    AppSection.shop,
    AppSection.events,
    AppSection.offers,
    AppSection.profile,
  ];

  static const double _barHeight = 58;
  static const double _overhang = 16;

  /// Slightly see-through glass (content shows faintly behind it).
  static const Color _glass = Color(0xBF141417);

  void _select(BuildContext context, AppSection section) {
    if (section == selected) return;
    HapticFeedback.selectionClick();
    final ValueChanged<AppSection>? callback = onSelected;
    if (callback != null) {
      callback(section);
    } else {
      context.goNamed(section.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: SizedBox(
          height: _barHeight + _overhang,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_barHeight / 2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _glass,
                        borderRadius: BorderRadius.circular(_barHeight / 2),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                      ),
                      child: Row(
                        children: _order.map((AppSection section) {
                          return Expanded(
                            child: _NavBarItem(
                              label: section.name.toUpperCase(),
                              isSelected: section == selected,
                              icon: _icons[section]!,
                              selectedIcon: _selectedIcons[section]!,
                              // Events' icon is drawn by the raised button.
                              showIcon: section != AppSection.events,
                              onTap: () => _select(context, section),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: _NavMainButton(
                    icon: selected == AppSection.events
                        ? _selectedIcons[AppSection.events]!
                        : _icons[AppSection.events]!,
                    isSelected: selected == AppSection.events,
                    onTap: () => _select(context, AppSection.events),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
    this.showIcon = true,
  });

  final String label;
  final bool isSelected;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected
        ? AppColors.primaryBright
        : const Color(0x99FFFFFF);

    return Semantics(
      selected: isSelected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        splashColor: const Color(0x1FD5001C),
        highlightColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // The red selection bar from the previous navigation, now on the
            // capsule's top edge.
            if (showIcon)
              Positioned(
                top: 0,
                child: AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  width: isSelected ? 18 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBright,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(3),
                    ),
                    boxShadow: isSelected
                        ? const <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 22,
                  child: showIcon
                      ? AnimatedScale(
                          scale: isSelected ? 1.08 : 1,
                          duration: AppMotion.medium,
                          curve: AppMotion.curve,
                          child: AnimatedSwitcher(
                            duration: AppMotion.fast,
                            layoutBuilder: AppMotion.switcherLayout,
                            child: Icon(
                              isSelected ? selectedIcon : icon,
                              key: ValueKey<bool>(isSelected),
                              color: color,
                              size: 22,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedDefaultTextStyle(
                    duration: AppMotion.medium,
                    style: AppTextStyles.label.copyWith(
                      color: color,
                      fontSize: 9.5,
                      letterSpacing: 0.9,
                    ),
                    child: Text(label, maxLines: 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Raised red button in the middle of the bar: the main (Events) tab.
class _NavMainButton extends StatelessWidget {
  const _NavMainButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Events',
      selected: isSelected,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.06 : 1,
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.primaryBright, AppColors.primary],
              ),
              // A ring in the bar's glass colour lifts it off the bar.
              border: Border.all(color: AppBottomNavigation._glass, width: 3),
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              layoutBuilder: AppMotion.switcherLayout,
              child: Icon(
                icon,
                key: ValueKey<IconData>(icon),
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
