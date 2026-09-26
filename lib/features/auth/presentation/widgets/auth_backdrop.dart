import 'package:flutter/material.dart';

import 'package:pcj_v4/core/theme/app_theme.dart';

/// Dark auth backdrop: optional photo, red glow, and a thin red swoosh that
/// echoes the car line in the club logo.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({
    super.key,
    required this.child,
    this.imagePath,
    this.glowCenter = const Alignment(0, -0.7),
  });

  final Widget child;
  final String? imagePath;
  final Alignment glowCenter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: AppColors.appBar),
        if (imagePath != null)
          Opacity(
            opacity: 0.32,
            child: Image.asset(
              imagePath!,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return const SizedBox.shrink();
                  },
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: glowCenter,
              radius: 0.95,
              colors: const <Color>[
                Color(0x4DD5001C),
                Color(0x1A7A0010),
                Color(0x00000000),
              ],
              stops: const <double>[0, 0.45, 1],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1.15, 1.2),
              radius: 0.85,
              colors: <Color>[Color(0x40D5001C), Color(0x00000000)],
            ),
          ),
        ),
        const CustomPaint(painter: _SwooshPainter()),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0x00050507), Color(0x99050507)],
              stops: <double>[0.55, 1],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _SwooshPainter extends CustomPainter {
  const _SwooshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    final Shader shader = const LinearGradient(
      colors: <Color>[Color(0x00D5001C), Color(0x99EE1A30), Color(0x00D5001C)],
      stops: <double>[0, 0.55, 1],
    ).createShader(bounds);

    void swoosh(double startY, double peakY, double endY, double width) {
      final Path path = Path()
        ..moveTo(-size.width * 0.05, size.height * startY)
        ..quadraticBezierTo(
          size.width * 0.55,
          size.height * peakY,
          size.width * 1.05,
          size.height * endY,
        );
      canvas.drawPath(
        path,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    swoosh(0.86, 0.70, 0.80, 1.6);
    swoosh(0.89, 0.75, 0.84, 0.8);
  }

  @override
  bool shouldRepaint(covariant _SwooshPainter oldDelegate) => false;
}

/// The club logo with a graceful fallback when the asset is missing.
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, this.maxHeight = 150});

  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Image.asset(
        'assets/images/porsche_club_jordan_logo.png',
        fit: BoxFit.contain,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return const SizedBox(
                height: 112,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textFaint,
                  size: 42,
                ),
              );
            },
      ),
    );
  }
}
