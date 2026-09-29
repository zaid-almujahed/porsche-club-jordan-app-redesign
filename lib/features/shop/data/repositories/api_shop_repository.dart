import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/features/shop/domain/repositories/shop_repository.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';

import '../../../user_orders/data/models/order_model.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';

class ApiShopRepository implements ShopRepository {
  ApiShopRepository({
    required PcjApiClient apiClient,
    required MemoryCache cache,
  }) : _apiClient = apiClient,
       _cache = cache;

  final PcjApiClient _apiClient;
  final MemoryCache _cache;

  @override
  Future<List<Product>> getProducts({
    String? category,
    bool forceRefresh = false,
  }) async {
    final List<Product> products = await _cache.getOrLoad<List<Product>>(
      'shop:products',
      () async => requireJsonMapList(
        await _apiClient.get('/member/items'),
        description: 'items response',
      ).map<Product>(ProductModel.fromJson).toList(growable: false),
      ttl: const Duration(minutes: 5),
      force: forceRefresh,
    );
    final String normalized = category?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty || normalized == 'all categories') return products;
    return products
        .where(
          (Product product) => product.category.toLowerCase() == normalized,
        )
        .toList(growable: false);
  }

  @override
  Future<Product> getProduct(
    String productId, {
    bool forceRefresh = false,
  }) async {
    return _cache.getOrLoad<Product>(
      'shop:product:$productId',
      () async => ProductModel.fromJson(
        requireJsonMap(
          await _apiClient.get(
            '/member/items/${Uri.encodeComponent(productId)}',
          ),
          description: 'item response',
        ),
      ),
      ttl: const Duration(minutes: 5),
      force: forceRefresh,
    );
  }

  @override
  Future<Cart> getCart() async {
    return CartModel.fromJson(
      requireJsonMap(
        await _apiClient.get('/member/cart'),
        description: 'cart response',
      ),
    );
  }

  @override
  Future<Cart> addToCart(AddToCartRequest request) async {
    if (!request.variant.isInStock ||
        request.quantity > request.variant.stock) {
      throw const AppException('The selected product variant is out of stock.');
    }
    final int? variantId = int.tryParse(request.variantId);
    if (variantId == null) {
      throw const AppException('The selected product variant is invalid.');
    }
    await _apiClient.postForm(
      '/member/cart',
      fields: <String, Object?>{
        'variant_id': variantId,
        'quantity': request.quantity,
      },
    );
    return getCart();
  }

  @override
  Future<Cart> removeCartItem(CartItem item) async {
    final String cartItemId = item.id.trim();
    if (cartItemId.isEmpty) {
      throw const AppException('The cart item could not be removed.');
    }
    await _apiClient.delete(
      '/member/cart/${Uri.encodeComponent(cartItemId)}',
    );
    return getCart();
  }

  @override
  Future<Order> placeOrder(PlaceOrderRequest request) async {
    final Cart cart = await getCart();
    final Map<String, Object?> parameters = <String, Object?>{
      'delivery_method': request.deliveryMethod.name.toUpperCase(),
      'payment_method': request.paymentMethod.name.toUpperCase(),
    };
    final Map<String, dynamic> json = requireJsonMap(
      await _apiClient.postForm('/member/cart/checkout', fields: parameters),
      description: 'checkout response',
    );
    return OrderModel.fromJson(
      json,
      fallbackItems: cart.items,
      fallbackDeliveryMethod: request.deliveryMethod.name.toUpperCase(),
      fallbackPaymentMethod: request.paymentMethod.name.toUpperCase(),
      fallbackCreatedAt: DateTime.now(),
    );
  }
}
