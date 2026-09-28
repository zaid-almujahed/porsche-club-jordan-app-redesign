import 'package:pcj_v5/features/events/domain/repositories/events_repository.dart';
import 'package:pcj_v5/features/home/domain/repositories/home_repository.dart';
import 'package:pcj_v5/features/offers/domain/repositories/offers_repository.dart';
import 'package:pcj_v5/features/shop/domain/repositories/shop_repository.dart';
import 'package:pcj_v5/features/user_orders/domain/repositories/user_orders_repository.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/domain/entities/home_feed.dart';
import 'package:pcj_v5/shared/domain/entities/offer.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';

/// Builds the home feed from documented feature endpoints; there is no home
/// feed endpoint in the current PCJ API documentation.
class CompositeHomeRepository implements HomeRepository {
  CompositeHomeRepository({
    required EventsRepository eventsRepository,
    required ShopRepository shopRepository,
    required OffersRepository offersRepository,
    UserOrdersRepository? userOrdersRepository,
  }) : _eventsRepository = eventsRepository,
       _shopRepository = shopRepository,
       _offersRepository = offersRepository,
       _userOrdersRepository = userOrdersRepository;

  final EventsRepository _eventsRepository;
  final ShopRepository _shopRepository;
  final OffersRepository _offersRepository;
  final UserOrdersRepository? _userOrdersRepository;

  @override
  Future<HomeFeed> getHomeFeed({bool forceRefresh = false}) async {
    // Start the independent requests together so the home screen waits for
    // the slowest endpoint rather than the sum of all three response times.
    final Future<_FeedResult<Event>> eventsRequest = _load<Event>(
      _eventsRepository.getRecentEvents(forceRefresh: forceRefresh),
    );
    final Future<_FeedResult<Product>> productsRequest = _load<Product>(
      _shopRepository.getProducts(forceRefresh: forceRefresh),
    );
    final Future<_FeedResult<Offer>> offersRequest = _load<Offer>(
      _offersRepository.getOffers(forceRefresh: forceRefresh),
    );
    // Orders are optional on Home: a failure only hides the tracking card.
    final UserOrdersRepository? userOrders = _userOrdersRepository;
    final Future<_FeedResult<Order>> ordersRequest = userOrders == null
        ? Future<_FeedResult<Order>>.value(const _FeedResult<Order>(values: []))
        : _load<Order>(userOrders.getOrders(active: true));
    final _FeedResult<Event> eventResult = await eventsRequest;
    final _FeedResult<Product> productResult = await productsRequest;
    final _FeedResult<Offer> offerResult = await offersRequest;
    final _FeedResult<Order> orderResult = await ordersRequest;
    if (eventResult.error != null &&
        productResult.error != null &&
        offerResult.error != null) {
      Error.throwWithStackTrace(
        eventResult.error!,
        eventResult.stackTrace ?? StackTrace.current,
      );
    }
    final List<Event> events = eventResult.values;
    final List<Product> products = productResult.values;
    final List<Offer> offers = offerResult.values;
    final Event? featured = _featured(events);

    return HomeFeed(
      featuredEvent: featured,
      seasonEvents: events.take(6).toList(growable: false),
      popularProducts: products.take(4).toList(growable: false),
      featuredOffers: offers.take(3).toList(growable: false),
      latestOrder: _latest(orderResult.values),
    );
  }

  static Order? _latest(List<Order> orders) {
    if (orders.isEmpty) return null;
    return orders.reduce(
      (Order a, Order b) => b.createdAt.isAfter(a.createdAt) ? b : a,
    );
  }

  static Event? _featured(List<Event> events) {
    if (events.isEmpty) return null;
    return events.firstWhere(
      (Event event) => event.isFeatured,
      orElse: () => events.first,
    );
  }

  static Future<_FeedResult<T>> _load<T>(Future<List<T>> request) async {
    try {
      return _FeedResult<T>(values: await request);
    } catch (error, stackTrace) {
      return _FeedResult<T>(
        values: <T>[],
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

class _FeedResult<T> {
  const _FeedResult({required this.values, this.error, this.stackTrace});

  final List<T> values;
  final Object? error;
  final StackTrace? stackTrace;
}
