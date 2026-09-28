import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';

class AddToCartRequest {
  const AddToCartRequest({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  final Product product;
  final ProductVariant variant;
  final int quantity;

  String get variantId => variant.id;
}

class PlaceOrderRequest {
  const PlaceOrderRequest({
    required this.deliveryMethod,
    required this.paymentMethod,
    this.deliveryAddress,
  });

  final DeliveryMethod deliveryMethod;
  final PaymentMethod paymentMethod;
  final String? deliveryAddress;
}

abstract interface class ShopRepository {
  Future<List<Product>> getProducts({
    String? category,
    bool forceRefresh = false,
  });

  Future<Product> getProduct(String productId, {bool forceRefresh = false});

  Future<Cart> getCart();

  Future<Cart> addToCart(AddToCartRequest request);

  Future<Cart> removeCartItem(CartItem item);

  Future<Order> placeOrder(PlaceOrderRequest request);
}
