// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_athlete_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One athlete: the shared summary, training load, power curve, wellbeing and rides.

@ProviderFor(CoachAthleteViewModel)
final coachAthleteViewModelProvider = CoachAthleteViewModelFamily._();

/// One athlete: the shared summary, training load, power curve, wellbeing and rides.
final class CoachAthleteViewModelProvider
    extends $NotifierProvider<CoachAthleteViewModel, CoachAthleteState> {
  /// One athlete: the shared summary, training load, power curve, wellbeing and rides.
  CoachAthleteViewModelProvider._({
    required CoachAthleteViewModelFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'coachAthleteViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coachAthleteViewModelHash();

  @override
  String toString() {
    return r'coachAthleteViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CoachAthleteViewModel create() => CoachAthleteViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachAthleteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachAthleteState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CoachAthleteViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coachAthleteViewModelHash() =>
    r'a232df2efaf185fe179e82b043e0e5891d730f07';

/// One athlete: the shared summary, training load, power curve, wellbeing and rides.

final class CoachAthleteViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          CoachAthleteViewModel,
          CoachAthleteState,
          CoachAthleteState,
          CoachAthleteState,
          (String, String)
        > {
  CoachAthleteViewModelFamily._()
    : super(
        retry: null,
        name: r'coachAthleteViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One athlete: the shared summary, training load, power curve, wellbeing and rides.

  CoachAthleteViewModelProvider call(String clubId, String userId) =>
      CoachAthleteViewModelProvider._(argument: (clubId, userId), from: this);

  @override
  String toString() => r'coachAthleteViewModelProvider';
}

/// One athlete: the shared summary, training load, power curve, wellbeing and rides.

abstract class _$CoachAthleteViewModel extends $Notifier<CoachAthleteState> {
  late final _$args = ref.$arg as (String, String);
  String get clubId => _$args.$1;
  String get userId => _$args.$2;

  CoachAthleteState build(String clubId, String userId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CoachAthleteState, CoachAthleteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CoachAthleteState, CoachAthleteState>,
              CoachAthleteState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
