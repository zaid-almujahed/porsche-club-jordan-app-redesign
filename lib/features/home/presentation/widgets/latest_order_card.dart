import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../../../user_orders/presentation/widgets/order_thumbnail.dart';

/// Home's "Track Your Order" card: the member's latest order in progress with
/// a step bar (pickup or delivery track) and what comes next.
class LatestOrderCard extends StatelessWidget {
  const LatestOrderCard({super.key, required this.order, this.onTap});

  final Order order;
  final VoidCallback? onTap;

  bool get _isPickupTrack =>
      order.isPickup || order.status == OrderStatus.readyForPickup;

  List<String> get _steps => _isPickupTrack
      ? const <String>['Pending', 'Processing', 'Ready for Pickup']
      : const <String>['Pending', 'Processing', 'Shipped', 'Delivered'];

  int get _reached => switch (order.status) {
    OrderStatus.pending => 0,
    OrderStatus.processing => 1,
    OrderStatus.readyForPickup => 2,
    OrderStatus.shipped => 2,
    OrderStatus.delivered => 3,
    OrderStatus.cancelled || OrderStatus.unknown => -1,
  };

  Color get _statusColor => switch (order.status) {
    OrderStatus.pending => AppColors.warning,
    OrderStatus.processing => AppColors.primaryBright,
    OrderStatus.readyForPickup => AppColors.success,
    OrderStatus.shipped => AppColors.accentSteel,
    OrderStatus.delivered => AppColors.success,
    OrderStatus.cancelled => AppColors.danger,
    OrderStatus.unknown => AppColors.textMuted,
  };

  String get _itemsTitle {
    if (order.items.isEmpty) return 'Marketplace order';
    final String first = order.items.first.product.name;
    final int more = order.items.length - 1;
    return more > 0 ? '$first +$more more' : first;
  }

  String? get _nextStep {
    final int next = _reached + 1;
    if (_reached < 0 || next >= _steps.length) return null;
    return _steps[next];
  }

  @override
  Widget build(BuildContext context) {
    final int reached = _reached;
    final String? next = _nextStep;

    return AppPressable(
      enabled: onTap != null,
      child: Material(
        color: AppColors.panelDark,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(AppRadii.large),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    OrderThumbnail(imagePaths: order.itemImagePaths, size: 52),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ORDER #${order.id}',
                            style: AppTextStyles.overline,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _itemsTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.title.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(label: order.status.label, color: _statusColor),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Segmented step bar.
                Row(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < _steps.length;
                      index++
                    ) ...<Widget>[
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: index <= reached ? 1 : 0,
                          ),
                          duration: Duration(milliseconds: 400 + index * 120),
                          curve: AppMotion.curve,
                          builder: (BuildContext context, double fill, _) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: fill,
                                minHeight: 4,
                                backgroundColor: const Color(0x1AFFFFFF),
                                color: AppColors.primaryBright,
                              ),
                            );
                          },
                        ),
                      ),
                      if (index != _steps.length - 1) const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        reached >= 0 ? _steps[reached] : order.status.label,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (next != null)
                      Text(
                        'Next: $next',
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Icon(
                      _isPickupTrack
                          ? Icons.storefront_outlined
                          : Icons.local_shipping_outlined,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_isPickupTrack ? 'Pickup' : 'Delivery'} · '
                        '${AppFormatters.money(order.total, order.currency)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                      ),
                    ),
                    Text(
                      'TRACK ORDER',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryBright,
                        fontSize: 11,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primaryBright,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
