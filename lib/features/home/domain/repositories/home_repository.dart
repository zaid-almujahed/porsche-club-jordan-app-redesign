import 'package:pcj_v5/shared/domain/entities/home_feed.dart';

abstract interface class HomeRepository {
  Future<HomeFeed> getHomeFeed({bool forceRefresh = false});
}
