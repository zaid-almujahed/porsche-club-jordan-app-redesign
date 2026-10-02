import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

Future<bool> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  IconData icon = Icons.help_outline_rounded,
  bool isDestructive = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AppDialog(
      icon: icon,
      iconColor: isDestructive ? AppColors.danger : AppColors.primaryBright,
      title: title,
      message: message,
      primaryLabel: confirmLabel,
      secondaryLabel: cancelLabel,
      onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
      onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  return result ?? false;
}

Future<void> showAppMessageDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonLabel = 'Continue',
  IconData icon = Icons.info_outline_rounded,
  Color iconColor = AppColors.primaryBright,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => AppDialog(
      icon: icon,
      iconColor: iconColor,
      title: title,
      message: message,
      primaryLabel: buttonLabel,
      onPrimaryPressed: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

Future<String?> showAppTextInputDialog({
  required BuildContext context,
  required String title,
  required String currentValue,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  String? hintText,
  TextInputType? keyboardType,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => _AppTextInputDialog(
      title: title,
      currentValue: currentValue,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      hintText: hintText,
      keyboardType: keyboardType,
    ),
  );
}

class _AppTextInputDialog extends StatefulWidget {
  const _AppTextInputDialog({
    required this.title,
    required this.currentValue,
    required this.confirmLabel,
    required this.cancelLabel,
    this.hintText,
    this.keyboardType,
  });

  final String title;
  final String currentValue;
  final String confirmLabel;
  final String cancelLabel;
  final String? hintText;
  final TextInputType? keyboardType;

  @override
  State<_AppTextInputDialog> createState() => _AppTextInputDialogState();
}

class _AppTextInputDialogState extends State<_AppTextInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      icon: Icons.edit_outlined,
      title: widget.title,
      content: TextField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        autofocus: true,
        style: AppTextStyles.input,
        decoration: InputDecoration(hintText: widget.hintText),
        onSubmitted: (_) => _submit(),
      ),
      primaryLabel: widget.confirmLabel,
      secondaryLabel: widget.cancelLabel,
      onPrimaryPressed: _submit,
      onSecondaryPressed: () => Navigator.of(context).pop(),
    );
  }
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.message,
    this.content,
    this.icon,
    this.iconColor = AppColors.primaryBright,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.onClose,
  }) : assert(message != null || content != null);

  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final Color iconColor;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  /// Shows a small × in the corner.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return AppDialogFrame(
      onClose: onClose,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Center(
              child: AppDialogIcon(icon: icon!, color: iconColor),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (message != null)
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 15.5),
            )
          else
            content!,
          const SizedBox(height: AppSpacing.xl),
          PrimaryActionButton(
            label: primaryLabel,
            onPressed: onPrimaryPressed,
            height: 52,
          ),
          if (secondaryLabel != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            SecondaryActionButton(
              label: secondaryLabel!,
              onPressed: onSecondaryPressed,
              height: 52,
            ),
          ],
        ],
      ),
    );
  }
}

/// What a dialog says before it closes, when closing it loses something.
class DialogCloseWarning {
  const DialogCloseWarning({
    required this.title,
    required this.message,
    this.confirmLabel = 'Leave',
    this.cancelLabel = 'Stay',
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  /// True when the member still wants to close.
  Future<bool> confirm(BuildContext context) => showAppConfirmationDialog(
    context: context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    icon: Icons.warning_amber_rounded,
    isDestructive: true,
  );
}

/// Shared dialog shell: rounded dark surface, hairline border, gentle scale-in.
class AppDialogFrame extends StatelessWidget {
  const AppDialogFrame({
    super.key,
    required this.child,
    this.maxWidth = 430,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.onClose,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  /// Shows a small × in the corner.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return AppScaleIn(
      child: Dialog(
        elevation: 0,
        backgroundColor: AppColors.panelDark,
        surfaceTintColor: AppColors.panelDark,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large + 4),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: MediaQuery.sizeOf(context).height - 64,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFF18181C), AppColors.panelDark],
              ),
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(AppRadii.large + 4),
            ),
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(padding: padding, child: child),
                if (onClose != null)
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: IconButton(
                      onPressed: onClose,
                      tooltip: 'Close',
                      iconSize: 20,
                      color: AppColors.textMuted,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular tinted icon with a soft ring, used at the top of dialogs.
class AppDialogIcon extends StatelessWidget {
  const AppDialogIcon({
    super.key,
    required this.icon,
    this.color = AppColors.primaryBright,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}
