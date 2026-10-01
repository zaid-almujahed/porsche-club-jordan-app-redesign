import 'package:flutter/material.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

class ApplicationStatusPanel extends StatelessWidget {
  const ApplicationStatusPanel({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.paragraphs,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    return GradientPanel(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 30),
      radius: AppRadii.large,
      child: Column(
        children: <Widget>[
          // Status medallion scales in with a soft coloured halo.
          AppScaleIn(
            begin: 0.6,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    iconColor.withValues(alpha: 0.22),
                    iconColor.withValues(alpha: 0.03),
                  ],
                ),
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.45),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.appBar, size: 32),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.appBarTitle.copyWith(
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppAccentBar(),
          const SizedBox(height: AppSpacing.lg),
          for (int index = 0; index < paragraphs.length; index++) ...<Widget>[
            AppFadeSlideIn.stagger(
              index: index,
              initialDelay: const Duration(milliseconds: 150),
              child: Text(
                paragraphs[index],
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15.5,
                  height: 1.5,
                ),
              ),
            ),
            if (index != paragraphs.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

/// "Application Approved", with the two steps left: entering the code just
/// emailed to [email] (signing in), then paying. True when the applicant
/// goes on to enter the code.
Future<bool> showApplicationApprovedDialog({
  required BuildContext context,
  required String email,
}) async {
  final bool? proceed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (BuildContext context) => AppDialog(
      icon: Icons.verified_rounded,
      iconColor: AppColors.success,
      title: 'Application Approved',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Welcome to Porsche Club Jordan! Two steps are left to activate '
            'your membership.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 15.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ApprovedStep(
            number: 1,
            text: 'Sign in with the code we just emailed to $email.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ApprovedStep(
            number: 2,
            text: 'Pay the yearly membership to activate it.',
          ),
        ],
      ),
      primaryLabel: 'Enter Code',
      onPrimaryPressed: () => Navigator.of(context).pop(true),
      secondaryLabel: 'Later',
      onSecondaryPressed: () => Navigator.of(context).pop(false),
    ),
  );
  return proceed ?? false;
}

class _ApprovedStep extends StatelessWidget {
  const _ApprovedStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.14),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '$number',
              style: AppTextStyles.label.copyWith(
                color: AppColors.success,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
