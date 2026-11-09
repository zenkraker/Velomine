// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_detail_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rideDetailData)
final rideDetailDataProvider = RideDetailDataProvider._();

final class RideDetailDataProvider
    extends $FunctionalProvider<RideDetailData, RideDetailData, RideDetailData>
    with $Provider<RideDetailData> {
  RideDetailDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rideDetailDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rideDetailDataHash();

  @$internal
  @override
  $ProviderElement<RideDetailData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RideDetailData create(Ref ref) {
    return rideDetailData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RideDetailData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RideDetailData>(value),
    );
  }
}

String _$rideDetailDataHash() => r'3c04d2b823194219e20ec04b0783ed2708035afd';
