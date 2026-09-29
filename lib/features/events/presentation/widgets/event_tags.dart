import 'package:flutter/material.dart';

import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

/// The tags on an event: "Today", "Tomorrow" or "In N days" while it starts
/// within three days, and "Registered" once the member has RSVP'd.
class EventTags extends StatelessWidget {
  const EventTags({super.key, required this.event, this.isRegistered = false});

  final Event event;
  final bool isRegistered;

  static const Color registeredColor = Color(0xFF178A55);

  /// Null once the event has started, or while it is more than three
  /// calendar days away.
  static String? startsSoonLabel(Event event, DateTime now) {
    if (event.hasStartedAt(now)) return null;
    final DateTime start = event.startsAt;
    final int days = DateTime.utc(
      start.year,
      start.month,
      start.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    return switch (days) {
      0 => 'Today',
      1 => 'Tomorrow',
      2 || 3 => 'In $days days',
      _ => null,
    };
  }

  static bool hasTags(Event event, {required bool isRegistered}) =>
      isRegistered || startsSoonLabel(event, DateTime.now()) != null;

  @override
  Widget build(BuildContext context) {
    final String? soon = startsSoonLabel(event, DateTime.now());
    if (soon == null && !isRegistered) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        if (soon != null) AppTagPill(label: soon, icon: Icons.bolt_rounded),
        if (isRegistered)
          const AppTagPill(
            label: 'Registered',
            icon: Icons.check_circle_rounded,
            color: registeredColor,
          ),
      ],
    );
  }
}
