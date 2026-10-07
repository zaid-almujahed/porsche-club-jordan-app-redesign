import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';

/// An admin turned down the payment for [eventTitle]: says so, with a way
/// to reach support.
Future<void> showPaymentRejectedDialog({
  required BuildContext context,
  required String eventTitle,
  required VoidCallback onContactSupport,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (BuildContext dialogContext) => AppDialog(
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.danger,
      title: 'Payment Rejected',
      message:
          'Your payment for $eventTitle could not be confirmed, so this '
          'registration is not active. Please contact the club to sort it '
          'out.',
      primaryLabel: 'Contact Support',
      onPrimaryPressed: () {
        Navigator.of(dialogContext).pop();
        onContactSupport();
      },
      secondaryLabel: 'Close',
      onSecondaryPressed: () => Navigator.of(dialogContext).pop(),
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}
