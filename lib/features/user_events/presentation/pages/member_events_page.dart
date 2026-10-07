import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_back_navigation.dart';
import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../../../events/presentation/widgets/event_payment_widgets.dart';
import '../../../events/presentation/widgets/event_tags.dart';

import '../controllers/user_events_controller.dart';
import '../widgets/member_events_widgets.dart';

class MemberEventsPage extends StatelessWidget {
  const MemberEventsPage({
    super.key,
    required this.controller,
    required this.onPay,
    required this.onContactSupport,
  });

  final UserEventsController controller;

  /// Opens the CliQ payment for an RSVP still waiting for it.
  final ValueChanged<EventBooking> onPay;
  final VoidCallback onContactSupport;

  Future<void> _cancel(BuildContext context, EventBooking booking) async {
    final bool confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Cancel registration?',
      message: booking.refundsOnCancel
          ? 'Your registration for ${booking.event.title} will be cancelled, '
                'and your payment refunded to the CliQ alias you gave when '
                'paying.'
          : 'Your registration for ${booking.event.title} will be cancelled.',
      confirmLabel: 'Cancel RSVP',
      cancelLabel: 'Keep Registration',
      icon: Icons.event_busy_outlined,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final bool cancelled = await controller.cancelRegistration(booking);
    if (!context.mounted) return;
    if (!cancelled) {
      final Object? error = controller.actionError;
      if (error != null) showAppErrorPulse(context, error);
      return;
    }
    showAppSnackBar(
      context,
      booking.refundsOnCancel
          ? 'Event registration cancelled. Your payment will be refunded.'
          : 'Event registration cancelled.',
      type: AppFeedbackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: PorscheAppBar(
        title: 'My Events',
        showBack: true,
        onBack: () => context.goBack(fallback: AppRoutes.profile),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          final EventBooking? rejected = controller.takeRejectionNotice();
          if (rejected != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              showPaymentRejectedDialog(
                context: context,
                eventTitle: rejected.event.title,
                onContactSupport: onContactSupport,
              );
            });
          }
          return AppPageBody(
            topPadding: AppSpacing.xl,
            bottomPadding: AppSpacing.pageBottom,
            onRefresh: () => controller.load(force: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const AppFadeSlideIn(child: PageHeading()),
                const SizedBox(height: AppSpacing.lg),
                EventTabs(
                  showUpcoming: controller.showUpcoming,
                  onSelected: (bool upcoming) {
                    controller.showTab(upcoming: upcoming);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AsyncStateView<List<EventBooking>>(
                  state: controller.bookings,
                  onRetry: () => controller.load(force: true),
                  isEmpty: (List<EventBooking> bookings) => bookings.isEmpty,
                  emptyMessage: controller.showUpcoming
                      ? 'No upcoming event registrations.'
                      : 'No past event registrations.',
                  builder: (BuildContext context, List<EventBooking> bookings) {
                    return Column(
                      children: <Widget>[
                        for (
                          int index = 0;
                          index < bookings.length;
                          index++
                        ) ...<Widget>[
                          AppFadeSlideIn.stagger(
                            index: index,
                            child: _BookingCard(
                              booking: bookings[index],
                              isCancelling: controller.isCancelling(
                                bookings[index].event.id,
                              ),
                              onPay: () => onPay(bookings[index]),
                              onContactSupport: onContactSupport,
                              onCancel:
                                  controller.showUpcoming &&
                                      bookings[index].canCancel &&
                                      !bookings[index].event.hasEndedAt(
                                        DateTime.now(),
                                      )
                                  ? () => _cancel(context, bookings[index])
                                  : null,
                            ),
                          ),
                          if (index != bookings.length - 1)
                            const SizedBox(height: AppSpacing.md),
                        ],
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

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.isCancelling,
    required this.onPay,
    required this.onContactSupport,
    this.onCancel,
  });

  final EventBooking booking;
  final bool isCancelling;
  final VoidCallback onPay;
  final VoidCallback onContactSupport;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final Event event = booking.event;
    final DateTime now = DateTime.now();
    final bool isHappeningNow = event.isHappeningAt(now);
    final bool hasEnded = event.hasEndedAt(now);
    // Upcoming, confirmed RSVPs only: past events have no ticket button. A
    // paid RSVP has no ticket until its payment is confirmed.
    final bool canOpenTicket =
        booking.status == EventBookingStatus.confirmed && !hasEnded;
    final bool canPay = booking.awaitsPayment && !hasEnded;
    // A rejected RSVP is listed under Past, where support can be reached
    // about it.
    final bool isRejected = booking.status == EventBookingStatus.rejected;
    // The backend's check-in state in its own words (PARTIALLY_CHECKED_IN
    // reads PARTIALLY CHECKED IN); past events just read PAST.
    final String attendance =
        booking.ticket?.attendanceStatus.replaceAll('_', ' ').trim() ?? '';
    final (String status, Color? statusColor) = switch (booking.status) {
      EventBookingStatus.canceled => ('CANCELLED', AppColors.textMuted),
      EventBookingStatus.rejected => ('PAYMENT REJECTED', AppColors.danger),
      _ when hasEnded => ('PAST', null),
      EventBookingStatus.waitingAdminApproval => (
        'PAYMENT UNDER REVIEW',
        AppColors.warning,
      ),
      EventBookingStatus.pendingPayment => (
        'PAYMENT NEEDED',
        AppColors.warning,
      ),
      EventBookingStatus.confirmed => (
        attendance.isEmpty ? 'CONFIRMED' : attendance.toUpperCase(),
        null,
      ),
    };
    return MemberEventCard(
      status: status,
      statusColor: statusColor,
      startsSoonLabel: EventTags.startsSoonLabel(event, now),
      title: event.title,
      date: AppFormatters.date(event.startsAt),
      time: AppFormatters.timeRange(event.startsAt, event.endsAt),
      location: event.location,
      isTicketAvailable: canOpenTicket || canPay || isRejected,
      ticketLabel: isRejected
          ? 'CONTACT SUPPORT'
          : canPay
          ? 'COMPLETE PAYMENT'
          : 'VIEW TICKET',
      isHappeningNow: isHappeningNow,
      onTicketPressed: canOpenTicket
          ? () => context.push(
              AppRoutes.ticketLocation(booking.id),
              extra: booking,
            )
          : canPay
          ? onPay
          : isRejected
          ? onContactSupport
          : null,
      onCancelPressed: onCancel,
      isCancelling: isCancelling,
    );
  }
}
