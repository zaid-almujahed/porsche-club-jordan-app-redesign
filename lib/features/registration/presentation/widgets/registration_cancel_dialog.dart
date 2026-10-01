import 'package:flutter/material.dart';

import 'package:pcj_v5/shared/widgets/app_dialog.dart';

Future<void> confirmRegistrationCancellation({
  required BuildContext context,
  required Future<void> Function() onCancel,
  bool isEditing = false,
}) async {
  final bool confirmed = isEditing
      ? await showAppConfirmationDialog(
          context: context,
          title: 'Discard changes?',
          message:
              'Your application stays as it was submitted. The changes you '
              'made here will not be saved.',
          confirmLabel: 'Discard Changes',
          cancelLabel: 'Keep Editing',
          icon: Icons.edit_off_rounded,
          isDestructive: true,
        )
      : await showAppConfirmationDialog(
          context: context,
          title: 'Cancel registration?',
          message:
              'Your application progress and selected photos will be cleared. '
              'Are you sure you want to leave registration?',
          confirmLabel: 'Cancel Registration',
          cancelLabel: 'Keep Registering',
          icon: Icons.close_rounded,
          isDestructive: true,
        );
  if (!confirmed || !context.mounted) return;
  await onCancel();
}
