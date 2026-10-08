import 'package:flutter/material.dart';
import 'package:pcj_v5/core/routing/app_back_navigation.dart';
import 'package:pcj_v5/core/routing/app_router.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/user_orders_controller.dart';
import '../widgets/user_orders_widgets.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key, required this.controller, required this.onPay});

  final UserOrdersController controller;

  /// Opens the CliQ payment for an order whose payment is still PENDING.
  final ValueChanged<Order> onPay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: PorscheAppBar(
        title: 'My Orders',
        showBack: true,
        // Pushing /profile here stacked a second navigation shell on top of
        // the first and crashed with duplicate page keys. goBack pops when
        // possible and otherwise *goes* to Profile (e.g. after an order).
        onBack: () => context.goBack(fallback: AppRoutes.profile),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            topPadding: AppSpacing.xl,
            onRefresh: () => controller.load(force: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                OrdersTabs(
                  showActive: controller.showActive,
                  onSelected: (bool active) {
                    controller.showTab(active: active);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AsyncStateView<List<Order>>(
                  state: controller.orders,
                  onRetry: () => controller.load(force: true),
                  isEmpty: (List<Order> orders) => orders.isEmpty,
                  emptyMessage: 'No orders are available.',
                  builder: (BuildContext context, List<Order> orders) {
                    return Column(
                      children: <Widget>[
                        for (
                          int index = 0;
                          index < orders.length;
                          index++
                        ) ...<Widget>[
                          AppFadeSlideIn.stagger(
                            index: index,
                            child: _OrderCardFromEntity(
                              order: orders[index],
                              onTap: () => showOrderDetailsDialog(
                                context: context,
                                controller: controller,
                                orderId: orders[index].id,
                                onPay: onPay,
                              ),
                            ),
                          ),
                          if (index != orders.length - 1)
                            const SizedBox(height: AppSpacing.sm),
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

class _OrderCardFromEntity extends StatelessWidget {
  const _OrderCardFromEntity({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final CartItem? firstItem = order.items.isEmpty ? null : order.items.first;
    final String productName = order.items.length == 1
        ? firstItem!.product.name
        : order.items.length > 1
        ? '${order.items.length} products'
        : <String>[
            AppFormatters.initCap(order.deliveryMethod),
            AppFormatters.paymentMethod(order.paymentMethod),
          ].where((String value) => value.isNotEmpty).join(' · ');
    final String createdDate = order.createdAt.millisecondsSinceEpoch == 0
        ? 'Not available'
        : AppFormatters.date(order.createdAt.toLocal());

    final StatusLabel? payment = order.showsPaymentStatus
        ? paymentStatusLabel(order.paymentStatus)
        : null;
    return OrderCard(
      imagePaths: order.itemImagePaths,
      orderId: '#${order.id}',
      productName: productName,
      status: orderStatusLabel(order).text.toUpperCase(),
      paymentStatus: payment == null ? null : 'PAYMENT · ${payment.text}',
      paymentColor: payment?.color,
      createdDate: createdDate,
      total: AppFormatters.money(order.total, order.currency),
      accentColor: orderStatusLabel(order).color,
      onTap: onTap,
    );
  }
}
