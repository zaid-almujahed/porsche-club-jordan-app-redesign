import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';

export 'package:pcj_v5/shared/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.currency,
    required super.stock,
    required super.imageUrls,
    super.colors,
    super.sizes,
    super.badge,
    super.variants,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final List<_ProductImage> orderedImages = _orderedImages(json['images']);
    final String? productImageUrl =
        firstString(json, const <String>['image']) ??
        (orderedImages.isEmpty ? null : orderedImages.first.url);
    final List<ProductVariant> variants = _variants(
      json,
      orderedImages: orderedImages,
      fallbackImageUrl: productImageUrl,
    );
    final List<String> images = _images(
      productImageUrl,
      orderedImages,
      variants,
    );
    final double price = firstDouble(json, const <String>['price']) ?? 0;
    final int stock = variants.fold<int>(
      0,
      (int total, ProductVariant variant) => total + variant.stock,
    );

    final Set<String> colorNames = variants
        .map((ProductVariant variant) => variant.colorName)
        .whereType<String>()
        .where((String value) => value.isNotEmpty)
        .toSet();
    final Set<String> sizes = variants
        .map((ProductVariant variant) => variant.size)
        .whereType<String>()
        .where((String value) => value.isNotEmpty)
        .toSet();

    return ProductModel(
      id: firstString(json, const <String>['id']) ?? '',
      name: firstString(json, const <String>['name']) ?? '',
      description: firstString(json, const <String>['description']) ?? '',
      price: price,
      currency: firstString(json, const <String>['currency']) ?? 'JOD',
      stock: stock,
      imageUrls: images,
      colors: colorNames
          .map(
            (String name) =>
                ProductColorOption(name: name, argbValue: _colorValue(name)),
          )
          .toList(growable: false),
      sizes: sizes.toList(growable: false),
      badge: firstString(json, const <String>['badge']),
      variants: variants,
    );
  }

  static List<ProductVariant> _variants(
    Map<String, dynamic> json, {
    required List<_ProductImage> orderedImages,
    required String? fallbackImageUrl,
  }) {
    final Object? raw = json['variants'];
    final List<Map<String, dynamic>> values = raw is List
        ? raw
              .whereType<Map>()
              .map((Map value) => Map<String, dynamic>.from(value))
              .toList(growable: false)
        : const <Map<String, dynamic>>[];
    return List<ProductVariant>.generate(values.length, (int index) {
          final Map<String, dynamic> variant = values[index];
          final int displayOrder = index + 1;
          final String? mappedImage = _imageAtOrder(
            orderedImages,
            displayOrder,
          );
          return ProductVariant(
            id: firstString(variant, const <String>['id']) ?? '',
            stock: firstInt(variant, const <String>['stock']) ?? 0,
            colorName: firstString(variant, const <String>['color']),
            size: firstString(variant, const <String>['size']),
            imageUrl: mappedImage ?? fallbackImageUrl,
          );
        }, growable: false);
  }

  static List<String> _images(
    String? productImageUrl,
    List<_ProductImage> orderedImages,
    List<ProductVariant> variants,
  ) {
    final Set<String> images = <String>{
      ?productImageUrl,
      ...orderedImages.map((_ProductImage image) => image.url),
      ...variants
          .map((ProductVariant variant) => variant.imageUrl)
          .whereType<String>(),
    };
    return images.toList(growable: false);
  }

  static List<_ProductImage> _orderedImages(Object? raw) {
    if (raw is! List) return const <_ProductImage>[];
    final List<_ProductImage> images = raw
        .whereType<Map>()
        .map<_ProductImage?>((Map value) {
          final Map<String, dynamic> json = Map<String, dynamic>.from(value);
          final String? url = firstString(json, const <String>['image_url']);
          final int? displayOrder = firstInt(
            json,
            const <String>['display_order'],
          );
          if (url == null || displayOrder == null) return null;
          return _ProductImage(url: url, displayOrder: displayOrder);
        })
        .whereType<_ProductImage>()
        .toList();
    images.sort(
      (_ProductImage left, _ProductImage right) =>
          left.displayOrder.compareTo(right.displayOrder),
    );
    return List<_ProductImage>.unmodifiable(images);
  }

  static String? _imageAtOrder(
    List<_ProductImage> images,
    int displayOrder,
  ) {
    for (final _ProductImage image in images) {
      if (image.displayOrder == displayOrder) return image.url;
    }
    for (final _ProductImage image in images) {
      if (image.displayOrder == 1) return image.url;
    }
    return images.isEmpty ? null : images.first.url;
  }

  static int _colorValue(String value) {
    final String normalized = value.trim().toLowerCase();
    final String hex = normalized.replaceFirst('#', '');
    if (RegExp(r'^[0-9a-f]{6}$').hasMatch(hex)) {
      return int.parse('FF$hex', radix: 16);
    }
    if (normalized.contains('black')) return 0xFF050505;
    if (normalized.contains('red')) return 0xFFB12B28;
    if (normalized.contains('white')) return 0xFFF2F2F2;
    if (normalized.contains('silver')) return 0xFFC0C0C0;
    if (normalized.contains('grey') || normalized.contains('gray')) {
      return 0xFF9E9E9E;
    }
    if (normalized.contains('navy')) return 0xFF0B1F3A;
    if (normalized.contains('blue')) return 0xFF1B3A66;
    if (normalized.contains('green')) return 0xFF315C3B;
    if (normalized.contains('yellow')) return 0xFFF2C94C;
    if (normalized.contains('orange')) return 0xFFE67E22;
    if (normalized.contains('brown')) return 0xFF6F4E37;
    if (normalized.contains('beige')) return 0xFFD8C3A5;
    if (normalized.contains('gold')) return 0xFFD4AF37;
    if (normalized.contains('purple')) return 0xFF6C4A8B;
    if (normalized.contains('pink')) return 0xFFD7859B;
    return 0xFF050505;
  }
}

class _ProductImage {
  const _ProductImage({required this.url, required this.displayOrder});

  final String url;
  final int displayOrder;
}
