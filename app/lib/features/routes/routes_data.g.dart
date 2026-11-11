// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(routesData)
final routesDataProvider = RoutesDataProvider._();

final class RoutesDataProvider
    extends $FunctionalProvider<RoutesData, RoutesData, RoutesData>
    with $Provider<RoutesData> {
  RoutesDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routesDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routesDataHash();

  @$internal
  @override
  $ProviderElement<RoutesData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RoutesData create(Ref ref) {
    return routesData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RoutesData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RoutesData>(value),
    );
  }
}

String _$routesDataHash() => r'cb9a17205e41554097a416628baa5a775e32e932';
