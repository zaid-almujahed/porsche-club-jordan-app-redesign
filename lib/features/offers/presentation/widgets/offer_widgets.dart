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

/// An offer as a ticket: a stub with the discount, then, past a
/// perforation, the partner, the offer and Claim.
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

  static const double _stubWidth = 104;
  static const EdgeInsets _detailsPadding = EdgeInsets.fromLTRB(16, 14, 14, 14);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The logo panel is as tall as the details are wide, so a square
        // logo gets a square; capped for wide screens.
        final double logoHeight =
            (constraints.maxWidth - _stubWidth - 1 - _detailsPadding.horizontal)
                .clamp(0, 240)
                .toDouble();
        return _buildCard(logoHeight);
      },
    );
  }

  Widget _buildCard(double logoHeight) {
    final String footer = offer.location.trim().isNotEmpty
        ? offer.location
        : offer.expiryDate == null
        ? 'Member exclusive'
        : 'Ends ${AppFormatters.date(offer.expiryDate!)}';
    final bool hasLogo = offer.logoUrl?.trim().isNotEmpty ?? false;

    return AppPressable(
      enabled: onTap != null && !isClaiming,
      child: Material(
        color: AppColors.panelDark,
        shape: const _TicketBorder(
          stubWidth: _stubWidth,
          side: BorderSide(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isClaiming ? null : onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _DiscountStub(offer: offer, width: _stubWidth),
                const SizedBox(
                  width: 1,
                  child: CustomPaint(painter: _PerforationPainter()),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _PartnerLogo(offer: offer, height: logoHeight),
                      Padding(
                        padding: _detailsPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // A logo that is only a mark still needs the name.
                            if (hasLogo) ...<Widget>[
                              Text(
                                offer.displayPartnerName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.textMuted,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              offer.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.title,
                            ),
                            if (offer.description
                                .trim()
                                .isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                offer.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    footer,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12,
                                    ),
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
                                      : const _ClaimLabel(
                                          key: ValueKey<String>('claim'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The ticket's stub: the discount, or a member perk when there is none.
/// It dims while the offer reads as claimed.
class _DiscountStub extends StatelessWidget {
  const _DiscountStub({required this.offer, required this.width});

  final Offer offer;
  final double width;

  @override
  Widget build(BuildContext context) {
    final double? discount = offer.discountRate;
    return AnimatedContainer(
      duration: AppMotion.medium,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: offer.isClaimed
              ? const <Color>[Color(0xFF1C1C20), Color(0xFF141417)]
              : const <Color>[Color(0xFF26262B), Color(0xFF151518)],
        ),
      ),
      child: AnimatedOpacity(
        duration: AppMotion.medium,
        opacity: offer.isClaimed ? 0.45 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: discount == null
              ? <Widget>[
                  const Icon(
                    Icons.card_giftcard_rounded,
                    size: 28,
                    color: AppColors.accentGold,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'MEMBER\nPERK',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.accentGold,
                      height: 1.3,
                      letterSpacing: 1.5,
                    ),
                  ),
                ]
              : <Widget>[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${discount.toStringAsFixed(0)}%',
                      style: AppTextStyles.display.copyWith(
                        fontSize: 32,
                        height: 1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'OFF',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primaryBright,
                      letterSpacing: 3,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

/// The partner's logo on a white tile over a blurred wash of its own
/// colours, filling its side of the ticket edge to edge; without one, the
/// partner's name in its place.
class _PartnerLogo extends StatelessWidget {
  const _PartnerLogo({required this.offer, required this.height});

  final Offer offer;
  final double height;

  @override
  Widget build(BuildContext context) {
    final String logo = offer.logoUrl?.trim() ?? '';
    final String name = offer.displayPartnerName;
    if (logo.isNotEmpty) {
      return SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // The logo, enlarged and blurred, tints the panel with its
            // colours.
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
                widthFactor: 0.8,
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
        ),
      );
    }
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.md),
      alignment: Alignment.center,
      color: AppColors.surfaceRaised,
      child: name.isEmpty
          ? const Icon(
              Icons.storefront_outlined,
              size: 38,
              color: AppColors.textMuted,
            )
          : Text(
              name.toUpperCase(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 20,
                letterSpacing: 1.2,
                height: 1.25,
              ),
            ),
    );
  }
}

/// Claim: the card's one red accent. The whole card is the button.
class _ClaimLabel extends StatelessWidget {
  const _ClaimLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.primaryBright, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: AppColors.primaryGlow, blurRadius: 10),
        ],
      ),
      child: Text(
        'CLAIM',
        style: AppTextStyles.label.copyWith(
          color: Colors.white,
          fontSize: 11.5,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// A rounded card with a notch cut into its top and bottom edges where
/// the stub tears off.
class _TicketBorder extends ShapeBorder {
  const _TicketBorder({required this.stubWidth, this.side = BorderSide.none});

  final double stubWidth;
  final BorderSide side;

  static const double _notchRadius = 11;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  Path _path(Rect rect) {
    final Path card = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(AppRadii.large)),
      );
    final double x = rect.left + stubWidth;
    final Path notches = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(x, rect.top), radius: _notchRadius),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(x, rect.bottom), radius: _notchRadius),
      );
    return Path.combine(PathOperation.difference, card, notches);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) =>
      _TicketBorder(stubWidth: stubWidth, side: side.scale(t));
}

/// The dashed line between the stub and the offer, clear of the notches.
class _PerforationPainter extends CustomPainter {
  const _PerforationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x40FFFFFF)
      ..strokeWidth = 1;
    for (double y = 16; y < size.height - 16; y += 9) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 5), paint);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter oldDelegate) => false;
}
