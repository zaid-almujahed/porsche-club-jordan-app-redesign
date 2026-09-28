import 'package:http/http.dart' as http;

import 'package:pcj_v5/core/cache/memory_cache.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/core/network/token_store.dart';
import 'package:pcj_v5/core/services/image_picker_service.dart';
import 'package:pcj_v5/features/auth/data/repositories/api_auth_repository.dart';
import 'package:pcj_v5/features/auth/domain/repositories/auth_repository.dart';
import 'package:pcj_v5/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pcj_v5/features/events/data/repositories/api_events_repository.dart';
import 'package:pcj_v5/features/events/domain/repositories/events_repository.dart';
import 'package:pcj_v5/features/events/presentation/controllers/events_controller.dart';
import 'package:pcj_v5/features/home/data/repositories/composite_home_repository.dart';
import 'package:pcj_v5/features/home/domain/repositories/home_repository.dart';
import 'package:pcj_v5/features/home/presentation/controllers/home_controller.dart';
import 'package:pcj_v5/features/offers/data/repositories/api_offers_repository.dart';
import 'package:pcj_v5/features/offers/domain/repositories/offers_repository.dart';
import 'package:pcj_v5/features/offers/presentation/controllers/offers_controller.dart';
import 'package:pcj_v5/features/notifications/data/repositories/api_notifications_repository.dart';
import 'package:pcj_v5/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:pcj_v5/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:pcj_v5/features/profile/data/repositories/api_membership_repository.dart';
import 'package:pcj_v5/features/profile/data/repositories/api_profile_repository.dart';
import 'package:pcj_v5/features/profile/domain/repositories/membership_repository.dart';
import 'package:pcj_v5/features/profile/domain/repositories/profile_repository.dart';
import 'package:pcj_v5/features/profile/presentation/controllers/membership_controller.dart';
import 'package:pcj_v5/features/profile/presentation/controllers/profile_controller.dart';
import 'package:pcj_v5/features/registration/data/repositories/api_registration_repository.dart';
import 'package:pcj_v5/features/registration/domain/repositories/registration_repository.dart';
import 'package:pcj_v5/features/registration/presentation/controllers/membership_payment_controller.dart';
import 'package:pcj_v5/features/registration/presentation/controllers/registration_controller.dart';
import 'package:pcj_v5/features/shop/data/repositories/api_shop_repository.dart';
import 'package:pcj_v5/features/shop/domain/repositories/shop_repository.dart';
import 'package:pcj_v5/features/shop/presentation/controllers/checkout_controller.dart';
import 'package:pcj_v5/features/shop/presentation/controllers/shop_controller.dart';
import 'package:pcj_v5/features/user_events/data/repositories/api_user_events_repository.dart';
import 'package:pcj_v5/features/user_events/domain/repositories/user_events_repository.dart';
import 'package:pcj_v5/features/user_events/presentation/controllers/user_events_controller.dart';
import 'package:pcj_v5/features/user_orders/data/repositories/api_user_orders_repository.dart';
import 'package:pcj_v5/features/user_orders/domain/repositories/user_orders_repository.dart';
import 'package:pcj_v5/features/user_orders/presentation/controllers/user_orders_controller.dart';

/// Composition root: creates each object once and states who owns its lifetime.
class AppDependencies {
  AppDependencies._({
    required http.Client httpClient,
    required this.memoryCache,
    required this.authRepository,
    required this.eventsRepository,
    required this.shopRepository,
    required this.offersRepository,
    required this.notificationsRepository,
    required this.profileRepository,
    required this.membershipRepository,
    required this.registrationRepository,
    required this.userEventsRepository,
    required this.userOrdersRepository,
    required this.authController,
    required this.homeController,
    required this.eventsController,
    required this.shopController,
    required this.checkoutController,
    required this.offersController,
    required this.notificationsController,
    required this.profileController,
    required this.membershipController,
    required this.userEventsController,
    required this.userOrdersController,
    required this.registrationController,
    required this.membershipPaymentController,
  }) : _httpClient = httpClient;

