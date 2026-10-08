import 'package:flutter/material.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

abstract final class MemberEventStyles {
  static const TextStyle pageTitle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.8,
  );

  static const TextStyle pageDescription = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle tab = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1,
  );

  static final BoxDecoration cardDecoration = AppDecorations.panel(
    radius: AppRadii.large,
  );

  static const TextStyle status = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textSecondary,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.1,
  );

  static const TextStyle eventTitle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 21,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static const TextStyle detailLabel = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 1.2,
  );

  static const TextStyle detailValue = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static const TextStyle ticketButton = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: 1.2,
  );
}

class EventTabs extends StatelessWidget {
  const EventTabs({
    super.key,
    required this.showUpcoming,
    required this.onSelected,
  });

  final bool showUpcoming;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedTabs(
      labels: const <String>['Upcoming', 'Past'],
      selectedIndex: showUpcoming ? 0 : 1,
      onSelected: (int index) => onSelected(index == 0),
    );
  }
}

class MemberEventCard extends StatelessWidget {
  const MemberEventCard({
    super.key,
    required this.status,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.isTicketAvailable,
    required this.isHappeningNow,
    this.onTicketPressed,
    this.onCancelPressed,
    this.onSupportPressed,
    this.isCancelling = false,
    this.startsSoonLabel,
    this.statusColor,
    this.paymentStatus,
    this.paymentStatusColor,
    this.ticketLabel = 'VIEW TICKET',
  });

  final String status;

  /// The status chip's colour, e.g. for a payment state.
  final Color? statusColor;

  /// A paid RSVP's payment, in a second chip; null hides it.
  final String? paymentStatus;
  final Color? paymentStatusColor;

  /// The main button: the ticket, or completing a payment.
  final String ticketLabel;

  final String title;
  final String date;
  final String time;
  final String location;
  final bool isTicketAvailable;
  final bool isHappeningNow;
  final VoidCallback? onTicketPressed;
  final VoidCallback? onCancelPressed;

  /// Set: a row to contact support, e.g. about a rejected payment.
  final VoidCallback? onSupportPressed;
  final bool isCancelling;

  /// "Today", "Tomorrow" or "In N days" while the event is close.
  final String? startsSoonLabel;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.medium,
      decoration: isHappeningNow
          ? MemberEventStyles.cardDecoration.copyWith(
              border: Border.all(color: const Color(0xB33DD68C), width: 1.4),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x2E3DD68C),
                  blurRadius: 24,
                  spreadRadius: -8,
                ),
              ],
            )
          : MemberEventStyles.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _StatusChip(
                  label: status,
                  isHighlighted: isTicketAvailable,
                  isHappeningNow: isHappeningNow,
                  tint: statusColor,
                ),
                if (paymentStatus != null)
                  _StatusChip(
                    label: paymentStatus!,
                    isHighlighted: false,
                    isHappeningNow: false,
                    tint: paymentStatusColor,
                  ),
                if (startsSoonLabel != null)
                  AppTagPill(label: startsSoonLabel!, icon: Icons.bolt_rounded),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: MemberEventStyles.eventTitle),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadii.medium),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: <Widget>[
                  _EventDetail(
                    label: 'DATE',
                    value: date,
                    icon: Icons.calendar_today_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _EventDetail(
                    label: 'TIME',
                    value: time,
                    icon: Icons.schedule_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _EventDetail(
                    label: 'LOCATION',
                    value: location,
                    icon: Icons.location_on_outlined,
                  ),
                ],
              ),
            ),
            if (isTicketAvailable) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _TicketButton(label: ticketLabel, onPressed: onTicketPressed),
            ],
            if (onSupportPressed != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              SupportHelpRow(onPressed: onSupportPressed),
            ],
            if (onCancelPressed != null) ...<Widget>[
              SizedBox(
                height: isTicketAvailable ? AppSpacing.xs : AppSpacing.md,
              ),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: isCancelling ? null : onCancelPressed,
                  style: AppButtonStyles.outline(
                    foregroundColor: AppColors.danger,
                    borderColor: AppColors.danger.withValues(alpha: 0.4),
                  ),
                  child: AppButtonLabel(
                    isCancelling ? 'CANCELLING...' : 'CANCEL RSVP',
                    style: MemberEventStyles.ticketButton.copyWith(
                      color: isCancelling
                          ? AppColors.textFaint
                          : AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TicketButton extends StatelessWidget {
  const _TicketButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceRaised,
          disabledForegroundColor: AppColors.textFaint,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          minimumSize: const Size.fromHeight(46),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
        ),
        child: AppButtonLabel(
          label,
          style: MemberEventStyles.ticketButton.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isHighlighted,
    required this.isHappeningNow,
    this.tint,
  });

  final String label;
  final bool isHighlighted;
  final bool isHappeningNow;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final Color color = isHappeningNow
        ? AppColors.success
        : tint ??
              (isHighlighted ? AppColors.primaryBright : AppColors.textMuted);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isHappeningNow) ...<Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: MemberEventStyles.status.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _EventDetail extends StatelessWidget {
  const _EventDetail({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: AppColors.primaryBright),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(label, style: MemberEventStyles.detailLabel),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: MemberEventStyles.detailValue,
          ),
        ),
      ],
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              const TextSpan(text: 'My ', style: MemberEventStyles.pageTitle),
              TextSpan(
                text: 'Events',
                style: MemberEventStyles.pageTitle.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Manage your registrations and access event tickets.',
          style: MemberEventStyles.pageDescription,
        ),
        const SizedBox(height: AppSpacing.sm),
        const AppAccentBar(),
      ],
    );
  }
}
