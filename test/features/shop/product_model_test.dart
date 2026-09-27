import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/shop/data/models/product_model.dart';

void main() {
  test('derives product options and stock from variants', () {
    final ProductModel product = ProductModel.fromJson(<String, dynamic>{
      'id': 'item-1',
      'name': 'Club Jacket',
      'variants': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'black-m',
          'color': <String, dynamic>{'name': 'Black'},
          'size': 'M',
          'price': 90,
          'stock': 2,
        },
        <String, dynamic>{
          'id': 'black-l',
          'color_name': 'Black',
          'size_name': 'L',
          'price': 95,
          'quantity': 3,
        },
      ],
    });

    expect(product.price, 90);
    expect(product.stock, 5);
    expect(product.colors.map((option) => option.name), <String>['Black']);
    expect(product.sizes, <String>['M', 'L']);
    expect(product.variants, hasLength(2));
  });
}
