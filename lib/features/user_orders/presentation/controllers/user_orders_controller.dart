import 'package:flutter/foundation.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';

import '../../domain/repositories/user_orders_repository.dart';

class UserOrdersController extends ChangeNotifier {
  UserOrdersController({required UserOrdersRepository repository})
    : _repository = repository;

  final UserOrdersRepository _repository;
  AsyncState<List<Order>> _orders = const AsyncState<List<Order>>.initial();
  bool _showActive = true;
  int _requestId = 0;

  AsyncState<List<Order>> get orders => _orders;
  bool get showActive => _showActive;

  Future<void> load({bool force = false}) async {
    if (!force && (_orders.isLoading || _orders.hasData)) return;
    await _fetch();
  }

  Future<void> showTab({required bool active}) async {
    if (_showActive == active) return;
    _showActive = active;
    notifyListeners();
    await _fetch();
  }

  Future<Order> getOrderDetails(String orderId) {
    return _repository.getOrder(orderId);
  }

  Future<OrderCancellationResult> cancelOrder(Order order) async {
    if (!order.canCancel) {
      throw const AppException('This order can no longer be cancelled.');
    }
    final OrderCancellationResult result = await _repository.cancelOrder(
      order.id,
    );
    await _fetch();
    return result;
  }

  Future<void> _fetch() async {
    final int requestId = ++_requestId;
    _orders = AsyncState<List<Order>>.loading(previousData: _orders.data);
    notifyListeners();
    try {
      final List<Order> orders = List<Order>.unmodifiable(
        await _repository.getOrders(active: _showActive),
      );
      if (requestId != _requestId) return;
      _orders = AsyncState<List<Order>>.success(orders);
    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
      _orders = AsyncState<List<Order>>.failure(
        error,
        stackTrace,
        previousData: _orders.data,
      );
    }
    if (requestId != _requestId) return;
    notifyListeners();
  }

  void reset() {
    _requestId++;
    _orders = const AsyncState<List<Order>>.initial();
    _showActive = true;
    notifyListeners();
  }
}
