// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rides_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ridesData)
final ridesDataProvider = RidesDataProvider._();

final class RidesDataProvider
    extends $FunctionalProvider<RidesData, RidesData, RidesData>
    with $Provider<RidesData> {
  RidesDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ridesDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ridesDataHash();

  @$internal
  @override
  $ProviderElement<RidesData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RidesData create(Ref ref) {
    return ridesData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RidesData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RidesData>(value),
    );
  }
}

String _$ridesDataHash() => r'2bd90fedca2263f097de6fd652ea012387e3b0ba';
