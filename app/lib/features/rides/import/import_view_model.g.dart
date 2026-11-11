// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Follows one import: asks the server until it is no longer processing, then
/// reloads the ride list so the new rides are there.

@ProviderFor(ImportViewModel)
final importViewModelProvider = ImportViewModelFamily._();

/// Follows one import: asks the server until it is no longer processing, then
/// reloads the ride list so the new rides are there.
final class ImportViewModelProvider
    extends $NotifierProvider<ImportViewModel, ImportState> {
  /// Follows one import: asks the server until it is no longer processing, then
  /// reloads the ride list so the new rides are there.
  ImportViewModelProvider._({
    required ImportViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'importViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$importViewModelHash();

  @override
  String toString() {
    return r'importViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ImportViewModel create() => ImportViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ImportViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$importViewModelHash() => r'84175d38ca8a65af475dd0bf6f1d9ff237a24244';

/// Follows one import: asks the server until it is no longer processing, then
/// reloads the ride list so the new rides are there.

final class ImportViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          ImportViewModel,
          ImportState,
          ImportState,
          ImportState,
          String
        > {
  ImportViewModelFamily._()
    : super(
        retry: null,
        name: r'importViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Follows one import: asks the server until it is no longer processing, then
  /// reloads the ride list so the new rides are there.

  ImportViewModelProvider call(String id) =>
      ImportViewModelProvider._(argument: id, from: this);

  @override
  String toString() => r'importViewModelProvider';
}

/// Follows one import: asks the server until it is no longer processing, then
/// reloads the ride list so the new rides are there.

abstract class _$ImportViewModel extends $Notifier<ImportState> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  ImportState build(String id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ImportState, ImportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ImportState, ImportState>,
              ImportState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
