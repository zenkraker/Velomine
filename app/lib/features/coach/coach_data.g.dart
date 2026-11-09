// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(coachData)
final coachDataProvider = CoachDataProvider._();

final class CoachDataProvider
    extends $FunctionalProvider<CoachData, CoachData, CoachData>
    with $Provider<CoachData> {
  CoachDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachDataHash();

  @$internal
  @override
  $ProviderElement<CoachData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoachData create(Ref ref) {
    return coachData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachData>(value),
    );
  }
}

String _$coachDataHash() => r'459b83577406d5582928f3100bad7b67468b0817';
