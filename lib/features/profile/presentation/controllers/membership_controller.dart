import 'package:flutter/foundation.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';

import '../../domain/repositories/membership_repository.dart';

class MembershipController extends ChangeNotifier {
  MembershipController({required MembershipRepository repository})
    : _repository = repository;

  final MembershipRepository _repository;
  AsyncState<Membership> _state = const AsyncState<Membership>.initial();
  bool _isRenewing = false;
  Object? _renewalError;

  AsyncState<Membership> get state => _state;
  bool get isRenewing => _isRenewing;
  Object? get renewalError => _renewalError;

  Future<void> load({bool force = false}) async {
    if (!force && (_state.isLoading || _state.hasData)) return;
    _state = AsyncState<Membership>.loading(previousData: _state.data);
    notifyListeners();
    try {
      _state = AsyncState<Membership>.success(
        await _repository.getMembership(forceRefresh: force),
      );
    } catch (error, stackTrace) {
      _state = AsyncState<Membership>.failure(
        error,
        stackTrace,
        previousData: _state.data,
      );
    }
    notifyListeners();
  }

  Future<bool> renew() async {
    if (_isRenewing) return false;
    _isRenewing = true;
    _renewalError = null;
    notifyListeners();
    try {
      final Membership membership = await _repository.startMembershipPayment();
      _state = AsyncState<Membership>.success(membership);
      if (membership.status != MembershipStatus.active) {
        _renewalError = const AppException(
          'The renewal request was started, but the backend has not confirmed '
          'payment. Membership dates will update after confirmation.',
        );
        return false;
      }
      return true;
    } catch (error) {
      _renewalError = error;
      return false;
    } finally {
      _isRenewing = false;
      notifyListeners();
    }
  }

  void reset() {
    _state = const AsyncState<Membership>.initial();
    _isRenewing = false;
    _renewalError = null;
    notifyListeners();
  }
}
