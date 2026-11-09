// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_view_models.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The period, discipline and ranges the progress page shows. Kept alive so the
/// choice follows the member between visits.

@ProviderFor(ProgressFiltersViewModel)
final progressFiltersViewModelProvider = ProgressFiltersViewModelProvider._();

/// The period, discipline and ranges the progress page shows. Kept alive so the
/// choice follows the member between visits.
final class ProgressFiltersViewModelProvider
    extends $NotifierProvider<ProgressFiltersViewModel, ProgressFiltersState> {
  /// The period, discipline and ranges the progress page shows. Kept alive so the
  /// choice follows the member between visits.
  ProgressFiltersViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'progressFiltersViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$progressFiltersViewModelHash();

  @$internal
  @override
  ProgressFiltersViewModel create() => ProgressFiltersViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgressFiltersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgressFiltersState>(value),
    );
  }
}

String _$progressFiltersViewModelHash() =>
    r'ea1a4cacb9ecca466164b0bf98f04f039cf0c391';

/// The period, discipline and ranges the progress page shows. Kept alive so the
/// choice follows the member between visits.

abstract class _$ProgressFiltersViewModel
    extends $Notifier<ProgressFiltersState> {
  ProgressFiltersState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProgressFiltersState, ProgressFiltersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProgressFiltersState, ProgressFiltersState>,
              ProgressFiltersState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(TotalsViewModel)
final totalsViewModelProvider = TotalsViewModelProvider._();

final class TotalsViewModelProvider
    extends $NotifierProvider<TotalsViewModel, TotalsState> {
  TotalsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalsViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalsViewModelHash();

  @$internal
  @override
  TotalsViewModel create() => TotalsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TotalsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TotalsState>(value),
    );
  }
}

String _$totalsViewModelHash() => r'8d193f2330e4cda1ab8e85d46e146cf0ccb05ccb';

abstract class _$TotalsViewModel extends $Notifier<TotalsState> {
  TotalsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TotalsState, TotalsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TotalsState, TotalsState>,
              TotalsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(GoalsViewModel)
final goalsViewModelProvider = GoalsViewModelProvider._();

final class GoalsViewModelProvider
    extends $NotifierProvider<GoalsViewModel, GoalsState> {
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

String _$goalsViewModelHash() => r'5875c34ca46c8f22154a491a1fe6300f08e9d207';

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

@ProviderFor(TrainingViewModel)
final trainingViewModelProvider = TrainingViewModelProvider._();

final class TrainingViewModelProvider
    extends $NotifierProvider<TrainingViewModel, TrainingState> {
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

String _$trainingViewModelHash() => r'abda001d0f35a61ab51abc5e91ac6c4c67933857';

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

@ProviderFor(PowerCurveViewModel)
final powerCurveViewModelProvider = PowerCurveViewModelProvider._();

final class PowerCurveViewModelProvider
    extends $NotifierProvider<PowerCurveViewModel, PowerState> {
  PowerCurveViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'powerCurveViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$powerCurveViewModelHash();

  @$internal
  @override
  PowerCurveViewModel create() => PowerCurveViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PowerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PowerState>(value),
    );
  }
}

String _$powerCurveViewModelHash() =>
    r'2956d723977bca4af053abf021c98b693428a74b';

abstract class _$PowerCurveViewModel extends $Notifier<PowerState> {
  PowerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PowerState, PowerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PowerState, PowerState>,
              PowerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ReadinessViewModel)
final readinessViewModelProvider = ReadinessViewModelProvider._();

final class ReadinessViewModelProvider
    extends $NotifierProvider<ReadinessViewModel, ReadinessState> {
  ReadinessViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'readinessViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$readinessViewModelHash();

  @$internal
  @override
  ReadinessViewModel create() => ReadinessViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReadinessState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReadinessState>(value),
    );
  }
}

String _$readinessViewModelHash() =>
    r'977a3e0174369c1a22107d5dad39a18f694a07ca';

abstract class _$ReadinessViewModel extends $Notifier<ReadinessState> {
  ReadinessState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ReadinessState, ReadinessState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReadinessState, ReadinessState>,
              ReadinessState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(WellbeingViewModel)
final wellbeingViewModelProvider = WellbeingViewModelProvider._();

final class WellbeingViewModelProvider
    extends $NotifierProvider<WellbeingViewModel, WellbeingState> {
  WellbeingViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wellbeingViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wellbeingViewModelHash();

  @$internal
  @override
  WellbeingViewModel create() => WellbeingViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WellbeingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WellbeingState>(value),
    );
  }
}

String _$wellbeingViewModelHash() =>
    r'641bbc696c14f0e6adc09451212c9524fe9189e4';

abstract class _$WellbeingViewModel extends $Notifier<WellbeingState> {
  WellbeingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<WellbeingState, WellbeingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WellbeingState, WellbeingState>,
              WellbeingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
