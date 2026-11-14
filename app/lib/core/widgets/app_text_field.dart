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

  @override
  Widget build(BuildContext context) => TextField(
    key: fieldKey,
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    enabled: enabled,
    maxLength: maxLength,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperMaxLines: 3,
      errorMaxLines: 2,
      suffixText: suffix,
    ),
  );
}
