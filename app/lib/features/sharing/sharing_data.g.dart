// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sharing_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sharingData)
final sharingDataProvider = SharingDataProvider._();

final class SharingDataProvider
    extends $FunctionalProvider<SharingData, SharingData, SharingData>
    with $Provider<SharingData> {
  SharingDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharingDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharingDataHash();

  @$internal
  @override
  $ProviderElement<SharingData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SharingData create(Ref ref) {
    return sharingData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharingData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharingData>(value),
    );
  }
}

String _$sharingDataHash() => r'df657fb921ef9ba9bacb90fefcf3934c8fdcfd37';
