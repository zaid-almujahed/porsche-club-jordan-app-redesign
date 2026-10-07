import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/dependencies/app_dependencies.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/routing/app_actions.dart';
import 'package:pcj_v5/features/auth/presentation/pages/launch_page.dart';
import 'package:pcj_v5/features/auth/presentation/pages/sign_in_page.dart';
import 'package:pcj_v5/features/auth/presentation/pages/welcome_page.dart';
import 'package:pcj_v5/features/events/presentation/controllers/event_details_controller.dart';
import 'package:pcj_v5/features/events/presentation/controllers/event_payment_controller.dart';
import 'package:pcj_v5/features/events/presentation/controllers/event_registration_controller.dart';
import 'package:pcj_v5/features/events/presentation/pages/event_details_page.dart';
import 'package:pcj_v5/features/events/presentation/pages/event_payment_page.dart';
import 'package:pcj_v5/features/events/presentation/pages/event_registration_page.dart';
import 'package:pcj_v5/features/events/presentation/pages/events_page.dart';
import 'package:pcj_v5/features/home/presentation/pages/home_page.dart';
import 'package:pcj_v5/features/notifications/presentation/pages/notifications_page.dart';
import 'package:pcj_v5/features/offers/presentation/pages/offers_page.dart';
import 'package:pcj_v5/features/profile/presentation/pages/account_settings_page.dart';
import 'package:pcj_v5/features/profile/presentation/pages/membership_settings_page.dart';
import 'package:pcj_v5/features/profile/presentation/pages/profile_info_edit_page.dart';
import 'package:pcj_v5/features/profile/presentation/pages/profile_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/application_status_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/cliq_payment_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/membership_payment_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/membership_renewal_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/registration_personal_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/registration_password_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/registration_review_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/registration_vehicle_page.dart';
import 'package:pcj_v5/features/shop/presentation/controllers/order_payment_controller.dart';
import 'package:pcj_v5/features/shop/presentation/controllers/product_details_controller.dart';
import 'package:pcj_v5/features/shop/presentation/pages/checkout_page.dart';
import 'package:pcj_v5/features/shop/presentation/pages/order_payment_page.dart';
import 'package:pcj_v5/features/shop/presentation/pages/product_details_page.dart';
import 'package:pcj_v5/features/shop/presentation/pages/shop_main_page.dart';
import 'package:pcj_v5/features/user_events/presentation/controllers/ticket_controller.dart';
import 'package:pcj_v5/features/user_events/presentation/pages/member_events_page.dart';
import 'package:pcj_v5/features/user_events/presentation/pages/virtual_ticket_page.dart';
import 'package:pcj_v5/features/user_orders/presentation/pages/orders_page.dart';
import 'package:pcj_v5/features/user_orders/presentation/widgets/user_orders_widgets.dart';
import 'package:pcj_v5/shared/domain/entities/order.dart';
import 'package:pcj_v5/shared/domain/entities/event.dart';
import 'package:pcj_v5/shared/domain/entities/event_booking.dart';
import 'package:pcj_v5/shared/domain/entities/cart.dart';
import 'package:pcj_v5/shared/domain/entities/product.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_live_refresh.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';
import 'package:pcj_v5/shared/widgets/support_contact_sheet.dart';

abstract final class AppRoutes {
  static const String launch = '/launch';
  static const String welcome = '/';
  static const String signIn = '/sign-in';
  static const String registerPersonal = '/registration/personal';
  static const String registerVehicle = '/registration/vehicle';
  static const String registerReview = '/registration/review';
  static const String registerPassword = '/registration/password';
  static const String applicationStatus = '/application-status';
  static const String membershipPayment = '/membership-payment';
  static const String membershipRenewal = '/membership-renewal';
  static const String cliqPayment = '/cliq-payment';
  static const String home = '/home';
  static const String events = '/events';
  static const String eventDetails = '/events/:eventId';
  static const String eventRegistration = '/events/:eventId/register';
  static const String eventPayment = '/events/:eventId/pay';
  static const String shop = '/shop';
  static const String productDetails = '/shop/products/:productId';
  static const String checkout = '/shop/checkout';
  static const String offers = '/offers';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String userOrders = '/profile/orders';
  static const String orderPayment = '/profile/orders/:orderId/pay';
  static const String userEvents = '/profile/events';
  static const String membershipSettings = '/profile/membership';
  static const String accountSettings = '/profile/account';
  static const String ticket = '/profile/events/:bookingId/ticket';

