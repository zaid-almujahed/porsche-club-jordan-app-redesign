import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/offer.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

class OfferCategories extends StatelessWidget {
  const OfferCategories({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(categories.length > 0);

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppFilterChips(
      labels: categories,
      selectedIndex: selectedIndex,
      onSelected: onSelected,
    );
  }
}

class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.isClaiming = false,
  });

  final Offer offer;
  final VoidCallback? onTap;
  final bool isClaiming;

  @override
  Widget build(BuildContext context) {
    final String footer = offer.location.trim().isNotEmpty
        ? offer.location
        : offer.expiryDate == null
        ? 'Member exclusive'
        : 'Valid until ${AppFormatters.date(offer.expiryDate!)}';

    return AppPressable(
      enabled: onTap != null && !isClaiming,
      child: Material(
        color: AppColors.panelDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: offer.isClaimed
                ? AppColors.cardBorder
                : AppColors.primary.withValues(alpha: 0.45),
          ),
          borderRadius: BorderRadius.circular(AppRadii.large),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isClaiming ? null : onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 2.15,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _OfferHeaderArt(offer: offer),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[Color(0x00000000), Color(0x99111114)],
                          stops: <double>[0.45, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC050507),
                          border: Border.all(color: AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.sell_rounded,
                              size: 14,
                              color: AppColors.accentGold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isClaiming ? 'CLAIMING...' : offer.badgeLabel,
                              style: AppTextStyles.label.copyWith(
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        // The logo now fills the header; no small copy here
                        // unless the header shows a photo instead.
                        if (offer.imageUrl.trim().isNotEmpty &&
                            offer.logoUrl != null &&
                            offer.logoUrl!.trim().isNotEmpty) ...<Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceRaised,
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: AppAssetImage(
                              path: offer.logoUrl!,
                              fit: BoxFit.contain,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                              fallbackIcon: Icons.storefront_outlined,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                offer.title,
                                style: AppTextStyles.sectionTitle.copyWith(
                                  fontSize: 19,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                offer.partnerName,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.primaryBright,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(offer.description, style: AppTextStyles.body),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(color: AppColors.cardBorder),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        Icon(
                          offer.location.trim().isNotEmpty
                              ? Icons.location_on_outlined
                              : Icons.event_available_outlined,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            footer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AnimatedSwitcher(
                          duration: AppMotion.medium,
                          layoutBuilder: AppMotion.switcherLayout,
                          child: isClaiming
                              ? const SizedBox.square(
                                  key: ValueKey<String>('claiming'),
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : offer.isClaimed
                              ? const StatusBadge(
                                  key: ValueKey<String>('claimed'),
                                  label: 'Claimed',
                                  color: AppColors.success,
                                  icon: Icons.check_rounded,
                                )
                              : Row(
                                  key: const ValueKey<String>('claim'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      'TAP TO CLAIM',
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.primaryBright,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: AppColors.primaryBright,
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Offer header art: the offer photo when there is one, otherwise the
/// partner logo on a blurred wash of its own colours.
class _OfferHeaderArt extends StatelessWidget {
  const _OfferHeaderArt({required this.offer});

  final Offer offer;

  @override
  Widget build(BuildContext context) {
    final String logo = offer.logoUrl?.trim() ?? '';
    if (offer.imageUrl.trim().isNotEmpty || logo.isEmpty) {
      return AppAssetImage(
        path: offer.imageUrl,
        fallbackIcon: Icons.local_offer_outlined,
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // The logo, enlarged and blurred, tints the header with its colours.
        ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Transform.scale(
              scale: 1.8,
              child: AppAssetImage(path: logo),
            ),
          ),
        ),
        const ColoredBox(color: Color(0xB30A0A0C)),
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.5,
            heightFactor: 0.62,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.medium + 2),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: AppAssetImage(
                path: logo,
                fit: BoxFit.contain,
                fallbackIcon: Icons.storefront_outlined,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
