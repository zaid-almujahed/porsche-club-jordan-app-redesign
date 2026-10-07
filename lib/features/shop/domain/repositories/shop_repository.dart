import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
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

/// What `POST /member/cart/checkout` answers.
class PlacedOrder {
  const PlacedOrder({
    required this.orderId,
    this.paymentId,
    this.total,
    this.requiresCliqPayment = false,
  });

  final String orderId;

  /// The payment a CliQ transfer is sent for.
  final String? paymentId;
  final double? total;

  /// The member still has to send the CliQ payment.
  final bool requiresCliqPayment;
}

abstract interface class ShopRepository {
  Future<List<Product>> getProducts({bool forceRefresh = false});

  Future<Product> getProduct(String productId, {bool forceRefresh = false});

  Future<Cart> getCart();

  Future<Cart> addToCart(AddToCartRequest request);

  Future<Cart> removeCartItem(CartItem item);

  /// `POST /member/cart/checkout`. My Orders is reloaded after it.
  Future<PlacedOrder> placeOrder(PlaceOrderRequest request);

  /// `POST /member/cliq`: an order's payment, with the transfer number, the
  /// member's alias for a refund and a screenshot of the receipt, for an
  /// admin to approve.
  Future<void> payOrderWithCliq({
    required String paymentId,
    required String transactionNumber,
    required String refundName,
    required CliqReceipt receipt,
  });

  /// The club's CliQ alias, or null while it is not known.
  Future<String?> getCliqAlias();
}
