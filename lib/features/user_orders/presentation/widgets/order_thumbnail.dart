import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

/// An order's picture, made of its first items: one fills the square, two
/// sit side by side, three show as one large and two stacked. More than
/// three add a "+N" badge.
class OrderThumbnail extends StatelessWidget {
  const OrderThumbnail({
    super.key,
    required this.imagePaths,
    this.size = 76,
    this.radius = AppRadii.medium,
  });

  /// One per item, in order; empty for an item without a photo.
  final List<String> imagePaths;
  final double size;
  final double radius;

  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final List<String> shown = imagePaths.take(3).toList(growable: false);
    final int more = imagePaths.length - shown.length;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: <Color>[Color(0xFF2A2A30), Color(0xFF111114)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: switch (shown.length) {
        0 => _tile('', large: true),
        1 => _tile(shown[0], large: true),
        2 => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: _tile(shown[0])),
            const SizedBox(width: _gap),
            Expanded(child: _tile(shown[1])),
          ],
        ),
        _ => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: _tile(shown[0])),
            const SizedBox(width: _gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(child: _tile(shown[1])),
                  const SizedBox(height: _gap),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        _tile(shown[2]),
                        if (more > 0)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: _MoreBadge(count: more),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      },
    );
  }

  Widget _tile(String path, {bool large = false}) {
    return AppAssetImage(
      path: path,
      fallbackIcon: Icons.shopping_bag_outlined,
      fallbackIconSize: size * (large ? 0.45 : 0.2),
    );
  }
}

class _MoreBadge extends StatelessWidget {
  const _MoreBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        '+$count',
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }
}
