// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_athletes_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The athletes in this club who share rides or training.

@ProviderFor(CoachAthletesViewModel)
final coachAthletesViewModelProvider = CoachAthletesViewModelFamily._();

/// The athletes in this club who share rides or training.
final class CoachAthletesViewModelProvider
    extends $NotifierProvider<CoachAthletesViewModel, CoachAthletesState> {
  /// The athletes in this club who share rides or training.
  CoachAthletesViewModelProvider._({
    required CoachAthletesViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'coachAthletesViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coachAthletesViewModelHash();

  @override
  String toString() {
    return r'coachAthletesViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CoachAthletesViewModel create() => CoachAthletesViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachAthletesState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachAthletesState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CoachAthletesViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coachAthletesViewModelHash() =>
    r'390d0d8250f8e6e3578908f705fe1731f83403d2';

/// The athletes in this club who share rides or training.

final class CoachAthletesViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          CoachAthletesViewModel,
          CoachAthletesState,
          CoachAthletesState,
          CoachAthletesState,
          String
        > {
  CoachAthletesViewModelFamily._()
    : super(
        retry: null,
        name: r'coachAthletesViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The athletes in this club who share rides or training.

  CoachAthletesViewModelProvider call(String clubId) =>
      CoachAthletesViewModelProvider._(argument: clubId, from: this);

  @override
  String toString() => r'coachAthletesViewModelProvider';
}

/// The athletes in this club who share rides or training.

abstract class _$CoachAthletesViewModel extends $Notifier<CoachAthletesState> {
  late final _$args = ref.$arg as String;
  String get clubId => _$args;

  CoachAthletesState build(String clubId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CoachAthletesState, CoachAthletesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CoachAthletesState, CoachAthletesState>,
              CoachAthletesState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
