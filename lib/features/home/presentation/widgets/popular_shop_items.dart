import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v4/core/routing/app_router.dart';
import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/shared/domain/entities/product.dart';
import 'package:pcj_v4/shared/widgets/app_product_card.dart';

class PopularItems extends StatelessWidget {
  const PopularItems({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
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
                child: _HomeProductCard(product: product),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeProductCard extends StatelessWidget {
  const _HomeProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return AppProductCard(
      product: product,
      onTap: () => context.push(
        AppRoutes.productDetailsLocation(product.id),
        extra: product,
      ),
    );
  }
}
