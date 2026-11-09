// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_choice.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Day, night, or whatever the device is set to. Kept on this device only: the
/// same member may want the night theme on the phone and the day theme on a
/// laptop, and the choice applies before anyone signs in.

@ProviderFor(ThemeChoiceViewModel)
final themeChoiceViewModelProvider = ThemeChoiceViewModelProvider._();

/// Day, night, or whatever the device is set to. Kept on this device only: the
/// same member may want the night theme on the phone and the day theme on a
/// laptop, and the choice applies before anyone signs in.
final class ThemeChoiceViewModelProvider
    extends $AsyncNotifierProvider<ThemeChoiceViewModel, ThemeMode> {
  /// Day, night, or whatever the device is set to. Kept on this device only: the
  /// same member may want the night theme on the phone and the day theme on a
  /// laptop, and the choice applies before anyone signs in.
  ThemeChoiceViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeChoiceViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeChoiceViewModelHash();

  @$internal
  @override
  ThemeChoiceViewModel create() => ThemeChoiceViewModel();
}

String _$themeChoiceViewModelHash() =>
    r'61dde1a9bae911342881617932baba337d85ebed';

/// Day, night, or whatever the device is set to. Kept on this device only: the
/// same member may want the night theme on the phone and the day theme on a
/// laptop, and the choice applies before anyone signs in.

abstract class _$ThemeChoiceViewModel extends $AsyncNotifier<ThemeMode> {
  FutureOr<ThemeMode> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ThemeMode>, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ThemeMode>, ThemeMode>,
              AsyncValue<ThemeMode>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
