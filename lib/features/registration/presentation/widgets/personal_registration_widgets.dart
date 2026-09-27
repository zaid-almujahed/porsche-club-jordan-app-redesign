import 'dart:io';

import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

import 'form_widgets.dart';

class ProfilePhotoCard extends StatelessWidget {
  const ProfilePhotoCard({
    super.key,
    required this.onAddPhotoPressed,
    this.imagePath,
    this.isLoading = false,
    this.errorText,
  });

  final String? imagePath;
  final bool isLoading;
  final String? errorText;
  final VoidCallback? onAddPhotoPressed;

  @override
  Widget build(BuildContext context) {
    return RegistrationFormPanel(
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: isLoading ? null : onAddPhotoPressed,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Container(
                  width: 124,
                  height: 124,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: imagePath == null
                        ? null
                        : const SweepGradient(
                            colors: <Color>[
                              AppColors.primaryBright,
                              AppColors.primaryDeep,
                              AppColors.primaryBright,
                            ],
                          ),
                    border: imagePath == null
                        ? Border.all(color: const Color(0x33FFFFFF))
                        : null,
                    boxShadow: imagePath == null
                        ? null
                        : const <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 20,
                            ),
                          ],
                  ),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: AppColors.canvas,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: AppMotion.medium,
                      child: imagePath == null
                          ? const Icon(
                              Icons.person_outline_rounded,
                              key: ValueKey<String>('no-photo'),
                              size: 52,
                              color: AppColors.textMuted,
                            )
                          : Image.file(
                              File(imagePath!),
                              key: ValueKey<String>(imagePath!),
                              fit: BoxFit.cover,
                              width: 118,
                              height: 118,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                size: 44,
                                color: AppColors.textMuted,
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.panelDark, width: 3),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Profile Photo',
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 19),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'This photo will be used for your digital membership card. '
            'A clear, front-facing portrait is required.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              'JPG or PNG • Max 5MB • 500×500px min',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontSize: 11.5),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onAddPhotoPressed,
              style: AppButtonStyles.compact(
                backgroundColor: AppColors.primary,
              ),
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_a_photo_outlined, size: 18),
              label: Text(
                imagePath == null ? 'Add Photo' : 'Change Photo',
                style: AppTextStyles.button,
              ),
            ),
          ),
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: errorText == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: AppInlineMessage.error(errorText!),
                  ),
          ),
        ],
      ),
    );
  }
}

class PersonalDetailsForm extends StatelessWidget {
  const PersonalDetailsForm({
    super.key,
    required this.fullNameController,
    required this.phoneController,
    required this.cityController,
    required this.dateOfBirthController,
    required this.onDateOfBirthPressed,
  });

  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController cityController;
  final TextEditingController dateOfBirthController;
  final VoidCallback onDateOfBirthPressed;

  @override
  Widget build(BuildContext context) {
    return RegistrationFormPanel(
      child: Column(
        children: <Widget>[
          RegistrationTextField(
            controller: fullNameController,
            label: 'FULL NAME',
            hintText: 'e.g. Ferdinand Porsche',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: <String>[AutofillHints.name],
          ),
          const SizedBox(height: AppSpacing.lg),
          RegistrationTextField(
            controller: phoneController,
            label: 'PHONE NUMBER',
            hintText: 'Phone number',
            prefixText: '+962  ',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: <String>[AutofillHints.telephoneNumber],
          ),
          const SizedBox(height: AppSpacing.lg),
          RegistrationTextField(
            controller: cityController,
            label: 'CITY',
            hintText: 'e.g. Amman',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: <String>[AutofillHints.addressCity],
          ),
          const SizedBox(height: AppSpacing.lg),
          RegistrationTextField(
            controller: dateOfBirthController,
            label: 'DATE OF BIRTH',
            hintText: 'e.g. 01/01/1980',
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.next,
            suffixIcon: Icons.calendar_month_outlined,
            readOnly: true,
            onTap: onDateOfBirthPressed,
          ),
        ],
      ),
    );
  }
}
