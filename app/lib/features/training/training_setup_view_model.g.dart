// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_setup_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The setup the rider answers to start auto training, and to change it later. It opens pre-filled from the plan;
/// Start saves it, and a typed maximum goes through the account's heart-rate rules on the server.

@ProviderFor(TrainingSetupViewModel)
final trainingSetupViewModelProvider = TrainingSetupViewModelProvider._();

/// The setup the rider answers to start auto training, and to change it later. It opens pre-filled from the plan;
/// Start saves it, and a typed maximum goes through the account's heart-rate rules on the server.
final class TrainingSetupViewModelProvider
    extends $NotifierProvider<TrainingSetupViewModel, TrainingSetupState> {
  /// The setup the rider answers to start auto training, and to change it later. It opens pre-filled from the plan;
  /// Start saves it, and a typed maximum goes through the account's heart-rate rules on the server.
  TrainingSetupViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trainingSetupViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trainingSetupViewModelHash();

  @$internal
  @override
  TrainingSetupViewModel create() => TrainingSetupViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrainingSetupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrainingSetupState>(value),
    );
  }
}

String _$trainingSetupViewModelHash() =>
    r'67b0d4df8f8985748c32b4b3e8406f93114e2a8a';

/// The setup the rider answers to start auto training, and to change it later. It opens pre-filled from the plan;
/// Start saves it, and a typed maximum goes through the account's heart-rate rules on the server.

abstract class _$TrainingSetupViewModel extends $Notifier<TrainingSetupState> {
  TrainingSetupState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TrainingSetupState, TrainingSetupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TrainingSetupState, TrainingSetupState>,
              TrainingSetupState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
