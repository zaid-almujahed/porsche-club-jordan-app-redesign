import 'package:flutter/material.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

class PersonalDetailsPanel extends StatelessWidget {
  const PersonalDetailsPanel({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.cityController,
    required this.dateOfBirthController,
    required this.avatarUrl,
    required this.isUploading,
    this.onChangePhoto,
    this.onDateOfBirthPressed,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController dateOfBirthController;
  final String? avatarUrl;
  final bool isUploading;
  final VoidCallback? onChangePhoto;
  final VoidCallback? onDateOfBirthPressed;

  @override
  Widget build(BuildContext context) {
    return GradientPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppRadii.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _PanelHeading(
            icon: Icons.person_outline_rounded,
            title: 'Personal Details',
            color: AppColors.accentSteel,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 108,
                  height: 108,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: <Color>[
                        AppColors.primaryBright,
                        AppColors.primaryDeep,
                        AppColors.primaryBright,
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: AppColors.primaryGlow, blurRadius: 20),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.panelDark,
                    ),
                    child: AnimatedSwitcher(
                      duration: AppMotion.medium,
                      child: AppAssetImage(
                        key: ValueKey<String>(avatarUrl ?? ''),
                        path: avatarUrl ?? '',
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadii.pill),
                        ),
                        fallbackIcon: Icons.person_outline,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(
                      side: BorderSide(color: AppColors.panelDark, width: 3),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: isUploading ? null : onChangePhoto,
                      child: SizedBox.square(
                        dimension: 36,
                        child: isUploading
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.photo_camera_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton(
              onPressed: isUploading ? null : onChangePhoto,
              child: AppButtonLabel(
                isUploading ? 'Uploading...' : 'Change Photo',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ProfileTextField(
            label: 'FULL NAME',
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            hintText: 'e.g. Ferdinand Porsche',
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProfileTextField(
            label: 'EMAIL ADDRESS',
            controller: emailController,
            readOnly: true,
            suffixIcon: Icons.lock_outline,
            helperText: 'Your email address cannot be changed here.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProfileTextField(
            label: 'PHONE NUMBER',
            controller: phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProfileTextField(
            label: 'CITY',
            controller: cityController,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProfileTextField(
            label: 'DATE OF BIRTH',
            controller: dateOfBirthController,
            readOnly: true,
            onTap: onDateOfBirthPressed,
            suffixIcon: Icons.calendar_month_outlined,
            hintText: 'YYYY-MM-DD',
          ),
        ],
      ),
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({
    required this.icon,
    required this.title,
    this.action,
    this.color = AppColors.primaryBright,
  });

  final IconData icon;
  final String title;
  final Widget? action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        AppIconBadge(icon: icon, color: color, size: 38, iconSize: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 19),
          ),
        ),
        ?action,
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label, style: AppTextStyles.overline),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTextStyles.input.copyWith(
            color: readOnly && onTap == null
                ? AppColors.textMuted
                : AppColors.textPrimary,
          ),
          cursorColor: AppColors.primaryBright,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            helperStyle: AppTextStyles.caption.copyWith(fontSize: 12),
            suffixIcon: suffixIcon == null
                ? null
                : Icon(suffixIcon, color: AppColors.textMuted, size: 20),
          ),
        ),
      ],
    );
  }
}

class VehiclesPanel extends StatelessWidget {
  const VehiclesPanel({
    super.key,
    required this.vehicles,
    required this.onDeleteVehicle,
    this.onAddVehicle,
    this.onEditVehicle,
  });

  final List<Vehicle> vehicles;
  final ValueChanged<String> onDeleteVehicle;

  /// No longer shown: Edit replaced Add.
  final VoidCallback? onAddVehicle;

  /// Wired once the vehicle-update endpoint exists; until then Edit explains
  /// that editing is coming soon.
  final ValueChanged<Vehicle>? onEditVehicle;

