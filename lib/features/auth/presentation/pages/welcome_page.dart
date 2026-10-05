//The main page the user lands on when opening the app

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pcj_v5/core/routing/app_router.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';
import 'package:pcj_v5/shared/widgets/support_contact_sheet.dart';

import '../widgets/auth_backdrop.dart';
import '../widgets/help_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const String _welcome = 'Welcome to\nthe Club.';
  static const String _subtitle =
      'Events, offers and the member shop,\nall in one place.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBar,
      body: LightTrailsBackdrop(
        glowCenter: const Alignment(0, -0.32),
        trails: const <LightTrail>[
          LightTrail(startY: 0.56, endY: 0.40, width: 1.6, opacity: 0.9),
          LightTrail(startY: 0.60, endY: 0.45, width: 0.9, opacity: 0.55),
          LightTrail(startY: 0.53, endY: 0.36, width: 0.6, opacity: 0.35),
        ],
        child: SafeArea(
          child: LayoutBuilder(
            // The logo in the middle; the welcome and the buttons along the
            // bottom. Scrolls only on very short screens.
            builder: (BuildContext context, BoxConstraints constraints) {
              final double horizontalPadding = AppLayout.horizontalPadding(
                constraints.maxWidth,
              );

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        AppSpacing.md,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppLayout.maxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: AuthHelpButton(
                                    onPressed: () => showSupportContactSheet(
                                      context: context,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const AppFadeSlideIn(
                                duration: Duration(milliseconds: 600),
                                offset: 16,
                                child: AppScaleIn(
                                  begin: 0.96,
                                  duration: Duration(milliseconds: 700),
                                  child: Center(child: AuthLogo(maxHeight: 96)),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: AppSpacing.xl),
                              AppFadeSlideIn(
                                delay: const Duration(milliseconds: 180),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const AppAccentBar(width: 36),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      _welcome,
                                      style: AppTextStyles.display.copyWith(
                                        color: Colors.white,
                                        fontSize: 40,
                                        height: 1.05,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      _subtitle,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              //ACTION BUTTONS
                              AppFadeSlideIn(
                                delay: const Duration(milliseconds: 320),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    PrimaryActionButton(
                                      label: 'Join the Club',
                                      onPressed: () => context.push(
                                        AppRoutes.registerPersonal,
                                      ),
                                      height: 56,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    SizedBox(
                                      height: 54,
                                      child: FilledButton(
                                        onPressed: () =>
                                            context.push(AppRoutes.signIn),
                                        style: AppButtonStyles.outline(
                                          foregroundColor:
                                              AppColors.textPrimary,
                                          borderColor: const Color(0x33FFFFFF),
                                        ),
                                        child: const AppButtonLabel('Sign In'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
