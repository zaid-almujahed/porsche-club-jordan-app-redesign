import 'package:country_picker/country_picker.dart';
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

  void _selectPhoneCountry(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      useRootNavigator: true,
      useSafeArea: true,
      moveAlongWithKeyboard: true,
      favorite: const <String>[RegistrationController.defaultPhoneCountryCode],
      onSelect: controller.selectPhoneCountry,
      countryListTheme: CountryListThemeData(
        backgroundColor: AppColors.panelDark,
        bottomSheetHeight: MediaQuery.sizeOf(context).height * 0.8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        textStyle: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        searchTextStyle: AppTextStyles.input,
        inputDecoration: const InputDecoration(
          hintText: 'Search country or code',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      extendBodyBehindAppBar: true,
      appBar: PorscheAppBar(
        title: 'Membership Application',
        showClose: true,
        onClose: () => confirmRegistrationCancellation(
          context: context,
          onCancel: onCancel,
          isEditing: controller.isEditingSubmittedApplication,
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
                  onAddPhotoPressed: () async {
                    final PhotoSource? source = await showPhotoSourceSheet(
                      context,
                    );
                    if (source != null) {
                      await controller.pickProfilePhoto(source);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                PersonalDetailsForm(
                  fullNameController: controller.fullNameController,
                  phoneController: controller.phoneController,
                  phoneCountry: controller.phoneCountry,
                  onPhoneCountryPressed: () => _selectPhoneCountry(context),
                  cityController: controller.cityController,
                  dateOfBirthController: controller.dateOfBirthController,
                  onDateOfBirthPressed: () => _selectDateOfBirth(context),
                ),
                const SizedBox(height: AppSpacing.xl),
                RegistrationActions(
                  onNext: () {
                    if (controller.validatePersonalInformation()) {
                      context.push(AppRoutes.registerVehicle);
                    } else if (controller.personalFormError != null) {
                      showAppErrorPulse(context, controller.personalFormError!);
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
