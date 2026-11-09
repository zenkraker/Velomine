// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clubData)
final clubDataProvider = ClubDataProvider._();

final class ClubDataProvider
    extends $FunctionalProvider<ClubData, ClubData, ClubData>
    with $Provider<ClubData> {
  ClubDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clubDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clubDataHash();

  @$internal
  @override
  $ProviderElement<ClubData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ClubData create(Ref ref) {
    return clubData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClubData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClubData>(value),
    );
  }
}

String _$clubDataHash() => r'09ceaf3ed2673368c96a4b100825c56458358ad2';
