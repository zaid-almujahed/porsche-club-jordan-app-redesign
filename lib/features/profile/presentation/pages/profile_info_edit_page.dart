import 'package:flutter/material.dart';

import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/routing/app_back_navigation.dart';
import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/domain/entities/user.dart';
import 'package:pcj_v5/shared/domain/entities/vehicle.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/profile_controller.dart';
import '../widgets/profile_edit_widgets.dart';
import '../widgets/vehicle_form_sheet.dart';

class ProfileInfoEditPage extends StatefulWidget {
  const ProfileInfoEditPage({super.key, required this.controller});

  final ProfileController controller;

  @override
  State<ProfileInfoEditPage> createState() => _ProfileInfoEditPageState();
}

class _ProfileInfoEditPageState extends State<ProfileInfoEditPage> {
  ProfileController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // After the first frame: beginEditing() notifies, and the Profile tab
    // listening underneath must not be marked dirty mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.beginEditing();
    });
  }

  Future<void> _save(BuildContext context) async {
    final bool saved = await controller.saveProfile();
    if (saved && context.mounted) {
      context.goBack(fallback: AppRoutes.profile);
    }
  }

  void _cancel(BuildContext context) {
    controller.discardProfileEdits();
    context.goBack(fallback: AppRoutes.profile);
  }

  Future<void> _pickDateOfBirth(BuildContext context, User user) async {
    final DateTime now = DateTime.now();
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: user.dateOfBirth ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected != null) controller.setDateOfBirth(selected);
  }

  /// Adds a car, or edits [vehicle].
  Future<void> _openVehicleForm(
    BuildContext context, [
    Vehicle? vehicle,
  ]) async {
    final bool saved = await showVehicleFormSheet(
      context: context,
      profile: controller,
      vehicle: vehicle,
    );
    if (saved && context.mounted) {
      showAppSuccessPulse(
        context,
        label: vehicle == null ? 'Vehicle Added' : 'Vehicle Updated',
      );
    }
  }

  Future<void> _removeVehicle(BuildContext context, Vehicle vehicle) async {
    final String name = vehicle.licensePlate.trim().isEmpty
        ? vehicle.model
        : '${vehicle.model} (${vehicle.licensePlate})';
    final bool confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Remove Vehicle?',
      message: 'Remove $name from your garage?',
      confirmLabel: 'Remove',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final bool removed = await controller.deleteVehicle(vehicle.id);
    if (removed && context.mounted) {
      showAppSuccessPulse(context, label: 'Vehicle Removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) controller.discardProfileEdits();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: PorscheAppBar(
          title: 'Edit Profile',
          showBack: true,
          onBack: () => _cancel(context),
        ),
        body: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) {
            return AppPageBody(
              topPadding: AppSpacing.xl,
              child: AsyncStateView<User>(
                state: controller.profile,
                onRetry: () => controller.load(force: true),
                builder: (BuildContext context, User user) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Edit Profile',
                        style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Update your personal details and manage your garage.',
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const AppAccentBar(),
                      const SizedBox(height: AppSpacing.xl),
                      PersonalDetailsPanel(
                        nameController: controller.nameController,
                        emailController: controller.emailController,
                        phoneController: controller.phoneController,
                        cityController: controller.cityController,
                        dateOfBirthController: controller.dateOfBirthController,
                        avatarUrl:
                            controller.avatarPreviewPath ?? user.avatarUrl,
                        isUploading: controller.isUploadingAvatar,
                        onChangePhoto: controller.changeAvatar,
                        onDateOfBirthPressed: () =>
                            _pickDateOfBirth(context, user),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      VehiclesPanel(
                        vehicles: controller.vehicles,
                        onDeleteVehicle: (Vehicle vehicle) =>
                            _removeVehicle(context, vehicle),
                        onEditVehicle: (Vehicle vehicle) =>
                            _openVehicleForm(context, vehicle),
                        onAddVehicle: () => _openVehicleForm(context),
                      ),
                      if (controller.vehicleError != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        AppInlineMessage.error(
                          readableError(controller.vehicleError!),
                        ),
                      ],
                      if (controller.actionError != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        AppInlineMessage.error(
                          readableError(controller.actionError!),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      PrimaryActionButton(
                        label: controller.isSaving
                            ? 'Saving...'
                            : 'Save Changes',
                        icon: Icons.check_rounded,
                        isLoading: controller.isSaving,
                        height: 58,
                        onPressed: controller.isSaving
                            ? null
                            : () => _save(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SecondaryActionButton(
                        label: 'Cancel',
                        height: 58,
                        onPressed: () => _cancel(context),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
