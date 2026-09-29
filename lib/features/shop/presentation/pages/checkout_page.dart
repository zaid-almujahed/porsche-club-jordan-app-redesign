import 'package:flutter/material.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/checkout_controller.dart';
import '../widgets/checkout_page_widgets.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({
    super.key,
    required this.controller,
    required this.onOrderPlaced,
  });

  final CheckoutController controller;
  final VoidCallback onOrderPlaced;

  Future<void> _chooseAddress(BuildContext context) async {
    final String? address = await showAppTextInputDialog(
      context: context,
      title: 'Delivery Address',
      currentValue: controller.deliveryAddress ?? '',
      confirmLabel: 'Use Address',
      hintText: 'Enter address',
      keyboardType: TextInputType.streetAddress,
    );
    if (address != null) controller.setDeliveryAddress(address);
  }

  Future<void> _placeOrder(BuildContext context) async {
    final bool confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Place Order?',
      message: 'Please confirm that you want to place this order.',
      confirmLabel: 'Place Order',
      icon: Icons.shopping_bag_outlined,
    );
    if (!confirmed || !context.mounted) return;
    final bool placed = await controller.placeOrder();
    if (!placed || !context.mounted) return;
    // The member is no longer taken to My Orders; a short confirmation tells
    // them where to track the order instead.
    showAppSuccessPulse(
      context,
      label: 'Order placed successfully',
      message: 'You can track it from My Orders in your Profile.',
    );
    onOrderPlaced();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const PorscheAppBar(title: 'Checkout', showBack: true),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            topPadding: AppSpacing.xl,
            onRefresh: () => controller.load(force: true),
            child: AsyncStateView<Cart>(
              state: controller.cart,
              onRetry: () => controller.load(force: true),
              isEmpty: (Cart cart) => cart.items.isEmpty,
              emptyMessage: 'Your cart is empty.',
              builder: (BuildContext context, Cart cart) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _CheckoutHeading(
                      title: 'Your Cart',
                      trailing:
                          '${cart.itemCount} '
                          '${cart.itemCount == 1 ? 'item' : 'items'}',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (
                      int index = 0;
                      index < cart.items.length;
                      index++
                    ) ...<Widget>[
                      AppFadeSlideIn.stagger(
                        index: index,
                        child: CheckoutItemCard(
                          item: cart.items[index],
                          onRemove: () =>
                              controller.removeItem(cart.items[index]),
                        ),
                      ),
                      if (index != cart.items.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.section),
                    const _CheckoutHeading(
                      title: 'Delivery Method',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DeliveryMethodPanel(
                      selectedMethod: controller.deliveryMethod,
                      deliveryAddress: controller.deliveryAddress,
                      onSelected: controller.selectDeliveryMethod,
                      onAddressPressed: () => _chooseAddress(context),
                    ),
                    if (controller.deliveryMethod ==
                        DeliveryMethod.delivery) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      const AppFadeSlideIn(child: DeliveryInformationPanel()),
                    ],
                    const SizedBox(height: AppSpacing.section),
                    const _CheckoutHeading(
                      title: 'Payment Method',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PaymentMethodPanel(
                      selectedMethod: controller.paymentMethod,
                      onSelected: controller.selectPaymentMethod,
                    ),
                    if (controller.orderError != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      AppInlineMessage.error(
                        readableError(controller.orderError!),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.section),
                    OrderSummary(
                      cart: cart,
                      isPlacingOrder:
                          controller.isPlacingOrder ||
                          controller.cart.isLoading,
                      onPlaceOrder: () => _placeOrder(context),
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

class _CheckoutHeading extends StatelessWidget {
  const _CheckoutHeading({
    required this.title,
    this.isRequired = false,
    this.trailing,
  });

  final String title;
  final bool isRequired;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(text: title),
                    if (isRequired)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.required),
                      ),
                  ],
                ),
                style: AppTextStyles.sectionTitle,
              ),
            ),
            if (trailing != null)
              Text(trailing!.toUpperCase(), style: AppTextStyles.overline),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const AppAccentBar(),
      ],
    );
  }
}
