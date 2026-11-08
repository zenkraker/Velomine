import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';

/// English, Italian, or whatever the device is set to. Kept on this device only, like the theme: it applies
/// before anyone signs in, and the choice is remembered for the next launch.
class LanguageChoice extends ChangeNotifier {
  LanguageChoice({LanguageChoiceStore? store})
    : _store = store ?? _Preferences();

  final LanguageChoiceStore _store;

  /// A language code such as `en` or `it`; null means follow the device.
  String? code;

  /// The languages the app has translations for.
  static const supported = ['en', 'it'];

  static String? _known(String? value) =>
      value != null && supported.contains(value) ? value : null;

  /// Null tells [MaterialApp] to use the device's language.
  Locale? get locale => code == null ? null : Locale(code!);

  Future<void> load() async {
    code = _known(await _store.read());
    notifyListeners();
  }

  Future<void> choose(String? value) async {
    code = _known(value);
    notifyListeners();
    await _store.write(code ?? 'system');
  }
}

/// Where the choice is kept. Tests pass one in memory.
abstract interface class LanguageChoiceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class _Preferences implements LanguageChoiceStore {
  static const _key = 'language';
  final _prefs = SharedPreferencesAsync();

  @override
  Future<String?> read() async {
    try {
      return await _prefs.getString(_key);
    } on Object {
      return null; // no storage available: follow the device
    }
  }

  @override
  Future<void> write(String value) async {
    try {
      await _prefs.setString(_key, value);
    } on Object {
      // Not kept; the app still uses the choice until it closes.
    }
  }
}

/// A button for the title bar that picks the language. Shown before sign-in too, so the choice is never hidden.
class LanguageChoiceButton extends StatelessWidget {
  const LanguageChoiceButton({super.key, required this.choice});

  final LanguageChoice choice;

  String _name(BuildContext context, String? code) {
    final l10n = context.l10n;
    return switch (code) {
      null => l10n.languageSystem,
      'it' => l10n.languageItalian,
      _ => l10n.languageEnglish,
    };
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: choice,
    builder: (context, _) => PopupMenuButton<String>(
      key: const Key('language-choice'),
      tooltip: context.l10n.languageTooltip(_name(context, choice.code)),
      icon: const Icon(Icons.language),
      initialValue: choice.code ?? 'system',
      onSelected: (value) => choice.choose(value == 'system' ? null : value),
      itemBuilder: (_) => [
        for (final code in [null, ...LanguageChoice.supported])
          PopupMenuItem(
            key: Key('language-${code ?? 'system'}'),
            value: code ?? 'system',
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(_name(context, code)),
              trailing: code == choice.code ? const Icon(Icons.check) : null,
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    ),
  );
}
