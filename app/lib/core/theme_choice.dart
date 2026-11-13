import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';

part 'theme_choice.g.dart';

/// Where the choice is kept. Tests override it with an in-memory store.
final themeChoiceStoreProvider = Provider<ThemeChoiceStore>(
  (ref) => PreferencesThemeChoiceStore(),
);

/// Day, night, or whatever the device is set to. Kept on this device only: the
/// same member may want the night theme on the phone and the day theme on a
/// laptop, and the choice applies before anyone signs in.
@Riverpod(keepAlive: true)
class ThemeChoiceViewModel extends _$ThemeChoiceViewModel {
  @override
  Future<ThemeMode> build() async {
    final saved = await ref.watch(themeChoiceStoreProvider).read();
    return ThemeMode.values.where((m) => m.name == saved).firstOrNull ??
        ThemeMode.system;
  }

  Future<void> choose(ThemeMode value) async {
    state = AsyncData(value);
    await ref.read(themeChoiceStoreProvider).write(value.name);
  }
}

/// Where the choice is kept. Tests pass one in memory.
abstract interface class ThemeChoiceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class PreferencesThemeChoiceStore implements ThemeChoiceStore {
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
class ThemeChoiceButton extends ConsumerWidget {
  const ThemeChoiceButton({super.key});

  /// The icon and the name of a theme, shared with any menu that offers the choice.
  static IconData iconOf(ThemeMode m) => switch (m) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.brightness_auto_outlined,
  };

  static String nameOf(BuildContext context, ThemeMode mode) => switch (mode) {
    ThemeMode.light => context.l10n.themeLight,
    ThemeMode.dark => context.l10n.themeDark,
    ThemeMode.system => context.l10n.themeSystem,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode =
        ref.watch(themeChoiceViewModelProvider).value ?? ThemeMode.system;
    return PopupMenuButton<ThemeMode>(
      key: const Key('theme-choice'),
      tooltip: context.l10n.themeTooltip(nameOf(context, mode)),
      icon: Icon(iconOf(mode)),
      initialValue: mode,
      onSelected: ref.read(themeChoiceViewModelProvider.notifier).choose,
      itemBuilder: (_) => [
        for (final m in [ThemeMode.light, ThemeMode.dark, ThemeMode.system])
          PopupMenuItem(
            key: Key('theme-${m.name}'),
            value: m,
            child: ListTile(
              leading: Icon(iconOf(m)),
              title: Text(nameOf(context, m)),
              trailing: m == mode ? const Icon(Icons.check) : null,
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }
}
