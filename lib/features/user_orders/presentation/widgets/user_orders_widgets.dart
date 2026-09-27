import 'package:flutter/material.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/user_orders_controller.dart';
import 'user_orders_styles.dart';

Future<void> showOrderDetailsDialog({
  required BuildContext context,
  required UserOrdersController controller,
  required String orderId,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) =>
        _OrderDetailsDialog(controller: controller, orderId: orderId),
  );
}

class OrdersTabs extends StatelessWidget {
  const OrdersTabs({
    super.key,
    required this.showActive,
    required this.onSelected,
  });

  final bool showActive;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedTabs(
      labels: const <String>['Active', 'Past'],
      selectedIndex: showActive ? 0 : 1,
      onSelected: (int index) => onSelected(index == 0),
    );
  }
}

// Replaced by the shared AppSegmentedTabs sliding control.
// class _OrdersTab extends StatelessWidget {
//   const _OrdersTab({
//     required this.label,
//     required this.onTap,
//     this.isSelected = false,
//   });
//
//   final String label;
//   final bool isSelected;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Stack(
//         fit: StackFit.expand,
//         children: <Widget>[
//           Center(
//             child: Text(
//               label,
//               textAlign: TextAlign.center,
//               style: AppTextStyles.sectionTitle.copyWith(
//                 color: isSelected
//                     ? AppColors.textPrimary
//                     : const Color(0x66FBFCFF),
//                 fontSize: 18,
//                 height: 1.6,
//                 letterSpacing: 0.45,
//               ),
//             ),
//           ),
//           if (isSelected)
//             const Positioned(
//               left: 0,
//               right: 0,
//               bottom: 0,
//               child: ColoredBox(
//                 color: AppColors.primaryBright,
//                 child: SizedBox(height: 2.25),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.imagePath,
    required this.orderId,
    required this.productName,
    required this.status,
    required this.createdDate,
    required this.total,
    required this.accentColor,
    required this.onTap,
  });

  final String imagePath;
  final String orderId;
  final String productName;
  final String status;
  final String createdDate;
  final String total;
  final Color accentColor;
  final VoidCallback onTap;

  static const BorderRadius _cardRadius = BorderRadius.all(
    Radius.circular(AppRadii.large),
  );

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      child: Material(
        color: Colors.transparent,
        borderRadius: _cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: AppDecorations.panel(radius: AppRadii.large),
            child: Stack(
              children: <Widget>[
                // Status-coloured spine, kept from the original card.
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(
                    color: accentColor,
                    child: const SizedBox(width: 4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 76,
                            height: 76,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              gradient: const RadialGradient(
                                colors: <Color>[
                                  Color(0xFF2A2A30),
                                  Color(0xFF111114),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadii.medium,
                              ),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: AppAssetImage(
                              path: imagePath,
                              fallbackIcon: Icons.shopping_bag_outlined,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        orderId,
                                        style: OrderStyles.orderId,
                                      ),
                                    ),
                                    _StatusBadge(
                                      label: status,
                                      color: accentColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  productName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: OrderStyles.productName,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(color: AppColors.cardBorder),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: _OrderValue(
                              label: 'Placed',
                              value: createdDate,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _OrderValue(
                              label: 'Total',
                              value: total,
                              alignEnd: true,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, this.color = AppColors.textMuted});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Neutral accents (e.g. the input border tone) read as muted grey.
    final Color tone = color == AppColors.inputBorder
        ? AppColors.textMuted
        : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.13),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(label, style: OrderStyles.badge.copyWith(color: tone)),
    );
  }
}

class _OrderValue extends StatelessWidget {
  const _OrderValue({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final CrossAxisAlignment crossAxisAlignment = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final TextAlign textAlign = alignEnd ? TextAlign.right : TextAlign.left;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          textAlign: textAlign,
          style: OrderStyles.metaLabel,
        ),
        const SizedBox(height: 4),
        Text(value, textAlign: textAlign, style: OrderStyles.metaValue),
      ],
    );
  }
}

class _OrderDetailsDialog extends StatefulWidget {
  const _OrderDetailsDialog({required this.controller, required this.orderId});

  final UserOrdersController controller;
  final String orderId;

