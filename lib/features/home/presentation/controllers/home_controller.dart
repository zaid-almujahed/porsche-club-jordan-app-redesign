import 'package:flutter/foundation.dart';

import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/home_feed.dart';

import '../../domain/repositories/home_repository.dart';

class HomeController extends ChangeNotifier {
  HomeController({required HomeRepository repository})
    : _repository = repository;

  final HomeRepository _repository;
  AsyncState<HomeFeed> _state = const AsyncState<HomeFeed>.initial();

  AsyncState<HomeFeed> get state => _state;

  Future<void> load({bool force = false}) async {
    if (!force && (_state.isLoading || _state.hasData)) return;

    _state = AsyncState<HomeFeed>.loading(previousData: _state.data);
    notifyListeners();
    try {
      _state = AsyncState<HomeFeed>.success(
        await _repository.getHomeFeed(forceRefresh: force),
      );
    } catch (error, stackTrace) {
      _state = AsyncState<HomeFeed>.failure(
        error,
        stackTrace,
        previousData: _state.data,
      );
    }
    notifyListeners();
  }

  void reset() {
    _state = const AsyncState<HomeFeed>.initial();
    notifyListeners();
  }
}
