// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(trainingData)
final trainingDataProvider = TrainingDataProvider._();

final class TrainingDataProvider
    extends $FunctionalProvider<TrainingData, TrainingData, TrainingData>
    with $Provider<TrainingData> {
  TrainingDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trainingDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trainingDataHash();

  @$internal
  @override
  $ProviderElement<TrainingData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TrainingData create(Ref ref) {
    return trainingData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrainingData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrainingData>(value),
    );
  }
}

String _$trainingDataHash() => r'3d7d61ad92ce42a95063e42ba6eeb4d96140a974';
