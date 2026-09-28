import 'package:flutter/material.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';
import 'package:pcj_v5/shared/widgets/app_product_card.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.isAddingToCart = false,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final bool isAddingToCart;

  @override
  Widget build(BuildContext context) {
    // Shared with the home "Popular Items" rail so both read as one system.
    return AppProductCard(
      product: product,
      onTap: onTap,
      onAddToCart: onAddToCart,
      isAddingToCart: isAddingToCart,
    );
  }
}
