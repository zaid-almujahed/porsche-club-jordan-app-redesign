import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import 'event_tags.dart';

class FeaturedEvent extends StatelessWidget {
  const FeaturedEvent({
    super.key,
    required this.event,
    this.onPressed,
    this.isRegistered = false,
  });

  final Event event;
  final VoidCallback? onPressed;

  /// The member has RSVP'd: shows the "Registered" tag.
  final bool isRegistered;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      enabled: onPressed != null,
      scale: 0.985,
      child: AspectRatio(
        aspectRatio: 0.9,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.large + 4),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.large + 4),
            child: Material(
              color: AppColors.panelDark,
              child: InkWell(
                onTap: onPressed,
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
                          colors: <Color>[
                            Color(0x00000000),
                            Color(0x33000000),
                            Color(0xE6050507),
                          ],
                          stops: <double>[0, 0.45, 1],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          if (EventTags.hasTags(
                            event,
                            isRegistered: isRegistered,
                          )) ...<Widget>[
                            EventTags(event: event, isRegistered: isRegistered),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.display.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _FeaturedMeta(
                            icon: Icons.calendar_today_rounded,
                            text: AppFormatters.dateAndTime(event.startsAt),
                          ),
                          const SizedBox(height: 6),
                          _FeaturedMeta(
                            icon: Icons.location_on_rounded,
                            text: event.location,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            height: 46,
                            child: FilledButton(
                              style: AppButtonStyles.pill(),
                              onPressed: onPressed,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Flexible(
                                    child: AppButtonLabel(
                                      'View Event',
                                      style: AppTextStyles.button,
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.xs),
                                  Icon(Icons.arrow_forward_rounded, size: 19),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedMeta extends StatelessWidget {
  const _FeaturedMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: AppColors.primaryBright),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
