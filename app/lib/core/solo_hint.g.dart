// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solo_hint.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the rider who is not in a club has put away the card that points at
/// nearby clubs.

@ProviderFor(SoloHintViewModel)
final soloHintViewModelProvider = SoloHintViewModelProvider._();

/// Whether the rider who is not in a club has put away the card that points at
/// nearby clubs.
final class SoloHintViewModelProvider
    extends $NotifierProvider<SoloHintViewModel, bool> {
  /// Whether the rider who is not in a club has put away the card that points at
  /// nearby clubs.
  SoloHintViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'soloHintViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$soloHintViewModelHash();

  @$internal
  @override
  SoloHintViewModel create() => SoloHintViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$soloHintViewModelHash() => r'e831d3e06d7a47659696a761f27f6b5ae5654d73';

/// Whether the rider who is not in a club has put away the card that points at
/// nearby clubs.

abstract class _$SoloHintViewModel extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
