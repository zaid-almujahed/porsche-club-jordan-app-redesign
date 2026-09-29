import 'package:flutter/foundation.dart';

/// Ignores late notifications from in-flight requests after a route is gone.
abstract class SafeChangeNotifier extends ChangeNotifier {
  bool _isDisposed = false;

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