  factory AppDependencies.create() {
    final http.Client httpClient = http.Client();
    final MemoryCache memoryCache = MemoryCache();
    final TokenStore tokenStore = SecureTokenStore();
    final PcjApiClient apiClient = PcjApiClient(
      httpClient,
      tokenStore: tokenStore,
    );

    final AuthRepository authRepository = ApiAuthRepository(
      apiClient: apiClient,
      tokenStore: tokenStore,
    );
    final EventsRepository eventsRepository = ApiEventsRepository(
      apiClient: apiClient,
      cache: memoryCache,
    );
    final ShopRepository shopRepository = ApiShopRepository(
      apiClient: apiClient,
      cache: memoryCache,
    );
    final OffersRepository offersRepository = ApiOffersRepository(
      apiClient: apiClient,
      cache: memoryCache,
    );
    final NotificationsRepository notificationsRepository =
        ApiNotificationsRepository(apiClient: apiClient);
    final ProfileRepository profileRepository = ApiProfileRepository(
      apiClient: apiClient,
      cache: memoryCache,
    );
    final MembershipRepository membershipRepository = ApiMembershipRepository(
      apiClient: apiClient,
      cache: memoryCache,
    );
    final RegistrationRepository registrationRepository =
        ApiRegistrationRepository(apiClient: apiClient);
    final UserEventsRepository userEventsRepository = ApiUserEventsRepository(
      apiClient: apiClient,
      cache: memoryCache,
    );
    final UserOrdersRepository userOrdersRepository = ApiUserOrdersRepository(
      apiClient: apiClient,
    );
    final HomeRepository homeRepository = CompositeHomeRepository(
      eventsRepository: eventsRepository,
      shopRepository: shopRepository,
      offersRepository: offersRepository,
      userOrdersRepository: userOrdersRepository,
    );
    final ImagePickerService imagePickerService = ImagePickerService();

    final AppDependencies dependencies = AppDependencies._(
      httpClient: httpClient,
      memoryCache: memoryCache,
      authRepository: authRepository,
      eventsRepository: eventsRepository,
      shopRepository: shopRepository,
      offersRepository: offersRepository,
      notificationsRepository: notificationsRepository,
      profileRepository: profileRepository,
      membershipRepository: membershipRepository,
      registrationRepository: registrationRepository,
      userEventsRepository: userEventsRepository,
      userOrdersRepository: userOrdersRepository,
      authController: AuthController(repository: authRepository),
      homeController: HomeController(repository: homeRepository),
      eventsController: EventsController(repository: eventsRepository),
      shopController: ShopController(repository: shopRepository),
      checkoutController: CheckoutController(repository: shopRepository),
      offersController: OffersController(repository: offersRepository),
      notificationsController: NotificationsController(
        repository: notificationsRepository,
      ),
      profileController: ProfileController(
        repository: profileRepository,
        imagePickerService: imagePickerService,
      ),
      membershipController: MembershipController(
        repository: membershipRepository,
      ),
      userEventsController: UserEventsController(
        repository: userEventsRepository,
      ),
      userOrdersController: UserOrdersController(
        repository: userOrdersRepository,
      ),
      registrationController: RegistrationController(
        imagePickerService: imagePickerService,
        registrationRepository: registrationRepository,
      ),
      membershipPaymentController: MembershipPaymentController(
        repository: membershipRepository,
      ),
    );
    apiClient.onSessionExpired = dependencies._handleSessionExpired;
    apiClient.onAccessDenied =
        dependencies.authController.checkMembershipStatus;
    return dependencies;
  }

  final http.Client _httpClient;
  final MemoryCache memoryCache;

  final AuthRepository authRepository;
  final EventsRepository eventsRepository;
  final ShopRepository shopRepository;
  final OffersRepository offersRepository;
  final NotificationsRepository notificationsRepository;
  final ProfileRepository profileRepository;
  final MembershipRepository membershipRepository;
  final RegistrationRepository registrationRepository;
  final UserEventsRepository userEventsRepository;
  final UserOrdersRepository userOrdersRepository;

  final AuthController authController;
  final HomeController homeController;
  final EventsController eventsController;
  final ShopController shopController;
  final CheckoutController checkoutController;
  final OffersController offersController;
  final NotificationsController notificationsController;
  final ProfileController profileController;
  final MembershipController membershipController;
  final UserEventsController userEventsController;
  final UserOrdersController userOrdersController;
  final RegistrationController registrationController;
  final MembershipPaymentController membershipPaymentController;

  /// Clears both the token and every member-specific in-memory state object.
  /// This prevents one member from briefly seeing another member's cached
  /// profile, offers, events, or cart after a sign-out/sign-in cycle.
  Future<void> signOut() async {
    try {
      await authController.signOut();
    } finally {
      _clearMemberState();
    }
  }

  /// The backend rejected the access token: drop every member-specific
  /// state. An expired token (it lasts one month) leads to Sign In; any other
  /// rejection means the account is gone (e.g. deleted), which shows
  /// "Something went wrong" and returns to Welcome.
  void _handleSessionExpired(String message) {
    final bool ended = message.toLowerCase().contains('expired')
        ? authController.expireSession()
        : authController.endSessionUnexpectedly();
    if (!ended) return;
    _clearMemberState();
  }

  void _clearMemberState() {
    memoryCache.clear();
    homeController.reset();
    eventsController.reset();
    shopController.reset();
    checkoutController.reset();
    offersController.reset();
    notificationsController.reset();
    profileController.reset();
    membershipController.reset();
    userEventsController.reset();
    userOrdersController.reset();
    registrationController.reset();
    membershipPaymentController.reset();
  }

  void dispose() {
    authController.dispose();
    homeController.dispose();
    eventsController.dispose();
    shopController.dispose();
    checkoutController.dispose();
    offersController.dispose();
    notificationsController.dispose();
    profileController.dispose();
    membershipController.dispose();
    userEventsController.dispose();
    userOrdersController.dispose();
    registrationController.dispose();
    membershipPaymentController.dispose();
    _httpClient.close();
  }
}
