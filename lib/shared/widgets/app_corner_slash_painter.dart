import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';

/// Red diagonal flourish drawn in the bottom-right corner of hero cards.
class AppCornerSlashPainter extends CustomPainter {
  const AppCornerSlashPainter({this.color = AppColors.primary});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Path slash = Path()
      ..moveTo(size.width, size.height * 0.42)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.70, size.height)
      ..close();
    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: <Color>[
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(slash, paint);
  }

  @override
  bool shouldRepaint(covariant AppCornerSlashPainter oldDelegate) =>
      oldDelegate.color != color;
}
