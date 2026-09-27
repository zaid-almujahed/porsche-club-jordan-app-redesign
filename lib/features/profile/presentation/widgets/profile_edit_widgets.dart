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
              child: Text(isUploading ? 'Uploading...' : 'Change Photo'),
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
  });

  final List<Vehicle> vehicles;
  final ValueChanged<String> onDeleteVehicle;
  final VoidCallback? onAddVehicle;

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
            title: 'My Vehicles',
            action: SizedBox(
              height: 38,
              child: FilledButton.icon(
                onPressed: onAddVehicle,
                style: AppButtonStyles.compact(
                  backgroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'ADD',
                  style: AppTextStyles.label.copyWith(letterSpacing: 1),
                ),
              ),
            ),
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
                child: _VehicleTile(
                  vehicle: vehicles[index],
                  onDelete: () => onDeleteVehicle(vehicles[index].id),
                ),
              ),
              if (index != vehicles.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle, required this.onDelete});

  final Vehicle vehicle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadii.medium + 2),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 92,
            height: 92,
            child: AppAssetImage(
              path: vehicle.imageUrl ?? '',
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadii.medium),
              ),
              fallbackIcon: Icons.directions_car_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    vehicle.model,
                    style: AppTextStyles.title.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vehicle.year} · ${vehicle.exteriorColor}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'VIN ${vehicle.vin}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.overline.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove vehicle',
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
