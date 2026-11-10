import 'package:flutter/material.dart';

import '../../core/l10n.dart';

/// A password box with the eye that shows what was typed, so a typo can be seen before the form is sent.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.fieldKey,
    this.visibilityKey,
    this.helperText,
    this.helperMaxLines,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;

  /// The key on the TextField itself, where tests and the form look for it.
  final Key? fieldKey;
  final Key? visibilityKey;
  final String? helperText;
  final int? helperMaxLines;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      key: widget.fieldKey,
      controller: widget.controller,
      obscureText: !_visible,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: widget.helperMaxLines,
        suffixIcon: IconButton(
          key: widget.visibilityKey,
          tooltip: _visible ? l10n.hidePassword : l10n.showPassword,
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}
