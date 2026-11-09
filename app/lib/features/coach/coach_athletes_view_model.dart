import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/result.dart';
import 'coach_data.dart';
import 'coach_state.dart';

part 'coach_athletes_view_model.g.dart';

/// The athletes in this club who share rides or training.
@riverpod
class CoachAthletesViewModel extends _$CoachAthletesViewModel {
  @override
  CoachAthletesState build(String clubId) {
    Future.microtask(refresh);
    return const CoachAthletesState();
  }

  Future<void> refresh() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(coachDataProvider).athletes(clubId);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        athletes: value?.athletes ?? const [],
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }
}
