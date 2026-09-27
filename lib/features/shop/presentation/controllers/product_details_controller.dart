import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/core/state/safe_change_notifier.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';

import '../../domain/repositories/shop_repository.dart';

class ProductDetailsController extends SafeChangeNotifier {
  ProductDetailsController({
    required ShopRepository repository,
    required this.productId,
    Product? initialProduct,
  }) : _repository = repository,
       _state = initialProduct == null
           ? const AsyncState<Product>.initial()
           : AsyncState<Product>.success(initialProduct) {
    if (initialProduct != null) _normalizeSelections(initialProduct);
  }

  final ShopRepository _repository;
  final String productId;
  AsyncState<Product> _state;
  int _selectedImageIndex = 0;
  ProductColorOption? _selectedColor;
  String? _selectedSize;
  int _quantity = 1;
  bool _isAddingToCart = false;
  Object? _cartError;

  AsyncState<Product> get state => _state;
  int get selectedImageIndex => _selectedImageIndex;
  ProductColorOption? get selectedColor => _selectedColor;
  String? get selectedSize => _selectedSize;
  int get quantity => _quantity;
  bool get isAddingToCart => _isAddingToCart;
  Object? get cartError => _cartError;

  ProductVariant? get selectedVariant {
    final Product? product = _state.data;
    if (product == null) return null;
    return product.variantFor(
      colorName: _selectedColor?.name,
      size: _selectedSize,
    );
  }

  List<ProductColorOption> get availableColors {
    final Product? product = _state.data;
    if (product == null) return const <ProductColorOption>[];
    final Set<String> names = product.variants
        .where((ProductVariant variant) => variant.isInStock)
        .map((ProductVariant variant) => _normalize(variant.colorName))
        .toSet();
    return product.colors
        .where(
          (ProductColorOption color) => names.contains(_normalize(color.name)),
        )
        .toList(growable: false);
  }

  List<String> get availableSizes {
    final Product? product = _state.data;
    if (product == null) return const <String>[];
    final String color = _normalize(_selectedColor?.name);
    final Set<String> sizes = product.variants
        .where(
          (ProductVariant variant) =>
              variant.isInStock && _normalize(variant.colorName) == color,
        )
        .map((ProductVariant variant) => variant.size?.trim() ?? '')
        .toSet();
    return product.sizes
        .where((String size) => sizes.contains(size.trim()))
        .toList(growable: false);
  }

  int get maximumQuantity => selectedVariant?.stock ?? 0;

  double get selectedPrice {
    final Product? product = _state.data;
    return selectedVariant?.price ?? product?.price ?? 0;
  }

  Future<void> load({bool force = false}) async {
    if (!force && (_state.isLoading || _state.hasData)) return;
    await refresh();
  }

  Future<void> refresh() async {
    final Product? current = _state.data;
    _state = AsyncState<Product>.loading(previousData: current);
    notifyListeners();
    try {
      final Product product = await _repository.getProduct(
        productId,
        forceRefresh: true,
      );
      _state = AsyncState<Product>.success(product);
      _normalizeSelections(product);
    } catch (error, stackTrace) {
      _state = AsyncState<Product>.failure(
        error,
        stackTrace,
        previousData: current,
      );
    }
    notifyListeners();
  }

  void _normalizeSelections(Product product) {
    if (_selectedImageIndex >= product.imageUrls.length) {
      _selectedImageIndex = 0;
    }
    final List<ProductVariant> inStock = product.variants
        .where((ProductVariant variant) => variant.isInStock)
        .toList(growable: false);
    if (inStock.isEmpty) {
      _selectedColor = null;
      _selectedSize = null;
      _quantity = 1;
      return;
    }

    ProductVariant chosen = inStock.first;
    final ProductVariant? previous = product.variantFor(
      colorName: _selectedColor?.name,
      size: _selectedSize,
    );
    if (previous != null) chosen = previous;
    _selectedColor = _colorFor(product, chosen.colorName);
    _selectedSize = chosen.size;
    _clampQuantity(chosen.stock);
  }

  void selectImage(int index) {
    _selectedImageIndex = index;
    notifyListeners();
  }

  void selectColor(ProductColorOption value) {
    final Product? product = _state.data;
    if (product == null) return;
    final String color = _normalize(value.name);
    final List<ProductVariant> matching = product.variants
        .where(
          (ProductVariant variant) =>
              variant.isInStock && _normalize(variant.colorName) == color,
        )
        .toList(growable: false);
    if (matching.isEmpty) return;
    _selectedColor = value;
    final String size = _normalize(_selectedSize);
    final ProductVariant variant = matching.firstWhere(
      (ProductVariant candidate) => _normalize(candidate.size) == size,
      orElse: () => matching.first,
    );
    _selectedSize = variant.size;
    _clampQuantity(variant.stock);
    _cartError = null;
    notifyListeners();
  }

  void selectSize(String value) {
    final Product? product = _state.data;
    if (product == null) return;
    final ProductVariant? variant = product.variantFor(
      colorName: _selectedColor?.name,
      size: value,
    );
    if (variant == null) return;
    _selectedSize = value;
    _clampQuantity(variant.stock);
    _cartError = null;
    notifyListeners();
  }

  void incrementQuantity() {
    if (_quantity >= maximumQuantity) return;
    _quantity++;
    notifyListeners();
  }

  void decrementQuantity() {
    if (_quantity == 1) return;
    _quantity--;
    notifyListeners();
  }

  Future<Cart?> addToCart() async {
    final Product? product = _state.data;
    if (product == null || _isAddingToCart) return null;

    _isAddingToCart = true;
    _cartError = null;
    notifyListeners();
    try {
      final ProductVariant? variant = selectedVariant;
      if (variant == null || variant.id.isEmpty) {
        throw const AppException(
          'This product has no purchasable variant in the API response.',
        );
      }
      return await _repository.addToCart(
        AddToCartRequest(
          product: product,
          variant: variant,
          quantity: _quantity,
        ),
      );
    } catch (error) {
      _cartError = error;
      return null;
    } finally {
      _isAddingToCart = false;
      notifyListeners();
    }
  }

  void _clampQuantity(int stock) {
    if (stock < 1) {
      _quantity = 1;
    } else if (_quantity > stock) {
      _quantity = stock;
    }
  }

  static ProductColorOption? _colorFor(Product product, String? name) {
    final String normalized = _normalize(name);
    for (final ProductColorOption color in product.colors) {
      if (_normalize(color.name) == normalized) return color;
    }
    return null;
  }

  static String _normalize(String? value) => value?.trim().toLowerCase() ?? '';
}
