import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/event_registration_controller.dart';
import '../widgets/event_registration_widgets.dart';

class EventRegistrationPage extends StatelessWidget {
  const EventRegistrationPage({
    super.key,
    required this.controller,
    required this.onRegistered,
  });

  final EventRegistrationController controller;
  final VoidCallback onRegistered;

  Future<void> _submit(BuildContext context, Event event) async {
    FocusScope.of(context).unfocus();
    if (!controller.validateGuestNames()) {
      final Object? error = controller.submissionError;
      if (error != null) showAppErrorPulse(context, error);
      return;
    }
    if (controller.guestCount > 0 && !controller.guestNoticeAccepted) {
      final bool acknowledged = await showAppConfirmationDialog(
        context: context,
        title: 'Guest Admission Notice',
        message:
            'For security and capacity control, only guests included in this '
            'registration will be permitted to enter the event. Please '
            'confirm that the guest names are accurate.',
        confirmLabel: 'I Understand',
        cancelLabel: 'Review Guests',
        icon: Icons.groups_2_outlined,
      );
      if (!acknowledged || !context.mounted) return;
      controller.acceptGuestNotice();
    }

    final bool registered = await controller.submit();
    if (!context.mounted) return;
    if (!registered) {
      final Object? error = controller.submissionError;
      if (error != null) showAppErrorPulse(context, error);
      return;
    }
    showAppSuccessPulse(
      context,
      label: 'RSVP Confirmed',
      message: 'Check My Events for your ticket.',
    );
    onRegistered();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const PorscheAppBar(title: 'Registration', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            child: AsyncStateView<Event>(
              state: controller.eventState,
              onRetry: () => controller.load(force: true),
              builder: (BuildContext context, Event event) {
                final bool allowsGuests = event.guestLimit > 0;
                final bool hasRegistrationCost =
                    controller.basePrice > 0 || controller.guestsTotal > 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppFadeSlideIn(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 15,
                                color: AppColors.primaryBright,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  AppFormatters.dateAndTime(
                                    event.startsAt,
                                  ).toUpperCase(),
                                  style: AppTextStyles.overline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            event.title.toUpperCase(),
                            style: AppTextStyles.display.copyWith(fontSize: 32),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const AppAccentBar(),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppFadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: BasePriceBanner(
                        amount: controller.basePrice,
                        currency: event.currency,
                      ),
                    ),
                    if (allowsGuests) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      const SectionTitleRow(title: 'Additional Guests'),
                      const SizedBox(height: AppSpacing.md),
                      GuestPanel(
                        count: controller.guestCount,
                        limit: event.guestLimit,
                        guestFee: controller.guestPrice,
                        currency: event.currency,
                        nameControllers: controller.guestNameControllers,
                        onIncrement: controller.incrementGuests,
                        onNameChanged: controller.onGuestNameChanged,
                        onRemove: controller.removeGuest,
                      ),
                    ],
                    if (hasRegistrationCost) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      PriceSummary(
                        basePrice: controller.basePrice,
                        guestsPrice: controller.guestsTotal,
                        total: controller.total,
                        currency: event.currency,
                        showGuests: allowsGuests,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.section),
                    if (controller.isAlreadyRegistered)
                      const SecondaryActionButton(
                        label: 'Already Registered',
                        height: 58,
                      )
                    else
                      PrimaryActionButton(
                        height: 58,
                        isLoading: controller.isSubmitting,
                        label: event.isAtCapacity
                            ? 'Event At Capacity'
                            : controller.isSubmitting
                            ? 'Processing...'
                            : 'Submit RSVP',
                        onPressed: controller.isSubmitting || event.isAtCapacity
                            ? null
                            : () => _submit(context, event),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
