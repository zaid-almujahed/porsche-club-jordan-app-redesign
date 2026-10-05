import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

/// Merchandise card used by the shop grid and the home "Popular Items" rail:
/// product shot on a dark vignette, bold name, price and a cart affordance.
class AppProductCard extends StatelessWidget {
  const AppProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.isAddingToCart = false,
  });

  final Product product;
  final VoidCallback onTap;

  /// Quick add from the card. When null the cart glyph is decorative.
  final VoidCallback? onAddToCart;
  final bool isAddingToCart;

  @override
  Widget build(BuildContext context) {
    final bool soldOut = !product.isInStock;
    final String? tag = soldOut ? 'Sold Out' : product.badge;

    return Semantics(
      button: true,
      label: 'View ${product.name}',
      child: AppPressable(
        child: Material(
          color: AppColors.panelDark,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(AppRadii.large),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, -0.15),
                            radius: 0.9,
                            colors: <Color>[
                              Color(0xFF2A2A30),
                              Color(0xFF111114),
                            ],
                          ),
                        ),
                      ),
                      SoldOutShade(
                        soldOut: soldOut,
                        child: AppAssetImage(
                          path: product.primaryImageUrl ?? '',
                          fallbackIcon: Icons.checkroom_rounded,
                        ),
                      ),
                      if (tag != null && tag.trim().isNotEmpty)
                        Positioned(
                          top: AppSpacing.sm,
                          left: AppSpacing.sm,
                          child: AppTagPill(
                            label: tag,
                            color: product.isInStock
                                ? AppColors.accentSteel
                                : const Color(0xFF3A3A40),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF141417),
                    border: Border(
                      top: BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.title.copyWith(
                                fontSize: 15,
                                color: soldOut ? AppColors.textMuted : null,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              AppFormatters.money(
                                product.price,
                                product.currency,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.numeric.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: soldOut
                                    ? AppColors.textFaint
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _AddToCartButton(
                        enabled: product.isInStock,
                        isLoading: isAddingToCart,
                        onPressed: onAddToCart,
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

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({
    required this.enabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool enabled;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && onPressed != null && !isLoading;
    return Tooltip(
      message: 'Add to cart',
      child: Material(
        // A faint red tint marks it as tappable without shouting.
        color: active ? const Color(0x24D5001C) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.small + 2),
          side: BorderSide(
            color: active
                ? AppColors.primary.withValues(alpha: 0.55)
                : const Color(0x33FFFFFF),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: active ? onPressed : null,
          child: SizedBox.square(
            dimension: 38,
            child: Center(
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                layoutBuilder: AppMotion.switcherLayout,
                child: isLoading
                    ? const SizedBox.square(
                        key: ValueKey<String>('adding'),
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : Icon(
                        Icons.add_shopping_cart_rounded,
                        key: const ValueKey<String>('add'),
                        size: 19,
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textFaint,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
