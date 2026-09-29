import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/dependencies/app_dependencies.dart';
import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/routing/app_actions.dart';
import 'package:pcj_v5/core/routing/app_back_navigation.dart';
import 'package:pcj_v5/features/auth/presentation/pages/launch_page.dart';
import 'package:pcj_v5/features/auth/presentation/pages/sign_in_page.dart';
import 'package:pcj_v5/features/auth/presentation/pages/welcome_page.dart';
import 'package:pcj_v5/features/events/presentation/controllers/event_details_controller.dart';
import 'package:pcj_v5/features/events/presentation/controllers/event_registration_controller.dart';
import 'package:pcj_v5/features/events/presentation/pages/event_details_page.dart';
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
import 'package:pcj_v5/features/registration/presentation/pages/membership_payment_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/registration_personal_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/registration_password_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/registration_review_page.dart';
import 'package:pcj_v5/features/registration/presentation/pages/registration_vehicle_page.dart';
import 'package:pcj_v5/features/shop/presentation/controllers/product_details_controller.dart';
import 'package:pcj_v5/features/shop/presentation/pages/checkout_page.dart';
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
  static const String home = '/home';
  static const String events = '/events';
  static const String eventDetails = '/events/:eventId';
  static const String eventRegistration = '/events/:eventId/register';
  static const String shop = '/shop';
  static const String productDetails = '/shop/products/:productId';
  static const String checkout = '/shop/checkout';
  static const String offers = '/offers';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String userOrders = '/profile/orders';
  static const String userEvents = '/profile/events';
  static const String membershipSettings = '/profile/membership';
  static const String accountSettings = '/profile/account';
  static const String ticket = '/profile/events/:bookingId/ticket';

  static String eventDetailsLocation(String id) =>
      '/events/${Uri.encodeComponent(id)}';
  static String eventRegistrationLocation(String id) =>
      '/events/${Uri.encodeComponent(id)}/register';
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
        return user.membershipStatus == MembershipStatus.active
            ? home
            : membershipPayment;
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

GoRoute _flowRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (BuildContext context, GoRouterState state) =>
        NoTransitionPage<void>(
          key: state.pageKey,
          child: builder(context, state),
        ),
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
      if (destination == AppRoutes.membershipPayment &&
          location != AppRoutes.membershipPayment) {
        return AppRoutes.membershipPayment;
      }
      if (destination == AppRoutes.home && isPublicRoute) {
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
        builder: (_, _) => SignInPage(
          controller: dependencies.authController,
          passwordController: dependencies.passwordController,
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
        builder: (BuildContext context, GoRouterState state) =>
            RegistrationPasswordPage(
              controller: dependencies.registrationController,
              onCancel: () => actions.cancelRegistration(context),
              onSubmitted: () {
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
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.membershipPayment,
        builder: (BuildContext context, GoRouterState state) {
          final controller = dependencies.membershipPaymentController;
          // An active member renewing early from Manage Membership. Expired
          // or unpaid members are redirected here and can only sign out.
          final bool isRenewal =
              dependencies.authController.currentUser?.membershipStatus ==
              MembershipStatus.active;
          _loadAfterBuild(() => controller.load(force: isRenewal));
          return MembershipPaymentPage(
            controller: controller,
            isRenewal: isRenewal,
            onClose: isRenewal
                ? () async =>
                      context.goBack(fallback: AppRoutes.membershipSettings)
                : () => actions.signOutToWelcome(context),
            onCodeApplied: (_) => actions.afterMembershipCodeApplied(
              context,
              isRenewal: isRenewal,
            ),
            onActivated: (_) =>
                actions.afterMembershipPaid(context, isRenewal: isRenewal),
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
      _flowRoute(
        path: AppRoutes.eventDetails,
        builder: (_, GoRouterState state) {
          final String id = state.pathParameters['eventId']!;
          final controller = EventDetailsController(
            repository: dependencies.eventsRepository,
            eventId: id,
            initialEvent: state.extra is Event ? state.extra! as Event : null,
          );
          controller.refresh();
          return _OwnedControllerPage<EventDetailsController>(
            controller: controller,
            builder: (EventDetailsController controller) => AppLiveRefresh(
              onRefresh: controller.refresh,
              child: EventDetailsPage(controller: controller),
            ),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.eventRegistration,
        builder: (BuildContext context, GoRouterState state) {
          final String id = state.pathParameters['eventId']!;
          final EventRegistrationController controller =
              EventRegistrationController(
                eventsRepository: dependencies.eventsRepository,
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
                onRegistered: (_) => actions.afterEventRegistration(context),
              );
            },
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.productDetails,
        builder: (BuildContext context, GoRouterState state) {
          final String id = state.pathParameters['productId']!;
          final controller = ProductDetailsController(
            repository: dependencies.shopRepository,
            productId: id,
            initialProduct: state.extra is Product
                ? state.extra! as Product
                : null,
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
            onOrderPlaced: (_) => actions.afterOrderPlaced(context),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.notifications,
        builder: (_, _) {
          _loadAfterBuild(dependencies.notificationsController.load);
          return NotificationsPage(
            controller: dependencies.notificationsController,
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.profileEdit,
        builder: (_, _) {
          _loadAfterBuild(dependencies.profileController.load);
          return ProfileInfoEditPage(
            controller: dependencies.profileController,
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.userOrders,
        builder: (_, _) {
          return _livePage(
            dependencies.userOrdersController.load,
            OrdersPage(controller: dependencies.userOrdersController),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.userEvents,
        builder: (_, _) {
          return _livePage(
            dependencies.userEventsController.load,
            MemberEventsPage(controller: dependencies.userEventsController),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.membershipSettings,
        builder: (BuildContext context, _) {
          return _livePage(
            dependencies.membershipController.load,
            MembershipSettingsPage(
              controller: dependencies.membershipController,
              onRenew: () => context.push(AppRoutes.membershipPayment),
            ),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.accountSettings,
        builder: (BuildContext context, GoRouterState state) {
          _loadAfterBuild(dependencies.profileController.load);
          return AccountSettingsPage(
            controller: dependencies.profileController,
            passwordController: dependencies.passwordController,
            onAccountDeleted: () => actions.signOutToWelcome(context),
          );
        },
      ),
      _flowRoute(
        path: AppRoutes.ticket,
        builder: (_, GoRouterState state) {
          final String id = state.pathParameters['bookingId']!;
          final controller = TicketController(
            repository: dependencies.userEventsRepository,
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