  @override
  State<_OrderDetailsDialog> createState() => _OrderDetailsDialogState();
}

class _OrderDetailsDialogState extends State<_OrderDetailsDialog> {
  Order? _order;
  Object? _error;
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final Order order = await widget.controller.getOrderDetails(
        widget.orderId,
      );
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    final Order? order = _order;
    if (order == null || !order.canCancel || _isCancelling) return;
    final bool confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Cancel Order?',
      message:
          'Order #${order.id} is pending and will be cancelled immediately.',
      confirmLabel: 'Cancel Order',
      icon: Icons.cancel_outlined,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _isCancelling = true;
      _error = null;
    });
    try {
      final OrderCancellationResult result = await widget.controller
          .cancelOrder(order);
      if (!mounted) return;
      await showAppMessageDialog(
        context: context,
        title: 'Order Cancelled',
        message: result.message.isEmpty
            ? 'Your order was cancelled successfully.'
            : result.message,
        buttonLabel: 'Done',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.success,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isCancelling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Order? order = _order;
    final bool canCancel = order?.canCancel ?? false;
    return AppDialog(
      icon: Icons.receipt_long_outlined,
      title: 'Order #${widget.orderId}',
      content: AnimatedSwitcher(
        duration: AppMotion.medium,
        child: _isLoading
            ? const Padding(
                key: ValueKey<String>('order-loading'),
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: AppLoadingIndicator()),
              )
            : order == null
            ? _OrderDetailsError(
                key: const ValueKey<String>('order-error'),
                error: _error,
              )
            : _OrderDetailsContent(
                key: const ValueKey<String>('order-content'),
                order: order,
                error: _error,
              ),
      ),
      primaryLabel: _isLoading
          ? 'Loading...'
          : order == null
          ? 'Retry'
          : canCancel
          ? _isCancelling
                ? 'Cancelling...'
                : 'Cancel Order'
          : 'Close',
      secondaryLabel: order != null && canCancel ? 'Close' : null,
      onPrimaryPressed: _isLoading || _isCancelling
          ? () {}
          : order == null
          ? _load
          : canCancel
          ? _cancelOrder
          : () => Navigator.of(context).pop(),
      onSecondaryPressed: order != null && canCancel
          ? () => Navigator.of(context).pop()
          : null,
    );
  }
}

class _OrderDetailsError extends StatelessWidget {
  const _OrderDetailsError({super.key, required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return AppInlineMessage.error(
      error == null
          ? 'The order details could not be loaded.'
          : readableError(error!),
      title: 'Couldn’t load this order',
    );
  }
}

class _OrderDetailsContent extends StatelessWidget {
  const _OrderDetailsContent({
    super.key,
    required this.order,
    required this.error,
  });

  final Order order;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (order.status != OrderStatus.unknown) ...<Widget>[
          _OrderTracker(status: order.status),
          const SizedBox(height: AppSpacing.lg),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          child: Column(
            children: <Widget>[
              _OrderDetailRow(
                label: 'Status',
                value: AppFormatters.initCap(order.status.name),
              ),
              _OrderDetailRow(
                label: 'Placed',
                value: order.createdAt.millisecondsSinceEpoch == 0
                    ? 'Not available'
                    : AppFormatters.dateAndTime(order.createdAt.toLocal()),
              ),
              _OrderDetailRow(
                label: 'Delivery',
                value: AppFormatters.initCap(order.deliveryMethod),
              ),
              _OrderDetailRow(
                label: 'Payment',
                value: AppFormatters.initCap(order.paymentMethod),
              ),
              _OrderDetailRow(
                label: 'Payment Status',
                value: AppFormatters.initCap(order.paymentStatus),
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('ITEMS', style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.sm),
        if (order.items.isEmpty)
          Text(
            'No item details were returned for this order.',
            style: AppTextStyles.body.copyWith(color: AppColors.textFaint),
          )
        else
          for (final CartItem item in order.items) ...<Widget>[
            _OrderItemRow(item: item),
            const SizedBox(height: AppSpacing.sm),
          ],
        const Divider(color: AppColors.cardBorder),
        const SizedBox(height: AppSpacing.sm),
        _OrderTotalRow(
          label: 'Delivery Fee',
          value: AppFormatters.money(order.deliveryFee, order.currency),
        ),
        const SizedBox(height: AppSpacing.sm),
        _OrderTotalRow(
          label: 'Total',
          value: AppFormatters.money(order.total, order.currency),
          emphasized: true,
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppInlineMessage.error(readableError(error!)),
        ],
        if (order.canCancel) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          const AppInlineMessage(
            type: AppFeedbackType.info,
            message: 'This pending cash order is eligible for cancellation.',
          ),
        ],
      ],
    );
  }
}

/// Placed → Processing → Shipped → Delivered progress, from the
/// track-order reference. Cancelled orders show a single red state.
class _OrderTracker extends StatelessWidget {
  const _OrderTracker({required this.status});

