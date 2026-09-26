import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

abstract final class AppColors {
  // Surfaces — layered near-blacks so panels read as depth, not boxes.
  static const Color canvas = Color(0xFF0F0F11);
  static const Color appBar = Color(0xFF050507);
  static const Color panel = Color(0xFF17171A);
  static const Color panelDark = Color(0xFF111114);
  static const Color surfaceRaised = Color(0xFF1C1C20);

  // Brand — Porsche Guards Red.
  static const Color primary = Color(0xFFD5001C);
  static const Color primaryBright = Color(0xFFEE1A30);
  static const Color primaryDeep = Color(0xFF7A0010);
  static const Color primaryGlow = Color(0x59D5001C);

  // Status. Danger is a lighter coral red so errors never read as branding.
  static const Color success = Color(0xFF3DD68C);
  static const Color warning = Color(0xFFF2B33D);
  static const Color danger = Color(0xFFFF5A60);

  // Accents — used sparingly.
  static const Color accentSteel = Color(0xFF4F8CFF);
  static const Color accentGold = Color(0xFFC9A55C);

  // Tinted surfaces for feedback and badges.
  static const Color dangerSurface = Color(0x1FFF5A60);
  static const Color successSurface = Color(0x1F3DD68C);
  static const Color warningSurface = Color(0x1FF2B33D);
  static const Color infoSurface = Color(0x1F4F8CFF);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFE4E4E7);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color textFaint = Color(0xFF7C7C85);
  static const Color inputText = Color(0xFFF5F5F7);

  static const Color border = Color(0xFF26262B);
  static const Color cardBorder = Color(0x1AFFFFFF);
  static const Color inputBorder = Color(0xFF2A2A30);
  static const Color inputFill = Color(0xFF16161A);
  static const Color required = Color(0xFFEE1A30);
  static const Color scrim = Color(0xB3000000);
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 40;
  static const double pageBottom = 48;
}

abstract final class AppRadii {
  static const double small = 8;
  static const double medium = 14;
  static const double large = 20;
  static const double pill = 999;
}

abstract final class AppLayout {
  static const double maxContentWidth = 560;
  static const double navigationBarHeight = 72;

  static double horizontalPadding(double screenWidth) {
    if (screenWidth < 360) return 16;
    if (screenWidth < 600) return 20;
    return 32;
  }
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve curve = Curves.easeOutCubic;
}

abstract final class AppTextStyles {
  // Inter (SIL Open Font License) — royalty-free stand-in for Porsche Next.
  // The font files must be bundled via pubspec.yaml; see REDESIGN_NOTES.md.
  static const String fontFamily = 'Inter';

  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static const TextStyle appBarTitle = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: 1.6,
  );

  static const TextStyle pageTitle = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.6,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textMuted,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.15,
    letterSpacing: 1.3,
  );

  static const TextStyle input = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 0.3,
  );

  // Large hero headline (welcome, featured event).
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -1,
  );

  // Card and row titles.
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
  );

  // Muted small caps used above values ("TIME", "LOCATION").
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textMuted,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  // Prices, IDs, counters.
  static const TextStyle numeric = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.2,
    fontFeatures: tabularFigures,
  );
}

abstract final class AppButtonStyles {
  static ButtonStyle get primary => _filled(
    backgroundColor: AppColors.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.medium),
    ),
  );

  // Outlined, as in "SCAN AT ENTRANCE" / secondary sign-in actions.
  static ButtonStyle get secondary =>
      _filled(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ).copyWith(
        side: const WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: Color(0x40FFFFFF)),
        ),
        overlayColor: const WidgetStatePropertyAll<Color>(Color(0x14FFFFFF)),
      );

  static ButtonStyle compact({required Color backgroundColor}) {
    return _filled(
      backgroundColor: backgroundColor,
      horizontalPadding: 20,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.small + 2),
      ),
    );
  }

  static ButtonStyle pill({
    Color backgroundColor = AppColors.primary,
    double horizontalPadding = 24,
  }) {
    return _filled(
      backgroundColor: backgroundColor,
      horizontalPadding: horizontalPadding,
      shape: const StadiumBorder(),
    );
  }

  // Transparent pill/rounded button with a hairline border.
  static ButtonStyle outline({
    Color foregroundColor = AppColors.textPrimary,
    Color borderColor = const Color(0x40FFFFFF),
    double radius = AppRadii.medium,
    double horizontalPadding = 20,
  }) {
    return _filled(
      backgroundColor: Colors.transparent,
      horizontalPadding: horizontalPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    ).copyWith(
      foregroundColor: WidgetStatePropertyAll<Color>(foregroundColor),
      side: WidgetStatePropertyAll<BorderSide>(BorderSide(color: borderColor)),
      overlayColor: WidgetStatePropertyAll<Color>(
        foregroundColor.withValues(alpha: 0.08),
      ),
    );
  }

  static ButtonStyle _filled({
    required Color backgroundColor,
    required OutlinedBorder shape,
    double horizontalPadding = 28,
  }) {
    return FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: AppColors.textPrimary,
      disabledBackgroundColor: AppColors.border,
      disabledForegroundColor: AppColors.textFaint,
      minimumSize: Size.zero,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevation: 0,
      shadowColor: Colors.transparent,
      textStyle: AppTextStyles.button,
      shape: shape,
    );
  }
}

