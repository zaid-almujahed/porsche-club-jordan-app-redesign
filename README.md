# Porsche Club Jordan — Member App

Flutter app for Porsche Club Jordan members (Android and iOS). Anyone can apply
for membership; the club reviews the application; approved applicants pay the
yearly membership; active members get events and RSVPs with QR tickets, the club
shop, partner offers, notifications, and their profile and membership details.

All data comes from the PCJ REST API. The phone stores only the login token
and the QR codes of opened event tickets.

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

Until the Firebase project is connected, the app runs normally without
pushes. To connect it, once:

1. Set the final app IDs (see "Before a store release"); Firebase registers
   the app under them.
2. Install the FlutterFire CLI (`dart pub global activate flutterfire_cli`),
   sign in with the club's Firebase account and run `flutterfire configure`
   in the project folder, choosing Android and iOS and the same Firebase
   project the backend sends pushes from (otherwise tokens are registered but
   pushes never arrive). It adds
   `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`
   and the Google services Gradle plugin.
3. iOS: in Xcode, add the **Push Notifications** capability to the Runner
   target (remote notifications are already enabled as a background mode),
   and upload an APNs key in the Firebase console (Project settings → Cloud
   Messaging).

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
    data/                      parsing shared by features (membership status)
    domain/entities/           User, Membership, Event, Product, Cart, Order, Offer...
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
  status page tries that login again every 30 seconds with the email and
  password typed this session (kept in memory only). Approval shows as the
  login going through: a pop-up lists the next steps (enter the emailed code,
  then pay). A rejection updates the page.
- **Replaced photos.** Photos are stored under their file names, so a new
  photo can keep the old address. `RemoteImageFreshness` re-checks the
  pictures on screen (a HEAD request, at most every 30 seconds each) and gives
  a changed one a new address so it is downloaded again.
- **Errors.** Errors from an action (a wrong password, an action that is not
  allowed, a failed save) appear as a short pop-up that fades on its own
  (`showAppErrorPulse`, beside `showAppSuccessPulse`). Only pages that could
  not load keep an inline message with a retry.
- **Gift / referral codes** are single use: the field is cleared once a code
  is accepted or the page is left, and the keyboard is told not to learn it.
- **Event tickets.** The backend issues a ticket's QR once: the first view
  moves the RSVP from "Not Checked In" to `PARTIALLY_CHECKED_IN`. The app
  saves the QR in secure storage before showing it and never requests it
  again; after `CHECKED_IN` it is no longer shown. Saved QRs are kept per
  member across sign-outs (`TicketQrStore`), so a QR first opened on another
  phone cannot be shown on this one. A saved QR is only used while the RSVP
  is `PARTIALLY_CHECKED_IN`; on "Not Checked In" it belongs to an earlier RSVP
  (iOS keeps it even after the app is deleted) and a new one is issued.
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

- **Card payments.** Membership payment calls `POST /member/membership/payment`,
  but no payment page (MEPS) opens yet; gift/referral codes work. The shop's
  "online" payment has no gateway either. The backend does not send the
  membership fee yet.
- **Paid events.** Registration treats events as free;
  `EventsRepository.startEventPayment` is ready.
- **Refresh token.** Stored but unused: members sign in again after 30 days.
- **Checkout delivery address** is asked for but not sent (no API field yet).
- **Support email** opens addressed to the member, because no club support
  address is configured.
- **Email changes** have no API endpoint yet.

## Before a store release

- Replace the placeholder app IDs (`com.example.pcj_v5` on Android,
  `com.example.pcjV5` on iOS).
- Set up Android release signing (release builds currently use debug signing)
  and the Apple team, provisioning and signing.
- Bundle the Inter font files and declare them in `pubspec.yaml`; the theme
  falls back to the system font until then.
- Set the version in `pubspec.yaml` (currently `1.0.0+1`).
