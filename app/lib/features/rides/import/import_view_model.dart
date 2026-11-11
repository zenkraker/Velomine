import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../../core/result.dart';
import '../rides_data.dart';
import '../rides_view_model.dart';
import 'import_state.dart';

part 'import_view_model.g.dart';

/// Follows one import: asks the server until it is no longer processing, then
/// reloads the ride list so the new rides are there.
@riverpod
class ImportViewModel extends _$ImportViewModel {
  String? _id;

  @override
  ImportState build(String id) {
    _id = id;
    Future.microtask(_poll);
    return const ImportState();
  }

  Future<void> retry() async {
    if (state.load.running) return;
    await _poll();
  }

  Future<void> _poll() async {
    final id = _id;
    if (id == null || state.load.running) return;

    state = state.copyWith(load: state.load.start());
    while (ref.mounted) {
      final result = await ref.read(ridesDataProvider).importStatus(id);
      if (!ref.mounted) return;
      state = state.copyWith(load: state.load.finish(result));

      final status = result.valueOrNull;
      if (result case Failed()) return;
      if (status == null || status.status != 'processing') {
        if (status != null) ref.invalidate(ridesViewModelProvider);
        return;
      }

      await Future<void>.delayed(ref.read(importPollIntervalProvider));
    }
  }
}
