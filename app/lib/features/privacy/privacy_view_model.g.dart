// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The member's privacy choices. Route-scoped, so leaving the screen drops
/// them; a sign-out or account change rebuilds it empty.

@ProviderFor(PrivacyViewModel)
final privacyViewModelProvider = PrivacyViewModelProvider._();

/// The member's privacy choices. Route-scoped, so leaving the screen drops
/// them; a sign-out or account change rebuilds it empty.
final class PrivacyViewModelProvider
    extends $NotifierProvider<PrivacyViewModel, PrivacyState> {
  /// The member's privacy choices. Route-scoped, so leaving the screen drops
  /// them; a sign-out or account change rebuilds it empty.
  PrivacyViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacyViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacyViewModelHash();

  @$internal
  @override
  PrivacyViewModel create() => PrivacyViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PrivacyState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PrivacyState>(value),
    );
  }
}

String _$privacyViewModelHash() => r'76506f936640f9ae882780fd01df3fdc3b20ce0e';

/// The member's privacy choices. Route-scoped, so leaving the screen drops
/// them; a sign-out or account change rebuilds it empty.

abstract class _$PrivacyViewModel extends $Notifier<PrivacyState> {
  PrivacyState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PrivacyState, PrivacyState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PrivacyState, PrivacyState>,
              PrivacyState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
