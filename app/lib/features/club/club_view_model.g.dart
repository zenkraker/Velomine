// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in account's club and the changes to it. Kept alive for the
/// session; a sign-out rebuilds it empty, and the router reads it for redirects.

@ProviderFor(ClubViewModel)
final clubViewModelProvider = ClubViewModelProvider._();

/// The signed-in account's club and the changes to it. Kept alive for the
/// session; a sign-out rebuilds it empty, and the router reads it for redirects.
final class ClubViewModelProvider
    extends $NotifierProvider<ClubViewModel, ClubState> {
  /// The signed-in account's club and the changes to it. Kept alive for the
  /// session; a sign-out rebuilds it empty, and the router reads it for redirects.
  ClubViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clubViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clubViewModelHash();

  @$internal
  @override
  ClubViewModel create() => ClubViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClubState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClubState>(value),
    );
  }
}

String _$clubViewModelHash() => r'4cf01177861964cef8801330757bea4d43af62d7';

/// The signed-in account's club and the changes to it. Kept alive for the
/// session; a sign-out rebuilds it empty, and the router reads it for redirects.

abstract class _$ClubViewModel extends $Notifier<ClubState> {
  ClubState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ClubState, ClubState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClubState, ClubState>,
              ClubState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
