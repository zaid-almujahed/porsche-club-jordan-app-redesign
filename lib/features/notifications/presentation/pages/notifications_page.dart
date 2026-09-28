import 'package:flutter/material.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/features/notifications/domain/entities/member_notification.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/notifications_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, required this.controller});

  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const PorscheAppBar(title: 'Notifications', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            topPadding: AppSpacing.xl,
            onRefresh: () => controller.load(force: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppFadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Stay up to date',
                        style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Get the latest updates about your membership, '
                        'orders, events and offers.',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: <Widget>[
                          const AppAccentBar(),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              '${controller.unreadCount} unread notification'
                              '${controller.unreadCount == 1 ? '' : 's'}',
                              style: AppTextStyles.caption,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: AppMotion.medium,
                            child: controller.unreadCount > 0
                                ? TextButton.icon(
                                    key: const ValueKey<String>('mark-all'),
                                    onPressed: controller.isMarkingAllRead
                                        ? null
                                        : controller.markAllAsRead,
                                    icon: const Icon(
                                      Icons.done_all_rounded,
                                      size: 18,
                                    ),
                                    label: AppButtonLabel(
                                      controller.isMarkingAllRead
                                          ? 'Marking All...'
                                          : 'Mark All as Read',
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey<String>('no-mark-all'),
                                    height: 40,
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _NotificationTabs(
                  showAll: controller.showAll,
                  unreadCount: controller.unreadCount,
                  onUnreadPressed: controller.showUnread,
                  onAllPressed: controller.showAllNotifications,
                ),
                if (controller.actionError != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  AppInlineMessage.error(
                    readableError(controller.actionError!),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AsyncStateView<List<MemberNotification>>(
                  state: controller.state,
                  onRetry: () => controller.load(force: true),
                  isEmpty: (List<MemberNotification> values) => values.isEmpty,
                  emptyMessage: controller.showAll
                      ? 'No notifications are available.'
                      : 'You are all caught up.',
                  builder:
                      (BuildContext context, List<MemberNotification> values) {
                        return Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: AppDecorations.panel(
                            radius: AppRadii.large,
                          ),
                          child: Column(
                            children: <Widget>[
                              for (
                                int index = 0;
                                index < values.length;
                                index++
                              ) ...<Widget>[
                                AppFadeSlideIn.stagger(
                                  index: index,
                                  child: _NotificationCard(
                                    notification: values[index],
                                    isMarkingRead: controller.isMarkingRead(
                                      values[index].id,
                                    ),
                                    onTap: () =>
                                        controller.markAsRead(values[index]),
                                  ),
                                ),
                                if (index != values.length - 1)
                                  const Divider(
                                    color: AppColors.cardBorder,
                                    height: 1,
                                  ),
                              ],
                            ],
                          ),
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

class _NotificationTabs extends StatelessWidget {
  const _NotificationTabs({
    required this.showAll,
    required this.onUnreadPressed,
    required this.onAllPressed,
    this.unreadCount = 0,
  });

  final bool showAll;
  final VoidCallback onUnreadPressed;
  final VoidCallback onAllPressed;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedTabs(
      labels: <String>[
        unreadCount > 0 ? 'Unread ($unreadCount)' : 'Unread',
        'All Notifications',
      ],
      selectedIndex: showAll ? 1 : 0,
      onSelected: (int index) {
        if (index == 0) {
          onUnreadPressed();
        } else {
          onAllPressed();
        }
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isMarkingRead,
    required this.onTap,
  });

  final MemberNotification notification;
  final bool isMarkingRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool unread = !notification.isRead;

    return Semantics(
      button: unread,
      label: unread ? 'Mark ${notification.title} as read' : null,
      child: Material(
        color: unread ? const Color(0x08FFFFFF) : Colors.transparent,
        child: InkWell(
          onTap: notification.isRead || isMarkingRead ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: _color.withValues(alpha: 0.22)),
                  ),
                  child: Icon(_icon, color: _color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        notification.title,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 16,
                          color: unread
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppFormatters.dateAndTime(notification.sentAt),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          color: AppColors.textFaint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        notification.message,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14.5,
                          color: unread
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                SizedBox(
                  width: 20,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: AnimatedSwitcher(
                      duration: AppMotion.medium,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) =>
                              ScaleTransition(scale: animation, child: child),
                      child: isMarkingRead
                          ? const SizedBox(
                              key: ValueKey<String>('marking'),
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBright,
                              ),
                            )
                          : unread
                          ? Container(
                              key: const ValueKey<String>('unread'),
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBright,
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.primaryGlow,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            )
                          : const Icon(
                              Icons.done_rounded,
                              key: ValueKey<String>('read'),
                              size: 16,
                              color: AppColors.textFaint,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (notification.type) {
    MemberNotificationType.event => Icons.event_available_outlined,
    MemberNotificationType.membership => Icons.verified_user_outlined,
    MemberNotificationType.marketplace => Icons.shopping_bag_outlined,
    MemberNotificationType.offer => Icons.local_offer_outlined,
    MemberNotificationType.system => Icons.campaign_outlined,
  };

  Color get _color => switch (notification.type) {
    MemberNotificationType.membership => AppColors.success,
    MemberNotificationType.event => AppColors.primaryBright,
    MemberNotificationType.marketplace => AppColors.warning,
    MemberNotificationType.offer => AppColors.accentSteel,
    MemberNotificationType.system => AppColors.textSecondary,
  };
}
