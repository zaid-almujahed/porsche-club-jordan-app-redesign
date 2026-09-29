class ProductColorOption {
  const ProductColorOption({required this.name, required this.argbValue});

  final String name;
  final int argbValue;
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.stock,
    this.price,
    this.colorName,
    this.size,
    this.imageUrl,
  });

  final String id;
  final int stock;
  final double? price;
  final String? colorName;
  final String? size;
  final String? imageUrl;

  bool get isInStock => stock > 0;

  bool matches({String? colorName, String? size}) {
    final String requestedColor = colorName?.trim().toLowerCase() ?? '';
    final String requestedSize = size?.trim().toLowerCase() ?? '';
    final String variantColor = this.colorName?.trim().toLowerCase() ?? '';
    final String variantSize = this.size?.trim().toLowerCase() ?? '';
    // A backend variant is the exact purchasable combination. Treating a
    // missing selection as a wildcard can add the wrong variant to the cart.
    return requestedColor == variantColor && requestedSize == variantSize;
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.stock,
    required this.imageUrls,
    this.colors = const <ProductColorOption>[],
    this.sizes = const <String>[],
    this.badge,
    this.variants = const <ProductVariant>[],
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final int stock;
  final List<String> imageUrls;
  final List<ProductColorOption> colors;
  final List<String> sizes;
  final String? badge;
  final List<ProductVariant> variants;

  bool get isInStock => stock > 0;
  String? get primaryImageUrl => imageUrls.isEmpty ? null : imageUrls.first;

  ProductVariant? variantFor({String? colorName, String? size}) {
    if (variants.isEmpty) return null;
    for (final ProductVariant variant in variants) {
      if (variant.isInStock &&
          variant.matches(colorName: colorName, size: size)) {
        return variant;
      }
    }
    return null;
  }
}
