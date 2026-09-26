import 'package:flutter/material.dart';
import 'package:pcj_v4/core/theme/app_theme.dart';

abstract final class OrderStyles {
  static const TextStyle orderId = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.2,
    fontFeatures: AppTextStyles.tabularFigures,
  );

  static const TextStyle productName = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: Colors.white,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.1,
  );

  static const TextStyle metaLabel = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textMuted,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.2,
  );

  static const TextStyle metaValue = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFeatures: AppTextStyles.tabularFigures,
  );
}
