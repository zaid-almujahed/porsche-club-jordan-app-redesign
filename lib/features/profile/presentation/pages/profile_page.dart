import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v4/core/routing/app_router.dart';
import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/shared/domain/entities/user.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

import '../controllers/profile_controller.dart';
import '../widgets/profile_page_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.controller,
    required this.onLogOut,
    this.onSupportPressed,
    this.unreadNotificationCount,
  });

  final ProfileController controller;
  final Future<void> Function() onLogOut;
  final VoidCallback? onSupportPressed;
  final ValueListenable<int>? unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.canvas,
      appBar: PorscheAppBar(
        title: 'Profile',
        showNotifications: true,
        unreadNotificationCount: unreadNotificationCount,
        onNotificationsPressed: () => context.push(AppRoutes.notifications),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            topPadding: AppSpacing.xl,
            bottomPadding:
                AppLayout.navigationBarHeight + AppSpacing.pageBottom,
            onRefresh: () => controller.load(force: true),
            child: AsyncStateView<User>(
              state: controller.profile,
              onRetry: () => controller.load(force: true),
              builder: (BuildContext context, User user) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppFadeSlideIn(
                      child: ProfileMemberCard(
                        user: user,
                        onEditPressed: () =>
                            context.push(AppRoutes.profileEdit),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppFadeSlideIn(
                      delay: const Duration(milliseconds: 90),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: ProfileFeatureCard(
                              icon: Icons.receipt_long_outlined,
                              title: 'Order History',
                              subtitle: 'Marketplace purchases and tracking',
                              backgroundIcon: Icons.shopping_bag_outlined,
                              onTap: () => context.push(AppRoutes.userOrders),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: ProfileFeatureCard(
                              icon: Icons.confirmation_number_outlined,
                              title: 'My Events',
                              subtitle: 'Access QR codes and tickets',
                              backgroundIcon:
                                  Icons.confirmation_number_outlined,
                              accentColor: AppColors.accentSteel,
                              onTap: () => context.push(AppRoutes.userEvents),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    AppFadeSlideIn(
                      delay: const Duration(milliseconds: 180),
                      child: AccountOptionsPanel(
                        onMembershipPressed: () =>
                            context.push(AppRoutes.membershipSettings),
                        onSettingsPressed: () =>
                            context.push(AppRoutes.accountSettings),
                        onSupportPressed: onSupportPressed ?? () {},
                        onLogOutPressed: () async {
                          await onLogOut();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
