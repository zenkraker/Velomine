// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_mark_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the "Saved." badge shows. A screen that saved something calls [show]; the badge goes by itself after
/// [shownFor], or at once on [hide] (a save that failed).

@ProviderFor(SavedMarkViewModel)
final savedMarkViewModelProvider = SavedMarkViewModelProvider._();

/// Whether the "Saved." badge shows. A screen that saved something calls [show]; the badge goes by itself after
/// [shownFor], or at once on [hide] (a save that failed).
final class SavedMarkViewModelProvider
    extends $NotifierProvider<SavedMarkViewModel, bool> {
  /// Whether the "Saved." badge shows. A screen that saved something calls [show]; the badge goes by itself after
  /// [shownFor], or at once on [hide] (a save that failed).
  SavedMarkViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedMarkViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedMarkViewModelHash();

  @$internal
  @override
  SavedMarkViewModel create() => SavedMarkViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$savedMarkViewModelHash() =>
    r'ac6f6423ec296031ce6f294cd1a70851373c362f';

/// Whether the "Saved." badge shows. A screen that saved something calls [show]; the badge goes by itself after
/// [shownFor], or at once on [hide] (a save that failed).

abstract class _$SavedMarkViewModel extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
