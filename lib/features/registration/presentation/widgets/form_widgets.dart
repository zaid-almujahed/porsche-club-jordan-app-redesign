import 'package:flutter/material.dart';

import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

class ProgressHeader extends StatelessWidget {
  const ProgressHeader({
    super.key,
    required this.pageNo,
    required this.title,
    required this.desc,
  });

  final String pageNo;
  final String title;
  final String desc;

  static const int _totalSteps = 4;

  @override
  Widget build(BuildContext context) {
    final int step = (int.tryParse(pageNo) ?? 1).clamp(1, _totalSteps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  const TextSpan(text: 'STEP  '),
                  TextSpan(
                    text: pageNo,
                    style: const TextStyle(color: AppColors.primaryBright),
                  ),
                  const TextSpan(
                    text: '  /  04',
                    style: TextStyle(color: AppColors.textFaint),
                  ),
                ],
              ),
              style: AppTextStyles.overline,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Segmented progress; the current step fills in on arrival.
        Row(
          children: <Widget>[
            for (int index = 1; index <= _totalSteps; index++) ...<Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: Stack(
                    children: <Widget>[
                      Container(height: 4, color: AppColors.border),
                      if (index <= step)
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: index == step ? 0 : 1,
                            end: 1,
                          ),
                          duration: const Duration(milliseconds: 650),
                          curve: AppMotion.curve,
                          builder:
                              (BuildContext context, double value, Widget? _) {
                                return FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: <Color>[
                                          AppColors.primary,
                                          AppColors.primaryBright,
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                        ),
                    ],
                  ),
                ),
              ),
              if (index != _totalSteps) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppFadeSlideIn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  style: AppTextStyles.pageTitle.copyWith(fontSize: 27),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(desc, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}

class RegistrationFormPanel extends StatelessWidget {
  const RegistrationFormPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = MediaQuery.sizeOf(context).width < 360;

    return GradientPanel(
      padding: padding ?? EdgeInsets.all(isCompact ? 16 : 20),
      radius: AppRadii.large,
      child: child,
    );
  }
}

class RegistrationRequiredLabel extends StatelessWidget {
  const RegistrationRequiredLabel({
    super.key,
    required this.label,
    this.required = true,
    this.fontSize = 12,
  });

  final String label;
  final bool required;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: '  *',
              style: TextStyle(
                color: AppColors.required,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
      style: AppTextStyles.overline.copyWith(fontSize: fontSize - 0.5),
    );
  }
}

class RegistrationTextField extends StatelessWidget {
  const RegistrationTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.prefixText,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.validator,
    this.obscureText = false,
  });

  final String label;
  final String hintText;
  final TextEditingController? controller;
  final String? prefixText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final IconData? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RegistrationRequiredLabel(label: label),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          obscureText: obscureText,
          style: AppTextStyles.input,
          cursorColor: AppColors.primaryBright,
          decoration: InputDecoration(
            hintText: hintText,
            prefixText: prefixText,
            prefixStyle: AppTextStyles.input.copyWith(
              color: AppColors.textMuted,
            ),
            suffixIcon: suffixIcon == null
                ? null
                : Icon(suffixIcon, color: AppColors.textMuted, size: 21),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 36,
            ),
          ),
        ),
      ],
    );
  }
}

class RegistrationSectionIntroduction extends StatelessWidget {
  const RegistrationSectionIntroduction({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: AppTextStyles.sectionTitle.copyWith(fontSize: 19)),
        const SizedBox(height: AppSpacing.xxs),
        Text(subtitle, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        const AppAccentBar(width: 22),
      ],
    );
  }
}

class RegistrationActions extends StatelessWidget {
  const RegistrationActions({
    super.key,
    required this.onNext,
    this.onBack,
    this.nextLabel = 'Next',
  });

  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(color: AppColors.cardBorder),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            if (onBack != null) ...<Widget>[
              SizedBox(
                width: 112,
                height: 54,
                child: FilledButton.icon(
                  onPressed: onBack,
                  style: AppButtonStyles.outline(horizontalPadding: 14),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back', style: AppTextStyles.button),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: onNext,
                  style: AppButtonStyles.compact(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          nextLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.button,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
