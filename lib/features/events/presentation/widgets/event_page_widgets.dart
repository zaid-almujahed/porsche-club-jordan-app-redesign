import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v4/core/routing/app_router.dart';
import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/core/utils/app_formatters.dart';
import 'package:pcj_v4/shared/domain/entities/event.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

class CategoryFilters extends StatelessWidget {
  const CategoryFilters({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = categories.indexOf(selectedCategory);
    // Upcoming / Past reads best as a segmented control; longer category
    // lists fall back to scrolling chips.
    if (categories.length <= 3) {
      return AppSegmentedTabs(
        labels: categories,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onSelected: (int index) => onSelected(categories[index]),
      );
    }
    return AppFilterChips(
      labels: categories,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      onSelected: (int index) => onSelected(categories[index]),
    );
  }
}

// Replaced by the shared AppSegmentedTabs / AppFilterChips.
// class _FilterChip extends StatelessWidget {
//   const _FilterChip({
//     required this.label,
//     required this.selected,
//     required this.onTap,
//   });
//
//   final String label;
//   final bool selected;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     final BorderRadius borderRadius = BorderRadius.circular(AppRadii.pill);
//     return Material(
//       color: Colors.transparent,
//       borderRadius: borderRadius,
//       clipBehavior: Clip.antiAlias,
//       child: Ink(
//         decoration: BoxDecoration(
//           color: selected ? AppColors.primary : AppColors.panelDark,
//           border: Border.all(
//             color: selected ? AppColors.primaryBright : AppColors.border,
//           ),
//           borderRadius: borderRadius,
//         ),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: borderRadius,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Center(child: Text(label, style: AppTextStyles.label)),
//           ),
//         ),
//       ),
//     );
//   }
// }

class UpcomingEventsCarousel extends StatefulWidget {
  const UpcomingEventsCarousel({super.key, required this.upcomingEvents});

  final List<Event> upcomingEvents;

  @override
  State<UpcomingEventsCarousel> createState() => _UpcomingEventsCarouselState();
}

class _UpcomingEventsCarouselState extends State<UpcomingEventsCarousel> {
  late final PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.94);
  }

  @override
  void didUpdateWidget(UpcomingEventsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.upcomingEvents.length) {
      _selectedIndex = 0;
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double cardWidth = constraints.maxWidth * 0.94;
        final double imageHeight = cardWidth / 1.05;

        return Column(
          children: <Widget>[
            SizedBox(
              height: imageHeight + 96,
              child: PageView.builder(
                controller: _pageController,
                padEnds: false,
                clipBehavior: Clip.none,
                itemCount: widget.upcomingEvents.length,
                onPageChanged: (int index) {
                  setState(() => _selectedIndex = index);
                },
                itemBuilder: (BuildContext context, int index) {
                  final Event event = widget.upcomingEvents[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == widget.upcomingEvents.length - 1
                          ? 0
                          : AppSpacing.md,
                    ),
                    child: AnimatedScale(
                      // The resting card sits slightly forward of its
                      // neighbours while swiping.
                      scale: index == _selectedIndex ? 1 : 0.96,
                      duration: AppMotion.medium,
                      curve: AppMotion.curve,
                      child: _UpcomingEventCard(
                        event: event,
                        onTap: () => context.push(
                          AppRoutes.eventDetailsLocation(event.id),
                          extra: event,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _CarouselDots(
              itemCount: widget.upcomingEvents.length,
              selectedIndex: _selectedIndex,
              onSelected: (int index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({
    required this.itemCount,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int itemCount;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(itemCount, (int index) {
        final bool selected = index == selectedIndex;
        return InkWell(
          onTap: () => onSelected(index),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.curve,
            width: selected ? 22 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryBright : AppColors.border,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
        );
      }),
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      scale: 0.98,
      child: Material(
        color: AppColors.panelDark,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(AppRadii.large + 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    AppAssetImage(
                      path: event.posterUrl,
                      fallbackIcon: Icons.directions_car_outlined,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[Color(0x00000000), Color(0xF2111114)],
                          stops: <double>[0.4, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: AppTagPill(label: event.category),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.display.copyWith(fontSize: 27),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _EventMeta(
                      icon: Icons.schedule_rounded,
                      value: AppFormatters.dateAndTime(event.startsAt),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _EventMeta(
                      icon: Icons.location_on_outlined,
                      value: event.location,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventMeta extends StatelessWidget {
  const _EventMeta({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 17, color: AppColors.primaryBright),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14.5,
            ),
          ),
        ),
      ],
    );
  }
}
