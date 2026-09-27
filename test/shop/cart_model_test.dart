import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/shop/data/models/cart_model.dart';

void main() {
  test('parses the server cart response and computes its subtotal', () {
    final CartModel cart = CartModel.fromJson(<String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'cart_item_id': 1,
          'item_id': 6,
          'variant_id': 6,
          'name': 'Club Cap',
          'color': 'red',
          'size': 's',
          'price': 10,
          'quantity': 1,
          'subtotal': 10,
          'image': 'https://example.com/cap.png',
        },
        <String, dynamic>{
          'cart_item_id': 2,
          'item_id': 4,
          'variant_id': 5,
          'name': 'Club Shirt',
          'color': 'black',
          'size': 'm',
          'price': 10,
          'quantity': 3,
          'subtotal': 30,
          'image': 'https://example.com/shirt.png',
        },
      ],
      'subtotal': 40,
    });

    expect(cart.items, hasLength(2));
    expect(cart.items.first.id, '1');
    expect(cart.items.first.product.id, '6');
    expect(cart.items.first.variantId, '6');
    expect(cart.items.first.selectedColor?.name, 'red');
    expect(cart.items.first.selectedSize, 's');
    expect(cart.items.first.product.primaryImageUrl, endsWith('cap.png'));
    expect(cart.subtotal, 40);
  });
}
