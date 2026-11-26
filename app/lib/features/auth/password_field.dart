import 'package:material_ui/material_ui.dart';

import '../../core/l10n.dart';
import '../../core/widgets/app_text_field.dart';

/// A password box with the word that shows what was typed, so a typo can be seen before the form is sent.
/// The design draws a text button at the end of the box (`docs/design/pages/sign-in/SignInPage.html`), not an eye.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.fieldKey,
    this.visibilityKey,
    this.helperText,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;

  /// The key on the TextField itself, where tests and the form look for it.
  final Key? fieldKey;
  final Key? visibilityKey;
  final String? helperText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppTextField(
      fieldKey: widget.fieldKey,
      controller: widget.controller,
      label: widget.label,
      helper: widget.helperText,
      obscureText: !_visible,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: widget.autofillHints,
      // The password is the last box on every form that uses this field, so the key that sends goes to the form.
      textInputAction:
          widget.textInputAction ??
          (widget.onSubmitted == null ? null : TextInputAction.done),
      onDone: widget.onSubmitted,
      // The word is the control; the sentence is what a screen reader reads, as the mock-up shows
      // only the word.
      suffixIcon: Tooltip(
        message: _visible ? l10n.hidePassword : l10n.showPassword,
        child: TextButton(
          key: widget.visibilityKey,
          onPressed: () => setState(() => _visible = !_visible),
          child: Text(_visible ? l10n.passwordHide : l10n.passwordShow),
        ),
      ),
    );
  }
}
