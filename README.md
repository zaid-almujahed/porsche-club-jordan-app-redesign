# Porsche Club Jordan — Member App

Flutter app for Porsche Club Jordan members (Android and iOS). Anyone can apply
for membership; the club reviews the application; approved applicants pay the
yearly membership; active members get events and RSVPs with QR tickets, the club
shop, partner offers, notifications, and their profile and membership details.

All data comes from the PCJ REST API. The phone stores only the login token,
the QR codes of opened event tickets and, when the member turns it on, the
email and password used for Face ID sign in.

## Requirements

- Flutter 3.47 (stable) or newer, Dart `^3.11`
- Android: minimum SDK 24
- iOS: 15.0 or newer (Firebase requires it), Xcode and CocoaPods

## Getting started

```bash
flutter pub get
flutter run
```

The app talks to `https://porscheclubjo.com` by default. To use another server
(for example staging), pass it at build time:

```bash
flutter run --dart-define=PCJ_API_BASE_URL=https://staging.example.com
```

The setting lives in `lib/core/config/app_config.dart`.

## Push notifications

The app registers each signed-in member's device with
`POST /notifications/token`, and the backend sends pushes through Firebase
Cloud Messaging. A tapped push opens Notifications; one that arrives while the
app is open refreshes the list (Android also shows a short message, iOS its
usual banner). The code is in `lib/core/services/push_notifications_service.dart`.

The Firebase project is `porsche-club-jordan`, and the app is registered
there as `com.porscheclubjordan.app`:

- **Android** reads `android/app/google-services.json` through the Google
  services Gradle plugin.
- **iOS** reads `ios/Runner/GoogleService-Info.plist` (part of the Runner
  target) and has the Push Notifications entitlement. Pushes also need an
  APNs key uploaded in the Firebase console (Project settings -> Cloud
  Messaging).

Without these files the app still runs, without pushes.

## Checks

```bash
flutter analyze
flutter test
```

Both should be clean before every commit. Format the files you change with
`dart format <file>`.

- `test/flows/member_flows_test.dart` boots the real app (router, controllers,
  repositories) against a fake backend. It is the quickest way to see how a
  feature behaves end to end, and the first place to add a test for new flows.
- The other tests cover JSON parsing, controllers and small rules (order
  statuses, guest limits, phone numbers, password rules).

## How the code is organised

```
lib/
  main.dart, app.dart          app start, router, status checks, session notices
  core/
    config/                    build-time settings (API base URL)
    dependencies/              AppDependencies: creates every repository and controller
    network/                   PcjApiClient (HTTP, token, errors), token storage, JSON helpers
    routing/                   routes, status-based redirects, back navigation
    cache/  constants/  errors/  services/  state/  theme/  utils/  validation/
  features/<feature>/
    data/models/               JSON -> app objects
    data/repositories/         endpoints, caching
    domain/repositories/       repository interfaces
    presentation/controllers/  screen state (ChangeNotifier)
    presentation/pages/        screens
    presentation/widgets/      feature widgets
  shared/
    data/                      parsing shared by features (membership status, CliQ)
    domain/entities/           User, Membership, Event, Product, Cart, Order, Offer...
    presentation/              the CliQ payment page used by events and orders
    widgets/                   shared widgets; import app_widgets.dart for all of them
```

Features: `auth`, `registration`, `home`, `events`, `user_events` (My Events,
tickets), `shop`, `user_orders`, `offers`, `profile`, `notifications`.

**Data flow.** A screen asks its controller to load; the controller calls a
repository; the repository reads the in-memory cache or calls `PcjApiClient`,
turns the JSON into entities, and returns them. The controller keeps the result
in an `AsyncState` (loading, data, error) and notifies; the screen rebuilds
through `AsyncStateView`. Screens never call the API directly.

**Where to start reading**

| What | Where |
|---|---|
| Everything the app creates, and who owns it | `lib/core/dependencies/app_dependencies.dart` |
| All routes and which member may see what | `lib/core/routing/app_router.dart` (`AppRoutes.destinationForUser`) |
| What happens after sign-out, payment, an order or an RSVP | `lib/core/routing/app_actions.dart` |
| Sign in, session, status checks | `lib/features/auth/presentation/controllers/auth_controller.dart` |
| Forgot / change password | `lib/features/auth/presentation/controllers/password_controller.dart` |
| Backend status → app status rules | `lib/shared/data/member_status_parser.dart` |
| HTTP, auth header, error handling | `lib/core/network/pcj_api_client.dart` |
| Colours, text styles, spacing | `lib/core/theme/app_theme.dart` |

## Key behaviour

