import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/offer.dart';

import '../../domain/repositories/offers_repository.dart';

class OffersController extends ChangeNotifier {
  OffersController({required OffersRepository repository})
    : _repository = repository;

  final OffersRepository _repository;
  final TextEditingController searchController = TextEditingController();
  AsyncState<List<Offer>> _offers = const AsyncState<List<Offer>>.initial();
  List<Offer> _allOffers = const <Offer>[];
  List<String> _categories = const <String>[];
  String? _selectedCategory;
  String _searchQuery = '';
  int _requestId = 0;
  final Set<String> _claimingOfferIds = <String>{};

  /// Offers claimed in the last [claimCooldown].
  final Map<String, Timer> _claimCooldowns = <String, Timer>{};
  Object? _actionError;

  static const Duration claimCooldown = Duration(seconds: 5);

  AsyncState<List<Offer>> get offers => _offers;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  Object? get actionError => _actionError;
  bool get hasSearchQuery => _searchQuery.isNotEmpty;
  bool isClaiming(String offerId) => _claimingOfferIds.contains(offerId);

  /// Just claimed: [offerId] cannot be claimed again until [claimCooldown]
  /// has passed.
  bool isCoolingDown(String offerId) => _claimCooldowns.containsKey(offerId);

  Future<void> load({bool force = false}) async {
    if (!force && (_offers.isLoading || _offers.hasData)) return;
    await _fetch(forceRefresh: force);
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    if (_offers.hasData) _applyFilter();
    notifyListeners();
  }

  void search(String value) {
    final String query = value.trim().toLowerCase();
    if (_searchQuery == query) return;
    _searchQuery = query;
    if (_offers.hasData) _applyFilter();
    notifyListeners();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty && searchController.text.isEmpty) return;
    searchController.clear();
    search('');
  }

  /// Claims [offer]. Offers can be claimed any number of times, once every
  /// [claimCooldown]; the page confirms each claim with a short animation.
  Future<bool> claimOffer(Offer offer) async {
    if (_claimingOfferIds.contains(offer.id) || isCoolingDown(offer.id)) {
      return false;
    }
    _claimingOfferIds.add(offer.id);
    _actionError = null;
    notifyListeners();
    try {
      await _repository.claimOffer(offer.id);
      _claimCooldowns[offer.id] = Timer(claimCooldown, () {
        _claimCooldowns.remove(offer.id);
        notifyListeners();
      });
      return true;
    } catch (error) {
      _actionError = error;
      return false;
    } finally {
      _claimingOfferIds.remove(offer.id);
      notifyListeners();
    }
  }

  Future<void> _fetch({required bool forceRefresh}) async {
    final int requestId = ++_requestId;
    _offers = AsyncState<List<Offer>>.loading(previousData: _offers.data);
    notifyListeners();
    try {
      final List<Offer> offers = List<Offer>.unmodifiable(
        await _repository.getOffers(forceRefresh: forceRefresh),
      );
      if (requestId != _requestId) return;
      _allOffers = offers;
      _categories = const <String>['NUQUL', 'PARTNERS'];
      _selectedCategory ??= _categories.first;
      _applyFilter();
    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
      _offers = AsyncState<List<Offer>>.failure(
        error,
        stackTrace,
        previousData: _offers.data,
      );
    }
    if (requestId != _requestId) return;
    notifyListeners();
  }

  void _applyFilter() {
    final String selected = _selectedCategory?.trim().toLowerCase() ?? '';
    final List<Offer> visible =
        _allOffers
            .where((Offer offer) {
              if (selected == 'nuqul') return offer.isNuqulExclusive;
              if (selected == 'partners') return !offer.isNuqulExclusive;
              return true;
            })
            .where((Offer offer) {
              if (_searchQuery.isEmpty) return true;
              return offer.title.toLowerCase().contains(_searchQuery) ||
                  offer.description.toLowerCase().contains(_searchQuery) ||
                  offer.displayPartnerName.toLowerCase().contains(
                    _searchQuery,
                  ) ||
                  offer.location.toLowerCase().contains(_searchQuery) ||
                  offer.category.toLowerCase().contains(_searchQuery);
            })
            .toList(growable: false)
          ..sort((Offer left, Offer right) {
            if (left.isClaimed == right.isClaimed) return 0;
            return left.isClaimed ? 1 : -1;
          });
    _offers = AsyncState<List<Offer>>.success(
      List<Offer>.unmodifiable(visible),
    );
  }

  void reset() {
    _requestId++;
    _offers = const AsyncState<List<Offer>>.initial();
    _allOffers = const <Offer>[];
    _categories = const <String>[];
    _selectedCategory = null;
    _searchQuery = '';
    searchController.clear();
    _claimingOfferIds.clear();
    _cancelCooldowns();
    _actionError = null;
    notifyListeners();
  }

  void _cancelCooldowns() {
    for (final Timer timer in _claimCooldowns.values) {
      timer.cancel();
    }
    _claimCooldowns.clear();
  }

  @override
  void dispose() {
    _cancelCooldowns();
    searchController.dispose();
    super.dispose();
  }
}
