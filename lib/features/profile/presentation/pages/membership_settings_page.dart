import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/membership_controller.dart';

class MembershipSettingsPage extends StatelessWidget {
  const MembershipSettingsPage({super.key, required this.controller});

  final MembershipController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const PorscheAppBar(title: 'Membership', showBack: true),
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
                    child: _MembershipCardPanel(membership: membership),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  const Text(
                    'Manage Membership',
                    style: _MembershipStyles.manageTitle,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const AppAccentBar(),
                  const SizedBox(height: AppSpacing.md),
                  _RenewMembershipTile(
                    isLoading: controller.isRenewing,
                    onPressed: controller.isRenewing ? null : controller.renew,
                  ),
                  if (controller.renewalError != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    AppInlineMessage.error(
                      readableError(controller.renewalError!),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ValidityPanel extends StatelessWidget {
  const _ValidityPanel({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (membership.status) {
      MembershipStatus.active => AppColors.success,
      MembershipStatus.inactive => AppColors.warning,
      MembershipStatus.expired => AppColors.danger,
    };

    return DecoratedBox(
      decoration: _MembershipStyles.validityDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  StatusBadge(
                    label: '${membership.status.name} member',
                    color: statusColor,
                    icon: membership.status == MembershipStatus.active
                        ? Icons.verified_user_rounded
                        : Icons.info_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    membership.validUntil == null
                        ? 'Validity date pending'
                        : 'Valid until '
                              '${AppFormatters.date(membership.validUntil!)}',
                    style: _MembershipStyles.validity,
                  ),
                ],
              ),
            ),
            AppIconBadge(
              icon: Icons.event_available_rounded,
              color: statusColor,
              size: 48,
              iconSize: 24,
              circle: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipCardPanel extends StatelessWidget {
  const _MembershipCardPanel({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: _MembershipStyles.membershipPanelDecoration,
      child: Column(
        children: <Widget>[
          _DigitalMemberCard(membership: membership),
          const SizedBox(height: AppSpacing.xl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: AppScaleIn(
              begin: 0.92,
              duration: AppMotion.slow,
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x33FFFFFF),
                        blurRadius: 24,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: membership.qrToken.trim().isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.qr_code_2,
                              size: 64,
                              color: Colors.black,
                            ),
                          )
                        : QrImageView(
                            data: membership.qrToken,
                            version: QrVersions.auto,
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 18,
                  color: AppColors.primaryBright,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'SCAN TO VERIFY MEMBERSHIP',
                  textAlign: TextAlign.center,
                  style: _MembershipStyles.scanLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitalMemberCard extends StatelessWidget {
  const _DigitalMemberCard({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 196,
      clipBehavior: Clip.antiAlias,
      decoration: _MembershipStyles.digitalCardDecoration,
      child: CustomPaint(
        painter: const AppCornerSlashPainter(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('PORSCHE', style: _MembershipStyles.brand),
                        SizedBox(height: 2),
                        Text('Club Jordan', style: _MembershipStyles.clubName),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentGold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      size: 18,
                      color: AppColors.primaryBright,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Gold hairline — the card's single metallic flourish.
              Container(
                height: 1,
                width: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[AppColors.accentGold, Color(0x00C9A55C)],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: _CardValue(
                      label: 'MEMBER NAME',
                      value: membership.memberName,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: _CardValue(
                        label: 'MEMBER ID',
                        value: membership.memberId,
                        compact: true,
                        alignEnd: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardValue extends StatelessWidget {
  const _CardValue({
    required this.label,
    required this.value,
    this.compact = false,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool compact;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: _MembershipStyles.cardLabel),
        const SizedBox(height: 4),
        if (compact)
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
                style: _MembershipStyles.cardId,
              ),
            ),
          )
        else
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: _MembershipStyles.cardName,
          ),
      ],
    );
  }
}

class _RenewMembershipTile extends StatelessWidget {
  const _RenewMembershipTile({required this.isLoading, this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      enabled: onPressed != null,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: _MembershipStyles.renewDecoration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: DecoratedBox(
                      decoration: AppDecorations.iconBadge(AppColors.primary),
                      child: Center(
                        child: isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Icon(
                                Icons.autorenew_rounded,
                                size: 22,
                                color: AppColors.primaryBright,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          isLoading ? 'Renewing...' : 'Renew Membership',
                          style: _MembershipStyles.renewTitle,
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Extend your access for another year',
                          style: _MembershipStyles.renewDescription,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: AppColors.textMuted,
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

  static const BoxDecoration digitalCardDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFF1E1E22), Color(0xFF0A0A0C)],
    ),
    border: Border.fromBorderSide(BorderSide(color: Color(0x33C9A55C))),
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.large)),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x59000000),
        blurRadius: 22,
        spreadRadius: -6,
        offset: Offset(0, 10),
      ),
    ],
  );

  static const BoxDecoration renewDecoration = BoxDecoration(
    gradient: panelGradient,
    border: Border.fromBorderSide(BorderSide(color: AppColors.cardBorder)),
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.large)),
  );

  // Replaced by the shared StatusBadge pill.
  // static const TextStyle activeMember = TextStyle(
  //   fontFamily: AppTextStyles.fontFamily,
  //   color: AppColors.panel,
  //   fontSize: 12,
  //   fontWeight: FontWeight.w600,
  //   height: 1,
  //   letterSpacing: 1,
  // );

  static const TextStyle validity = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle brand = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: 5,
  );

  static const TextStyle clubName = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.accentGold,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 1.6,
  );

  static const TextStyle cardLabel = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 1.4,
  );

  static const TextStyle cardName = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle cardId = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: 1,
    fontFeatures: AppTextStyles.tabularFigures,
  );

  static const TextStyle scanLabel = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 1.4,
  );

  static const TextStyle manageTitle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static const TextStyle renewTitle = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle renewDescription = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
}
