// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_location.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A point the rider saved on this device for their account, used for nearby
/// clubs when the device will not share its position. It never goes to the
/// server except inside a nearby-clubs request.

@ProviderFor(HomeLocationViewModel)
final homeLocationViewModelProvider = HomeLocationViewModelProvider._();

/// A point the rider saved on this device for their account, used for nearby
/// clubs when the device will not share its position. It never goes to the
/// server except inside a nearby-clubs request.
final class HomeLocationViewModelProvider
    extends $NotifierProvider<HomeLocationViewModel, GeoPoint?> {
  /// A point the rider saved on this device for their account, used for nearby
  /// clubs when the device will not share its position. It never goes to the
  /// server except inside a nearby-clubs request.
  HomeLocationViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeLocationViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeLocationViewModelHash();

  @$internal
  @override
  HomeLocationViewModel create() => HomeLocationViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeoPoint? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeoPoint?>(value),
    );
  }
}

String _$homeLocationViewModelHash() =>
    r'4ff584f4fe3e30a31094f777121a32e0c3ca6789';

/// A point the rider saved on this device for their account, used for nearby
/// clubs when the device will not share its position. It never goes to the
/// server except inside a nearby-clubs request.

abstract class _$HomeLocationViewModel extends $Notifier<GeoPoint?> {
  GeoPoint? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GeoPoint?, GeoPoint?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GeoPoint?, GeoPoint?>,
              GeoPoint?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
