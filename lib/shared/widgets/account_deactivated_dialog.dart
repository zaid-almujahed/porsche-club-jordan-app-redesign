import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_dialog.dart';
import 'package:pcj_v5/shared/widgets/support_contact_sheet.dart';

/// Shown when a SUSPENDED or DEACTIVATED member is turned away. The member
/// has already been signed out; the caller routes to Welcome afterwards.
Future<void> showAccountDeactivatedDialog({
  required BuildContext context,
  required String email,
}) async {
  final bool? contactSupport = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => PopScope<Object?>(
      canPop: false,
      child: AppDialog(
        icon: Icons.person_off_outlined,
        iconColor: AppColors.danger,
        title: 'Account Deactivated',
        message:
            'Your Porsche Club Jordan account has been deactivated. If you '
            'believe this is a mistake, please contact our support team.',
        primaryLabel: 'OK',
        secondaryLabel: 'Contact Support',
        onPrimaryPressed: () => Navigator.of(dialogContext).pop(false),
        onSecondaryPressed: () => Navigator.of(dialogContext).pop(true),
      ),
    ),
  );
  if (contactSupport != true || !context.mounted) return;
  await showSupportContactSheet(
    context: context,
    senderEmail: email,
    initialTopic: 'Account access',
  );
}