  static String eventDetailsLocation(String id) =>
      '/events/${Uri.encodeComponent(id)}';
  static String eventRegistrationLocation(String id) =>
      '/events/${Uri.encodeComponent(id)}/register';
  static String eventPaymentLocation(String id) =>
      '/events/${Uri.encodeComponent(id)}/pay';
  static String orderPaymentLocation(String id) =>
      '/profile/orders/${Uri.encodeComponent(id)}/pay';
  static String productDetailsLocation(String id) =>
      '/shop/products/${Uri.encodeComponent(id)}';
  static String ticketLocation(String id) =>
      '/profile/events/${Uri.encodeComponent(id)}/ticket';

  /// Where "back" leads when a page was opened without any history underneath
  /// it (e.g. after `context.go`). Mirrors the app's visual hierarchy.
  static String parentOf(String location) {
    final List<String> segments = Uri.parse(location).pathSegments;
    if (segments.isEmpty) return home;
    switch (segments.first) {
      case 'profile':
        // /profile/events/:bookingId/ticket -> My Events.
        if (segments.length >= 3 && segments[1] == 'events') return userEvents;
        // /profile/orders/:orderId/pay -> My Orders.
        if (segments.length >= 3 && segments[1] == 'orders') return userOrders;
        return profile;
      case 'events':
        // /events/:eventId/register -> that event's details.
        if (segments.length >= 3) return eventDetailsLocation(segments[1]);
        return events;
      case 'shop':
        return shop;
      case 'offers':
        return offers;
      default:
        return home;
    }
  }

  static String destinationForUser(User user) {
    // Application approval and paid membership are separate backend states:
    // APPROVED must complete payment; ACTIVE can enter member content.
    switch (user.applicationStatus) {
      case ApplicationStatus.notSubmitted:
        return registerPersonal;
      case ApplicationStatus.pending:
      case ApplicationStatus.denied:
        return applicationStatus;
      case ApplicationStatus.approved:
        return switch (user.membershipStatus) {
          MembershipStatus.active => home,
          MembershipStatus.expired => membershipRenewal,
          _ => membershipPayment,
        };
    }
  }
}

/// Starts a load once the current build has finished.
///
/// Route builders run while the router is building, and every
/// shared controller's load() calls notifyListeners() before its first await.
/// Calling it here marked pages that are still on screen as dirty mid-build
/// ("setState() or markNeedsBuild() called during build"), which surfaced as
/// crashes when going back to Home/Profile while a request was pending or had
/// failed.
void _loadAfterBuild(FutureOr<void> Function() load) {
  scheduleMicrotask(() {
    load();
  });
}

/// Loads a page's data once it is built, then keeps it current while it is
/// on screen ([AppLiveRefresh]).
Widget _livePage(Future<void> Function({bool force}) load, Widget page) {
  _loadAfterBuild(load);
  return AppLiveRefresh(onRefresh: () => load(force: true), child: page);
}

/// [swipeBack]: the page opens on top of another (details, settings, the
/// next step), so on iOS it slides in and can be swiped back from the left
/// edge. Elsewhere it appears at once, and Android's back gesture pops it.
GoRoute _flowRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
  bool swipeBack = false,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (BuildContext context, GoRouterState state) {
      final Widget child = builder(context, state);
      if (swipeBack && _swipesBack(context)) {
        return CupertinoPage<void>(key: state.pageKey, child: child);
      }
      return NoTransitionPage<void>(key: state.pageKey, child: child);
    },
  );
}

/// iOS goes back with a swipe from the left edge, which needs its slide
/// transition.
bool _swipesBack(BuildContext context) =>
    Theme.of(context).platform == TargetPlatform.iOS;

