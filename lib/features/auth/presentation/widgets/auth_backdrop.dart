import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';

/// Dark auth backdrop: red glow, and a thin red swoosh that echoes the car
/// line in the club logo.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({
    super.key,
    required this.child,
    this.glowCenter = const Alignment(0, -0.7),
  });

  final Widget child;
  final Alignment glowCenter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: AppColors.appBar),
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

/// A thin light trail rising from the left edge at [startY] to the right
/// edge at [endY] (fractions of the height).
class LightTrail {
  const LightTrail({
    required this.startY,
    required this.endY,
    required this.width,
    required this.opacity,
  });

  final double startY;
  final double endY;
  final double width;
  final double opacity;
}

/// Welcome's and Sign In's backdrop: a soft red glow behind the logo and
/// thin light trails sweeping under it, like tail lights on a long exposure.
class LightTrailsBackdrop extends StatelessWidget {
  const LightTrailsBackdrop({
    super.key,
    required this.child,
    required this.glowCenter,
    required this.trails,
  });

  final Widget child;
  final Alignment glowCenter;
  final List<LightTrail> trails;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: AppColors.appBar),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: glowCenter,
              radius: 0.9,
              colors: const <Color>[
                Color(0x59D5001C),
                Color(0x1A7A0010),
                Color(0x00000000),
              ],
              stops: const <double>[0, 0.45, 1],
            ),
          ),
        ),
        CustomPaint(painter: _LightTrailsPainter(trails)),
        // Darker towards the bottom, where the welcome and buttons sit.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0x00050507), Color(0xE6050507)],
              stops: <double>[0.5, 0.82],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _LightTrailsPainter extends CustomPainter {
  const _LightTrailsPainter(this.trails);

  final List<LightTrail> trails;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;

    // Brightest towards the right.
    void trail(double startY, double endY, double width, double opacity) {
      final Path path = Path()
        ..moveTo(-size.width * 0.1, size.height * startY)
        ..cubicTo(
          size.width * 0.35,
          size.height * (startY - 0.02),
          size.width * 0.65,
          size.height * (endY + 0.04),
          size.width * 1.1,
          size.height * endY,
        );
      Shader shader(double alpha) => LinearGradient(
        colors: <Color>[
          const Color(0x00D5001C),
          AppColors.primaryBright.withValues(alpha: alpha),
          const Color(0xFFFFC2C8).withValues(alpha: alpha),
          const Color(0x00D5001C),
        ],
        stops: const <double>[0, 0.5, 0.78, 1],
      ).createShader(bounds);

      canvas
        // A soft glow under a thin bright line.
        ..drawPath(
          path,
          Paint()
            ..shader = shader(opacity * 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = width * 6
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        )
        ..drawPath(
          path,
          Paint()
            ..shader = shader(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round,
        );
    }

    for (final LightTrail line in trails) {
      trail(line.startY, line.endY, line.width, line.opacity);
    }
  }

  @override
  bool shouldRepaint(covariant _LightTrailsPainter oldDelegate) =>
      oldDelegate.trails != trails;
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
