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

String _$totalsViewModelHash() => r'12cb9396b0b2de3b56ee86740ed66d6799316d10';

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

String _$goalsViewModelHash() => r'4d4fde365cfb1b46bc4be64a483f8034029c22f5';

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

String _$trainingViewModelHash() => r'677e10863de1610597f551f804cb2a2ddaa7816b';

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
    r'b3617818e8a43d2db2e040d72147a7d6c200926d';

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

@ProviderFor(FtpReminderViewModel)
final ftpReminderViewModelProvider = FtpReminderViewModelProvider._();

final class FtpReminderViewModelProvider
    extends $NotifierProvider<FtpReminderViewModel, FtpReminderState> {
  FtpReminderViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ftpReminderViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ftpReminderViewModelHash();

  @$internal
  @override
  FtpReminderViewModel create() => FtpReminderViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FtpReminderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FtpReminderState>(value),
    );
  }
}

String _$ftpReminderViewModelHash() =>
    r'4dba306cef778a3cea24428883024289f9cb4cff';

abstract class _$FtpReminderViewModel extends $Notifier<FtpReminderState> {
  FtpReminderState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FtpReminderState, FtpReminderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FtpReminderState, FtpReminderState>,
              FtpReminderState,
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
    r'082da647cd7cb9ff29ea9920bbca1b44291d2abb';

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

/// The open heart-rate suggestions, each above the value the rider typed. The profile says what each is above.

@ProviderFor(HeartRateSuggestionViewModel)
final heartRateSuggestionViewModelProvider =
    HeartRateSuggestionViewModelProvider._();

/// The open heart-rate suggestions, each above the value the rider typed. The profile says what each is above.
final class HeartRateSuggestionViewModelProvider
    extends
        $NotifierProvider<
          HeartRateSuggestionViewModel,
          HeartRateSuggestionState
        > {
  /// The open heart-rate suggestions, each above the value the rider typed. The profile says what each is above.
  HeartRateSuggestionViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'heartRateSuggestionViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$heartRateSuggestionViewModelHash();

  @$internal
  @override
  HeartRateSuggestionViewModel create() => HeartRateSuggestionViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HeartRateSuggestionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HeartRateSuggestionState>(value),
    );
  }
}

String _$heartRateSuggestionViewModelHash() =>
    r'18dfe400e4b5c970971c1088e7eae3e9547e32e9';

/// The open heart-rate suggestions, each above the value the rider typed. The profile says what each is above.

abstract class _$HeartRateSuggestionViewModel
    extends $Notifier<HeartRateSuggestionState> {
  HeartRateSuggestionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<HeartRateSuggestionState, HeartRateSuggestionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HeartRateSuggestionState, HeartRateSuggestionState>,
              HeartRateSuggestionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The events the rider is training for. A change reloads the list, so the card and the list agree.

@ProviderFor(EventsViewModel)
final eventsViewModelProvider = EventsViewModelProvider._();

/// The events the rider is training for. A change reloads the list, so the card and the list agree.
final class EventsViewModelProvider
    extends $NotifierProvider<EventsViewModel, EventsState> {
  /// The events the rider is training for. A change reloads the list, so the card and the list agree.
  EventsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventsViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventsViewModelHash();

  @$internal
  @override
  EventsViewModel create() => EventsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventsState>(value),
    );
  }
}

String _$eventsViewModelHash() => r'764f419610793f23fe3753035a65d8a745461ae7';

/// The events the rider is training for. A change reloads the list, so the card and the list agree.

abstract class _$EventsViewModel extends $Notifier<EventsState> {
  EventsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EventsState, EventsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EventsState, EventsState>,
              EventsState,
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
    r'afcce6f28be44df7cb4850674493682b7cdeefbf';

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
