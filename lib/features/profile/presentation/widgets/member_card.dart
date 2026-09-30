import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

/// The digital club card: brand, the member's name and member ID. An
/// [isExpired] card is dimmed and stamped "Expired".
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.memberName,
    required this.memberId,
    this.isExpired = false,
  });

  final String memberName;
  final String memberId;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    final Widget content = Padding(
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
                    Text('PORSCHE', style: _MemberCardStyles.brand),
                    SizedBox(height: 2),
                    Text('Club Jordan', style: _MemberCardStyles.clubName),
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
                child: _CardValue(label: 'MEMBER NAME', value: memberName),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: _CardValue(
                    label: 'MEMBER ID',
                    value: memberId,
                    compact: true,
                    alignEnd: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      height: 196,
      clipBehavior: Clip.antiAlias,
      decoration: _MemberCardStyles.decoration,
      child: CustomPaint(
        painter: const AppCornerSlashPainter(),
        child: isExpired
            ? Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Opacity(opacity: 0.45, child: content),
                  const Center(child: _ExpiredStamp()),
                ],
              )
            : content,
      ),
    );
  }
}

class _ExpiredStamp extends StatelessWidget {
  const _ExpiredStamp();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -8 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.small),
          border: Border.all(color: AppColors.danger, width: 2),
          color: const Color(0x33000000),
        ),
        child: Text(
          'EXPIRED',
          style: AppTextStyles.overline.copyWith(
            color: AppColors.danger,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
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
        Text(label, style: _MemberCardStyles.label),
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
                style: _MemberCardStyles.id,
              ),
            ),
          )
        else
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: _MemberCardStyles.name,
          ),
      ],
    );
  }
}

abstract final class _MemberCardStyles {
  static const BoxDecoration decoration = BoxDecoration(
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

  static const TextStyle label = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 1.4,
  );

  static const TextStyle name = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle id = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1,
    letterSpacing: 1,
    fontFeatures: AppTextStyles.tabularFigures,
  );
}
