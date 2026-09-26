import 'package:flutter/material.dart';
import 'package:pcj_v4/shared/domain/entities/product.dart';
import 'package:pcj_v4/shared/widgets/app_product_card.dart';

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Shared with the home "Popular Items" rail so both read as one system.
    return AppProductCard(product: product, onTap: onTap);
  }
}
