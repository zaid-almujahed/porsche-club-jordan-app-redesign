import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';
import 'package:pcj_v5/shared/widgets/app_search_field.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/shop_controller.dart';
import '../widgets/product_page_widgets.dart';

class ShopMainPage extends StatelessWidget {
  const ShopMainPage({
    super.key,
    required this.controller,
    this.unreadNotificationCount,
  });

  final ShopController controller;
  final ValueListenable<int>? unreadNotificationCount;

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
        onCartPressed: () => context.push(AppRoutes.checkout),
        onNotificationsPressed: () => context.push(AppRoutes.notifications),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
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
                // if (controller.categories.isNotEmpty)
                //   _ShopCategories(
                //     categories: controller.categories,
                //     selectedCategory: controller.selectedCategory,
                //     onSelected: controller.selectCategory,
                //   ),
                // const SizedBox(height: 36),
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