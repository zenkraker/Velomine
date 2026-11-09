// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One ride, read fresh on the detail route. A processing upload is polled
/// until the server has read it.

@ProviderFor(RideDetailViewModel)
final rideDetailViewModelProvider = RideDetailViewModelFamily._();

/// One ride, read fresh on the detail route. A processing upload is polled
/// until the server has read it.
final class RideDetailViewModelProvider
    extends $NotifierProvider<RideDetailViewModel, RideDetailState> {
  /// One ride, read fresh on the detail route. A processing upload is polled
  /// until the server has read it.
  RideDetailViewModelProvider._({
    required RideDetailViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'rideDetailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rideDetailViewModelHash();

  @override
  String toString() {
    return r'rideDetailViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RideDetailViewModel create() => RideDetailViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RideDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RideDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RideDetailViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rideDetailViewModelHash() =>
    r'e9745265e796b5a942797ac3fd2c48e37c758031';

/// One ride, read fresh on the detail route. A processing upload is polled
/// until the server has read it.

final class RideDetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          RideDetailViewModel,
          RideDetailState,
          RideDetailState,
          RideDetailState,
          String
        > {
  RideDetailViewModelFamily._()
    : super(
        retry: null,
        name: r'rideDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One ride, read fresh on the detail route. A processing upload is polled
  /// until the server has read it.

  RideDetailViewModelProvider call(String id) =>
      RideDetailViewModelProvider._(argument: id, from: this);

  @override
  String toString() => r'rideDetailViewModelProvider';
}

/// One ride, read fresh on the detail route. A processing upload is polled
/// until the server has read it.

abstract class _$RideDetailViewModel extends $Notifier<RideDetailState> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  RideDetailState build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RideDetailState, RideDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RideDetailState, RideDetailState>,
              RideDetailState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
