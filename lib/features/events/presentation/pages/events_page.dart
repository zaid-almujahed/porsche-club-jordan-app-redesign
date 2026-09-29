import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/widgets/app_search_field.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/events_controller.dart';
import '../widgets/event_page_widgets.dart';
import '../widgets/featured_event.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({
    super.key,
    required this.controller,
    this.unreadNotificationCount,
  });

  final EventsController controller;
  final ValueListenable<int>? unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.canvas,
      appBar: PorscheAppBar(
        title: 'Events',
        showNotifications: true,
        unreadNotificationCount: unreadNotificationCount,
        onNotificationsPressed: () => context.push(AppRoutes.notifications),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            topPadding: AppSpacing.xl,
            bottomPadding:
                AppLayout.navigationBarHeight + AppSpacing.pageBottom,
            onRefresh: () => controller.load(force: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppFadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Club Events',
                        style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      const Text(
                        'Drives, meets and gatherings for members.',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const AppAccentBar(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppSearchField(
                  controller: controller.searchController,
                  hintText: 'Search events',
                  onChanged: controller.search,
                  onClear: controller.clearSearch,
                ),
                const SizedBox(height: AppSpacing.lg),
                AsyncStateView<List<Event>>(
                  state: controller.events,
                  onRetry: () => controller.load(force: true),
                  builder: (BuildContext context, List<Event> events) {
                    Event? featured;
                    for (final Event event in events) {
                      if (event.isFeatured) {
                        featured = event;
                        break;
                      }
                    }
                    final Event? featuredEvent =
                        featured ?? (events.isEmpty ? null : events.first);
                    final bool showingPast =
                        controller.selectedCategory ==
                        EventsController.pastCategory;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (controller.categories.isNotEmpty) ...<Widget>[
                          CategoryFilters(
                            categories: controller.categories,
                            selectedCategory: controller.selectedCategory,
                            onSelected: controller.selectCategory,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        if (events.isNotEmpty && !showingPast) ...<Widget>[
                          AppFadeSlideIn(child: _EventStats(events: events)),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        // Past events never show a featured event.
                        if (featuredEvent != null && !showingPast) ...<Widget>[
                          AppFadeSlideIn(
                            delay: const Duration(milliseconds: 80),
                            child: FeaturedEvent(
                              event: featuredEvent,
                              isRegistered: controller.registeredEventIds
                                  .contains(featuredEvent.id),
                              onPressed: () => context.push(
                                AppRoutes.eventDetailsLocation(
                                  featuredEvent.id,
                                ),
                                extra: featuredEvent,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.section),
                        ],
                        SectionTitleRow(
                          title: controller.sectionTitle,
                          trailing: events.isEmpty
                              ? null
                              : EventViewSwitch(
                                  isCompact: controller.isCompactView,
                                  onChanged: controller.setCompactView,
                                ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (events.isEmpty)
                          AppEmptyState(
                            icon: Icons.event_busy_outlined,
                            message: controller.hasSearchQuery
                                ? 'No events match your search.'
                                : showingPast
                                ? 'No past events are available.'
                                : 'No upcoming events are available.',
                          )
                        else
                          AppFadeSlideIn(
                            delay: const Duration(milliseconds: 160),
                            child: AnimatedSwitcher(
                              duration: AppMotion.medium,
                              child: controller.isCompactView
                                  ? CompactEventList(
                                      key: const ValueKey<String>('compact'),
                                      events: events,
                                      registeredEventIds:
                                          controller.registeredEventIds,
                                    )
                                  : UpcomingEventsCarousel(
                                      key: const ValueKey<String>('cards'),
                                      upcomingEvents: events,
                                      registeredEventIds:
                                          controller.registeredEventIds,
                                    ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Compact numbers strip (inspired by the event-app reference hero).
class _EventStats extends StatelessWidget {
  const _EventStats({required this.events});

  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int thisMonth = events
        .where(
          (Event event) =>
              event.startsAt.year == now.year &&
              event.startsAt.month == now.month,
        )
        .length;
    final int open = events.where((Event event) => !event.isAtCapacity).length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: AppDecorations.panel(radius: AppRadii.large),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            _Stat(value: events.length, label: 'Listed'),
            const VerticalDivider(color: AppColors.cardBorder, width: 1),
            _Stat(
              value: thisMonth,
              label: 'This Month',
              color: AppColors.accentSteel,
            ),
            const VerticalDivider(color: AppColors.cardBorder, width: 1),
            _Stat(
              value: open,
              label: 'Open',
              highlight: true,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.highlight = false,
    this.color,
  });

  final int value;
  final String label;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 700),
            curve: AppMotion.curve,
            builder: (BuildContext context, double current, Widget? child) {
              return Text(
                current.round().toString(),
                style: AppTextStyles.numeric.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color:
                      color ??
                      (highlight
                          ? AppColors.primaryBright
                          : AppColors.textPrimary),
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: AppTextStyles.overline),
        ],
      ),
    );
  }
}
