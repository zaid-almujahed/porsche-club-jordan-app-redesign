import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.title,
    required this.child,
    required this.onEdit,
  });

  final String title;
  final Widget child;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GradientPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppRadii.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 19),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primaryBright,
                  size: 16,
                ),
                label: AppButtonLabel(
                  'EDIT',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primaryBright,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class PersonalInformation extends StatelessWidget {
  const PersonalInformation({
    super.key,
    required this.imagePath,
    required this.fullName,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.city,
  });

  final String? imagePath;
  final String fullName;
  final String dateOfBirth;
  final String phoneNumber;
  final String city;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
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
              ),
              child: _ReviewImage(
                imagePath: imagePath,
                width: 84,
                height: 84,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                fallbackIcon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                fullName,
                style: AppTextStyles.title.copyWith(fontSize: 19),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewDetail(label: 'FULL NAME', value: fullName),
        _ReviewDetail(label: 'DATE OF BIRTH', value: dateOfBirth),
        _ReviewDetail(label: 'PHONE NUMBER', value: phoneNumber),
        _ReviewDetail(label: 'CITY', value: city, isLast: true),
      ],
    );
  }
}

class VehicleInformation extends StatelessWidget {
  const VehicleInformation({
    super.key,
    required this.imagePath,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.vin,
  });

  final String? imagePath;
  final String model;
  final String year;
  final String licensePlate;
  final String vin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 342 / 220,
          child: _ReviewImage(
            imagePath: imagePath,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            fallbackIcon: Icons.directions_car_outlined,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReviewDetail(label: 'MODEL', value: model),
        _ReviewDetail(label: 'YEAR', value: year),
        _ReviewDetail(
          label: 'LICENSE PLATE',
          value: licensePlate,
          compact: true,
        ),
        _ReviewDetail(label: 'VIN', value: vin, monospace: true, isLast: true),
      ],
    );
  }
}

class _ReviewImage extends StatelessWidget {
  const _ReviewImage({
    required this.imagePath,
    required this.borderRadius,
    required this.fallbackIcon,
    this.width,
    this.height,
  });

  final String? imagePath;
  final BorderRadius borderRadius;
  final IconData fallbackIcon;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: imagePath == null
            ? ColoredBox(
                color: AppColors.canvas,
                child: Icon(fallbackIcon, color: AppColors.textMuted),
              )
            : Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: AppColors.canvas,
                  child: Icon(fallbackIcon, color: AppColors.textMuted),
                ),
              ),
      ),
    );
  }
}

class _ReviewDetail extends StatelessWidget {
  const _ReviewDetail({
    required this.label,
    required this.value,
    this.compact = false,
    this.monospace = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool compact;
  final bool monospace;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Widget valueWidget = Text(
      value,
      textAlign: TextAlign.right,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: compact ? 13 : 15.5,
        fontWeight: compact ? FontWeight.w700 : FontWeight.w600,
        // Tabular figures keep VINs and plates aligned without a mono font.
        fontFamily: AppTextStyles.fontFamily,
        fontFeatures: monospace ? AppTextStyles.tabularFigures : null,
        letterSpacing: monospace || compact ? 0.8 : 0,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: <Widget>[
          Text(label, style: AppTextStyles.overline),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: compact
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(AppRadii.small),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: valueWidget,
                      ),
                    )
                  : valueWidget,
            ),
          ),
        ],
      ),
    );
  }
}

class AgreementPanel extends StatelessWidget {
  const AgreementPanel({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.medium,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: value
            ? Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.07),
                AppColors.panelDark,
              )
            : AppColors.panelDark,
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.55)
              : AppColors.cardBorder,
        ),
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        const TextSpan(
                          text:
                              'By checking this box, I confirm that all provided '
                              'information is accurate and I agree to abide by the ',
                        ),
                        TextSpan(
                          text: 'Rules and Regulations',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryBright,
                          ),
                        ),
                        const TextSpan(text: ' of Porsche Club Jordan.'),
                      ],
                    ),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Transform.scale(
                  scale: 1.15,
                  child: Checkbox(
                    value: value,
                    onChanged: (bool? nextValue) {
                      onChanged(nextValue ?? false);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
