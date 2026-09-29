import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import 'event_tags.dart';

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

/// Switches the events list between the cards and the compact list.
class EventViewSwitch extends StatelessWidget {
  const EventViewSwitch({
    super.key,
    required this.isCompact,
    required this.onChanged,
  });

  final bool isCompact;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.panelDark,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ViewOption(
            icon: Icons.view_carousel_outlined,
            tooltip: 'Card view',
            isSelected: !isCompact,
            onPressed: () => onChanged(false),
          ),
          _ViewOption(
            icon: Icons.view_list_rounded,
            tooltip: 'Compact view',
            isSelected: isCompact,
            onPressed: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ViewOption extends StatelessWidget {
  const _ViewOption({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            width: 36,
            height: 30,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// The compact list: a small poster per event, under a heading for each
/// month. Events keep the order they are given in.
class CompactEventList extends StatelessWidget {
  const CompactEventList({
    super.key,
    required this.events,
    this.registeredEventIds = const <String>{},
  });

  final List<Event> events;

  /// The member's RSVPs, marked with a check.
  final Set<String> registeredEventIds;

  @override
  Widget build(BuildContext context) {
    // Consecutive events in the same month share a heading.
    final List<List<Event>> months = <List<Event>>[];
    for (final Event event in events) {
      final List<Event>? month = months.isEmpty ? null : months.last;
      if (month != null &&
          month.first.startsAt.year == event.startsAt.year &&
          month.first.startsAt.month == event.startsAt.month) {
        month.add(event);
      } else {
        months.add(<Event>[event]);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int m = 0; m < months.length; m++) ...<Widget>[
          if (m > 0) const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              AppFormatters.monthYear(months[m].first.startsAt).toUpperCase(),
              style: AppTextStyles.overline,
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: AppDecorations.panel(radius: AppRadii.large),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < months[m].length; i++) ...<Widget>[
                  _CompactEventRow(
                    event: months[m][i],
                    isRegistered: registeredEventIds.contains(months[m][i].id),
                    onTap: () => context.push(
                      AppRoutes.eventDetailsLocation(months[m][i].id),
                      extra: months[m][i],
                    ),
                  ),
                  if (i != months[m].length - 1)
                    const Divider(height: 1, color: AppColors.cardBorder),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CompactEventRow extends StatelessWidget {
  const _CompactEventRow({
    required this.event,
    required this.isRegistered,
    required this.onTap,
  });

  final Event event;
  final bool isRegistered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? startsSoon = EventTags.startsSoonLabel(event, DateTime.now());
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 72,
                child: AppAssetImage(
                  path: event.posterUrl,
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  fallbackIcon: Icons.directions_car_outlined,
                  fallbackIconSize: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppFormatters.dateAndTime(event.startsAt).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.overline.copyWith(
                        fontSize: 10,
                        color: AppColors.primaryBright,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isRegistered || startsSoon != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    if (isRegistered)
                      const Tooltip(
                        message: 'Registered',
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.success,
                        ),
                      ),
                    if (isRegistered && startsSoon != null)
                      const SizedBox(height: 4),
                    if (startsSoon != null)
                      Text(
                        startsSoon.toUpperCase(),
                        style: AppTextStyles.overline.copyWith(
                          fontSize: 9.5,
                          color: AppColors.primaryBright,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class UpcomingEventsCarousel extends StatefulWidget {
  const UpcomingEventsCarousel({
    super.key,
    required this.upcomingEvents,
    this.registeredEventIds = const <String>{},
  });

  final List<Event> upcomingEvents;

  /// The member's RSVPs, tagged "Registered".
  final Set<String> registeredEventIds;

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
                        isRegistered: widget.registeredEventIds.contains(
                          event.id,
                        ),
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
            // Capped at five dots; the rest fade out at the edges.
            AppPageDots(
              count: widget.upcomingEvents.length,
              current: _selectedIndex,
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

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({
    required this.event,
    required this.isRegistered,
    required this.onTap,
  });

  final Event event;
  final bool isRegistered;
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
                      child: EventTags(
                        event: event,
                        isRegistered: isRegistered,
                      ),
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
