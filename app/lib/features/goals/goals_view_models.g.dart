// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_view_models.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The member's goals: read on open, and the add, change and delete the Goals page makes.

@ProviderFor(GoalsViewModel)
final goalsViewModelProvider = GoalsViewModelProvider._();

/// The member's goals: read on open, and the add, change and delete the Goals page makes.
final class GoalsViewModelProvider
    extends $NotifierProvider<GoalsViewModel, GoalsState> {
  /// The member's goals: read on open, and the add, change and delete the Goals page makes.
  GoalsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalsViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalsViewModelHash();

  @$internal
  @override
  GoalsViewModel create() => GoalsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalsState>(value),
    );
  }
}

String _$goalsViewModelHash() => r'4d4fde365cfb1b46bc4be64a483f8034029c22f5';

/// The member's goals: read on open, and the add, change and delete the Goals page makes.

abstract class _$GoalsViewModel extends $Notifier<GoalsState> {
  GoalsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GoalsState, GoalsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoalsState, GoalsState>,
              GoalsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
