import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';

class AppAssetImage extends StatelessWidget {
  const AppAssetImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackLabel,
  });

  final String path;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    if (path.trim().isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: _buildFallback(
          context,
          StateError('No image path was supplied.'),
          null,
        ),
      );
    }

    final bool isRemote =
        path.startsWith('http://') || path.startsWith('https://');
    final bool isDataImage =
        path.startsWith('data:image/') && path.contains(',');
    final bool isAbsoluteFile =
        path.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);

    final Widget image;
    if (isDataImage) {
      try {
        image = Image.memory(
          base64Decode(path.substring(path.indexOf(',') + 1)),
          fit: fit,
          frameBuilder: _fadeInFrame,
          errorBuilder: _buildFallback,
        );
      } on FormatException catch (error, stackTrace) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: _buildFallback(context, error, stackTrace),
        );
      }
    } else if (isRemote) {
      image = Image.network(
        path,
        fit: fit,
        frameBuilder: _fadeInFrame,
        errorBuilder: _buildFallback,
      );
    } else if (isAbsoluteFile) {
      image = Image.file(
        io.File(path),
        fit: fit,
        frameBuilder: _fadeInFrame,
        errorBuilder: _buildFallback,
      );
    } else {
      image = Image.asset(
        path,
        fit: fit,
        frameBuilder: _fadeInFrame,
        errorBuilder: _buildFallback,
      );
    }

    return ClipRRect(borderRadius: borderRadius, child: image);
  }

  // Images that arrive asynchronously fade in instead of popping.
  Widget _fadeInFrame(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) return child;
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: AppMotion.medium,
      curve: Curves.easeOut,
      child: child,
    );
  }

  Widget _buildFallback(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1E1E22), Color(0xFF0E0E10)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(fallbackIcon, color: const Color(0x4DFFFFFF), size: 38),
            if (fallbackLabel != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                fallbackLabel!,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textFaint,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
