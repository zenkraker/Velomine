// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rides_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The member's rides: filtering, paging, uploading, and following an upload
/// until the server has read it.

@ProviderFor(RidesViewModel)
final ridesViewModelProvider = RidesViewModelProvider._();

/// The member's rides: filtering, paging, uploading, and following an upload
/// until the server has read it.
final class RidesViewModelProvider
    extends $NotifierProvider<RidesViewModel, RidesState> {
  /// The member's rides: filtering, paging, uploading, and following an upload
  /// until the server has read it.
  RidesViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ridesViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ridesViewModelHash();

  @$internal
  @override
  RidesViewModel create() => RidesViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RidesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RidesState>(value),
    );
  }
}

String _$ridesViewModelHash() => r'858d68f436ad3ed1f3bb5c83fe2c30129e5e388f';

/// The member's rides: filtering, paging, uploading, and following an upload
/// until the server has read it.

abstract class _$RidesViewModel extends $Notifier<RidesState> {
  RidesState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RidesState, RidesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RidesState, RidesState>,
              RidesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
