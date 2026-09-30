import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

BoxDecoration profilePanelDecoration({
  required double radius,
  bool includeShadow = false,
}) {
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFF1B1B1F), Color(0xFF131316)],
    ),
    border: Border.all(color: AppColors.cardBorder),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: includeShadow
        ? const <BoxShadow>[
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 40,
              offset: Offset(0, 20),
              spreadRadius: -12,
            ),
          ]
        : null,
  );
}

class ProfileMemberCard extends StatelessWidget {
  const ProfileMemberCard({
    super.key,
    required this.user,
    required this.onEditPressed,
  });

  final User user;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final bool active = user.membershipStatus == MembershipStatus.active;
    final Color statusColor = switch (user.membershipStatus) {
      MembershipStatus.active => AppColors.success,
      MembershipStatus.inactive => AppColors.warning,
      MembershipStatus.expired => AppColors.danger,
      MembershipStatus.suspended => AppColors.danger,
    };
    final String statusLabel = switch (user.membershipStatus) {
      MembershipStatus.active => 'Active Member',
      MembershipStatus.inactive => 'Inactive',
      MembershipStatus.expired => 'Expired',
      MembershipStatus.suspended => 'Deactivated',
    };
    final String validity = user.membershipValidUntil == null
        ? 'Membership date unavailable'
        : 'Valid until ${AppFormatters.date(user.membershipValidUntil!)}';

    return DecoratedBox(
      decoration: AppDecorations.heroPanel(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.large),
        child: CustomPaint(
          painter: const AppCornerSlashPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 290;
                final double avatarSize = compact ? 72 : 88;
                final double editSize = compact ? 38 : 42;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: <Color>[
                                AppColors.primaryBright,
                                AppColors.primaryDeep,
                                AppColors.primaryBright,
                              ],
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.primaryGlow,
                                blurRadius: 22,
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.panelDark,
                            ),
                            child: AppAssetImage(
                              path: user.avatarUrl ?? '',
                              borderRadius: const BorderRadius.all(
                                Radius.circular(AppRadii.pill),
                              ),
                              fallbackIcon: Icons.person_outline_rounded,
                            ),
                          ),
                        ),
                        SizedBox(width: compact ? 10 : 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              StatusBadge(
                                label: statusLabel,
                                uppercase: false,
                                color: statusColor,
                                icon: active
                                    ? Icons.verified_user_rounded
                                    : Icons.info_outline_rounded,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                validity,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Semantics(
                          button: true,
                          label: 'Edit profile',
                          child: Material(
                            color: const Color(0x1AFFFFFF),
                            shape: const CircleBorder(
                              side: BorderSide(color: Color(0x33FFFFFF)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: onEditPressed,
                              child: SizedBox.square(
                                dimension: editSize,
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 19,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: _ProfileMemberValue(
                              label: 'MEMBER NAME',
                              value: user.name,
                            ),
                          ),
                          const VerticalDivider(
                            width: AppSpacing.xl,
                            color: Color(0x26FFFFFF),
                          ),
                          Expanded(
                            flex: 2,
                            child: _ProfileMemberValue(
                              label: 'ID NUMBER',
                              value: user.memberId ?? '—',
                              // Left-aligned after the divider, as in the
                              // profile reference.
                              alignEnd: false,
                              mutedValue: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMemberValue extends StatelessWidget {
  const _ProfileMemberValue({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.mutedValue = false,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final bool mutedValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text(label, style: AppTextStyles.overline),
        const SizedBox(height: 6),
        if (mutedValue)
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: alignEnd
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                style: AppTextStyles.numeric.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          )
        else
          Text(
            value,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.title.copyWith(fontSize: 19, height: 1.2),
          ),
      ],
    );
  }
}

class AccountOptionsPanel extends StatelessWidget {
  const AccountOptionsPanel({
    super.key,
    required this.onMembershipPressed,
    required this.onSettingsPressed,
    required this.onSupportPressed,
    required this.onLogOutPressed,
  });

  final VoidCallback onMembershipPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onSupportPressed;
  final VoidCallback onLogOutPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionTitleRow(title: 'Account Options'),
        const SizedBox(height: AppSpacing.md),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: profilePanelDecoration(radius: AppRadii.large),
          child: Column(
            children: <Widget>[
              AccountOptionTile(
                icon: Icons.workspace_premium_outlined,
                label: 'Membership Status',
                subtitle: 'View and manage your membership',
                accentColor: AppColors.accentGold,
                onTap: onMembershipPressed,
              ),
              AccountOptionTile(
                icon: Icons.settings_outlined,
                label: 'Account Settings',
                subtitle: 'Update your information and preferences',
                accentColor: AppColors.accentSteel,
                onTap: onSettingsPressed,
              ),
              AccountOptionTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                subtitle: 'Get help or contact our support team',
                accentColor: AppColors.accentTeal,
                onTap: onSupportPressed,
              ),
              AccountOptionTile(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                showDivider: false,
                isDestructive: true,
                onTap: onLogOutPressed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AccountOptionTile extends StatelessWidget {
  const AccountOptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
    this.subtitle,
    this.isDestructive = false,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;
  final String? subtitle;
  final bool isDestructive;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isDestructive
        ? AppColors.danger
        : accentColor ?? AppColors.primaryBright;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: AppColors.cardBorder))
                : null,
          ),
          child: Row(
            children: <Widget>[
              AppIconBadge(icon: icon, color: iconColor, size: 42),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label,
                      style: AppTextStyles.title.copyWith(
                        fontSize: 16,
                        color: isDestructive
                            ? AppColors.danger
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isDestructive)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileFeatureCard extends StatelessWidget {
  const ProfileFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundIcon,
    required this.onTap,
    this.accentColor = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData backgroundIcon;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final bool isBrand = accentColor == AppColors.primary;

    return AppPressable(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.large),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          // At least 214 tall, taller when larger text needs more room
          // (the page gives both cards the same height).
          decoration: AppDecorations.tintedPanel(accentColor),
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 214),
              child: Stack(
                children: <Widget>[
                  // Oversized watermark icon, as in the profile reference.
                  Positioned(
                    right: -14,
                    bottom: -14,
                    child: Transform.rotate(
                      angle: -0.35,
                      child: Icon(
                        backgroundIcon,
                        size: 104,
                        color: accentColor.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg - 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          icon,
                          color: isBrand
                              ? AppColors.primaryBright
                              : accentColor,
                          size: 30,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Shrinks to fit rather than cutting the title off.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            maxLines: 1,
                            style: AppTextStyles.title.copyWith(fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isBrand
                                ? AppColors.primary
                                : const Color(0x1FFFFFFF),
                            boxShadow: isBrand
                                ? const <BoxShadow>[
                                    BoxShadow(
                                      color: AppColors.primaryGlow,
                                      blurRadius: 14,
                                    ),
                                  ]
                                : null,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: Colors.white,
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
    );
  }
}