  final OrderStatus status;

  static const List<(String, IconData)> _steps = <(String, IconData)>[
    ('Placed', Icons.receipt_long_rounded),
    ('Processing', Icons.inventory_2_outlined),
    ('Shipped', Icons.local_shipping_outlined),
    ('Delivered', Icons.home_outlined),
  ];

  int get _reached => switch (status) {
    OrderStatus.pending => 0,
    OrderStatus.processing => 1,
    OrderStatus.shipped => 2,
    OrderStatus.delivered => 3,
    OrderStatus.cancelled || OrderStatus.unknown => -1,
  };

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return const AppInlineMessage(
        type: AppFeedbackType.error,
        title: 'Order cancelled',
        message: 'This order will not be processed or delivered.',
        animate: false,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int index = 0; index < _steps.length; index++) ...<Widget>[
          Expanded(
            flex: 5,
            child: _TrackerStep(
              label: _steps[index].$1,
              icon: _steps[index].$2,
              isDone: index <= _reached,
              isCurrent: index == _reached,
              index: index,
            ),
          ),
          if (index != _steps.length - 1)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(top: 17),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: index < _reached ? 1 : 0),
                  duration: Duration(milliseconds: 380 + index * 120),
                  curve: AppMotion.curve,
                  builder: (BuildContext context, double value, _) {
                    return Stack(
                      children: <Widget>[
                        Container(height: 2, color: AppColors.border),
                        FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 2,
                            color: AppColors.primaryBright,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _TrackerStep extends StatelessWidget {
  const _TrackerStep({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
    required this.index,
  });

  final String label;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AppScaleIn(
          begin: 0.7,
          duration: Duration(milliseconds: 300 + index * 90),
          child: AnimatedContainer(
            duration: AppMotion.medium,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? AppColors.primary : AppColors.surfaceRaised,
              border: Border.all(
                color: isDone ? AppColors.primaryBright : AppColors.cardBorder,
              ),
              boxShadow: isCurrent
                  ? const <BoxShadow>[
                      BoxShadow(color: AppColors.primaryGlow, blurRadius: 14),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 17,
              color: isDone ? Colors.white : AppColors.textFaint,
            ),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDone ? AppColors.textPrimary : AppColors.textFaint,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderDetailRow extends StatelessWidget {
  const _OrderDetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(fontSize: 14),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  value.isEmpty ? 'Not available' : value,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(color: AppColors.cardBorder),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final List<String> details = <String>[
      if (item.selectedColor?.name.trim().isNotEmpty == true)
        AppFormatters.initCap(item.selectedColor!.name),
      if (item.selectedSize?.trim().isNotEmpty == true) item.selectedSize!,
      'Qty ${item.quantity}',
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 60,
            height: 60,
            child: AppAssetImage(
              path: item.product.primaryImageUrl ?? '',
              borderRadius: BorderRadius.circular(AppRadii.small),
              fallbackIcon: Icons.shopping_bag_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.product.name,
                  style: AppTextStyles.title.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(details.join(' · '), style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.money(item.total, item.product.currency),
                  style: AppTextStyles.numeric.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTotalRow extends StatelessWidget {
  const _OrderTotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = emphasized
        ? AppTextStyles.numeric.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          )
        : AppTextStyles.body.copyWith(fontSize: 14.5);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: emphasized
                ? AppTextStyles.title.copyWith(fontSize: 17)
                : style,
          ),
        ),
        Text(value, style: style),
      ],
    );
  }
}
