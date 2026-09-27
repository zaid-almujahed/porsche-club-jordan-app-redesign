import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/home_feed.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/home_controller.dart';
import '../widgets/event_season_list.dart';
import '../widgets/offer_tiles.dart';
import '../widgets/popular_shop_items.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    this.user,
    this.unreadNotificationCount,
  });

  final HomeController controller;
  final User? user;
  final ValueListenable<int>? unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.canvas,
      appBar: PorscheAppBar(
        title: 'Home',
        showNotifications: true,
        unreadNotificationCount: unreadNotificationCount,
        onNotificationsPressed: () => context.push(AppRoutes.notifications),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            bottomPadding:
                AppLayout.navigationBarHeight + AppSpacing.pageBottom,
            onRefresh: () => controller.load(force: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppFadeSlideIn(child: _Greeting(user: user)),
                const SizedBox(height: AppSpacing.section),
                AsyncStateView<HomeFeed>(
                  state: controller.state,
                  onRetry: () => controller.load(force: true),
                  builder: (BuildContext context, HomeFeed feed) {
                    return _HomeFeedContent(feed: feed);
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

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final bool isActive = user?.membershipStatus == MembershipStatus.active;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Welcome back,',
                style: AppTextStyles.body.copyWith(fontSize: 17),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                user?.name ?? 'Member',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
              ),
              if (isActive) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                const StatusBadge(
                  label: 'Active Member',
                  color: AppColors.success,
                  icon: Icons.verified_user_rounded,
                ),
              ],
            ],
          ),
        ),
        if (user != null) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: AppColors.primaryGlow, blurRadius: 16),
              ],
            ),
            child: AppAssetImage(
              path: user!.avatarUrl ?? '',
              borderRadius: BorderRadius.circular(AppRadii.pill),
              fallbackIcon: Icons.person_outline_rounded,
            ),
          ),
        ],
      ],
    );
  }
}

class _HomeFeedContent extends StatelessWidget {
  const _HomeFeedContent({required this.feed});

  final HomeFeed feed;

  @override
  Widget build(BuildContext context) {
    int section = 0;
    Widget reveal(Widget child) => AppFadeSlideIn.stagger(
      index: section++,
      step: const Duration(milliseconds: 90),
      child: child,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (feed.featuredEvent != null) ...<Widget>[
          reveal(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SectionTitleRow(title: 'Featured Event'),
                const SizedBox(height: AppSpacing.md),
                FeaturedEvent(
                  event: feed.featuredEvent!,
                  onPressed: () => context.push(
                    AppRoutes.eventDetailsLocation(feed.featuredEvent!.id),
                    extra: feed.featuredEvent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section + 4),
        ],
        reveal(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionTitleRow(
                title: 'This Season',
                actionLabel: 'All Events ›',
                onActionPressed: () => context.go(AppRoutes.events),
              ),
              const SizedBox(height: AppSpacing.md),
              if (feed.seasonEvents.isEmpty)
                const _EmptySection(label: 'No upcoming events.')
              else
                ThisSeasonList(events: feed.seasonEvents),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section + 4),
        reveal(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionTitleRow(
                title: 'Popular Items',
                actionLabel: 'Visit Shop ›',
                onActionPressed: () => context.go(AppRoutes.shop),
              ),
              const SizedBox(height: AppSpacing.md),
              if (feed.popularProducts.isEmpty)
                const _EmptySection(label: 'No popular items.')
              else
                PopularItems(products: feed.popularProducts),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section + 4),
        reveal(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SectionTitleRow(
                title: 'Exclusive Offers',
                actionLabel: 'All Offers ›',
                onActionPressed: () => context.go(AppRoutes.offers),
              ),
              const SizedBox(height: AppSpacing.md),
              if (feed.featuredOffers.isEmpty)
                const _EmptySection(label: 'No featured offers.')
              else
                for (
                  int index = 0;
                  index < feed.featuredOffers.length;
                  index++
                ) ...<Widget>[
                  OfferTile(
                    offer: feed.featuredOffers[index],
                    onTap: () => context.go(AppRoutes.offers),
                  ),
                  if (index != feed.featuredOffers.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.panelDark,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.hourglass_empty_rounded,
            size: 18,
            color: AppColors.textFaint,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
