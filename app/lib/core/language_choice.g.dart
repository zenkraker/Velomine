// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_choice.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The language on screen. Before sign-in it follows the device; after sign-in
/// it follows the account, so a choice on the web is the same on the phone.
/// There is no per-device setting.

@ProviderFor(LanguageChoiceViewModel)
final languageChoiceViewModelProvider = LanguageChoiceViewModelProvider._();

/// The language on screen. Before sign-in it follows the device; after sign-in
/// it follows the account, so a choice on the web is the same on the phone.
/// There is no per-device setting.
final class LanguageChoiceViewModelProvider
    extends $NotifierProvider<LanguageChoiceViewModel, String?> {
  /// The language on screen. Before sign-in it follows the device; after sign-in
  /// it follows the account, so a choice on the web is the same on the phone.
  /// There is no per-device setting.
  LanguageChoiceViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'languageChoiceViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$languageChoiceViewModelHash();

  @$internal
  @override
  LanguageChoiceViewModel create() => LanguageChoiceViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$languageChoiceViewModelHash() =>
    r'83b327334069a930535141bf981ebea52ce376dd';

/// The language on screen. Before sign-in it follows the device; after sign-in
/// it follows the account, so a choice on the web is the same on the phone.
/// There is no per-device setting.

abstract class _$LanguageChoiceViewModel extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
