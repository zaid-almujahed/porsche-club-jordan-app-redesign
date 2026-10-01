import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_back_navigation.dart';
import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../../data/known_locations.dart';
import '../controllers/event_details_controller.dart';
import '../widgets/event_details_widgets.dart';
import '../widgets/event_tags.dart';

class EventDetailsPage extends StatelessWidget {
  const EventDetailsPage({
    super.key,
    required this.controller,
    required this.onRsvpCancelled,
  });

  final EventDetailsController controller;

  /// After the member cancels their RSVP here.
  final VoidCallback onRsvpCancelled;

  Future<void> _cancelRsvp(BuildContext context, Event event) async {
    final bool confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Cancel RSVP?',
      message: 'Your registration for ${event.title} will be cancelled.',
      confirmLabel: 'Cancel RSVP',
      cancelLabel: 'Keep Registration',
      icon: Icons.event_busy_outlined,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final bool cancelled = await controller.cancelRsvp();
    if (!context.mounted) return;
    if (!cancelled) {
      final Object? error = controller.rsvpError;
      if (error != null) showAppErrorPulse(context, error);
      return;
    }
    showAppSuccessPulse(context, label: 'RSVP Cancelled');
    onRsvpCancelled();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final bool isUnavailable = controller.isUnavailable;
        final Event? current = isUnavailable ? null : controller.state.data;
        final double topInset =
            MediaQuery.paddingOf(context).top + kToolbarHeight;

        return AppBackScope(
          child: Scaffold(
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
              toolbarHeight: 64,
              leading: AppBarButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                // Pops, or returns to Events when opened without history.
                onPressed: () => context.goBack(),
                leading: true,
              ),
              title: current == null
                  ? const Text(
                      'EVENT DETAILS',
                      style: AppTextStyles.appBarTitle,
                    )
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
                    child: isUnavailable
                        ? EventUnavailable(
                            onBrowseEvents: () => context.go(AppRoutes.events),
                          )
                        : AsyncStateView<Event>(
                            state: controller.state,
                            onRetry: controller.refresh,
                            builder: (BuildContext context, Event event) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  _GalleryHero(
                                    images: event.photoUrls,
                                    event: event,
                                    isRegistered: controller.isRegistered,
                                    horizontalPadding: horizontalPadding,
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
                                          isRegistered: controller.isRegistered,
                                          isCancellingRsvp:
                                              controller.isCancellingRsvp,
                                          onCancelRsvp: () =>
                                              _cancelRsvp(context, event),
                                          onViewTicket: () => context.push(
                                            AppRoutes.ticketLocation(
                                              controller.eventId,
                                            ),
                                          ),
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
          ),
        );
      },
    );
  }
}

/// Photo gallery with the event heading over its bottom edge. Owns the
/// visible photo index so the dots can sit beside the status badge.
class _GalleryHero extends StatefulWidget {
  const _GalleryHero({
    required this.images,
    required this.event,
    required this.isRegistered,
    required this.horizontalPadding,
  });

  final List<String> images;
  final Event event;
  final bool isRegistered;
  final double horizontalPadding;

  @override
  State<_GalleryHero> createState() => _GalleryHeroState();
}

class _GalleryHeroState extends State<_GalleryHero> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        EventGallery(
          images: widget.images,
          onPageChanged: (int page) => setState(() => _page = page),
        ),
        Positioned(
          left: widget.horizontalPadding,
          right: widget.horizontalPadding,
          bottom: 0,
          child: AppFadeSlideIn(
            child: _EventHeading(
              event: widget.event,
              isRegistered: widget.isRegistered,
              pageCount: widget.images.length,
              page: _page,
            ),
          ),
        ),
      ],
    );
  }
}

class _EventHeading extends StatelessWidget {
  const _EventHeading({
    required this.event,
    required this.isRegistered,
    this.pageCount = 0,
    this.page = 0,
  });

  final Event event;
  final bool isRegistered;
  final int pageCount;
  final int page;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String? startsSoon = EventTags.startsSoonLabel(event, now);
    final (String status, IconData icon, Color color) = event.hasEndedAt(now)
        ? ('Past', Icons.history_rounded, const Color(0xFF3A3A40))
        : event.isHappeningAt(now)
        ? ('Happening now', Icons.bolt_rounded, AppColors.primary)
        : startsSoon != null
        ? (startsSoon, Icons.bolt_rounded, AppColors.primary)
        : ('Upcoming', Icons.event_available_rounded, AppColors.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            AppTagPill(label: status, icon: icon, color: color),
            if (isRegistered) ...<Widget>[
              const SizedBox(width: 6),
              const AppTagPill(
                label: 'Registered',
                icon: Icons.check_circle_rounded,
                color: EventTags.registeredColor,
              ),
            ],
            const Spacer(),
            // Gallery position, capped at five dots.
            AppPageDots(
              count: pageCount,
              current: page,
              activeColor: Colors.white,
              inactiveColor: const Color(0x99FFFFFF),
              dotSize: 6,
              activeWidth: 16,
              gap: 6,
            ),
          ],
        ),
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
                AppFormatters.date(event.startsAt),
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

/// When the forecast reaches [event], while it is still beyond it; null
/// when weather will never come (a place the weather endpoint does not
/// know) or is already due.
DateTime? _forecastFrom(Event event) {
  final DateTime now = DateTime.now();
  if (!event.startsAt.isAfter(now.add(Event.forecastWindow)) ||
      knownLocationFor(event.location) == null) {
    return null;
  }
  return event.startsAt.subtract(Event.forecastWindow);
}

class _EventDetailsBody extends StatelessWidget {
  const _EventDetailsBody({
    required this.event,
    required this.isRegistered,
    required this.isCancellingRsvp,
    required this.onCancelRsvp,
    required this.onViewTicket,
    required this.onRegister,
  });

  final Event event;
  final bool isRegistered;
  final bool isCancellingRsvp;
  final VoidCallback onCancelRsvp;
  final VoidCallback onViewTicket;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final bool hasStarted = event.hasStartedAt(now);
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
            guestLimit: event.guestLimit,
            precipitationProbability: event.precipitationProbability,
            windSpeedKmh: event.windSpeedKmh,
            showWeather: event.hasForecastAt(DateTime.now()),
            forecastFrom: _forecastFrom(event),
            weatherUnavailable: event.weatherUnavailable,
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
        // An RSVP'd member opens their ticket (until the event ends) and
        // can cancel until it starts, instead of registering again.
        if (isRegistered && !event.hasEndedAt(now)) ...<Widget>[
          PrimaryActionButton(
            label: 'View Ticket',
            height: 58,
            onPressed: onViewTicket,
          ),
          if (!hasStarted) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 58,
              child: FilledButton(
                onPressed: isCancellingRsvp ? null : onCancelRsvp,
                style: AppButtonStyles.outline(
                  foregroundColor: AppColors.danger,
                  borderColor: AppColors.danger.withValues(alpha: 0.4),
                ),
                child: AppButtonLabel(
                  isCancellingRsvp ? 'Cancelling...' : 'Cancel RSVP',
                ),
              ),
            ),
          ],
        ] else if (hasStarted)
          const SecondaryActionButton(label: 'Registration Closed', height: 58)
        else if (event.isAtCapacity)
          const SecondaryActionButton(label: 'Event At Capacity', height: 58)
        else
          PrimaryActionButton(
            label: 'Register for Event',
            height: 58,
            onPressed: onRegister,
          ),
      ],
    );
  }
}
