import 'package:flutter/foundation.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';

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

  AsyncState<Cart> get cart => _cart;
  DeliveryMethod get deliveryMethod => _deliveryMethod;
  PaymentMethod get paymentMethod => _paymentMethod;
  String? get deliveryAddress => _deliveryAddress;
  bool get isPlacingOrder => _isPlacingOrder;
  Object? get orderError => _orderError;

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

  Future<Order?> placeOrder() async {
    if (_isPlacingOrder ||
        _cart.isLoading ||
        _cart.data == null ||
        _cart.data!.items.isEmpty) {
      return null;
    }
    if (_deliveryMethod == DeliveryMethod.delivery &&
        (_deliveryAddress == null || _deliveryAddress!.isEmpty)) {
      _orderError = const AppException('Choose a delivery address.');
      notifyListeners();
      return null;
    }

    _isPlacingOrder = true;
    _orderError = null;
    notifyListeners();
    try {
      return await _repository.placeOrder(
        PlaceOrderRequest(
          deliveryMethod: _deliveryMethod,
          paymentMethod: _paymentMethod,
          deliveryAddress: _deliveryAddress,
        ),
      );
    } catch (error) {
      _orderError = error;
      return null;
    } finally {
      _isPlacingOrder = false;
      notifyListeners();
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
    notifyListeners();
  }
}
