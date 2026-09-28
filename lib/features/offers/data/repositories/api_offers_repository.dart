import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/features/offers/domain/repositories/offers_repository.dart';

import '../models/offer_model.dart';

class ApiOffersRepository implements OffersRepository {
  ApiOffersRepository({
    required PcjApiClient apiClient,
    required MemoryCache cache,
  }) : _apiClient = apiClient,
       _cache = cache;

  final PcjApiClient _apiClient;
  final MemoryCache _cache;
  final Set<String> _claimedOfferIds = <String>{};

  @override
  Future<List<Offer>> getOffers({
    String? category,
    bool forceRefresh = false,
  }) async {
    final List<Offer> rawOffers = await _cache.getOrLoad<List<Offer>>(
      'offers:all',
      () async =>
          _readList(await _apiClient.get('/member/offers'))
              .map<Offer>(OfferModel.fromJson)
              .toList(growable: false),
      ttl: const Duration(minutes: 5),
      force: forceRefresh,
    );
    // Offers can be claimed any number of times, so a previous claim no
    // longer marks (and disables) the offer.
    final List<Offer> offers = rawOffers;
    final String normalized = category?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty || normalized == 'all') return offers;
    return offers
        .where((Offer offer) => offer.category.toLowerCase() == normalized)
        .toList(growable: false);
  }

  @override
  Future<Offer> getOffer(String offerId) async {
    return OfferModel.fromJson(
      requireJsonMap(
        await _apiClient.get('/member/offers/${Uri.encodeComponent(offerId)}'),
        description: 'offer response',
      ),
    );
  }

  @override
  Future<void> claimOffer(String offerId) async {
    final String normalizedOfferId = offerId.trim();
    if (normalizedOfferId.isEmpty) {
      throw const AppException('The offer ID is missing.');
    }
    await _apiClient.post(
      '/member/offers/${Uri.encodeComponent(normalizedOfferId)}/claim',
      authenticated: true,
    );
    _claimedOfferIds.add(normalizedOfferId);
    _cache.remove('offers:all');
  }

  @override
  Future<List<Offer>> getClaimedOffers({bool forceRefresh = false}) async {
    final List<Offer> offers = await getOffers(forceRefresh: forceRefresh);
    return offers
        .where((Offer offer) => _claimedOfferIds.contains(offer.id))
        .map((Offer offer) => offer.copyWith(isClaimed: true))
        .toList(growable: false);
  }

  @override
  void clearLocalState() {
    _claimedOfferIds.clear();
  }

  static List<Map<String, dynamic>> _readList(Object? response) {
    final Object? value = unwrapApiData(response);
    if (value is! List) {
      throw const AppException(
        'The server returned an invalid offers response.',
      );
    }
    return value
        .whereType<Map>()
        .map<Map<String, dynamic>>((Map item) {
          return Map<String, dynamic>.from(item);
        })
        .toList(growable: false);
  }
}
