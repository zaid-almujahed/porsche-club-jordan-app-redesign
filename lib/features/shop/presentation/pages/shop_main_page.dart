import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';
import 'package:pcj_v5/shared/widgets/app_search_field.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/checkout_controller.dart';
import '../controllers/shop_controller.dart';
import '../widgets/product_page_widgets.dart';
import '../widgets/quick_add_sheet.dart';

class ShopMainPage extends StatelessWidget {
  const ShopMainPage({
    super.key,
    required this.controller,
    this.unreadNotificationCount,
    this.cartController,
  });

  final ShopController controller;
  final ValueListenable<int>? unreadNotificationCount;

  /// Owns the member's cart: quick add from the grid and the badge count.
  final CheckoutController? cartController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.canvas,
      appBar: PorscheAppBar(
        title: 'Shop',
        showCart: true,
        showNotifications: true,
        unreadNotificationCount: unreadNotificationCount,
        cartItemCount: cartController?.itemCount,
        onCartPressed: () => context.push(AppRoutes.checkout),
        onNotificationsPressed: () => context.push(AppRoutes.notifications),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge(<Listenable?>[controller, cartController]),
        builder: (BuildContext context, Widget? child) {
          final CheckoutController? cart = cartController;
          return AppPageBody(
            topPadding: AppSpacing.lg,
            bottomPadding:
                AppLayout.navigationBarHeight + AppSpacing.pageBottom,
            onRefresh: () => controller.load(force: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSearchField(
                  controller: controller.searchController,
                  hintText: 'Search the shop',
                  onChanged: controller.search,
                  onClear: controller.clearSearch,
                ),
                const SizedBox(height: AppSpacing.lg),
                AsyncStateView<List<Product>>(
                  state: controller.products,
                  onRetry: () => controller.load(force: true),
                  isEmpty: (List<Product> products) => products.isEmpty,
                  emptyMessage: controller.hasSearchQuery
                      ? 'No products match your search.'
                      : 'No products are currently available.',
                  builder: (BuildContext context, List<Product> products) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.74,
                          ),
                      itemBuilder: (BuildContext context, int index) {
                        final Product product = products[index];
                        return AppFadeSlideIn.stagger(
                          index: index,
                          child: ProductTile(
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
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}