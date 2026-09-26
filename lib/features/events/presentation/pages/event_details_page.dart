import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v4/core/routing/app_router.dart';
import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/core/utils/app_formatters.dart';
import 'package:pcj_v4/shared/domain/entities/event.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

import '../controllers/event_details_controller.dart';
import '../widgets/event_details_widgets.dart';

class EventDetailsPage extends StatelessWidget {
  const EventDetailsPage({super.key, required this.controller});

  final EventDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final Event? current = controller.state.data;
        final double topInset =
            MediaQuery.paddingOf(context).top + kToolbarHeight;

        return Scaffold(
          backgroundColor: AppColors.canvas,
          // The hero photo runs under a transparent bar with floating
          // controls, as in the event reference design.
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: const Border(),
            automaticallyImplyLeading: false,
            leadingWidth: 68,
            leading: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: Center(
                child: AppGlassIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () {
                    // Redirected routes can be the first page in the stack.
                    if (context.canPop()) context.pop();
                  },
                ),
              ),
            ),
            title: current == null
                ? const Text('EVENT DETAILS', style: AppTextStyles.appBarTitle)
                : null,
          ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double horizontalPadding = AppLayout.horizontalPadding(
                constraints.maxWidth,
              );

              return RefreshIndicator(
                color: AppColors.primaryBright,
                backgroundColor: AppColors.surfaceRaised,
                edgeOffset: topInset,
                elevation: 0,
                onRefresh: controller.refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    top: current == null ? topInset : 0,
                    bottom: AppSpacing.pageBottom,
                  ),
                  child: AsyncStateView<Event>(
                    state: controller.state,
                    onRetry: controller.refresh,
                    builder: (BuildContext context, Event event) {
                      final List<String> gallery = event.galleryUrls.isEmpty
                          ? <String>[event.posterUrl]
                          : event.galleryUrls;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Stack(
                            children: <Widget>[
                              EventGallery(images: gallery),
                              Positioned(
                                left: horizontalPadding,
                                right: horizontalPadding,
                                bottom: 0,
                                child: AppFadeSlideIn(
                                  child: _EventHeading(event: event),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AppLayout.maxContentWidth,
                                ),
                                child: _EventDetailsBody(
                                  event: event,
                                  onRegister: () => context.push(
                                    AppRoutes.eventRegistrationLocation(
                                      controller.eventId,
                                    ),
                                    extra: event,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EventHeading extends StatelessWidget {
  const _EventHeading({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final (String status, IconData icon, Color color) = event.hasEndedAt(now)
        ? ('Past', Icons.history_rounded, const Color(0xFF3A3A40))
        : event.isHappeningAt(now)
        ? ('Happening now', Icons.bolt_rounded, AppColors.primary)
        : ('Upcoming', Icons.event_available_rounded, AppColors.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppTagPill(label: status, icon: icon, color: color),
        const SizedBox(height: AppSpacing.sm),
        Text(
          event.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.display.copyWith(fontSize: 30),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            const Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${AppFormatters.date(event.startsAt)}  ·  '
                '${event.category}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EventDetailsBody extends StatelessWidget {
  const _EventDetailsBody({required this.event, required this.onRegister});

  final Event event;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    int section = 0;
    Widget reveal(Widget child) => AppFadeSlideIn.stagger(
      index: section++,
      initialDelay: const Duration(milliseconds: 120),
      step: const Duration(milliseconds: 70),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: AppSpacing.xl),
        if (event.sponsors.isNotEmpty) ...<Widget>[
          reveal(
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: AppDecorations.panel(radius: AppRadii.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(
                        Icons.emoji_events_rounded,
                        size: 18,
                        color: AppColors.primaryBright,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text('SPONSORED BY', style: AppTextStyles.overline),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SponsorsList(sponsors: event.sponsors),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        reveal(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Event Overview',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 22),
              ),
              const SizedBox(height: AppSpacing.xs),
              const AppAccentBar(),
              const SizedBox(height: AppSpacing.md),
              Text(
                event.description,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        reveal(
          EventStatistics(
            capacity: event.capacity,
            registeredCount: event.registeredCount,
            startsAt: event.startsAt,
            weatherCelsius: event.weatherCelsius,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        reveal(
          LocationCard(
            location: event.location,
            mapImageUrl: event.mapImageUrl,
            latitude: event.latitude,
            longitude: event.longitude,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (event.hasStartedAt(DateTime.now()))
          const SecondaryActionButton(label: 'Registration Closed', height: 58)
        else if (event.isAtCapacity)
          const SecondaryActionButton(label: 'Event At Capacity', height: 58)
        else
          PrimaryActionButton(
            label: 'Register for Event',
            icon: Icons.event_available_rounded,
            height: 58,
            onPressed: onRegister,
          ),
      ],
    );
  }
}
