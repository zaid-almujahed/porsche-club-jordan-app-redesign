import 'package:flutter/material.dart';

import 'package:pcj_v5/core/theme/app_theme.dart';

class SignInField extends StatefulWidget {
  const SignInField({
    super.key,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.onSubmitted,
    this.controller,
  });

  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  /// A password: hidden, with a button to show it while typing.
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;

  @override
  State<SignInField> createState() => _SignInFieldState();
}

class _SignInFieldState extends State<SignInField> {
  late bool _hidden = widget.obscureText;

  IconData get _prefixIcon {
    if (widget.obscureText) return Icons.lock_outline_rounded;
    if (widget.keyboardType == TextInputType.emailAddress) {
      return Icons.mail_outline_rounded;
    }
    return Icons.person_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onSubmitted,
      style: AppTextStyles.input,
      cursorColor: AppColors.primaryBright,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(_prefixIcon, size: 20),
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: _hidden ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}
