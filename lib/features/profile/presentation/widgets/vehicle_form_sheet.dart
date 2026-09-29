import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/core/validation/vehicle_rules.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../../domain/repositories/profile_repository.dart';
import '../controllers/profile_controller.dart';
import '../controllers/vehicle_form_controller.dart';

/// Adds a car, or edits [vehicle]. Returns true once it is saved.
Future<bool> showVehicleFormSheet({
  required BuildContext context,
  required ProfileController profile,
  Vehicle? vehicle,
}) async {
  profile.clearVehicleError();
  final bool? saved = await showModalBottomSheet<bool>(
    context: context,
    // Above the whole app, like the other sheets.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.panelDark,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _VehicleFormSheet(profile: profile, vehicle: vehicle),
  );
  profile.clearVehicleError();
  return saved ?? false;
}

class _VehicleFormSheet extends StatefulWidget {
  const _VehicleFormSheet({required this.profile, this.vehicle});

  final ProfileController profile;
  final Vehicle? vehicle;

  @override
  State<_VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<_VehicleFormSheet> {
  late final VehicleFormController _form = VehicleFormController(
    pickPhoto: widget.profile.pickVehiclePhoto,
    vehicle: widget.vehicle,
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final VehicleDraft? draft = await _form.buildDraft();
    if (draft == null || !mounted) return;
    final Vehicle? vehicle = widget.vehicle;
    final bool saved = vehicle == null
        ? await widget.profile.addVehicle(draft)
        : await widget.profile.updateVehicle(vehicle.id, draft);
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_form, widget.profile]),
        builder: (BuildContext context, Widget? child) {
          final bool isSaving = widget.profile.isSavingVehicle;
          final Object? saveError = widget.profile.vehicleError;
          final String? error =
              _form.error ??
              (saveError == null ? null : readableError(saveError));
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
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
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    const AppIconBadge(icon: Icons.directions_car_outlined),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _form.isEditing ? 'Edit Vehicle' : 'Add Vehicle',
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 23,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: isSaving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Enter the details as they appear on the registration card.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: AppSpacing.lg),
                _VehicleField(
                  label: 'MODEL',
                  hintText: 'e.g. 911 Carrera S',
                  controller: _form.modelController,
                  onChanged: _form.onChanged,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.md),
                _VehicleField(
                  label: 'YEAR',
                  hintText: 'e.g. ${VehicleRules.newestYear - 1}',
                  controller: _form.yearController,
                  onChanged: _form.onChanged,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _VehicleField(
                  label: 'VIN',
                  hintText: '17 characters (10 for older cars)',
                  controller: _form.vinController,
                  onChanged: _form.onChanged,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(17),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _VehicleField(
                  label: 'LICENCE PLATE (OPTIONAL)',
                  hintText: 'e.g. 12-34567',
                  controller: _form.plateController,
                  onChanged: _form.onChanged,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: AppSpacing.lg),
                _PlatePhotoTile(
                  photoPath: _form.photo?.path,
                  currentPhotoUrl: widget.vehicle?.imageUrl,
                  isOptional: _form.isEditing,
                  isPicking: _form.isPickingPhoto,
                  onPressed: isSaving ? null : _form.pickPhoto,
                ),
                if (error != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  AppInlineMessage.error(error),
                ],
                const SizedBox(height: AppSpacing.xl),
                PrimaryActionButton(
                  label: _form.isEditing ? 'Save Vehicle' : 'Add Vehicle',
                  icon: Icons.check_rounded,
                  height: 56,
                  isLoading: isSaving,
                  onPressed: isSaving ? null : _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VehicleField extends StatelessWidget {
  const _VehicleField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label, style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: AppTextStyles.input,
          cursorColor: AppColors.primaryBright,
          decoration: InputDecoration(hintText: hintText),
        ),
      ],
    );
  }
}

/// The licence plate photo: the one just picked, else the car's current
/// photo (kept when editing), else a prompt to add one.
class _PlatePhotoTile extends StatelessWidget {
  const _PlatePhotoTile({
    required this.photoPath,
    required this.currentPhotoUrl,
    required this.isOptional,
    required this.isPicking,
    required this.onPressed,
  });

  final String? photoPath;
  final String? currentPhotoUrl;

  /// Editing: a new photo is optional.
  final bool isOptional;
  final bool isPicking;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final String? preview =
        photoPath ??
        ((currentPhotoUrl ?? '').trim().isEmpty ? null : currentPhotoUrl);
    final String caption = photoPath != null
        ? 'New photo selected · tap to change'
        : preview != null
        ? 'Current photo is kept · tap to replace'
        : isOptional
        ? 'Optional · tap to add a photo'
        : 'Add a photo of the licence plate';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('LICENCE PLATE PHOTO', style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.medium),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 72,
                    height: 52,
                    child: isPicking
                        ? const Center(
                            child: SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : preview == null
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.panelDark,
                              borderRadius: BorderRadius.circular(
                                AppRadii.small,
                              ),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.textMuted,
                            ),
                          )
                        : AppAssetImage(
                            path: preview,
                            borderRadius: BorderRadius.circular(AppRadii.small),
                            fallbackIcon: Icons.image_outlined,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      caption,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
