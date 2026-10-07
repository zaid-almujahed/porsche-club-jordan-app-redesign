import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/cliq_payment.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';

import '../../domain/repositories/shop_repository.dart';

class CheckoutController extends ChangeNotifier {
  CheckoutController({required ShopRepository repository})
    : _repository = repository;

  final ShopRepository _repository;
  AsyncState<Cart> _cart = const AsyncState<Cart>.initial();
  DeliveryMethod _deliveryMethod = DeliveryMethod.pickup;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _deliveryAddress;
  bool _isPlacingOrder = false;
  Object? _orderError;
  int _cartRequestId = 0;
  final Set<String> _addingProductIds = <String>{};
  Object? _addError;

  /// What delivery adds to an order; picking it up is free.
  static const double deliveryCharge = 2;

  /// Items in the member's cart, for the badge on the cart button.
  late final ValueListenable<int> itemCount = _CartItemCount(this);

  AsyncState<Cart> get cart => _cart;
  Object? get addError => _addError;
  bool isAdding(String productId) => _addingProductIds.contains(productId);
  DeliveryMethod get deliveryMethod => _deliveryMethod;
  double get deliveryFee =>
      _deliveryMethod == DeliveryMethod.delivery ? deliveryCharge : 0;
  PaymentMethod get paymentMethod => _paymentMethod;
  String? get deliveryAddress => _deliveryAddress;
  bool get isPlacingOrder => _isPlacingOrder;
  Object? get orderError => _orderError;

  /// How many of [variantId] the member already has in the cart.
  int quantityInCart(String variantId) {
    int total = 0;
    for (final CartItem item in _cart.data?.items ?? const <CartItem>[]) {
      if (item.variantId == variantId) total += item.quantity;
    }
    return total;
  }

  void useCart(Cart value) {
    _cartRequestId++;
    _cart = AsyncState<Cart>.success(value);
    _orderError = null;
    notifyListeners();
  }

  Future<void> load({bool force = false}) async {
    if (!force && (_cart.isLoading || _cart.hasData)) return;
    await _replaceCart(() => _repository.getCart());
  }

  void selectDeliveryMethod(DeliveryMethod value) {
    _deliveryMethod = value;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethod value) {
    _paymentMethod = value;
    notifyListeners();
  }

  void setDeliveryAddress(String? value) {
    _deliveryAddress = value?.trim();
    notifyListeners();
  }

  /// Adds a product straight from a card (shop grid, home rail). The member
  /// stays on the current page; only the cart badge changes.
  Future<bool> addItem(
    Product product,
    ProductVariant variant, {
    int quantity = 1,
  }) async {
    if (_addingProductIds.contains(product.id)) return false;
    _addingProductIds.add(product.id);
    _addError = null;
    notifyListeners();
    try {
      final Cart cart = await _repository.addToCart(
        AddToCartRequest(
          product: product,
          variant: variant,
          quantity: quantity,
        ),
      );
      useCart(cart);
      return true;
    } catch (error) {
      _addError = error;
      return false;
    } finally {
      _addingProductIds.remove(product.id);
      notifyListeners();
    }
  }

  /// Removes from the server's cart what [ordered] held. Anything added
  /// since stays.
  Future<void> _removeOrderedItems(Cart ordered) async {
    final Set<String> ids = ordered.items
        .map((CartItem item) => item.id)
        .toSet();
    try {
      final Cart left = await _repository.getCart();
      for (final CartItem item in left.items) {
        if (ids.contains(item.id)) await _repository.removeCartItem(item);
      }
    } catch (_) {
      // Shown empty anyway; the next load shows anything left.
    }
  }

  Future<void> removeItem(CartItem item) async {
    await _replaceCart(() => _repository.removeCartItem(item));
  }

  Future<void> _replaceCart(Future<Cart> Function() action) async {
    final int requestId = ++_cartRequestId;
    _cart = AsyncState<Cart>.loading(previousData: _cart.data);
    notifyListeners();
    try {
      final Cart value = await action();
      if (requestId != _cartRequestId) return;
      _cart = AsyncState<Cart>.success(value);
    } catch (error, stackTrace) {
      if (requestId != _cartRequestId) return;
      _cart = AsyncState<Cart>.failure(
        error,
        stackTrace,
        previousData: _cart.data,
      );
    }
    if (requestId != _cartRequestId) return;
    notifyListeners();
  }

