import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';

import 'product_model.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.id,
    required super.product,
    required super.quantity,
    super.selectedColor,
    super.selectedSize,
    super.variantId,
    super.reportedSubtotal,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final int quantity = firstInt(json, const <String>['quantity']) ?? 1;
    final Map<String, dynamic> variant = <String, dynamic>{
      'id': json['variant_id'],
      'color': json['color'],
      'size': json['size'],
      // Cart responses do not publish available stock. The quantity already
      // in the cart is the only stock amount this payload proves exists.
      'stock': quantity,
    };
    final Map<String, dynamic> productJson = <String, dynamic>{
      'id': json['item_id'],
      'name': json['name'],
      'price': json['price'],
      'image': json['image'],
      'variants': <Map<String, dynamic>>[variant],
    };
    final Product product = ProductModel.fromJson(productJson);
    final String? colorName = firstString(json, const <String>['color']);

    return CartItemModel(
      id: firstString(json, const <String>['cart_item_id']) ?? '',
      product: product,
      quantity: quantity,
      variantId: firstString(json, const <String>['variant_id']),
      selectedColor: colorName == null ? null : _color(product, colorName),
      selectedSize: firstString(json, const <String>['size']),
      reportedSubtotal: firstDouble(json, const <String>['subtotal']),
    );
  }

  static ProductColorOption _color(Product product, String name) {
    final String normalized = name.trim().toLowerCase();
    for (final ProductColorOption color in product.colors) {
      if (color.name.trim().toLowerCase() == normalized) return color;
    }
    return ProductColorOption(name: name, argbValue: 0xFF5A5A5A);
  }
}

class CartModel extends Cart {
  const CartModel({
    required super.items,
    required super.shippingFee,
    required super.currency,
    super.reportedSubtotal,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final Object? rawItems = json['items'];
    final List<CartItem> items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map<CartItem>((Map item) {
                return CartItemModel.fromJson(Map<String, dynamic>.from(item));
              })
              .toList(growable: false)
        : const <CartItem>[];
    return CartModel(
      items: items,
      shippingFee: 0,
      currency: 'JOD',
      reportedSubtotal: firstDouble(json, const <String>['subtotal']),
    );
  }
}
