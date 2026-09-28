import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/shared/domain/entities/offer.dart';
import 'package:pcj_v5/shared/widgets/app_search_field.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/offers_controller.dart';
import '../widgets/offer_widgets.dart';

class PartnerOffersPage extends StatelessWidget {
  const PartnerOffersPage({
    super.key,
    required this.controller,
    this.unreadNotificationCount,
  });

  final OffersController controller;
  final ValueListenable<int>? unreadNotificationCount;

  Future<void> _claim(BuildContext context, Offer offer) async {
    final bool claimed = await controller.claimOffer(offer);
    if (claimed && context.mounted) {
      showAppSuccessPulse(context, label: 'Claimed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.canvas,
      appBar: PorscheAppBar(
        title: 'Offers',
        showNotifications: true,
        unreadNotificationCount: unreadNotificationCount,
        onNotificationsPressed: () => context.push(AppRoutes.notifications),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          final int selectedIndex = controller.selectedCategory == null
              ? 0
              : controller.categories.indexOf(controller.selectedCategory!);

          return AppPageBody(
            bottomPadding:
                AppLayout.navigationBarHeight + AppSpacing.pageBottom,
            onRefresh: () => controller.load(force: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppFadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Partners & Offers',
                        style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Exclusive privileges for Porsche Club Jordan members.',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const AppAccentBar(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppSearchField(
                  controller: controller.searchController,
                  hintText: 'Search offers and partners',
                  onChanged: controller.search,
                  onClear: controller.clearSearch,
                ),
                if (controller.categories.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.lg),
                  OfferCategories(
                    categories: controller.categories,
                    selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                    onSelected: (int index) {
                      controller.selectCategory(controller.categories[index]);
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                if (controller.actionError != null) ...<Widget>[
                  AppInlineMessage.error(
                    readableError(controller.actionError!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AsyncStateView<List<Offer>>(
                  state: controller.offers,
                  onRetry: () => controller.load(force: true),
                  isEmpty: (List<Offer> offers) => offers.isEmpty,
                  emptyMessage: controller.hasSearchQuery
                      ? 'No offers match your search.'
                      : 'No offers are currently available.',
                  builder: (BuildContext context, List<Offer> offers) {
                    return Column(
                      children: <Widget>[
                        for (
                          int index = 0;
                          index < offers.length;
                          index++
                        ) ...<Widget>[
                          AppFadeSlideIn.stagger(
                            index: index,
                            child: OfferCard(
                              offer: offers[index],
                              isClaiming: controller.isClaiming(
                                offers[index].id,
                              ),
                              onTap: () => _claim(context, offers[index]),
                            ),
                          ),
                          if (index != offers.length - 1)
                            const SizedBox(height: AppSpacing.lg),
                        ],
                      ],
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
