import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';

/// Day, night, or whatever the device is set to. Kept on this device only: the same member may want the night
/// theme on the phone and the day theme on a laptop, and the choice applies before anyone signs in.
class ThemeChoice extends ChangeNotifier {
  ThemeChoice({ThemeChoiceStore? store}) : _store = store ?? _Preferences();

  final ThemeChoiceStore _store;
  ThemeMode mode = ThemeMode.system;

  Future<void> load() async {
    final saved = await _store.read();
    mode =
        ThemeMode.values.where((m) => m.name == saved).firstOrNull ??
        ThemeMode.system;
    notifyListeners();
  }

  Future<void> choose(ThemeMode value) async {
    mode = value;
    notifyListeners();
    await _store.write(value.name);
  }
}

/// Where the choice is kept. Tests pass one in memory.
abstract interface class ThemeChoiceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class _Preferences implements ThemeChoiceStore {
  static const _key = 'theme';
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

/// A button for the title bar that switches between the themes.
class ThemeChoiceButton extends StatelessWidget {
  const ThemeChoiceButton({super.key, required this.choice});

  final ThemeChoice choice;

  static IconData _icon(ThemeMode m) => switch (m) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.brightness_auto_outlined,
  };

  static String _name(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.light => context.l10n.themeLight,
    ThemeMode.dark => context.l10n.themeDark,
    ThemeMode.system => context.l10n.themeSystem,
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: choice,
    builder: (context, _) => PopupMenuButton<ThemeMode>(
      key: const Key('theme-choice'),
      tooltip: context.l10n.themeTooltip(_name(context, choice.mode)),
      icon: Icon(_icon(choice.mode)),
      initialValue: choice.mode,
      onSelected: choice.choose,
      itemBuilder: (_) => [
        for (final m in [ThemeMode.light, ThemeMode.dark, ThemeMode.system])
          PopupMenuItem(
            key: Key('theme-${m.name}'),
            value: m,
            child: ListTile(
              leading: Icon(_icon(m)),
              title: Text(_name(context, m)),
              trailing: m == choice.mode ? const Icon(Icons.check) : null,
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    ),
  );
}
