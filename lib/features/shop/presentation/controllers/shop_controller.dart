import 'package:flutter/material.dart';

import 'package:pcj_v5/core/state/async_state.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';

import '../../domain/repositories/shop_repository.dart';

class ShopController extends ChangeNotifier {
  ShopController({required ShopRepository repository})
    : _repository = repository;

  final ShopRepository _repository;
  final TextEditingController searchController = TextEditingController();
  AsyncState<List<Product>> _products =
      const AsyncState<List<Product>>.initial();
  List<Product> _allProducts = const <Product>[];
  String _searchQuery = '';
  int _requestId = 0;

  AsyncState<List<Product>> get products => _products;
  bool get hasSearchQuery => _searchQuery.isNotEmpty;

  Future<void> load({bool force = false}) async {
    if (!force && (_products.isLoading || _products.hasData)) return;
    await _fetch(forceRefresh: force);
  }

  void search(String value) {
    final String query = value.trim().toLowerCase();
    if (_searchQuery == query) return;
    _searchQuery = query;
    if (_products.hasData) _applyFilter();
    notifyListeners();
  }

  void clearSearch() {
    if (_searchQuery.isEmpty && searchController.text.isEmpty) return;
    searchController.clear();
    search('');
  }

  Future<void> _fetch({required bool forceRefresh}) async {
    final int requestId = ++_requestId;
    _products = AsyncState<List<Product>>.loading(previousData: _products.data);
    notifyListeners();
    try {
      final List<Product> products = List<Product>.unmodifiable(
        await _repository.getProducts(forceRefresh: forceRefresh),
      );
      if (requestId != _requestId) return;
      _allProducts = products;
      _applyFilter();
    } catch (error, stackTrace) {
      if (requestId != _requestId) return;
      _products = AsyncState<List<Product>>.failure(
        error,
        stackTrace,
        previousData: _products.data,
      );
    }
    if (requestId != _requestId) return;
    notifyListeners();
  }

  void _applyFilter() {
    final List<Product> visible = _allProducts.where((Product product) {
      if (_searchQuery.isEmpty) return true;
      return product.name.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery) ||
          product.colors.any(
            (ProductColorOption color) =>
                color.name.toLowerCase().contains(_searchQuery),
          ) ||
          product.sizes.any(
            (String size) => size.toLowerCase().contains(_searchQuery),
          );
    }).toList(growable: false);
    _products = AsyncState<List<Product>>.success(
      List<Product>.unmodifiable(visible),
    );
  }

  void reset() {
    _requestId++;
    _products = const AsyncState<List<Product>>.initial();
    _allProducts = const <Product>[];
    _searchQuery = '';
    searchController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
