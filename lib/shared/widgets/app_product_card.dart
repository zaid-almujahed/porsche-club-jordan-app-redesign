import 'package:flutter/material.dart';

import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/core/utils/app_formatters.dart';
import 'package:pcj_v4/shared/domain/entities/product.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

/// Merchandise card used by the shop grid and the home "Popular Items" rail:
/// product shot on a dark vignette, bold name, price and a cart affordance.
class AppProductCard extends StatelessWidget {
  const AppProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? tag = !product.isInStock ? 'Out of stock' : product.badge;

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
                      AppAssetImage(
                        path: product.primaryImageUrl ?? '',
                        fallbackIcon: Icons.checkroom_rounded,
                      ),
                      if (tag != null && tag.trim().isNotEmpty)
                        Positioned(
                          top: AppSpacing.sm,
                          left: AppSpacing.sm,
                          child: AppTagPill(
                            label: tag,
                            color: product.isInStock
                                ? AppColors.primary
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
                              style: AppTextStyles.title.copyWith(fontSize: 15),
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
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppRadii.small + 2,
                          ),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 19,
                          color: AppColors.textPrimary,
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
