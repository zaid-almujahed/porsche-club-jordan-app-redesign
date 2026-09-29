import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';

import 'event_card_preview.dart';

class ThisSeasonList extends StatelessWidget {
  const ThisSeasonList({
    super.key,
    required this.events,
    this.registeredEventIds = const <String>{},
  });

  final List<Event> events;

  /// The member's RSVPs, tagged "Registered".
  final Set<String> registeredEventIds;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final Event event = events[index];
          return SizedBox(
            width: 240,
            child: EventPreviewCard(
              event: event,
              isRegistered: registeredEventIds.contains(event.id),
              onTap: () => context.push(
                AppRoutes.eventDetailsLocation(event.id),
                extra: event,
              ),
            ),
          );
        },
      ),
    );
  }
}