/// Like [_flowRoute], but the page fades in while settling into place
/// instead of appearing at once. On iOS it slides in instead, so it can be
/// swiped back.
GoRoute _fadeInRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (BuildContext context, GoRouterState state) =>
        _swipesBack(context)
        ? CupertinoPage<void>(
            key: state.pageKey,
            child: builder(context, state),
          )
        : CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: AppMotion.medium,
            reverseTransitionDuration: AppMotion.fast,
            child: builder(context, state),
            transitionsBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child,
                ) {
                  final Animation<double> curved = CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.curve,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
                      child: child,
                    ),
                  );
                },
          ),
  );
}

/// The support form, about an event registration.
void _contactSupportAboutEvents(
  BuildContext context,
  AppDependencies dependencies,
) {
  showSupportContactSheet(
    context: context,
    senderEmail: dependencies.authController.currentUser?.email ?? '',
    initialTopic: 'Event registration',
  );
}

/// The CliQ payment of an order still waiting for it.
void _payOrder(BuildContext context, Order order) {
  context.push(
    AppRoutes.orderPaymentLocation(order.id),
    extra: OrderPaymentDetails.fromOrder(order),
  );
}

GoRouter createAppRouter(AppDependencies dependencies) {
  // Route builders receive a context that sits *above* the root Navigator,
  // so sheets, dialogs and overlays opened from them use this key instead.
  final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );
  BuildContext overlayContext(BuildContext fallback) =>
      rootNavigatorKey.currentContext ?? fallback;
  final AppActions actions = AppActions(
    dependencies,
    rootNavigatorKey: rootNavigatorKey,
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.welcome,
    refreshListenable: dependencies.authController,
    errorBuilder: (_, _) => const _RouterErrorPage(),
    redirect: (BuildContext context, GoRouterState state) {
      final auth = dependencies.authController;
      final String location = state.matchedLocation;

      // While the stored session is checked at start-up, hold on the launch
      // screen: a member whose token is still valid goes straight to Home
      // and never sees Welcome.
      if (auth.session.isInitial ||
          (auth.session.isLoading && auth.currentUser == null)) {
        return location == AppRoutes.welcome ? AppRoutes.launch : null;
      }
      if (auth.session.isLoading) return null;

      if (location == AppRoutes.launch) {
        final User? restored = auth.currentUser;
        if (restored != null) return AppRoutes.destinationForUser(restored);
        // A network failure stays on the launch screen with a retry; no
        // token or an expired one continues to Welcome.
        final Object? error = auth.session.error;
        return auth.session.hasError && error is! AuthenticationException
            ? null
            : AppRoutes.welcome;
      }

      final bool isRegistrationRoute = location.startsWith('/registration/');
      final bool isPublicRoute =
          location == AppRoutes.welcome ||
          location == AppRoutes.signIn ||
          location == AppRoutes.applicationStatus ||
          isRegistrationRoute;
      final User? user = auth.currentUser;

      if (user == null) {
        return isPublicRoute ? null : AppRoutes.signIn;
      }

      final String destination = AppRoutes.destinationForUser(user);
      if (location == AppRoutes.welcome || location == AppRoutes.signIn) {
        return destination;
      }
      if (destination == AppRoutes.registerPersonal && !isRegistrationRoute) {
        return AppRoutes.registerPersonal;
      }
      if (destination == AppRoutes.applicationStatus &&
          location != AppRoutes.applicationStatus) {
        return AppRoutes.applicationStatus;
      }
      // The CliQ page belongs to both payment pages.
      final bool isCliqRoute = location == AppRoutes.cliqPayment;
      if (destination == AppRoutes.membershipPayment &&
          location != AppRoutes.membershipPayment &&
          !isCliqRoute) {
        return AppRoutes.membershipPayment;
      }
      if (destination == AppRoutes.membershipRenewal &&
          location != AppRoutes.membershipRenewal &&
          !isCliqRoute) {
        return AppRoutes.membershipRenewal;
      }
      // Active again, also when the club renews or activates the membership
      // while a payment page is open: on to Home.
      if (destination == AppRoutes.home &&
          (isPublicRoute ||
              location == AppRoutes.membershipPayment ||
              location == AppRoutes.membershipRenewal ||
              isCliqRoute)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: <RouteBase>[
      _flowRoute(
        path: AppRoutes.launch,
        builder: (_, _) => LaunchPage(controller: dependencies.authController),
      ),
      _flowRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomePage(),
      ),
      _flowRoute(
        path: AppRoutes.signIn,
        swipeBack: true,
        builder: (_, _) => SignInPage(
          controller: dependencies.authController,
          passwordController: dependencies.passwordController,
          biometricSignIn: dependencies.biometricSignIn,
        ),
      ),
      _flowRoute(
        path: AppRoutes.registerPersonal,
        builder: (BuildContext context, _) => RegistrationPersonalPage(
          controller: dependencies.registrationController,
          onCancel: () => actions.cancelRegistration(context),
        ),
      ),
      _flowRoute(
        path: AppRoutes.registerVehicle,
        swipeBack: true,
        builder: (BuildContext context, GoRouterState state) {
          final controller = dependencies.registrationController;
          return RegistrationVehiclePage(
            controller: controller,
            onCancel: () => actions.cancelRegistration(context),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.registerReview,
        swipeBack: true,
        builder: (BuildContext context, _) => RegistrationReviewPage(
          controller: dependencies.registrationController,
          onCancel: () => actions.cancelRegistration(context),
          onEdited: () => context.go(
            AppRoutes.applicationStatus,
            extra: dependencies.registrationController.submittedUser,
          ),
        ),
      ),
      _flowRoute(
        path: AppRoutes.registerPassword,
        swipeBack: true,
        builder: (BuildContext context, GoRouterState state) =>
            RegistrationPasswordPage(
              controller: dependencies.registrationController,
              onCancel: () => actions.cancelRegistration(context),
              onSubmitted: () {
                // Kept in memory so the status page can ask for a decision.
                final ({String email, String password})? login =
                    dependencies.registrationController.submittedLogin;
                if (login != null) {
                  dependencies.authController.rememberApplicantLogin(
                    email: login.email,
                    password: login.password,
                  );
                }
                context.go(
                  AppRoutes.applicationStatus,
                  extra: dependencies.registrationController.submittedUser,
                );
              },
            ),
      ),
      _flowRoute(
        path: AppRoutes.applicationStatus,
        builder: (BuildContext context, GoRouterState state) {
          final User? user = state.extra is User
              ? state.extra! as User
              : dependencies.authController.currentUser;
          if (user == null) return const _MissingRouteDataPage();
          final bool canEditDuringRegistrationSession =
              dependencies.authController.currentUser == null &&
              state.extra is User &&
              dependencies.registrationController.canEditSubmittedApplication;
          return ApplicationStatusPage(
            user: user,
            onContactSupport: () {
              showSupportContactSheet(
                context: overlayContext(context),
                senderEmail: user.email,
              );
            },
            onContinue: () => context.go(AppRoutes.membershipPayment),
            onEditProfile: () => context.go(AppRoutes.registerPersonal),
            onEditApplication: canEditDuringRegistrationSession
                ? () {
                    dependencies.registrationController
                        .beginEditingSubmittedApplication();
                    context.go(AppRoutes.registerPersonal);
                  }
                : null,
            onLogOut: () => actions.signOutToWelcome(context),
            onRecheck: dependencies.authController.canRecheckApplication
                ? dependencies.authController.recheckApplication
                : null,
            onApproved: () => actions.continueApprovedApplication(context),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.membershipPayment,
        builder: (BuildContext context, GoRouterState state) {
          final controller = dependencies.membershipPaymentController;
          _loadAfterBuild(controller.load);
          return MembershipPaymentPage(
            controller: controller,
            onClose: () => actions.signOutToWelcome(context),
            onCodeApplied: (_) =>
                actions.afterMembershipCodeApplied(context, isRenewal: false),
            onActivated: (_) =>
                actions.afterMembershipPaid(context, isRenewal: false),
            onPayWithCliq: () => context.push(AppRoutes.cliqPayment),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.membershipRenewal,
        builder: (BuildContext context, GoRouterState state) {
          final controller = dependencies.membershipPaymentController;
          _loadAfterBuild(() => controller.load(force: true));
          return MembershipRenewalPage(
            controller: controller,
            memberName: dependencies.authController.currentUser?.name ?? '',
            onClose: () => actions.signOutToWelcome(context),
            onCodeApplied: (_) =>
                actions.afterMembershipCodeApplied(context, isRenewal: true),
            onRenewed: (_) =>
                actions.afterMembershipPaid(context, isRenewal: true),
            onPayWithCliq: () => context.push(AppRoutes.cliqPayment),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.cliqPayment,
        swipeBack: true,
        builder: (BuildContext context, GoRouterState state) {
          final controller = dependencies.membershipPaymentController;
          return AppLiveRefresh(
            onRefresh: () => controller.load(force: true),
            child: CliqPaymentPage(
              controller: controller,
              onContactSupport: () => showSupportContactSheet(
                context: overlayContext(context),
                senderEmail:
                    dependencies.authController.currentUser?.email ?? '',
                initialTopic: 'Membership payment',
              ),
            ),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              _loadAfterBuild(dependencies.notificationsController.load);
              // The cart badge and quick add need the member's cart.
              _loadAfterBuild(dependencies.checkoutController.load);
              return _MainNavigationShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: 'home',
                path: AppRoutes.home,
                builder: (BuildContext context, _) {
                  return _livePage(
                    dependencies.homeController.load,
                    HomePage(
                      controller: dependencies.homeController,
                      user: dependencies.authController.currentUser,
                      unreadNotificationCount:
                          dependencies.notificationsController,
                      cartController: dependencies.checkoutController,
                      onTrackOrder: (Order order) => showOrderDetailsDialog(
                        context: overlayContext(context),
                        controller: dependencies.userOrdersController,
                        orderId: order.id,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: 'events',
                path: AppRoutes.events,
                builder: (_, _) {
                  return _livePage(
                    dependencies.eventsController.load,
                    EventsPage(
                      controller: dependencies.eventsController,
                      unreadNotificationCount:
                          dependencies.notificationsController,
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: 'shop',
                path: AppRoutes.shop,
                builder: (_, _) {
                  return _livePage(
                    dependencies.shopController.load,
                    ShopMainPage(
                      controller: dependencies.shopController,
                      unreadNotificationCount:
                          dependencies.notificationsController,
                      cartController: dependencies.checkoutController,
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: 'offers',
                path: AppRoutes.offers,
                builder: (_, _) {
                  return _livePage(
                    dependencies.offersController.load,
                    PartnerOffersPage(
                      controller: dependencies.offersController,
                      unreadNotificationCount:
                          dependencies.notificationsController,
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                name: 'profile',
                path: AppRoutes.profile,
                builder: (BuildContext context, GoRouterState state) {
                  return _livePage(
                    dependencies.profileController.load,
                    ProfilePage(
                      controller: dependencies.profileController,
                      unreadNotificationCount:
                          dependencies.notificationsController,
                      onSupportPressed: () {
                        final User? user =
                            dependencies.authController.currentUser;
                        if (user == null) return;
                        showSupportContactSheet(
                          context: context,
                          senderEmail: user.email,
                          initialTopic: 'Account access',
                        );
                      },
                      onLogOut: () => actions.signOutToWelcome(context),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      _fadeInRoute(
        path: AppRoutes.eventDetails,
        builder: (BuildContext context, GoRouterState state) {
          final String id = state.pathParameters['eventId']!;
          final controller = EventDetailsController(
            repository: dependencies.eventsRepository,
            userEventsRepository: dependencies.userEventsRepository,
            eventId: id,
            initialEvent: state.extra is Event ? state.extra! as Event : null,
          );
          controller.refresh();
          return _OwnedControllerPage<EventDetailsController>(
            controller: controller,
            builder: (EventDetailsController controller) => AppLiveRefresh(
              onRefresh: controller.refresh,
              child: EventDetailsPage(
                controller: controller,
                onRsvpCancelled: actions.afterRsvpCancelled,
                onContactSupport: () => _contactSupportAboutEvents(
                  overlayContext(context),
                  dependencies,
                ),
              ),
            ),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.eventRegistration,
        swipeBack: true,
        builder: (BuildContext context, GoRouterState state) {
          final String id = state.pathParameters['eventId']!;
          final EventRegistrationController controller =
              EventRegistrationController(
                eventsRepository: dependencies.eventsRepository,
                userEventsRepository: dependencies.userEventsRepository,
                eventId: id,
                initialEvent: state.extra is Event
                    ? state.extra! as Event
                    : null,
              );
          controller.load(force: true);
          return _OwnedControllerPage<EventRegistrationController>(
            controller: controller,
            builder: (EventRegistrationController controller) {
              return EventRegistrationPage(
                controller: controller,
                onRegistered: () => actions.afterEventRegistration(context, id),
                onPaymentNeeded: (EventPaymentDetails details) =>
                    context.pushReplacement(
                      AppRoutes.eventPaymentLocation(id),
                      extra: details,
                    ),
              );
            },
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.eventPayment,
        swipeBack: true,
        builder: (BuildContext context, GoRouterState state) {
          final String id = state.pathParameters['eventId']!;
          final Object? extra = state.extra;
          // Opened from registration only.
          if (extra is! EventPaymentDetails) return const _RouterErrorPage();
          final EventPaymentController controller = EventPaymentController(
            repository: dependencies.eventsRepository,
            imagePickerService: dependencies.imagePickerService,
            payment: extra,
          );
          controller.load();
          return _OwnedControllerPage<EventPaymentController>(
            controller: controller,
            builder: (EventPaymentController controller) => EventPaymentPage(
              controller: controller,
              onPaid: () => actions.afterEventRegistration(context, id),
            ),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.productDetails,
        swipeBack: true,
        builder: (BuildContext context, GoRouterState state) {
          final String id = state.pathParameters['productId']!;
          final controller = ProductDetailsController(
            repository: dependencies.shopRepository,
            productId: id,
            initialProduct: state.extra is Product
                ? state.extra! as Product
                : null,
            quantityInCart: dependencies.checkoutController.quantityInCart,
          );
          controller.refresh();
          return _OwnedControllerPage<ProductDetailsController>(
            controller: controller,
            builder: (ProductDetailsController controller) => AppLiveRefresh(
              onRefresh: controller.refresh,
              child: ProductDetailsPage(
                controller: controller,
                // Adding keeps the member on this page; only the cart
                // badge changes.
                onAddedToCart: (cart) {
                  dependencies.checkoutController.useCart(cart);
                },
                cartItemCount: dependencies.checkoutController.itemCount,
                onCartPressed: () => context.push(AppRoutes.checkout),
              ),
            ),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.checkout,
        swipeBack: true,
        builder: (BuildContext context, GoRouterState state) {
          if (state.extra is Cart) {
            final Cart cart = state.extra! as Cart;
            _loadAfterBuild(
              () => dependencies.checkoutController.useCart(cart),
            );
          } else {
            _loadAfterBuild(
              () => dependencies.checkoutController.load(force: true),
            );
          }
          return CheckoutPage(
            controller: dependencies.checkoutController,
            onOrderPlaced: () => actions.afterOrderPlaced(context),
            onCliqPaymentNeeded: (OrderPaymentDetails details) =>
                context.pushReplacement(
                  AppRoutes.orderPaymentLocation(details.orderId),
                  extra: details,
                ),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.orderPayment,
        swipeBack: true,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          // Opened from checkout or My Orders only.
          if (extra is! OrderPaymentDetails) return const _RouterErrorPage();
          final OrderPaymentController controller = OrderPaymentController(
            repository: dependencies.shopRepository,
            imagePickerService: dependencies.imagePickerService,
            payment: extra,
          );
          controller.load();
          return _OwnedControllerPage<OrderPaymentController>(
            controller: controller,
            builder: (OrderPaymentController controller) => OrderPaymentPage(
              controller: controller,
              onPaid: () => actions.afterOrderPlaced(context),
            ),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.notifications,
        swipeBack: true,
        builder: (BuildContext context, _) {
          _loadAfterBuild(dependencies.notificationsController.load);
          return NotificationsPage(
            controller: dependencies.notificationsController,
            onOpenOrder: (String orderId) => showOrderDetailsDialog(
              context: overlayContext(context),
              controller: dependencies.userOrdersController,
              orderId: orderId,
              onPay: (Order order) => _payOrder(context, order),
            ),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.profileEdit,
        swipeBack: true,
        builder: (_, _) {
          _loadAfterBuild(dependencies.profileController.load);
          return ProfileInfoEditPage(
            controller: dependencies.profileController,
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.userOrders,
        swipeBack: true,
        builder: (BuildContext context, _) {
          return _livePage(
            dependencies.userOrdersController.load,
            OrdersPage(
              controller: dependencies.userOrdersController,
              onPay: (Order order) => _payOrder(context, order),
            ),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.userEvents,
        swipeBack: true,
        builder: (BuildContext context, _) {
          return _livePage(
            dependencies.userEventsController.load,
            MemberEventsPage(
              controller: dependencies.userEventsController,
              onContactSupport: () => _contactSupportAboutEvents(
                overlayContext(context),
                dependencies,
              ),
            ),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.membershipSettings,
        swipeBack: true,
        builder: (BuildContext context, _) {
          return _livePage(
            dependencies.membershipController.load,
            MembershipSettingsPage(
              controller: dependencies.membershipController,
              memberName: dependencies.authController.currentUser?.name ?? '',
            ),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.accountSettings,
        swipeBack: true,
        builder: (BuildContext context, GoRouterState state) {
          _loadAfterBuild(dependencies.profileController.load);
          return AccountSettingsPage(
            controller: dependencies.profileController,
            passwordController: dependencies.passwordController,
            onAccountDeleted: () {
              dependencies.biometricSignIn.disable();
              actions.signOutToWelcome(context);
            },
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.ticket,
        swipeBack: true,
        builder: (_, GoRouterState state) {
          final String id = state.pathParameters['bookingId']!;
          final controller = TicketController(
            repository: dependencies.userEventsRepository,
            qrStore: dependencies.ticketQrStore,
            memberId: dependencies.authController.currentUser?.id ?? '',
            bookingId: id,
            initialBooking: state.extra is EventBooking
                ? state.extra! as EventBooking
                : null,
          );
          controller.load();
          return _OwnedControllerPage<TicketController>(
            controller: controller,
            // Stays live so the QR is replaced by "already used" soon after
            // the member is checked in.
            builder: (TicketController controller) => AppLiveRefresh(
              onRefresh: () => controller.load(force: true),
              child: VirtualTicketPage(controller: controller),
            ),
          );
        },
      ),
    ],
  );
}

class _MainNavigationShell extends StatelessWidget {
  const _MainNavigationShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.canvas,
      body: navigationShell,
      bottomNavigationBar: AppBottomNavigation(
        selected: AppSection.values[navigationShell.currentIndex],
        onSelected: (AppSection section) {
          navigationShell.goBranch(section.index);
        },
      ),
    );
  }
}

/// Owns controllers created for one route and disposes them when that route is
/// removed. App-wide controllers are owned by [AppDependencies] instead.
class _OwnedControllerPage<T extends ChangeNotifier> extends StatefulWidget {
  const _OwnedControllerPage({required this.controller, required this.builder});

  final T controller;
  final Widget Function(T controller) builder;

  @override
  State<_OwnedControllerPage<T>> createState() =>
      _OwnedControllerPageState<T>();
}

class _OwnedControllerPageState<T extends ChangeNotifier>
    extends State<_OwnedControllerPage<T>> {
  @override
  void didUpdateWidget(covariant _OwnedControllerPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.dispose();
    }
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(widget.controller);
}

class _MissingRouteDataPage extends StatelessWidget {
  const _MissingRouteDataPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Required account data is unavailable.')),
    );
  }
}

class _RouterErrorPage extends StatelessWidget {
  const _RouterErrorPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(title: const Text('Something went wrong')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 46, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'This page could not be opened. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.signIn),
                child: const Text('Return to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
