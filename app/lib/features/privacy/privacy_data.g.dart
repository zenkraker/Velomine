// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(privacyData)
final privacyDataProvider = PrivacyDataProvider._();

final class PrivacyDataProvider
    extends $FunctionalProvider<PrivacyData, PrivacyData, PrivacyData>
    with $Provider<PrivacyData> {
  PrivacyDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'privacyDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$privacyDataHash();

  @$internal
  @override
  $ProviderElement<PrivacyData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PrivacyData create(Ref ref) {
    return privacyData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PrivacyData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PrivacyData>(value),
    );
  }
}

String _$privacyDataHash() => r'70ccc708ceaac5c7c1bdb169a5ac7e93ce4d6f14';
