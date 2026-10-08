import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/features/shop/domain/repositories/shop_repository.dart';
import 'package:pcj_v5/shared/data/cliq_api.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';

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
  Future<List<Product>> getProducts({bool forceRefresh = false}) {
    return _cache.getOrLoad<List<Product>>(
      'shop:products',
      () async => requireJsonMapList(
        await _apiClient.get('/member/items'),
        description: 'items response',
      ).map<Product>(ProductModel.fromJson).toList(growable: false),
      ttl: const Duration(minutes: 5),
      force: forceRefresh,
    );
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
  Future<PlacedOrder> placeOrder(PlaceOrderRequest request) async {
    final Object? response = await _apiClient.postForm(
      '/member/cart/checkout',
      fields: <String, Object?>{
        'delivery_method': request.deliveryMethod.name.toUpperCase(),
        'payment_method': request.paymentMethod.name.toUpperCase(),
      },
    );
    _cache.remove('order-payments');
    final Map<String, dynamic> reply = response is Map
        ? Map<String, dynamic>.from(response)
        : const <String, dynamic>{};
    return PlacedOrder(
      orderId: firstString(reply, const <String>['order_id']) ?? '',
      paymentId: firstString(reply, const <String>['payment_id']),
    );
  }

  @override
  Future<void> payOrderWithCliq({
    required String paymentId,
    required String transactionNumber,
    required String refundName,
    required CliqReceipt receipt,
  }) async {
    await sendCliqPayment(
      _apiClient,
      '/member/cliq',
      fields: <String, Object?>{'payment_id': paymentId},
      transactionNumber: transactionNumber,
      refundName: refundName,
      receipt: receipt,
    );
    _cache.remove('order-payments');
  }

  @override
  Future<String?> getCliqAlias() => readCliqAlias(_apiClient);

  @override
  Future<void> cancelOrder(String orderId) async {
    await _apiClient.patch(
      '/member/orders/${Uri.encodeComponent(orderId)}/cancel',
    );
  }
}
