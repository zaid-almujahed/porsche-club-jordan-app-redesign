import 'package:flutter_test/flutter_test.dart';
import 'package:pcj_v5/features/shop/data/models/product_model.dart';

void main() {
  test('derives product options and stock from variants', () {
    // Shape of GET /member/items/{id}.
    final ProductModel product = ProductModel.fromJson(<String, dynamic>{
      'id': 2,
      'name': 'PCJ Tee',
      'price': 30,
      'images': <Map<String, dynamic>>[
        <String, dynamic>{
          'image_url': 'https://example.com/back.jpg',
          'display_order': 2,
        },
        <String, dynamic>{
          'image_url': 'https://example.com/front.jpg',
          'display_order': 1,
        },
      ],
      'variants': <Map<String, dynamic>>[
        <String, dynamic>{'id': 21, 'stock': 5, 'color': 'Black', 'size': 'S'},
        <String, dynamic>{'id': 22, 'stock': 3, 'color': 'Black', 'size': 'M'},
      ],
    });

    expect(product.id, '2');
    expect(product.price, 30);
    expect(product.currency, 'JOD');
    expect(product.stock, 8);
    expect(product.colors.map((option) => option.name), <String>['Black']);
    expect(product.sizes, <String>['S', 'M']);
    expect(product.variants.map((variant) => variant.id), <String>['21', '22']);
    expect(product.imageUrls, <String>[
      'https://example.com/front.jpg',
      'https://example.com/back.jpg',
    ]);
  });
}
