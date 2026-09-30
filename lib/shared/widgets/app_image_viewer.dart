import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_asset_image.dart';

/// Shows [images] full screen from [initialIndex]: swipe between them, pinch
/// to zoom, and close with the small × at the top right.
Future<void> showAppImageViewer(
  BuildContext context, {
  required List<String> images,
  int initialIndex = 0,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          _AppImageViewer(images: images, initialIndex: initialIndex),
      transitionsBuilder: (_, Animation<double> animation, _, Widget child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _AppImageViewer extends StatefulWidget {
  const _AppImageViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_AppImageViewer> createState() => _AppImageViewerState();
}

class _AppImageViewerState extends State<_AppImageViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (int index) => setState(() => _index = index),
            itemBuilder: (BuildContext context, int index) {
              return InteractiveViewer(
                maxScale: 4,
                child: AppAssetImage(
                  path: widget.images[index],
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
          Positioned(
            top: padding.top + AppSpacing.sm,
            right: AppSpacing.sm,
            child: Material(
              color: const Color(0x66000000),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Close',
                constraints: BoxConstraints.tight(const Size.square(36)),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: padding.bottom + AppSpacing.lg,
              child: Text(
                '${_index + 1} / ${widget.images.length}',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
