// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(progressData)
final progressDataProvider = ProgressDataProvider._();

final class ProgressDataProvider
    extends $FunctionalProvider<ProgressData, ProgressData, ProgressData>
    with $Provider<ProgressData> {
  ProgressDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressDataHash();

  @$internal
  @override
  $ProviderElement<ProgressData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProgressData create(Ref ref) {
    return progressData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressData>(value),
    );
  }
}

String _$progressDataHash() => r'9686df848faa55786baf002f7cfe589bd89375b2';
