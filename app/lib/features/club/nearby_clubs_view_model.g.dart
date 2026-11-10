// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_clubs_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Clubs within reach of the rider and the one open join request.
///
/// The position flow lives here: the device first, then the point saved on this
/// phone. The screen only navigates to the map picker and hands back a point.

@ProviderFor(NearbyClubsViewModel)
final nearbyClubsViewModelProvider = NearbyClubsViewModelProvider._();

/// Clubs within reach of the rider and the one open join request.
///
/// The position flow lives here: the device first, then the point saved on this
/// phone. The screen only navigates to the map picker and hands back a point.
final class NearbyClubsViewModelProvider
    extends $NotifierProvider<NearbyClubsViewModel, NearbyClubsState> {
  /// Clubs within reach of the rider and the one open join request.
  ///
  /// The position flow lives here: the device first, then the point saved on this
  /// phone. The screen only navigates to the map picker and hands back a point.
  NearbyClubsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyClubsViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyClubsViewModelHash();

  @$internal
  @override
  NearbyClubsViewModel create() => NearbyClubsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NearbyClubsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NearbyClubsState>(value),
    );
  }
}

String _$nearbyClubsViewModelHash() =>
    r'76bfb7768e43cabcc827fd17c510c49420f09ed2';

/// Clubs within reach of the rider and the one open join request.
///
/// The position flow lives here: the device first, then the point saved on this
/// phone. The screen only navigates to the map picker and hands back a point.

abstract class _$NearbyClubsViewModel extends $Notifier<NearbyClubsState> {
  NearbyClubsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NearbyClubsState, NearbyClubsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NearbyClubsState, NearbyClubsState>,
              NearbyClubsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
