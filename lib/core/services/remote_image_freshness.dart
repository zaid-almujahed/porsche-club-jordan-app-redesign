import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

/// Notices when a picture is replaced under the same web address.
///
/// The club's photos are stored under their file names, so a new
/// "images.png" keeps the old address and the phone would keep showing the
/// copy it already downloaded. Every address on screen is re-checked now
/// and then with a HEAD request (its ETag); one whose picture changed is
/// given a new address (`?v=…`, which the storage ignores) so the new
/// picture is downloaded.
class RemoteImageFreshness extends ChangeNotifier {
  RemoteImageFreshness({
    required http.Client client,
    this.checkInterval = const Duration(seconds: 30),
  }) : _client = client;

  final http.Client _client;

  /// How long an address is trusted before it is checked again.
  final Duration checkInterval;

  // The tag first seen for each address, and the latest one.
  final Map<String, String> _firstTags = <String, String>{};
  final Map<String, String> _latestTags = <String, String>{};
  final Map<String, DateTime> _checkedAt = <String, DateTime>{};
  final Set<String> _checking = <String>{};
  bool _isDisposed = false;

  static RemoteImageFreshness? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<RemoteImageFreshnessScope>()
      ?.freshness;

  /// [url], or a new address for it once the picture behind it changed.
  /// Checks it again when it has not been checked for [checkInterval].
  String resolve(String url) {
    _checkIfDue(url);
    final String? latest = _latestTags[url];
    if (latest == null || latest == _firstTags[url]) return url;
    final String version = latest.replaceAll(RegExp('[^A-Za-z0-9]'), '');
    return '$url${url.contains('?') ? '&' : '?'}v=$version';
  }

  void _checkIfDue(String url) {
    if (_checking.contains(url)) return;
    final DateTime now = DateTime.now();
    final DateTime? checkedAt = _checkedAt[url];
    if (checkedAt != null && now.difference(checkedAt) < checkInterval) {
      return;
    }
    _checkedAt[url] = now;
    _checking.add(url);
    unawaited(_check(url));
  }

  Future<void> _check(String url) async {
    try {
      final http.Response response = await _client.head(Uri.base.resolve(url));
      final String? tag =
          response.headers['etag'] ?? response.headers['last-modified'];
      if (_isDisposed || response.statusCode != 200 || tag == null) return;
      _firstTags.putIfAbsent(url, () => tag);
      if (_latestTags[url] == tag) return;
      final bool wasChanged =
          (_latestTags[url] ?? _firstTags[url]) != _firstTags[url];
      _latestTags[url] = tag;
      // Only a picture that differs from the one first shown (or changed
      // again) needs a new address.
      if (tag != _firstTags[url] || wasChanged) notifyListeners();
    } catch (_) {
      // Offline or refused: the address stays as it is.
    } finally {
      _checking.remove(url);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// Gives [AppAssetImage]s below it access to [RemoteImageFreshness].
class RemoteImageFreshnessScope extends InheritedWidget {
  const RemoteImageFreshnessScope({
    super.key,
    required this.freshness,
    required super.child,
  });

  final RemoteImageFreshness freshness;

  @override
  bool updateShouldNotify(RemoteImageFreshnessScope oldWidget) =>
      !identical(freshness, oldWidget.freshness);
}
