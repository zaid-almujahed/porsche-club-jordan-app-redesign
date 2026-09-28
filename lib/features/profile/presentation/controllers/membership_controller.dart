import 'package:flutter/foundation.dart';

import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/membership.dart';

import '../../domain/repositories/membership_repository.dart';

class MembershipController extends ChangeNotifier {
  MembershipController({required MembershipRepository repository})
    : _repository = repository;

  final MembershipRepository _repository;
  AsyncState<Membership> _state = const AsyncState<Membership>.initial();

  AsyncState<Membership> get state => _state;

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

  void reset() {
    _state = const AsyncState<Membership>.initial();
    notifyListeners();
  }
}
