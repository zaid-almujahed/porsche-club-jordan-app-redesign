import 'package:flutter/material.dart';

/// Greys out, and dims a little, the picture of something that is sold out.
class SoldOutShade extends StatelessWidget {
  const SoldOutShade({super.key, required this.soldOut, required this.child});

  final bool soldOut;
  final Widget child;

  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    if (!soldOut) return child;
    return Opacity(
      opacity: 0.55,
      child: ColorFiltered(colorFilter: _greyscale, child: child),
    );
  }
}
