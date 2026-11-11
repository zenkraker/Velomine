// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bikes_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bikesData)
final bikesDataProvider = BikesDataProvider._();

final class BikesDataProvider
    extends $FunctionalProvider<BikesData, BikesData, BikesData>
    with $Provider<BikesData> {
  BikesDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bikesDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bikesDataHash();

  @$internal
  @override
  $ProviderElement<BikesData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BikesData create(Ref ref) {
    return bikesData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BikesData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BikesData>(value),
    );
  }
}

String _$bikesDataHash() => r'3907ccf757c9fdaa1abab9927dcdae0b59095c07';