  void _edit(BuildContext context, Vehicle? vehicle) {
    final ValueChanged<Vehicle>? callback = onEditVehicle;
    if (callback != null && vehicle != null) {
      callback(vehicle);
      return;
    }
    showAppSnackBar(
      context,
      'Vehicle editing will be available soon.',
      type: AppFeedbackType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppRadii.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PanelHeading(
            icon: Icons.garage_outlined,
            title: vehicles.length > 1 ? 'My Vehicles' : 'My Vehicle',
            action: vehicles.length == 1
                ? _EditVehicleButton(
                    onPressed: () => _edit(context, vehicles.first),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (vehicles.isEmpty)
            const AppEmptyState(
              icon: Icons.directions_car_outlined,
              message: 'No vehicles are registered.',
            )
          else
            for (int index = 0; index < vehicles.length; index++) ...<Widget>[
              AppFadeSlideIn.stagger(
                index: index,
                child: _VehicleCard(
                  vehicle: vehicles[index],
                  onDelete: () => onDeleteVehicle(vehicles[index].id),
                  // With several vehicles each card carries its own Edit.
                  onEdit: vehicles.length > 1
                      ? () => _edit(context, vehicles[index])
                      : null,
                ),
              ),
              if (index != vehicles.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}

class _EditVehicleButton extends StatelessWidget {
  const _EditVehicleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: AppButtonStyles.outline(
          radius: AppRadii.pill,
          horizontalPadding: 14,
        ),
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: AppButtonLabel(
          'EDIT',
          style: AppTextStyles.label.copyWith(letterSpacing: 1),
        ),
      ),
    );
  }
}

/// One vehicle as a single hero card: photo with the model over it, then
/// colour, plate and VIN.
class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.onDelete,
    this.onEdit,
  });

  final Vehicle vehicle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  bool get _hasPhoto => (vehicle.imageUrl ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadii.large),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(
            // Without a photo the header shrinks to a short banner.
            aspectRatio: _hasPhoto ? 16 / 9 : 2.6,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.2),
                      radius: 0.9,
                      colors: <Color>[Color(0xFF2A2A30), Color(0xFF0E0E10)],
                    ),
                  ),
                ),
                if (_hasPhoto)
                  AppAssetImage(
                    path: vehicle.imageUrl!,
                    fallbackIcon: Icons.directions_car_filled_outlined,
                  )
                else
                  const Align(
                    alignment: Alignment(0.9, -0.35),
                    child: Icon(
                      Icons.directions_car_filled_rounded,
                      size: 76,
                      color: Color(0x14FFFFFF),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0x00000000), Color(0xE60A0A0C)],
                      stops: <double>[0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (vehicle.year > 0)
                        Text(
                          '${vehicle.year}',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.primaryBright,
                            letterSpacing: 1.6,
                          ),
                        ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          vehicle.model,
                          maxLines: 1,
                          style: AppTextStyles.pageTitle.copyWith(fontSize: 26),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Row(
                    children: <Widget>[
                      if (onEdit != null) ...<Widget>[
                        SizedBox.square(
                          dimension: 40,
                          child: AppGlassIconButton(
                            icon: Icons.edit_outlined,
                            tooltip: 'Edit vehicle',
                            onPressed: onEdit,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      SizedBox.square(
                        dimension: 40,
                        child: AppGlassIconButton(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Remove vehicle',
                          onPressed: onDelete,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _VehicleSpec(
                  label: 'PLATE',
                  value: vehicle.licensePlate,
                  icon: Icons.pin_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: AppSpacing.md),
                _VehicleSpec(
                  label: 'VIN',
                  value: vehicle.vin,
                  icon: Icons.qr_code_2_rounded,
                  monospace: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleSpec extends StatelessWidget {
  const _VehicleSpec({
    required this.label,
    required this.value,
    required this.icon,
    this.monospace = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.accentSteel),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: AppTextStyles.overline.copyWith(fontSize: 10)),
              const SizedBox(height: 3),
              Text(
                value.trim().isEmpty ? '—' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title.copyWith(
                  fontSize: monospace ? 14 : 15,
                  letterSpacing: monospace ? 1.2 : 0,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
