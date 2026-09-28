import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Keeps a page's data current without the member pulling to refresh.
///
/// While the page is on screen and the app is in the foreground,
/// [onRefresh] runs every [interval], and straight away whenever the page
/// comes back into view (returning to a tab or closing a page on top of it).
/// Pages covered by another page and inactive tabs are skipped: Flutter
/// disables their tickers, which is what this listens to.
class AppLiveRefresh extends StatefulWidget {
  const AppLiveRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  static const Duration interval = Duration(seconds: 10);

  /// Reloads the page's data without clearing what is on screen, e.g.
  /// `controller.load(force: true)`.
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<AppLiveRefresh> createState() => _AppLiveRefreshState();
}

class _AppLiveRefreshState extends State<AppLiveRefresh>
    with WidgetsBindingObserver {
  Timer? _timer;
  ValueListenable<TickerModeData>? _visibility;
  bool _wasVisible = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(AppLiveRefresh.interval, (_) => _refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ValueListenable<TickerModeData> visibility =
        TickerMode.getValuesNotifier(context);
    if (identical(visibility, _visibility)) return;
    _visibility?.removeListener(_onVisibilityChanged);
    _visibility = visibility..addListener(_onVisibilityChanged);
    _wasVisible = visibility.value.enabled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _onVisibilityChanged() {
    final bool visible = _visibility?.value.enabled ?? true;
    if (visible && !_wasVisible) _refresh();
    _wasVisible = visible;
  }

  bool get _isOnScreen {
    final AppLifecycleState? lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return false;
    }
    return _visibility?.value.enabled ?? true;
  }

  Future<void> _refresh() async {
    if (!mounted || _isRefreshing || !_isOnScreen) return;
    _isRefreshing = true;
    try {
      await widget.onRefresh();
    } catch (_) {
      // The controller keeps its data and records the error; the next tick
      // tries again.
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _visibility?.removeListener(_onVisibilityChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
