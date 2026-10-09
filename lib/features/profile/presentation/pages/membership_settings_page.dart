import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/membership_controller.dart';
import '../widgets/member_card.dart';

class MembershipSettingsPage extends StatelessWidget {
  const MembershipSettingsPage({
    super.key,
    required this.controller,
    required this.memberName,
  });

  final MembershipController controller;

  /// The signed-in member, shown on their card.
  final String memberName;

  /// Within this many days of the end date the membership is shown as
  /// expiring soon. Renewing is only possible once it has expired, from the
  /// renewal page the member is taken to.
  static const int renewalWindowDays = 14;

  static int? daysLeft(Membership membership) {
    final DateTime? end = membership.validUntil;
    if (end == null) return null;
    return DateUtils.dateOnly(
      end,
    ).difference(DateUtils.dateOnly(DateTime.now())).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      extendBodyBehindAppBar: true,
      appBar: const PorscheAppBar(title: 'Membership Status', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) => AppPageBody(
          topPadding: AppSpacing.xl,
          bottomPadding: 140,
          onRefresh: () => controller.load(force: true),
          child: AsyncStateView<Membership>(
            state: controller.state,
            onRetry: () => controller.load(force: true),
            builder: (BuildContext context, Membership membership) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppFadeSlideIn(child: _ValidityPanel(membership: membership)),
                  const SizedBox(height: AppSpacing.lg),
                  AppFadeSlideIn(
                    delay: const Duration(milliseconds: 90),
                    child: _MembershipCardPanel(
                      memberName: memberName,
                      memberId: membership.memberId,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// "Valid until" card: the end date on one line, a ring showing how much of
/// the membership year is left, and the member-since date. The ring turns
/// amber in the last two weeks and red once expired.
class _ValidityPanel extends StatelessWidget {
  const _ValidityPanel({required this.membership});

  final Membership membership;

  /// Share of the membership period still remaining (0–1).
  double get _remaining {
    final DateTime? start = membership.startDate;
    final DateTime? end = membership.validUntil;
    if (end == null) return 0;
    if (start == null || !end.isAfter(start)) {
      return DateTime.now().isBefore(end) ? 1 : 0;
    }
    final double total = end.difference(start).inMinutes.toDouble();
    final double left = end.difference(DateTime.now()).inMinutes.toDouble();
    return (left / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final int? daysLeft = MembershipSettingsPage.daysLeft(membership);
    final bool isExpired =
        membership.status == MembershipStatus.expired ||
        (daysLeft != null && daysLeft < 0);
    final bool isRenewalOpen =
        !isExpired &&
        daysLeft != null &&
        daysLeft <= MembershipSettingsPage.renewalWindowDays;

    final Color statusColor = switch (membership.status) {
      MembershipStatus.active => AppColors.success,
      MembershipStatus.inactive => AppColors.warning,
      MembershipStatus.expired => AppColors.danger,
      MembershipStatus.suspended => AppColors.danger,
    };
    final Color ringColor = isExpired
        ? AppColors.danger
        : isRenewalOpen
        ? AppColors.warning
        : AppColors.success;

    return DecoratedBox(
      decoration: _MembershipStyles.validityDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: StatusBadge(
                    label: '${membership.status.name} member',
                    color: statusColor,
                    icon: membership.status == MembershipStatus.active
                        ? Icons.verified_user_rounded
                        : Icons.info_outline_rounded,
                  ),
                ),
                if (isRenewalOpen) ...<Widget>[
                  const SizedBox(width: AppSpacing.xs),
                  const StatusBadge(
                    label: 'Expires soon',
                    color: AppColors.warning,
                    icon: Icons.autorenew_rounded,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('VALID UNTIL', style: AppTextStyles.overline),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          membership.validUntil == null
                              ? 'Pending'
                              : AppFormatters.date(membership.validUntil!),
                          maxLines: 1,
                          style: _MembershipStyles.validity,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        membership.startDate == null
                            ? 'Annual membership'
                            : 'Member since '
                                  '${AppFormatters.date(membership.startDate!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _DaysLeftRing(
                  value: _remaining,
                  daysLeft: daysLeft,
                  isExpired: isExpired,
                  color: ringColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DaysLeftRing extends StatelessWidget {
  const _DaysLeftRing({
    required this.value,
    required this.daysLeft,
    required this.isExpired,
    required this.color,
  });

  final double value;
  final int? daysLeft;
  final bool isExpired;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final int days = daysLeft == null ? 0 : daysLeft!.clamp(0, 9999);
    return SizedBox.square(
      dimension: 84,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double progress, Widget? child) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: const Color(0x1AFFFFFF),
                color: color,
              ),
              child!,
            ],
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  daysLeft == null ? '—' : '$days',
                  style: AppTextStyles.numeric.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isExpired
                    ? 'EXPIRED'
                    : days == 1
                    ? 'DAY LEFT'
                    : 'DAYS LEFT',
                style: AppTextStyles.overline.copyWith(
                  fontSize: 8.5,
                  letterSpacing: 0.8,
                  color: isExpired ? AppColors.danger : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipCardPanel extends StatelessWidget {
  const _MembershipCardPanel({
    required this.memberName,
    required this.memberId,
  });

  final String memberName;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: _MembershipStyles.membershipPanelDecoration,
      child: MemberCard(memberName: memberName, memberId: memberId),
    );
  }
}

abstract final class _MembershipStyles {
  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1B1B1F), Color(0xFF131316)],
  );

  static const BoxDecoration validityDecoration = BoxDecoration(
    gradient: panelGradient,
    border: Border.fromBorderSide(BorderSide(color: AppColors.cardBorder)),
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.large)),
  );

  static const BoxDecoration membershipPanelDecoration = BoxDecoration(
    color: AppColors.panelDark,
    border: Border.fromBorderSide(BorderSide(color: AppColors.cardBorder)),
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.large)),
  );

  static const TextStyle validity = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );
}
