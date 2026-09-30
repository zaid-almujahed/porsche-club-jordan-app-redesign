import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:pcj_v5/features/notifications/domain/repositories/notifications_repository.dart';

/// Push notifications through Firebase Cloud Messaging. The backend sends
/// them to the device token registered with `POST /notifications/token`.
///
/// Stays off, harmlessly, until the Firebase project is set up for the app
/// (see the README).
class PushNotificationsService {
  PushNotificationsService({required NotificationsRepository repository})
    : _repository = repository;

  final NotificationsRepository _repository;
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];
  StreamSubscription<String>? _tokenRefresh;
  bool _isAvailable = false;
  String? _registeredToken;

  /// A push arrived while the app is open.
  void Function(RemoteMessage message)? onMessage;

  /// The member opened the app by tapping a push.
  void Function(RemoteMessage message)? onOpened;

  /// Set [onMessage] and [onOpened] first: a tap that launched the app is
  /// reported from here.
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Not set up for this build: the app runs without pushes.
      return;
    }
    _isAvailable = true;
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    // iOS shows the banner while the app is open too.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _subscriptions
      ..add(
        FirebaseMessaging.onMessage.listen(
          (RemoteMessage message) => onMessage?.call(message),
        ),
      )
      ..add(
        FirebaseMessaging.onMessageOpenedApp.listen(
          (RemoteMessage message) => onOpened?.call(message),
        ),
      );
    final RemoteMessage? launchedBy = await messaging.getInitialMessage();
    if (launchedBy != null) onOpened?.call(launchedBy);
  }

  /// Asks for permission, then registers this device for the signed-in
  /// member. The token is sent again only when Firebase changes it.
  Future<void> registerDevice() async {
    if (!_isAvailable) return;
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final NotificationSettings settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      // Listen first, so a token that arrives later is still registered.
      _tokenRefresh ??= messaging.onTokenRefresh.listen(_registerQuietly);
      await _registerCurrentToken();
    } catch (_) {
      // Pushes are optional; the in-app list still updates while open.
    }
  }

  /// When the app comes back: a device that could not register earlier
  /// (offline, or iOS had no APNs token yet) tries again.
  Future<void> retryRegistration() async {
    if (!_isAvailable || _tokenRefresh == null || _registeredToken != null) {
      return;
    }
    try {
      await _registerCurrentToken();
    } catch (_) {
      // Tried again on the next resume.
    }
  }

  Future<void> _registerCurrentToken() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    // iOS gives out the FCM token only once Apple has sent the APNs token,
    // which can take a few seconds after permission is granted.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      for (int i = 0; i < 10 && await messaging.getAPNSToken() == null; i++) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    // Signed out while waiting.
    if (_tokenRefresh == null) return;
    await _register(await messaging.getToken());
  }

  Future<void> _registerQuietly(String token) async {
    try {
      await _register(token);
    } catch (_) {
      // Tried again on the next resume.
    }
  }

  /// On sign-out: this device stops receiving the member's pushes, and the
  /// next member to sign in gets a new token.
  Future<void> unregisterDevice() async {
    if (!_isAvailable) return;
    await _tokenRefresh?.cancel();
    _tokenRefresh = null;
    _registeredToken = null;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Nothing more to do: a stale token simply receives nothing.
    }
  }

  Future<void> _register(String? token) async {
    if (token == null || token.isEmpty || token == _registeredToken) return;
    await _repository.registerDeviceToken(token);
    _registeredToken = token;
  }

  void dispose() {
    for (final StreamSubscription<Object?> subscription in _subscriptions) {
      subscription.cancel();
    }
    _tokenRefresh?.cancel();
  }
}
