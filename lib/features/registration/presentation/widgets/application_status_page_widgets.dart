import 'package:flutter/material.dart';
import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

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
