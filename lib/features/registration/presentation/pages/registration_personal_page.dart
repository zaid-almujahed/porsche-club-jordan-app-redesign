import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../controllers/registration_controller.dart';
import '../widgets/form_widgets.dart';
import '../widgets/personal_registration_widgets.dart';
import '../widgets/registration_cancel_dialog.dart';

class RegistrationPersonalPage extends StatelessWidget {
  const RegistrationPersonalPage({
    super.key,
    required this.controller,
    required this.onCancel,
  });

  final RegistrationController controller;
  final Future<void> Function() onCancel;

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: controller.dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      controller.setDateOfBirth(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: PorscheAppBar(
        title: 'Membership Application',
        showClose: true,
        onClose: () => confirmRegistrationCancellation(
          context: context,
          onCancel: onCancel,
        ),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return AppPageBody(
            topPadding: AppSpacing.lg,
            bottomPadding: AppSpacing.section,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const ProgressHeader(
                  title: 'Personal Information',
                  pageNo: '01',
                  desc:
                      'Please provide your information exactly as it appears '
                      'on official identification documents to ensure accurate '
                      'processing of your club membership.',
                ),
                const SizedBox(height: AppSpacing.xl),
                ProfilePhotoCard(
                  imagePath: controller.profilePhoto?.path,
                  isLoading: controller.isPickingProfilePhoto,
                  errorText: controller.profilePhotoError,
                  onAddPhotoPressed: controller.pickProfilePhoto,
                ),
                const SizedBox(height: AppSpacing.md),
                PersonalDetailsForm(
                  fullNameController: controller.fullNameController,
                  phoneController: controller.phoneController,
                  cityController: controller.cityController,
                  dateOfBirthController: controller.dateOfBirthController,
                  onDateOfBirthPressed: () => _selectDateOfBirth(context),
                ),
                AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  alignment: Alignment.topCenter,
                  child: controller.personalFormError == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: AppInlineMessage.error(
                            controller.personalFormError!,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                RegistrationActions(
                  onNext: () {
                    if (controller.validatePersonalInformation()) {
                      context.push(AppRoutes.registerVehicle);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
