import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pcj_v4/core/routing/app_router.dart';
import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

import '../controllers/registration_controller.dart';
import '../widgets/form_widgets.dart';
import '../widgets/vehicle_registration_widgets.dart';
import '../widgets/registration_cancel_dialog.dart';

class RegistrationVehiclePage extends StatelessWidget {
  const RegistrationVehiclePage({
    super.key,
    required this.controller,
    required this.onCancel,
    this.vehicleImagePath = 'assets/images/registration_vehicle_car.png',
  });

  final RegistrationController controller;
  final Future<void> Function() onCancel;
  final String vehicleImagePath;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const ProgressHeader(
                  title: 'Vehicle Information',
                  pageNo: '02',
                  desc:
                      'Register your primary Porsche vehicle. This '
                      'information validates your membership eligibility.',
                ),
                const SizedBox(height: AppSpacing.xl),
                LicensePhotoCard(
                  placeholderImagePath: vehicleImagePath,
                  selectedImagePath: controller.licensePhoto?.path,
                  isLoading: controller.isPickingLicensePhoto,
                  errorText: controller.licensePhotoError,
                  onAddPhotoPressed: controller.pickLicensePhoto,
                ),
                const SizedBox(height: AppSpacing.section),
                const RegistrationSectionIntroduction(
                  title: 'Vehicle Details',
                  subtitle: 'Basic information about your vehicle.',
                ),
                const SizedBox(height: AppSpacing.md),
                VehicleDetailsForm(
                  yearController: controller.vehicleYearController,
                  modelController: controller.vehicleModelController,
                ),
                const SizedBox(height: AppSpacing.section),
                const RegistrationSectionIntroduction(
                  title: 'Vehicle Identification',
                  subtitle: 'Enter your VIN and plate number for verification.',
                ),
                const SizedBox(height: AppSpacing.md),
                VehicleIdentificationForm(
                  vinController: controller.vinController,
                  licensePlateController: controller.licensePlateController,
                ),
                AnimatedSize(
                  duration: AppMotion.medium,
                  curve: AppMotion.curve,
                  alignment: Alignment.topCenter,
                  child: controller.vehicleFormError == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: AppInlineMessage.error(
                            controller.vehicleFormError!,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.section),
                RegistrationActions(
                  onBack: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.registerPersonal);
                    }
                  },
                  onNext: () {
                    if (controller.validateVehicleInformation()) {
                      context.push(AppRoutes.registerReview);
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
