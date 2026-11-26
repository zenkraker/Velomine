// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_picker_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(locationPickerData)
final locationPickerDataProvider = LocationPickerDataProvider._();

final class LocationPickerDataProvider
    extends
        $FunctionalProvider<
          LocationPickerData,
          LocationPickerData,
          LocationPickerData
        >
    with $Provider<LocationPickerData> {
  LocationPickerDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationPickerDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationPickerDataHash();

  @$internal
  @override
  $ProviderElement<LocationPickerData> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocationPickerData create(Ref ref) {
    return locationPickerData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationPickerData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationPickerData>(value),
    );
  }
}

String _$locationPickerDataHash() =>
    r'454a8c8461a9e32b2e5a9148eaa5a71c3bd39807';

/// The map picker for one point: where the map looks, and asking the device for the rider's position.
///
/// Route scoped: one map, one point. The page returns the point itself; nothing is saved here.

@ProviderFor(LocationPickerViewModel)
final locationPickerViewModelProvider = LocationPickerViewModelFamily._();

/// The map picker for one point: where the map looks, and asking the device for the rider's position.
///
/// Route scoped: one map, one point. The page returns the point itself; nothing is saved here.
final class LocationPickerViewModelProvider
    extends $NotifierProvider<LocationPickerViewModel, LocationPickerState> {
  /// The map picker for one point: where the map looks, and asking the device for the rider's position.
  ///
  /// Route scoped: one map, one point. The page returns the point itself; nothing is saved here.
  LocationPickerViewModelProvider._({
    required LocationPickerViewModelFamily super.from,
    required LocationPickerArgs super.argument,
  }) : super(
         retry: null,
         name: r'locationPickerViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$locationPickerViewModelHash();

  @override
  String toString() {
    return r'locationPickerViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  LocationPickerViewModel create() => LocationPickerViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationPickerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationPickerState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LocationPickerViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$locationPickerViewModelHash() =>
    r'50de1d74abfb495079baa87d8bc3f4431ac59ac8';

/// The map picker for one point: where the map looks, and asking the device for the rider's position.
///
/// Route scoped: one map, one point. The page returns the point itself; nothing is saved here.

final class LocationPickerViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          LocationPickerViewModel,
          LocationPickerState,
          LocationPickerState,
          LocationPickerState,
          LocationPickerArgs
        > {
  LocationPickerViewModelFamily._()
    : super(
        retry: null,
        name: r'locationPickerViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The map picker for one point: where the map looks, and asking the device for the rider's position.
  ///
  /// Route scoped: one map, one point. The page returns the point itself; nothing is saved here.

  LocationPickerViewModelProvider call(LocationPickerArgs args) =>
      LocationPickerViewModelProvider._(argument: args, from: this);

  @override
  String toString() => r'locationPickerViewModelProvider';
}

/// The map picker for one point: where the map looks, and asking the device for the rider's position.
///
/// Route scoped: one map, one point. The page returns the point itself; nothing is saved here.

abstract class _$LocationPickerViewModel
    extends $Notifier<LocationPickerState> {
  late final _$args = ref.$arg as LocationPickerArgs;
  LocationPickerArgs get args => _$args;

  LocationPickerState build(LocationPickerArgs args);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LocationPickerState, LocationPickerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LocationPickerState, LocationPickerState>,
              LocationPickerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
