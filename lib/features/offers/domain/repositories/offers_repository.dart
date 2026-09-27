import 'package:pcj_v5/shared/domain/entities/offer.dart';

abstract interface class OffersRepository {
  Future<List<Offer>> getOffers({String? category, bool forceRefresh = false});

  Future<Offer> getOffer(String offerId);

  Future<void> claimOffer(String offerId);

  Future<List<Offer>> getClaimedOffers({bool forceRefresh = false});

  void clearLocalState();
}
