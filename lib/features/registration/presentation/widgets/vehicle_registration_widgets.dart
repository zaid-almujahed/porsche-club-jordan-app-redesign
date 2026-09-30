import 'dart:io';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import 'form_widgets.dart';

class LicensePhotoCard extends StatelessWidget {
  const LicensePhotoCard({
    super.key,
    required this.placeholderImagePath,
    required this.onAddPhotoPressed,
    this.selectedImagePath,
    this.isLoading = false,
    this.errorText,
  });

  final String placeholderImagePath;
  final String? selectedImagePath;
  final bool isLoading;
  final String? errorText;
  final VoidCallback? onAddPhotoPressed;

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = selectedImagePath != null;

    return RegistrationFormPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const RegistrationRequiredLabel(label: 'LICENSE PHOTO', fontSize: 13),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            "Upload a clear picture of your driver's license. "
            'Maximum file size is 5 MB.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          AspectRatio(
            aspectRatio: 350 / 250,
            child: CustomPaint(
              foregroundPainter: hasPhoto
                  ? null
                  : const _DashedBorderPainter(radius: AppRadii.medium),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  border: hasPhoto
                      ? Border.all(color: AppColors.cardBorder)
                      : null,
                  borderRadius: BorderRadius.circular(AppRadii.medium),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isLoading ? null : onAddPhotoPressed,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        AnimatedSwitcher(
                          duration: AppMotion.medium,
                          layoutBuilder: AppMotion.switcherLayout,
                          child: !hasPhoto
                              ? Opacity(
                                  key: const ValueKey<String>('placeholder'),
                                  opacity: 0.22,
                                  child: AppAssetImage(
                                    path: placeholderImagePath,
                                    fallbackIcon: Icons.badge_outlined,
                                  ),
                                )
                              : Image.file(
                                  File(selectedImagePath!),
                                  key: ValueKey<String>(selectedImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.textMuted,
                                      size: 48,
                                    ),
                                  ),
                                ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Color(0x10000000),
                                Color(0x80000000),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (!hasPhoto) ...<Widget>[
                                const AppIconBadge(
                                  icon: Icons.add_a_photo_outlined,
                                  size: 56,
                                  iconSize: 26,
                                  circle: true,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                              SizedBox(
                                height: 40,
                                child: FilledButton(
                                  onPressed: isLoading
                                      ? null
                                      : onAddPhotoPressed,
                                  style: AppButtonStyles.pill(
                                    horizontalPadding: 18,
                                  ),
                                  child: isLoading
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : AppButtonLabel(
                                          hasPhoto
                                              ? 'Change Photo'
                                              : 'Add Photo',
                                          style: AppTextStyles.button.copyWith(
                                            fontSize: 14.5,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    hasPhoto
                                        ? Icons.check_circle_rounded
                                        : Icons.info_outline_rounded,
                                    size: 15,
                                    color: hasPhoto
                                        ? AppColors.success
                                        : AppColors.textFaint,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    hasPhoto
                                        ? 'Photo selected'
                                        : 'No photo chosen',
                                    style: AppTextStyles.caption.copyWith(
                                      color: hasPhoto
                                          ? AppColors.success
                                          : AppColors.textFaint,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: errorText == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: AppInlineMessage.error(errorText!),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Dashed rounded outline for empty upload targets.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Path outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    final Paint paint = Paint()
      ..color = const Color(0x66D5001C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const double dash = 8;
    const double gap = 6;
    for (final PathMetric metric in outline.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

class VehicleDetailsForm extends StatelessWidget {
  const VehicleDetailsForm({
    super.key,
    required this.yearController,
    required this.modelController,
  });

  final TextEditingController yearController;
  final TextEditingController modelController;

  @override
  Widget build(BuildContext context) {
    return RegistrationFormPanel(
      child: Column(
        children: <Widget>[
          RegistrationTextField(
            controller: modelController,
            label: 'VEHICLE MODEL',
            hintText: 'enter model',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            suffixIcon: Icons.directions_car_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          RegistrationTextField(
            controller: yearController,
            label: 'YEAR',
            hintText: 'YYYY',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            suffixIcon: Icons.event_outlined,
          ),
        ],
      ),
    );
  }
}

class VehicleIdentificationForm extends StatelessWidget {
  const VehicleIdentificationForm({
    super.key,
    required this.vinController,
    required this.licensePlateController,
  });

  final TextEditingController vinController;
  final TextEditingController licensePlateController;

  @override
  Widget build(BuildContext context) {
    return RegistrationFormPanel(
      child: Column(
        children: <Widget>[
          RegistrationTextField(
            controller: vinController,
            label: 'VEHICLE IDENTIFICATION NUMBER (VIN)',
            hintText: '10- or 17-character VIN',
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            suffixIcon: Icons.pin_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          RegistrationTextField(
            controller: licensePlateController,
            label: 'LICENSE PLATE',
            hintText: 'e.g. 01-23456',
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            suffixIcon: Icons.credit_card_outlined,
          ),
        ],
      ),
    );
  }
}
