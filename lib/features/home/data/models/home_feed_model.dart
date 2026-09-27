import 'package:pcj_v5/features/events/data/models/event_model.dart';
import 'package:pcj_v5/features/offers/data/models/offer_model.dart';
import 'package:pcj_v5/features/shop/data/models/product_model.dart';
import 'package:pcj_v5/shared/domain/entities/home_feed.dart';

class HomeFeedModel extends HomeFeed {
  const HomeFeedModel({
    required super.featuredEvent,
    required super.seasonEvents,
    required super.popularProducts,
    required super.featuredOffers,
  });

  factory HomeFeedModel.fromJson(Map<String, dynamic> json) {
    final Object? featuredEventJson = json['featured_event'];
    return HomeFeedModel(
      featuredEvent: featuredEventJson is Map
          ? EventModel.fromSummaryJson(
              Map<String, dynamic>.from(featuredEventJson),
            )
          : null,
      seasonEvents: _maps(
        json['season_events'],
      ).map(EventModel.fromSummaryJson).toList(growable: false),
      popularProducts: _maps(
        json['popular_products'],
      ).map(ProductModel.fromJson).toList(growable: false),
      featuredOffers: _maps(
        json['featured_offers'],
      ).map(OfferModel.fromJson).toList(growable: false),
    );
  }

  static List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
