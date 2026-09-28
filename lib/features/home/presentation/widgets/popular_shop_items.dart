import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/features/shop/presentation/controllers/checkout_controller.dart';
import 'package:pcj_v5/features/shop/presentation/widgets/quick_add_sheet.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';
import 'package:pcj_v5/shared/widgets/app_product_card.dart';

class PopularItems extends StatelessWidget {
  const PopularItems({super.key, required this.products, this.cartController});

  final List<Product> products;

  /// Enables quick add from the rail; the member stays on Home.
  final CheckoutController? cartController;

  @override
  Widget build(BuildContext context) {
    final CheckoutController? cart = cartController;
    if (cart == null) return _buildRail();
    return ListenableBuilder(
      listenable: cart,
      builder: (BuildContext context, Widget? child) => _buildRail(),
    );
  }

  Widget _buildRail() {
    return SizedBox(
      height: 262,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (BuildContext context, int index) {
              final Product product = products[index];
              return SizedBox(
                width: cardWidth,
                child: _HomeProductCard(
                  product: product,
                  cartController: cartController,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeProductCard extends StatelessWidget {
  const _HomeProductCard({required this.product, this.cartController});

  final Product product;
  final CheckoutController? cartController;

  @override
  Widget build(BuildContext context) {
    final CheckoutController? cart = cartController;
    return AppProductCard(
      product: product,
      onTap: () => context.push(
        AppRoutes.productDetailsLocation(product.id),
        extra: product,
      ),
      isAddingToCart: cart?.isAdding(product.id) ?? false,
      onAddToCart: cart == null
          ? null
          : () => quickAddToCart(
              context: context,
              product: product,
              controller: cart,
            ),
    );
  }
}
