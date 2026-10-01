import 'package:flutter/material.dart';

import 'package:pcj_v5/core/services/biometric_sign_in.dart';
import 'package:pcj_v5/core/theme/app_theme.dart';
import 'package:pcj_v5/shared/widgets/app_widgets.dart';

/// "Sign in with Face ID" under Sign In, when a login is saved for it on
/// this phone and Face ID (or a fingerprint) is set up.
class BiometricSignInButton extends StatefulWidget {
  const BiometricSignInButton({
    super.key,
    required this.biometricSignIn,
    required this.onPressed,
    this.enabled = true,
  });

  final BiometricSignIn biometricSignIn;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<BiometricSignInButton> createState() => _BiometricSignInButtonState();
}

class _BiometricSignInButtonState extends State<BiometricSignInButton> {
  String? _name;

  @override
  void initState() {
    super.initState();
    widget.biometricSignIn.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.biometricSignIn.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final String? email = await widget.biometricSignIn.savedEmail();
    final String? name = email == null
        ? null
        : await widget.biometricSignIn.availableName();
    if (mounted && name != _name) setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) {
    final String? name = _name;
    if (name == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SecondaryActionButton(
        label: 'Sign in with $name',
        height: 56,
        onPressed: widget.enabled ? widget.onPressed : null,
      ),
    );
  }
}
