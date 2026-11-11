// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_rides_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clubRidesData)
final clubRidesDataProvider = ClubRidesDataProvider._();

final class ClubRidesDataProvider
    extends $FunctionalProvider<ClubRidesData, ClubRidesData, ClubRidesData>
    with $Provider<ClubRidesData> {
  ClubRidesDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clubRidesDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clubRidesDataHash();

  @$internal
  @override
  $ProviderElement<ClubRidesData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClubRidesData create(Ref ref) {
    return clubRidesData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClubRidesData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClubRidesData>(value),
    );
  }
}

String _$clubRidesDataHash() => r'9ea9acfcf8a6d6015b3428306e1aeb689dace86a';
