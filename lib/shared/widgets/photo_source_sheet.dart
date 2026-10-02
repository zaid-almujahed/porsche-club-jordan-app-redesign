import 'package:flutter/material.dart';

import 'package:pcj_v5/core/services/image_picker_service.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';

export 'package:pcj_v5/core/services/image_picker_service.dart'
    show PhotoSource;

/// "Take Photo" or "Choose from Library"; null when dismissed.
Future<PhotoSource?> showPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<PhotoSource>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: AppColors.panelDark,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x40FFFFFF),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _SourceOption(
            source: PhotoSource.camera,
            icon: Icons.photo_camera_outlined,
            label: 'Take Photo',
          ),
          const SizedBox(height: AppSpacing.xs),
          const _SourceOption(
            source: PhotoSource.library,
            icon: Icons.photo_library_outlined,
            label: 'Choose from Library',
          ),
        ],
      ),
    ),
  );
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.source,
    required this.icon,
    required this.label,
  });

  final PhotoSource source;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadii.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        onTap: () => Navigator.of(context).pop(source),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 16,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 22, color: AppColors.primaryBright),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
