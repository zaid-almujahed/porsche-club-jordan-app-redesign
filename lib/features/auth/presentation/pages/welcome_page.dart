//The main page the user lands on when opening the app

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pcj_v4/core/routing/app_router.dart';

import 'package:pcj_v4/core/theme/app_theme.dart';
import 'package:pcj_v4/shared/widgets/app_widgets.dart';

import '../widgets/auth_backdrop.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const String _welcome = 'Welcome';
  static const String _subtitle =
      'Exclusive access to excellence. Connect with the ultimate '
      'performance community.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBar,
      body: AuthBackdrop(
        imagePath: 'assets/images/bgimage.jpg',
        glowCenter: const Alignment(0, -0.35),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double horizontalPadding = AppLayout.horizontalPadding(
                constraints.maxWidth,
              );

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.xxl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (AppSpacing.xxl * 2),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppLayout.maxContentWidth,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const AppFadeSlideIn(
                            duration: Duration(milliseconds: 600),
                            offset: 16,
                            child: AppScaleIn(
                              begin: 0.96,
                              duration: Duration(milliseconds: 700),
                              child: AuthLogo(maxHeight: 170),
                            ),
                          ),
                          const SizedBox(height: 56),
                          AppFadeSlideIn(
                            delay: const Duration(milliseconds: 180),
                            child: Column(
                              children: <Widget>[
                                const AppAccentBar(width: 36),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  _welcome,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.display.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  _subtitle,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 56),

                          //ACTION BUTTONS
                          AppFadeSlideIn(
                            delay: const Duration(milliseconds: 320),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                PrimaryActionButton(
                                  label: 'Join the Club',
                                  icon: Icons.arrow_forward_rounded,
                                  onPressed: () =>
                                      context.push(AppRoutes.registerPersonal),
                                  height: 58,
                                ),
                                const SizedBox(height: 12),
                                SecondaryActionButton(
                                  label: 'Sign In',
                                  onPressed: () =>
                                      context.push(AppRoutes.signIn),
                                  height: 58,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const AppFadeSlideIn(
                            delay: Duration(milliseconds: 450),
                            child: Text(
                              'PORSCHE CLUB JORDAN',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.overline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
