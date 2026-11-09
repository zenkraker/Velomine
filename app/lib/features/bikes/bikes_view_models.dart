import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:velomine_api/api.dart';

import '../../core/failure.dart';
import '../../core/providers.dart';
import '../../core/result.dart';
import '../../core/user_message.dart';
import 'bikes_data.dart';
import 'bikes_state.dart';

part 'bikes_view_models.g.dart';

/// The member's bikes and adding one.
@Riverpod(keepAlive: true)
class BikesViewModel extends _$BikesViewModel {
  int _messageId = 0;

  @override
  BikesState build() {
    if (ref.watch(signedInUserIdProvider) == null) return const BikesState();
    Future.microtask(refresh);
    return const BikesState();
  }

  Future<void> refresh() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final result = await ref.read(bikesDataProvider).list();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => state.copyWith(
        load: state.load.finish(result),
        bikes: value,
      ),
      Failed() => state.copyWith(load: state.load.finish(result)),
    };
  }

  /// Returns the new bike's id, or null when a message says why.
  Future<String?> add(CreateBikeRequest bike) async {
    if (state.action.running) return null;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(bikesDataProvider).create(bike);
    if (!ref.mounted) return null;
    if (result case Failed(:final failure)) {
      state = state.copyWith(action: state.action.finish(result));
      _fail(failure);
      return null;
    }
    state = state.copyWith(action: state.action.finish(result));
    await refresh();
    return result.valueOrNull;
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}

/// One bike: editing it and its parts, and applying a template. Route-scoped,
/// so it lives exactly as long as the detail screen.
@riverpod
class BikeDetailViewModel extends _$BikeDetailViewModel {
  int _messageId = 0;

  @override
  BikeDetailState build(String id) {
    Future.microtask(load);
    return const BikeDetailState();
  }

  Future<void> load() async {
    if (state.load.running) return;
    state = state.copyWith(load: state.load.start());
    final data = ref.read(bikesDataProvider);

    final bikeResult = await data.bike(id);
    if (!ref.mounted) return;
    if (bikeResult case Failed(:final failure)) {
      if (failure.kind == FailureKind.missing) {
        state = state.copyWith(
          load: state.load.finish(const Ok(null)),
          notFound: true,
        );
        return;
      }
      state = state.copyWith(load: state.load.finish(bikeResult));
      return;
    }

    final types = await data.types();
    final templates = (await data.templates()).valueOrNull ?? const [];
    if (!ref.mounted) return;
    state = BikeDetailState(
      detail: bikeResult.valueOrNull,
      types: types.valueOrNull ?? const [],
      templates: templates,
      load: types.isOk
          ? state.load.finish(bikeResult)
          : state.load.finish(Failed(types.failureOrNull!)),
      messages: state.messages,
    );
  }

  Future<bool> save(UpdateBikeRequest bike) =>
      _change(() => ref.read(bikesDataProvider).update(id, bike));

  /// Archiving keeps the rides and the history; the bike just stops being
  /// offered for new rides.
  Future<bool> setActive(bool active) {
    final bike = state.detail!.bike;
    return save(
      UpdateBikeRequest(
        name: bike.name,
        brand: Optional.present(bike.brand),
        model: Optional.present(bike.model),
        modelYear: Optional.present(bike.modelYear),
        buildSpec: Optional.present(bike.buildSpec),
        frameSize: Optional.present(bike.frameSize),
        kind: bike.kind,
        wheelCircumferenceMm: bike.wheelCircumferenceMm,
        initialDistanceM: bike.initialDistanceM,
        purchasedOn: Optional.present(bike.purchasedOn),
        isActive: Optional.present(active),
      ),
    );
  }

  Future<bool> makeDefault() async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(bikesDataProvider).makeDefault(id);
    if (!ref.mounted) return false;
    if (result case Failed(:final failure)) {
      state = state.copyWith(action: state.action.finish(result));
      _fail(failure);
      return false;
    }
    state = state.copyWith(action: state.action.finish(result));
    await load();
    return true;
  }

  Future<bool> delete() async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(bikesDataProvider).delete(id);
    if (!ref.mounted) return false;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return false;
    }
    return true;
  }

  Future<bool> addPart(CreateComponentRequest part) =>
      _change(() => ref.read(bikesDataProvider).addPart(id, part));

  Future<bool> editPart(String partId, UpdateComponentRequest part) =>
      _change(() => ref.read(bikesDataProvider).editPart(id, partId, part));

  Future<bool> removePart(String partId) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(bikesDataProvider).removePart(id, partId);
    if (!ref.mounted) return false;
    if (result case Failed(:final failure)) {
      state = state.copyWith(action: state.action.finish(result));
      _fail(failure);
      return false;
    }
    state = state.copyWith(action: state.action.finish(result));
    await load();
    return true;
  }

  /// Copies the parts currently fitted to this bike into a reusable template.
  Future<bool> saveTemplateFromBike(String name) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await ref.read(bikesDataProvider).saveTemplate(id, name);
    if (!ref.mounted) return false;
    if (result case Failed(:final failure)) {
      state = state.copyWith(action: state.action.finish(result));
      _fail(failure);
      return false;
    }
    final saved = result.valueOrNull;
    state = state.copyWith(
      action: state.action.finish(result),
      templates: saved == null
          ? state.templates
          : ([...state.templates, saved]..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            )),
    );
    return true;
  }

  /// Fills the bike with the template's parts, leaving alone any kind of part
  /// it already has.
  Future<bool> applyTemplate(String templateId) => _change(
    () => ref.read(bikesDataProvider).applyTemplate(id, templateId, _today()),
  );

  /// Takes the old part off today and fits [replacement].
  Future<bool> replacePart(
    ComponentResponse old,
    CreateComponentRequest replacement,
  ) async {
    final today = _today();
    final retired = await editPart(
      old.id,
      UpdateComponentRequest(
        type: old.type,
        brand: Optional.present(old.brand),
        model: Optional.present(old.model),
        installedOn: old.installedOn,
        removedOn: Optional.present(today),
        expectedDistanceM: Optional.present(old.expectedDistanceM),
        expectedHours: Optional.present(old.expectedHours),
        expectedMonths: Optional.present(old.expectedMonths),
      ),
    );
    return retired && await addPart(replacement);
  }

  /// Waits for a pause in typing before asking the server, and ignores answers
  /// that arrive after a newer keystroke.
  int _searchSeq = 0;

  /// The parts this club has used before, for the "find a known part" field.
  Future<List<PartResponse>> searchParts(String query, String? type) async {
    final seq = ++_searchSeq;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (seq != _searchSeq || !ref.mounted) return const [];
    final result = await ref.read(bikesDataProvider).searchParts(query, type);
    if (seq != _searchSeq || !ref.mounted) return const [];
    return result.valueOrNull ?? const [];
  }

  void messageShown(int id) => state = state.copyWith(
    messages: [
      for (final message in state.messages)
        if (message.id != id) message,
    ],
  );

  Future<bool> _change(
    Future<Result<BikeDetailResponse?>> Function() call,
  ) async {
    if (state.action.running) return false;
    state = state.copyWith(action: state.action.start());
    final result = await call();
    if (!ref.mounted) return false;
    state = state.copyWith(action: state.action.finish(result));
    if (result case Failed(:final failure)) {
      _fail(failure);
      return false;
    }
    final detail = result.valueOrNull;
    if (detail != null) state = state.copyWith(detail: detail);
    return true;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _fail(Failure failure) => state = state.copyWith(
    messages: [...state.messages, FailureMessage(_messageId++, failure)],
  );
}
