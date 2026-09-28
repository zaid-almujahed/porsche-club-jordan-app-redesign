import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v5/core/routing/app_router.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import '../widgets/form_widgets.dart';

import '../controllers/registration_controller.dart';
import '../widgets/review_page_widgets.dart';
import '../widgets/registration_cancel_dialog.dart';

class RegistrationReviewPage extends StatelessWidget {
  const RegistrationReviewPage({
    super.key,
    required this.controller,
    required this.onCancel,
    required this.onEdited,
  });

  final RegistrationController controller;
  final Future<void> Function() onCancel;
  final VoidCallback onEdited;

  Future<void> _continue(BuildContext context) async {
    if (!controller.validateReview()) return;
    if (!controller.isEditingSubmittedApplication) {
      context.push(AppRoutes.registerPassword);
      return;
    }

    final bool wasUpdated = await controller.updateSubmittedApplication();
    if (!wasUpdated || !context.mounted) return;
    await showAppMessageDialog(
      context: context,
      title: 'Application Updated',
      message: 'Your membership application changes were saved successfully.',
      buttonLabel: 'Return to Status',
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.success,
    );
    if (context.mounted) onEdited();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const ProgressHeader(
                  pageNo: '03',
                  title: 'Review',
                  desc:
                      'Please verify your details before submitting your membership '
                      'application to Porsche Club Jordan.',
                ),
                const SizedBox(height: AppSpacing.xl),
                ReviewCard(
                  title: 'Personal Information',
                  onEdit: () => context.go(AppRoutes.registerPersonal),
                  child: PersonalInformation(
                    imagePath: controller.profilePhoto?.path,
                    fullName: controller.fullNameController.text.trim(),
                    dateOfBirth: controller.dateOfBirthController.text.trim(),
                    phoneNumber: controller.normalizedPhoneNumber,
                    city: controller.cityController.text.trim(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ReviewCard(
                  title: 'Vehicle Information',
                  onEdit: () => context.go(AppRoutes.registerVehicle),
                  child: VehicleInformation(
                    imagePath: controller.licensePhoto?.path,
                    model: controller.vehicleModelController.text.trim(),
                    year: controller.vehicleYearController.text.trim(),
                    licensePlate: controller.licensePlateController.text.trim(),
                    vin: controller.vinController.text.trim(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AgreementPanel(
                  value: controller.isAgreementAccepted,
                  onChanged: controller.setAgreementAccepted,
                ),
                AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  alignment: Alignment.topCenter,
                  child: controller.submissionError == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: AppInlineMessage.error(
                            controller.submissionError!,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryActionButton(
                  label: controller.isEditingSubmittedApplication
                      ? 'Save Changes'
                      : 'Next',
                  onPressed: controller.isSubmitting
                      ? null
                      : () => _continue(context),
                  isLoading: controller.isSubmitting,
                  icon: controller.isEditingSubmittedApplication
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  height: 58,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
