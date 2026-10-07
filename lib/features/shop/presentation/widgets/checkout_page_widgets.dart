import 'package:flutter/material.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';

import 'package:pcj_v5/shared/widgets/app_widgets.dart';

class OrderSummary extends StatelessWidget {
  const OrderSummary({
    super.key,
    required this.cart,
    required this.deliveryMethod,
    required this.deliveryFee,
    required this.isPlacingOrder,
    this.placeOrderLabel = 'Place Order',
    this.onPlaceOrder,
  });

  final Cart cart;
  final DeliveryMethod deliveryMethod;

  /// Added to the cart's total.
  final double deliveryFee;
  final bool isPlacingOrder;

  /// "Continue to Payment" for CliQ, which places the order with its
  /// payment.
  final String placeOrderLabel;
  final VoidCallback? onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: checkoutPanelDecoration(radius: AppRadii.large),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[AppColors.primary, AppColors.primaryDeep],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 20,
                      color: AppColors.primaryBright,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Order Summary',
                      style: AppTextStyles.title.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.cardBorder),
                const SizedBox(height: AppSpacing.md),
                _OrderRow(
                  label: 'Subtotal (${cart.itemCount} items)',
                  value: AppFormatters.money(cart.subtotal, cart.currency),
                ),
                const SizedBox(height: AppSpacing.sm),
                _OrderRow(
                  label: deliveryMethod == DeliveryMethod.delivery
                      ? 'Delivery'
                      : 'Pick up',
                  value: deliveryFee == 0
                      ? 'Free'
                      : AppFormatters.money(deliveryFee, cart.currency),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(color: AppColors.cardBorder),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Total',
                          style: AppTextStyles.title.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'INCL. TAXES',
                          style: AppTextStyles.overline,
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          AppFormatters.money(
                            cart.total + deliveryFee,
                            cart.currency,
                          ),
                          style: AppTextStyles.numeric.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryActionButton(
                  label: placeOrderLabel,
                  isLoading: isPlacingOrder,
                  onPressed: isPlacingOrder ? null : onPlaceOrder,
                  height: 56,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 15.5,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.numeric.copyWith(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

BoxDecoration checkoutPanelDecoration({
  required double radius,
  Color borderColor = AppColors.cardBorder,
}) {
  return BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[Color(0xFF1B1B1F), Color(0xFF131316)],
    ),
    border: Border.all(color: borderColor),
    borderRadius: BorderRadius.circular(radius),
  );
}

class CheckoutItemCard extends StatelessWidget {
  const CheckoutItemCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final List<String> tags = <String>[
      if (item.selectedSize != null) 'Size ${item.selectedSize}',
      if (item.selectedColor != null)
        AppFormatters.initCap(item.selectedColor!.name),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: checkoutPanelDecoration(radius: AppRadii.large),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 96,
            height: 96,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                colors: <Color>[Color(0xFF2A2A30), Color(0xFF111114)],
              ),
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            child: AppAssetImage(
              path: item.product.primaryImageUrl ?? '',
              fallbackIcon: Icons.shopping_bag_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.title.copyWith(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        tooltip: 'Remove item',
                        onPressed: onRemove,
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceRaised,
                          shape: const CircleBorder(
                            side: BorderSide(color: AppColors.cardBorder),
                          ),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.product.description.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    item.product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
                if (tags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((String tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          tag,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    _CartQuantity(value: item.quantity),
                    const Spacer(),
                    Text(
                      AppFormatters.money(item.total, item.product.currency),
                      style: AppTextStyles.numeric.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartQuantity extends StatelessWidget {
  const _CartQuantity({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Center(
        child: Text(
          'QTY $value',
          style: AppTextStyles.label.copyWith(
            fontSize: 11,
            fontFeatures: AppTextStyles.tabularFigures,
          ),
        ),
      ),
    );
  }
}

class DeliveryMethodPanel extends StatelessWidget {
  const DeliveryMethodPanel({
    super.key,
    required this.selectedMethod,
    required this.onSelected,
    required this.deliveryPrice,
    this.deliveryAddress,
    this.onAddressPressed,
  });

  final DeliveryMethod selectedMethod;
  final ValueChanged<DeliveryMethod> onSelected;

  /// What delivery costs, e.g. "2.00 JOD".
  final String deliveryPrice;
  final String? deliveryAddress;
  final VoidCallback? onAddressPressed;

  @override
  Widget build(BuildContext context) {
    final bool isDelivery = selectedMethod == DeliveryMethod.delivery;
    return Column(
      children: <Widget>[
        _DeliveryChoice(
          icon: Icons.storefront_outlined,
          label: 'PICK UP',
          selected: selectedMethod == DeliveryMethod.pickup,
          showBorder: true,
          onTap: () => onSelected(DeliveryMethod.pickup),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DeliveryChoice(
          icon: Icons.local_shipping_outlined,
          label: 'DELIVERY',
          price: '+ $deliveryPrice',
          selected: isDelivery,
          showBorder: true,
          onTap: () => onSelected(DeliveryMethod.delivery),
          footer: _DeliveryDetail(
            label: 'DESTINATION',
            value: deliveryAddress?.isNotEmpty == true
                ? deliveryAddress!
                : 'Select address',
            valueIcon: Icons.edit_location_alt_outlined,
            onPressed: onAddressPressed,
          ),
        ),
      ],
    );
  }
}

class PaymentMethodPanel extends StatelessWidget {
  const PaymentMethodPanel({
    super.key,
    required this.selectedMethod,
    required this.onSelected,
  });

  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _DeliveryChoice(
          icon: Icons.payments_outlined,
          label: 'CASH',
          selected: selectedMethod == PaymentMethod.cash,
          showBorder: true,
          onTap: () => onSelected(PaymentMethod.cash),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DeliveryChoice(
          icon: Icons.account_balance_outlined,
          label: 'CLIQ',
          selected: selectedMethod == PaymentMethod.cliq,
          showBorder: true,
          onTap: () => onSelected(PaymentMethod.cliq),
        ),
        const SizedBox(height: AppSpacing.sm),
        // No payment gateway yet.
        const _DeliveryChoice(
          icon: Icons.credit_card_outlined,
          label: 'ONLINE',
          showBorder: true,
          comingSoon: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.textFaint,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.medium,
                layoutBuilder: AppMotion.switcherLayout,
                child: Text(
                  switch (selectedMethod) {
                    PaymentMethod.cash =>
                      'Pending cash orders can be cancelled from My Orders.',
                    PaymentMethod.cliq =>
                      'You send the payment with CliQ next; the order is '
                          'placed together with it.',
                  },
                  key: ValueKey<PaymentMethod>(selectedMethod),
                  style: AppTextStyles.caption,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeliveryChoice extends StatelessWidget {
  const _DeliveryChoice({
    required this.icon,
    required this.label,
    this.selected = false,
    this.showBorder = false,
    this.onTap,
    this.footer,
    this.price,
    this.comingSoon = false,
  });

  final IconData icon;
  final String label;

  /// What choosing it adds to the order, beside the label.
  final String? price;
  final bool selected;
  final bool showBorder;
  final VoidCallback? onTap;
  final Widget? footer;

  /// Not offered yet: greyed out, and a tap shakes it and says "Coming Soon".
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    if (!comingSoon) return _choice(onTap, showTag: false);
    return ComingSoonBuilder(
      builder: (BuildContext context, VoidCallback onTap, bool showTag) =>
          _choice(onTap, showTag: showTag),
    );
  }

  Widget _choice(VoidCallback? onTap, {required bool showTag}) {
    final double fade = comingSoon ? 0.4 : 1;
    final Color accent = selected
        ? AppColors.primaryBright
        : AppColors.textMuted;

    final Widget content = SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: <Widget>[
            Opacity(
              opacity: fade,
              child: AnimatedContainer(
                duration: AppMotion.medium,
                width: 40,
                height: 40,
                decoration: AppDecorations.iconBadge(
                  selected ? AppColors.primary : AppColors.textMuted,
                ),
                child: Icon(icon, size: 21, color: accent),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Opacity(
                opacity: fade,
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            if (price != null) ...<Widget>[
              Text(
                price!,
                style: AppTextStyles.numeric.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
            ],
            ComingSoonSwitch(
              showTag: showTag,
              child: Opacity(
                opacity: fade,
                child: AnimatedContainer(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryBright
                          : AppColors.textFaint,
                      width: selected ? 6.5 : 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final Widget interactive = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: <Widget>[
            content,
            if (footer != null)
              AnimatedSize(
                duration: AppMotion.medium,
                curve: AppMotion.curve,
                alignment: Alignment.topCenter,
                child: selected
                    ? Column(
                        children: <Widget>[
                          const Divider(
                            color: AppColors.cardBorder,
                            indent: 14,
                            endIndent: 14,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                            child: footer,
                          ),
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              ),
          ],
        ),
      ),
    );

    if (!showBorder) return interactive;

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.curve,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: selected
            ? Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.07),
                AppColors.panelDark,
              )
            : AppColors.panelDark,
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.cardBorder,
        ),
        borderRadius: BorderRadius.circular(AppRadii.medium + 2),
      ),
      child: interactive,
    );
  }
}

class _DeliveryDetail extends StatelessWidget {
  const _DeliveryDetail({
    required this.label,
    required this.value,
    this.valueIcon,
    this.onPressed,
  });

  final String label;
  final String value;
  final IconData? valueIcon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadii.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            Text(label, style: AppTextStyles.overline),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (valueIcon != null) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              Icon(valueIcon, size: 18, color: AppColors.primaryBright),
            ],
          ],
        ),
      ),
    );
  }
}

class DeliveryInformationPanel extends StatelessWidget {
  const DeliveryInformationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: checkoutPanelDecoration(radius: AppRadii.medium + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppIconBadge(
            icon: Icons.local_shipping_rounded,
            color: AppColors.accentSteel,
            size: 42,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Club Delivery Service',
                  style: AppTextStyles.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Items will be delivered directly by the club logistics team '
                  'to your registered address. You will receive notifications '
                  'once your order is on its way. Ensure your profile details '
                  'are up to date.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
