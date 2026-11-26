import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

/// A labelled field for every form in the app: three lines of help and two of error, so a long hint
/// wraps instead of ending in an ellipsis.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.fieldKey,
    required this.controller,
    this.label,
    this.hint,
    this.helper,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.onDone,
    this.focusNode,
    this.onChanged,
    this.errorText,
    this.autofocus = false,
    this.obscureText = false,
    this.autofillHints,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
  });

  /// The key a test or a finder looks the field up by; it lands on the `TextField` itself.
  final Key? fieldKey;
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? helper;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  /// The most characters the field takes; a counter shows how many are left.
  final int? maxLength;

  /// Lines shown at once; more than one makes a text area.
  final int maxLines;

  /// Called when the keyboard's done key is pressed, with the text as it is then.
  final ValueChanged<String>? onDone;

  /// The node the field's focus belongs to, for a field that saves itself when the rider leaves it.
  final FocusNode? focusNode;

  /// Called on every edit, with the text as it is then.
  final ValueChanged<String>? onChanged;

  /// A failure the field shows under itself in the error colour.
  final String? errorText;
  final bool autofocus;

  /// A password: the text is hidden, and suggestions and autocorrect are off.
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;

  /// With [maxLines], the field grows from this many lines to that many.
  final int? minLines;

  /// A control or glyph inside the field's edge. [suffix] is text; [suffixIcon] is a widget, such as
  /// the password's show/hide word.
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) => TextField(
    key: fieldKey,
    controller: controller,
    focusNode: focusNode,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    enabled: enabled,
    maxLength: maxLength,
    maxLines: obscureText ? 1 : maxLines,
    minLines: minLines,
    onSubmitted: onDone,
    onChanged: onChanged,
    autofocus: autofocus,
    obscureText: obscureText,
    autofillHints: autofillHints,
    textInputAction: textInputAction,
    textCapitalization: textCapitalization,
    autocorrect: autocorrect,
    enableSuggestions: enableSuggestions,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 3,
      errorText: errorText,
      errorMaxLines: 2,
      suffixText: suffix,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    ),
  );
}