abstract final class AppDecorations {
  static BoxDecoration panel({double radius = AppRadii.medium}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF1B1B1F), Color(0xFF131316)],
      ),
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  // Member / hero card: dark glass with a faint red rim.
  static BoxDecoration heroPanel({double radius = AppRadii.large}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF1D1D21),
          Color(0xFF141417),
          Color(0xFF1A0B0E),
        ],
        stops: <double>[0, 0.62, 1],
      ),
      border: Border.all(color: const Color(0x47D5001C)),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x33D5001C),
          blurRadius: 28,
          spreadRadius: -12,
          offset: Offset(0, 14),
        ),
      ],
    );
  }

  // Colour-washed card (e.g. red "Order History", steel "My Events").
  static BoxDecoration tintedPanel(
    Color color, {
    double radius = AppRadii.large,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.alphaBlend(color.withValues(alpha: 0.20), AppColors.panelDark),
          Color.alphaBlend(color.withValues(alpha: 0.05), AppColors.panelDark),
        ],
      ),
      border: Border.all(color: color.withValues(alpha: 0.28)),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  // Small rounded square/circle behind an icon.
  static BoxDecoration iconBadge(
    Color color, {
    double radius = AppRadii.small + 2,
    bool circle = false,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.14),
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(radius),
    );
  }
}

abstract final class AppTheme {
  static ThemeData get dark {
    final OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.medium),
      borderSide: const BorderSide(color: AppColors.inputBorder),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      splashFactory: InkRipple.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryBright,
        onSecondary: Colors.white,
        surface: AppColors.canvas,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.panel,
        error: AppColors.danger,
        onError: Colors.white,
        outline: AppColors.border,
        outlineVariant: AppColors.cardBorder,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(
            backgroundColor: AppColors.canvas,
          ),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        titleTextStyle: AppTextStyles.appBarTitle,
        shape: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppColors.panelDark,
        surfaceTintColor: Colors.transparent,
        barrierColor: AppColors.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large + 4),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.panelDark,
        modalBackgroundColor: AppColors.panelDark,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: Color(0x40FFFFFF),
        dragHandleSize: Size(40, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.panelDark,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.appBar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large + 4),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
        ),
        actionTextColor: AppColors.primaryBright,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBright,
        linearTrackColor: AppColors.border,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryBright,
        selectionColor: Color(0x59D5001C),
        selectionHandleColor: AppColors.primaryBright,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
        side: const BorderSide(color: AppColors.textFaint, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppColors.primaryBright
              : AppColors.textFaint,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll<Color>(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBright,
          textStyle: AppTextStyles.label.copyWith(letterSpacing: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: Color(0x40FFFFFF)),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.small),
          border: Border.all(color: AppColors.cardBorder),
        ),
        textStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        hintStyle: AppTextStyles.input.copyWith(color: AppColors.textFaint),
        labelStyle: AppTextStyles.body,
        floatingLabelStyle: AppTextStyles.body.copyWith(
          color: AppColors.primaryBright,
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 15,
        ),
        constraints: const BoxConstraints(minHeight: 52),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(
            color: AppColors.primaryBright,
            width: 1.4,
          ),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: Color(0x99FF5A60)),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        errorStyle: AppTextStyles.caption.copyWith(
          color: AppColors.danger,
          fontSize: 12.5,
          height: 1.3,
        ),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(style: AppButtonStyles.primary),
    );
  }
}