- **Status decides the screen.** No application → registration; pending or
  rejected → application status; approved but unpaid → membership payment;
  expired → membership renewal (the only way to renew); active → the member
  area. Suspended or deactivated accounts are signed out with a notice.
  Unknown statuses never unlock the app.
- **Staying signed in.** The access token (valid 30 days) is kept in the iOS
  Keychain / Android Keystore. A rejected token ends the session.
- **Live updates.** While the app is open, signed-in members' status is
  re-checked every 10 seconds with `GET /member/membership` (an expiry opens the
  renewal page, and a membership the club renews or activates leaves the
  payment pages for Home; a deactivated or deleted account shows "Something
  went wrong" and returns to Welcome). The page on screen reloads itself on
  the same interval (`AppLiveRefresh`); covered pages and inactive tabs do
  not.
- **Application decisions.** An applicant cannot sign in while waiting
  (`POST /auth/login` answers 400 "Waiting for admin approval."), so the
  status page tries that login again every 10 seconds with the email and
  password typed this session (kept in memory only). Approval shows as the
  login going through: a pop-up lists the next steps (enter the emailed code,
  then pay). A rejection updates the page. 404 "User not found." (the account
  was removed) signs the applicant out to Welcome with "Something went
  wrong".
- **Replaced photos.** Photos are stored under their file names, so a new
  photo can keep the old address. `RemoteImageFreshness` re-checks the
  pictures on screen (a HEAD request, at most every 30 seconds each) and gives
  a changed one a new address so it is downloaded again.
- **Face ID sign in.** After signing in with a typed password, the app offers
  Face ID (Touch ID / fingerprint on other phones) for next time. The email
  and password are then kept in the Keychain / Keystore on this phone only
  (`BiometricSignIn`) and filled in after Face ID confirms; the emailed code
  is still asked for. A changed or reset password updates the saved one; a
  saved password the backend refuses (401 / 404) is forgotten, and so is the
  login when the account is deleted. Android needs `FlutterFragmentActivity`
  (done) and iOS the `NSFaceIDUsageDescription` text (done).
- **Event weather.** `GET /weather` only knows a fixed list of places (the backend's
  SPECIAL_LOCATIONS, copied in `known_locations.dart`). The app looks for one of
  them inside the event's location text and asks for that place's weather,
  only when the event starts within 16 days; otherwise the weather tile is
  hidden. The same list gives the map its coordinates when the event has none.
- **Errors.** Errors from an action (a wrong password, an action that is not
  allowed, a failed save) appear as a short pop-up that fades on its own
  (`showAppErrorPulse`, beside `showAppSuccessPulse`). Only pages that could
  not load keep an inline message with a retry.
- **Gift / referral codes** are single use: the field is cleared once a code
  is accepted or the page is left, and the keyboard is told not to learn it.
- **Shop stock.** Items with no stock left are greyed out and tagged
  "Sold Out". The quantity a member can pick stops at the variant's stock
  less what is already in their cart (the cart reply does not include stock).
- **Event tickets.** The backend issues a ticket's QR once: the first view
  moves the RSVP from "Not Checked In" to `PARTIALLY_CHECKED_IN`. The app
  saves the QR in secure storage before showing it and never requests it
  again; after `CHECKED_IN` it is no longer shown. Saved QRs are kept per
  member across sign-outs (`TicketQrStore`), so a QR first opened on another
  phone cannot be shown on this one. A saved QR is only used while the RSVP
  is `PARTIALLY_CHECKED_IN`; on "Not Checked In" it belongs to an earlier RSVP
  (iOS keeps it even after the app is deleted) and a new one is issued.
- **CliQ payments.** Every CliQ endpoint takes `transaction_number`,
  `cliq_refund_name` (the member's own alias, where a refund is sent; the
  page says so) and the receipt screenshot `photo`. The club's alias comes
  from `GET /member/CLIQ` (field `CLIQ`).
- **Paid events.** `price` is charged per member and per guest. A new RSVP
  is only sent with its payment: the member fills in the CliQ details first,
  then Submit Payment sends the RSVP (`POST /member/events/{id}/rsvp`, which
  returns its `rsvp_id`) and right after it
  `POST /member/events/{rsvp_id}/cliq`. If the payment fails, the RSVP is
  cancelled at once and the member asked to try again. `rsvp_status`:
  `PENDING_PAYMENT` (no payment sent: "Payment needed" and Complete Payment,
  which pays that RSVP. My Events rows have no `rsvp_id`, so without it the
  unpaid RSVP is cancelled and sent again, with the same guests, together
  with the payment; the payment page says so first),
  `WAITING_ADMIN_APPROVAL` (payment under review), `CONFIRMED` (only then is
  the QR shown), `REJECTED` (listed under Past with Contact Support; the
  member can register for the event again) and `CANCELLED`
  (listed only under Past). A paid RSVP also shows its latest payment from
  `GET /member/payments` (its `related_id` is the RSVP's `rsvp_id`), in a second
  chip: `PENDING` or `FAILED` (it did not go through: can be paid again),
  `WAITING_ADMIN_APPROVAL` (no other payment can be sent), `REJECTED`,
  `CANCELLED`, `PENDING_REFUND`, `REFUNDED` or `REJECT_REFUNDED` (the RSVP is
  removed: listed under
  Past, and the member can register again), `COMPLETED` (the chip is hidden).
  An `rsvp_status` of `REFUND_PENDING` or `REFUNDED` is listed under Past too.
  A `CANCELLED` RSVP only shows its payment while it is `PENDING`, refund
  pending or `REJECT_REFUNDED`; once its payment is `REFUNDED` it reads
  REFUNDED. Free events
  show `rsvp_status` alone. Cancelling before the event starts is refunded,
  and the cancel dialog says so.
- **CliQ orders.** An order is never placed without its payment: with CliQ
  chosen, Continue to Payment opens the CliQ page, and Submit Payment calls
  `POST /member/cart/checkout` (`payment_method` `CLIQ`, which returns a
  `payment_id`) and right after it `POST /member/cliq`. If the payment fails,
  the order is cancelled at once (`PATCH /member/orders/{id}/cancel`), its
  items go back in the cart and the member is asked to try again. My Orders
  shows each order's status and, in a second chip, its latest payment from
  `GET /member/payments` (matched by `order_id`): `PENDING` or `FAILED`
  (Complete Payment sends it for that `payment_id`), `WAITING_ADMIN_APPROVAL`
  (no other payment), `REJECTED`, `CANCELLED`, `REFUND_PENDING`, `REFUNDED` or
  `REJECT_REFUNDED`
  (the order moves to Past, and reads REMOVED while its own status has not
  caught up); the chip is hidden once `COMPLETED`. An order status of
  `REFUND_PENDING` or `REFUNDED` (refund done) is listed under Past. Both `REFUND_PENDING` and
  `PENDING_REFUND` are read, for orders, RSVPs and payments. Orders can be cancelled
  while pending or processing; a sent or completed CliQ payment is then
  refunded, and the dialogs say so. Cash orders show no payment status,
  and neither do free events. An order or RSVP status of REJECTED means an admin
  rejected its payment (the payment then reads FAILED); it is listed under
  Past. My Events, My Orders, an open order and an event's page re-read these
  statuses every 10 seconds.
- **Out-of-stock items.** Sold-out products show greyed out with a "Sold Out"
  tag, and sold-out colours and sizes crossed out. This needs the backend to
  list them: `GET /member/items` currently leaves them out, and
  `GET /member/items/{id}` answers "Item is out of stock."
- **Caching.** Read-only data is cached in memory for 1–5 minutes and cleared on
  sign-out, together with every controller, so one member never sees another's
  data.
- **Privacy.** The API client never logs request fields, URLs or response
  bodies.

## Adding a feature

1. Create `lib/features/<name>/` with the folders above.
2. Add the repository interface and its `Api…Repository` implementation, and a
   controller. Create both in `AppDependencies` and reset the controller in
   `_clearMemberState`.
3. Add the route in `app_router.dart`. Pages that show server data use
   `_livePage` there so they stay current. If finishing an action should
   reload other data or move the member elsewhere, add a method to
   `AppActions` and connect the page's callback to it.
4. Render with `AsyncStateView` and the shared widgets.
5. Add a flow test with the fake backend.

## Not built yet

- **Card payments.** The card option on the membership pages is greyed out
  and says "Coming Soon"; gift/referral codes work. The shop's "online"
  payment has no gateway either. The backend does not send the membership
  fee yet.
- **Membership CliQ.** The payment goes to `POST /member/membership/cliq`.
  The page shows no amount, since the backend does not send the fee, and
  only a receipt sent in this session shows as under review, since the
  backend does not report one. Without an alias, Pay calls
  `POST /member/membership/payment` as before.
- **Card payment for events** shows Coming Soon;
  `EventsRepository.startEventPayment` is ready for it.
- **Refresh token.** Stored but unused: members sign in again after 30 days.
- **Checkout delivery address** is asked for but not sent (no API field yet).
- **Email changes** have no API endpoint yet.

## Before a store release

- The app ID is `com.porscheclubjordan.app` on Android and iOS, after the
  Firebase project `porsche-club-jordan`; register it there under this ID.
- Set up Android release signing (release builds currently use debug signing)
  and the Apple team, provisioning and signing.
- Bundle the Inter font files and declare them in `pubspec.yaml`; the theme
  falls back to the system font until then.
- Set the version in `pubspec.yaml` (currently `1.0.0+1`).
