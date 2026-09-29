import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.color = AppColors.primaryBright,
  });

  final IconData icon;
  final String title;
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

  /// Shown as an "Add Vehicle" button under the cars.
  final VoidCallback? onAddVehicle;
  final ValueChanged<Vehicle>? onEditVehicle;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<Vehicle>? edit = onEditVehicle;
    final VoidCallback? add = onAddVehicle;
    return GradientPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppRadii.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PanelHeading(
            icon: Icons.garage_outlined,
            title: vehicles.length > 1 ? 'My Vehicles' : 'My Vehicle',
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
                  onEdit: edit == null ? null : () => edit(vehicles[index]),
                ),
              ),
              if (index != vehicles.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
          if (add != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: add,
                style: AppButtonStyles.outline(radius: AppRadii.medium),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const AppButtonLabel('Add Vehicle'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One vehicle: a header with the model, year and plate, then the VIN and
/// the Edit / Remove buttons. The only photo is of the licence plate, so the
/// header never shows a picture.
class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.onDelete,
    this.onEdit,
  });

  final Vehicle vehicle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? edit = onEdit;
    final String plate = vehicle.licensePlate.trim();
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
            aspectRatio: 21 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.6, -0.4),
                      radius: 1.1,
                      colors: <Color>[Color(0xFF2A1015), Color(0xFF0E0E10)],
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment(0.85, 0),
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    size: 88,
                    color: Color(0x1FFFFFFF),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Color(0x00000000), Color(0xE60A0A0C)],
                      stops: <double>[0.3, 1],
                    ),
                  ),
                ),
                if (plate.isNotEmpty)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: _PlateBadge(plate: plate),
                  ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.sm,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            vehicle.model,
                            maxLines: 1,
                            style: AppTextStyles.pageTitle.copyWith(
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      if (vehicle.year > 0) ...<Widget>[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${vehicle.year}',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.primaryBright,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          _VinRow(vin: vehicle.vin.trim()),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                if (edit != null) ...<Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: FilledButton.icon(
                        onPressed: edit,
                        style: AppButtonStyles.outline(radius: AppRadii.medium),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const AppButtonLabel('Edit'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: FilledButton.icon(
                      onPressed: onDelete,
                      style: AppButtonStyles.outline(
                        radius: AppRadii.medium,
                        foregroundColor: AppColors.danger,
                        borderColor: const Color(0x55FF5A60),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const AppButtonLabel('Remove'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The plate text drawn as a white Jordanian plate.
class _PlateBadge extends StatelessWidget {
  const _PlateBadge({required this.plate});

  final String plate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 8, 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'JOR',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            plate,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
              letterSpacing: 1.2,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

class _VinRow extends StatelessWidget {
  const _VinRow({required this.vin});

  final String vin;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: vin));
    if (context.mounted) {
      showAppSnackBar(context, 'VIN copied.', type: AppFeedbackType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.qr_code_2_rounded,
            size: 18,
            color: AppColors.accentSteel,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'VIN',
                  style: AppTextStyles.overline.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  vin.isEmpty ? '—' : vin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 14,
                    letterSpacing: 1.2,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          if (vin.isNotEmpty)
            IconButton(
              tooltip: 'Copy VIN',
              onPressed: () => _copy(context),
              icon: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            )
          else
            const SizedBox(height: 48),
        ],
      ),
    );
  }
}
