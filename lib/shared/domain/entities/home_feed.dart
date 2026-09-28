import 'event.dart';
import 'offer.dart';
import 'order.dart';
import 'product.dart';

class HomeFeed {
  const HomeFeed({
    required this.featuredEvent,
    required this.seasonEvents,
    required this.popularProducts,
    required this.featuredOffers,
    this.latestOrder,
  });

  final Event? featuredEvent;
  final List<Event> seasonEvents;
  final List<Product> popularProducts;
  final List<Offer> featuredOffers;

  /// The member's most recent order that is still in progress, for tracking
  /// from Home. Null when there is none.
  final Order? latestOrder;
}
