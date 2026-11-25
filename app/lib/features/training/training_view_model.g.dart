// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The member's auto-training plan and week for the session: the shell reads the plan to show the Training
/// destination, the profile for its switch, the Training page for today and the week, and Progress for its Today
/// strip. A sign-out rebuilds it empty.

@ProviderFor(TrainingViewModel)
final trainingViewModelProvider = TrainingViewModelProvider._();

/// The member's auto-training plan and week for the session: the shell reads the plan to show the Training
/// destination, the profile for its switch, the Training page for today and the week, and Progress for its Today
/// strip. A sign-out rebuilds it empty.
final class TrainingViewModelProvider
    extends $NotifierProvider<TrainingViewModel, TrainingState> {
  /// The member's auto-training plan and week for the session: the shell reads the plan to show the Training
  /// destination, the profile for its switch, the Training page for today and the week, and Progress for its Today
  /// strip. A sign-out rebuilds it empty.
  TrainingViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trainingViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trainingViewModelHash();

  @$internal
  @override
  TrainingViewModel create() => TrainingViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrainingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrainingState>(value),
    );
  }
}

String _$trainingViewModelHash() => r'295714fcdf2322baeff0892cf81525182cbfaa30';

/// The member's auto-training plan and week for the session: the shell reads the plan to show the Training
/// destination, the profile for its switch, the Training page for today and the week, and Progress for its Today
/// strip. A sign-out rebuilds it empty.

abstract class _$TrainingViewModel extends $Notifier<TrainingState> {
  TrainingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TrainingState, TrainingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TrainingState, TrainingState>,
              TrainingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