  /// What the order comes to: the items and the delivery charge.
  double get orderTotal => (_cart.data?.subtotal ?? 0) + deliveryFee;

  /// True when the cart can be ordered; otherwise false, with an error set
  /// when the member has something to fix.
  bool validateOrder() {
    final Cart? cart = _cart.data;
    if (_isPlacingOrder ||
        _cart.isLoading ||
        cart == null ||
        cart.items.isEmpty) {
      return false;
    }
    if (_deliveryMethod == DeliveryMethod.delivery &&
        (_deliveryAddress == null || _deliveryAddress!.isEmpty)) {
      _orderError = const AppException('Choose a delivery address.');
      notifyListeners();
      return false;
    }
    return true;
  }

  /// True once the order is placed.
  Future<bool> placeOrder() async {
    if (!validateOrder()) return false;
    final Cart ordered = _cart.data!;
    _isPlacingOrder = true;
    _orderError = null;
    notifyListeners();
    try {
      await _repository.placeOrder(
        PlaceOrderRequest(
          deliveryMethod: _deliveryMethod,
          paymentMethod: _paymentMethod,
          deliveryAddress: _deliveryAddress,
        ),
      );
      _emptyCart(ordered);
      return true;
    } catch (error) {
      _orderError = error;
      return false;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  /// Places a CliQ order and sends its payment right after it: an order is
  /// never left without its payment. If the payment fails, the order is
  /// cancelled at once and its items go back in the cart.
  Future<void> placeCliqOrder({
    required String transactionNumber,
    required String refundName,
    required CliqReceipt receipt,
  }) async {
    if (!validateOrder()) {
      throw _orderError ?? const AppException('Your cart is empty.');
    }
    final Cart ordered = _cart.data!;
    _isPlacingOrder = true;
    _orderError = null;
    notifyListeners();
    try {
      final PlacedOrder placed = await _repository.placeOrder(
        PlaceOrderRequest(
          deliveryMethod: _deliveryMethod,
          paymentMethod: PaymentMethod.cliq,
          deliveryAddress: _deliveryAddress,
        ),
      );
      try {
        final String? paymentId = placed.paymentId;
        if (paymentId == null) {
          throw const AppException('The order has no payment id.');
        }
        await _repository.payOrderWithCliq(
          paymentId: paymentId,
          transactionNumber: transactionNumber,
          refundName: refundName,
          receipt: receipt,
        );
      } catch (_) {
        await _undoOrder(placed.orderId, ordered);
        throw const AppException(
          'Your payment could not be sent, so your order was not placed. '
          'Please try again.',
        );
      }
      _emptyCart(ordered);
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
    }
  }

  // The cart starts empty again, also when the server keeps the ordered
  // items in it.
  void _emptyCart(Cart ordered) {
    useCart(
      Cart(
        items: const <CartItem>[],
        shippingFee: 0,
        currency: ordered.currency,
      ),
    );
    unawaited(_removeOrderedItems(ordered));
  }

  /// Cancels an order whose payment failed and puts its items back in the
  /// cart.
  Future<void> _undoOrder(String orderId, Cart ordered) async {
    try {
      await _repository.cancelOrder(orderId);
    } catch (_) {
      throw const AppException(
        'Your payment could not be sent. Please contact support about your '
        'order.',
      );
    }
    try {
      Cart cart = await _repository.getCart();
      for (final CartItem item in ordered.items) {
        final bool kept = cart.items.any(
          (CartItem left) => left.variantId == item.variantId,
        );
        if (kept || item.product.variants.isEmpty) continue;
        cart = await _repository.addToCart(
          AddToCartRequest(
            product: item.product,
            variant: item.product.variants.first,
            quantity: item.quantity,
          ),
        );
      }
      useCart(cart);
    } catch (_) {
      // The checkout reloads the cart when it opens again.
    }
  }

  void reset() {
    _cartRequestId++;
    _cart = const AsyncState<Cart>.initial();
    _deliveryMethod = DeliveryMethod.pickup;
    _paymentMethod = PaymentMethod.cash;
    _deliveryAddress = null;
    _isPlacingOrder = false;
    _orderError = null;
    _addingProductIds.clear();
    _addError = null;
    notifyListeners();
  }
}

class _CartItemCount implements ValueListenable<int> {
  _CartItemCount(this._controller);

  final CheckoutController _controller;

  @override
  int get value => _controller.cart.data?.itemCount ?? 0;

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }
}
