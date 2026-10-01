import 'package:flutter/material.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/utils/app_formatters.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/checkout_controller.dart';
import 'product_details_widgets.dart';

/// Adds a product from a card (shop grid, home rail) without leaving the
/// page. A product with a single in-stock variant is added at once; otherwise
/// a compact sheet asks for the colour/size first. Success is confirmed with
/// a short self-dismissing animation and the cart badge updates.
Future<void> quickAddToCart({
  required BuildContext context,
  required Product product,
  required CheckoutController controller,
}) async {
  final List<ProductVariant> inStock = product.variants
      .where((ProductVariant variant) => variant.isInStock)
      .toList(growable: false);
  if (inStock.isEmpty) {
    showAppSnackBar(
      context,
      'This item is currently out of stock.',
      type: AppFeedbackType.warning,
    );
    return;
  }

  ProductVariant? variant = inStock.length == 1 ? inStock.first : null;
  variant ??= await showModalBottomSheet<ProductVariant>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.panelDark,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _QuickAddSheet(product: product),
  );
  if (variant == null || !context.mounted) return;

  final bool added = await controller.addItem(product, variant);
  if (!context.mounted) return;
  if (added) {
    showAppSuccessPulse(context, label: 'Added to Cart');
  } else if (controller.addError != null) {
    showAppErrorPulse(
      context,
      readableError(
        controller.addError!,
        fallback: 'The item could not be added to your cart.',
      ),
    );
  }
}

class _QuickAddSheet extends StatefulWidget {
  const _QuickAddSheet({required this.product});

  final Product product;

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  ProductColorOption? _color;
  String? _size;

  Product get _product => widget.product;

  Iterable<ProductVariant> get _inStock =>
      _product.variants.where((ProductVariant variant) => variant.isInStock);

  static String _normalize(String? value) => value?.trim().toLowerCase() ?? '';

  List<ProductColorOption> get _colors {
    final Set<String> names = _inStock
        .map((ProductVariant variant) => _normalize(variant.colorName))
        .toSet();
    return _product.colors
        .where(
          (ProductColorOption color) => names.contains(_normalize(color.name)),
        )
        .toList(growable: false);
  }

  List<String> get _sizes {
    final String color = _normalize(_color?.name);
    final Set<String> sizes = _inStock
        .where(
          (ProductVariant variant) => _normalize(variant.colorName) == color,
        )
        .map((ProductVariant variant) => variant.size?.trim() ?? '')
        .toSet();
    return _product.sizes
        .where((String size) => sizes.contains(size.trim()))
        .toList(growable: false);
  }

  ProductVariant? get _variant =>
      _product.variantFor(colorName: _color?.name, size: _size);

  @override
  void initState() {
    super.initState();
    final ProductVariant first = _inStock.first;
    _color = _colorFor(first.colorName);
    _size = first.size;
  }

  ProductColorOption? _colorFor(String? name) {
    for (final ProductColorOption color in _product.colors) {
      if (_normalize(color.name) == _normalize(name)) return color;
    }
    return null;
  }

  void _selectColor(ProductColorOption color) {
    setState(() {
      _color = color;
      final List<String> sizes = _sizes;
      if (!sizes.contains(_size)) _size = sizes.isEmpty ? null : sizes.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ProductVariant? variant = _variant;
    final double price = variant?.price ?? _product.price;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x40FFFFFF),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 64,
                child: AppAssetImage(
                  path: _product.primaryImageUrl ?? '',
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                  fallbackIcon: Icons.checkroom_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.title.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppFormatters.money(price, _product.currency),
                      style: AppTextStyles.numeric.copyWith(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_colors.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            ColorSelector(
              colors: _colors,
              selectedColor: _color,
              onSelected: _selectColor,
            ),
          ],
          if (_sizes.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            SizeSelector(
              sizes: _sizes,
              selectedSize: _size,
              onSelected: (String size) => setState(() => _size = size),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          PrimaryActionButton(
            label: 'Add to Cart',
            height: 56,
            onPressed: variant == null
                ? null
                : () => Navigator.of(context).pop(variant),
          ),
        ],
      ),
    );
  }
}
