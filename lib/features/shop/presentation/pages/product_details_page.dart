import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/product_details_controller.dart';
import '../widgets/product_details_widgets.dart';

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({
    super.key,
    required this.controller,
    required this.onAddedToCart,
    this.cartItemCount,
    this.onCartPressed,
  });

  final ProductDetailsController controller;
  final ValueChanged<Cart> onAddedToCart;
  final ValueListenable<int>? cartItemCount;
  final VoidCallback? onCartPressed;

  Future<void> _addToCart(BuildContext context) async {
    final Cart? cart = await controller.addToCart();
    if (!context.mounted) return;
    if (cart == null) {
      final Object? error = controller.cartError;
      if (error != null) showAppErrorPulse(context, error);
      return;
    }
    // The member stays on this page; a short animation confirms the add and
    // the cart badge in the app bar updates.
    showAppSuccessPulse(context, label: 'Added to Cart');
    onAddedToCart(cart);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final Product? product = controller.state.data;
        final bool canPurchase = controller.selectedVariant != null;
        return Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: PorscheAppBar(
            title: 'Shop',
            showBack: true,
            showCart: onCartPressed != null,
            cartItemCount: cartItemCount,
            onCartPressed: onCartPressed,
          ),
          bottomNavigationBar: product == null
              ? null
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.appBar,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                      child: Row(
                        children: <Widget>[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'PRICE',
                                style: AppTextStyles.overline,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppFormatters.money(
                                  controller.selectedPrice,
                                  product.currency,
                                ),
                                style: AppTextStyles.numeric.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: canPurchase
                                ? PrimaryActionButton(
                                    label: 'Add to Cart',
                                    isLoading: controller.isAddingToCart,
                                    onPressed: controller.isAddingToCart
                                        ? null
                                        : () => _addToCart(context),
                                    height: 56,
                                  )
                                : const SecondaryActionButton(
                                    label: 'Out of Stock',
                                    height: 56,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          body: AppPageBody(
            topPadding: AppSpacing.lg,
            onRefresh: controller.refresh,
            child: AsyncStateView<Product>(
              state: controller.state,
              onRetry: controller.refresh,
              builder: (BuildContext context, Product product) {
                final String selectedImage = product.imageUrls.isEmpty
                    ? ''
                    : product.imageUrls[controller.selectedImageIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppFadeSlideIn(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppRadii.large + 4,
                            ),
                            border: Border.all(color: AppColors.cardBorder),
                            gradient: const RadialGradient(
                              center: Alignment(0, -0.1),
                              radius: 0.85,
                              colors: <Color>[
                                Color(0xFF2A2A30),
                                Color(0xFF111114),
                              ],
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: AppMotion.medium,
                            layoutBuilder: AppMotion.switcherLayout,
                            child: AppAssetImage(
                              key: ValueKey<String>(selectedImage),
                              path: selectedImage,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(AppRadii.large + 3),
                              ),
                              fallbackIcon: Icons.checkroom_rounded,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (product.imageUrls.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      ProductThumbnails(
                        images: product.imageUrls,
                        selectedIndex: controller.selectedImageIndex,
                        onSelected: controller.selectImage,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppFadeSlideIn(
                      delay: const Duration(milliseconds: 90),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            product.name,
                            style: AppTextStyles.pageTitle.copyWith(
                              fontSize: 30,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            AppFormatters.money(
                              controller.selectedPrice,
                              product.currency,
                            ),
                            style: AppTextStyles.numeric.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (product.description.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(color: AppColors.cardBorder),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        product.description,
                        style: AppTextStyles.body.copyWith(fontSize: 15.5),
                      ),
                    ],
                    if (controller.availableColors.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      ColorSelector(
                        colors: controller.availableColors,
                        selectedColor: controller.selectedColor,
                        onSelected: controller.selectColor,
                      ),
                    ],
                    if (controller.availableSizes.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xl),
                      SizeSelector(
                        sizes: controller.availableSizes,
                        selectedSize: controller.selectedSize,
                        onSelected: controller.selectSize,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    QuantitySelector(
                      quantity: controller.quantity,
                      enabled: canPurchase,
                      canIncrement:
                          controller.quantity < controller.maximumQuantity,
                      onIncrement: controller.incrementQuantity,
                      onDecrement: controller.decrementQuantity,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
