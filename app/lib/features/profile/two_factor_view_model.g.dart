// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'two_factor_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The member's second factor. Route-scoped: it holds one visit, not the session.

@ProviderFor(TwoFactorViewModel)
final twoFactorViewModelProvider = TwoFactorViewModelProvider._();

/// The member's second factor. Route-scoped: it holds one visit, not the session.
final class TwoFactorViewModelProvider
    extends $NotifierProvider<TwoFactorViewModel, TwoFactorScreenState> {
  /// The member's second factor. Route-scoped: it holds one visit, not the session.
  TwoFactorViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'twoFactorViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$twoFactorViewModelHash();

  @$internal
  @override
  TwoFactorViewModel create() => TwoFactorViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TwoFactorScreenState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TwoFactorScreenState>(value),
    );
  }
}

String _$twoFactorViewModelHash() =>
    r'66a0d3d7401b64a7c8d69be55ab9452749c8d4f7';

/// The member's second factor. Route-scoped: it holds one visit, not the session.

abstract class _$TwoFactorViewModel extends $Notifier<TwoFactorScreenState> {
  TwoFactorScreenState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TwoFactorScreenState, TwoFactorScreenState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TwoFactorScreenState, TwoFactorScreenState>,
              TwoFactorScreenState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
