import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v4/core/errors/app_exception.dart';
import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/shared/domain/entities/user.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

import '../controllers/profile_controller.dart';
import '../widgets/profile_edit_widgets.dart';

class ProfileInfoEditPage extends StatefulWidget {
  const ProfileInfoEditPage({
    super.key,
    required this.controller,
    this.onAddVehicle,
  });

  final ProfileController controller;
  final VoidCallback? onAddVehicle;

  @override
  State<ProfileInfoEditPage> createState() => _ProfileInfoEditPageState();
}

class _ProfileInfoEditPageState extends State<ProfileInfoEditPage> {
  ProfileController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.beginEditing();
  }

  Future<void> _save(BuildContext context) async {
    final bool saved = await controller.saveProfile();
    if (saved && context.mounted && context.canPop()) context.pop();
  }

  void _cancel(BuildContext context) {
    controller.discardProfileEdits();
    if (context.canPop()) context.pop();
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
                        onDeleteVehicle: controller.deleteVehicle,
                        onAddVehicle: widget.onAddVehicle,
                      ),
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
