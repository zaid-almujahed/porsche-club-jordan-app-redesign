import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/ticket_controller.dart';
import '../widgets/virtual_ticket_widgets.dart';

class VirtualTicketPage extends StatelessWidget {
  const VirtualTicketPage({super.key, required this.controller});

  final TicketController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const PorscheAppBar(title: 'Virtual Ticket', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            topPadding: AppSpacing.xl,
            bottomPadding: AppSpacing.pageBottom,
            onRefresh: () => controller.load(force: true),
            child: AsyncStateView<EventBooking>(
              state: controller.booking,
              onRetry: () => controller.load(force: true),
              builder: (BuildContext context, EventBooking booking) {
                return AsyncStateView<EventTicket>(
                  state: controller.ticket,
                  onRetry: () => controller.load(force: true),
                  builder: (BuildContext context, EventTicket ticket) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 506),
                        child: TicketCard(booking: booking, ticket: ticket),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
