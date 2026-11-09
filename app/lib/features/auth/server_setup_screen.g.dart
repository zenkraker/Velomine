// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_setup_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Checks the typed address and saves it. The root then leaves this screen on
/// its own, because it watches the saved address.

@ProviderFor(ServerSetupViewModel)
final serverSetupViewModelProvider = ServerSetupViewModelProvider._();

/// Checks the typed address and saves it. The root then leaves this screen on
/// its own, because it watches the saved address.
final class ServerSetupViewModelProvider
    extends $NotifierProvider<ServerSetupViewModel, ServerSetupState> {
  /// Checks the typed address and saves it. The root then leaves this screen on
  /// its own, because it watches the saved address.
  ServerSetupViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverSetupViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverSetupViewModelHash();

  @$internal
  @override
  ServerSetupViewModel create() => ServerSetupViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerSetupState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerSetupState>(value),
    );
  }
}

String _$serverSetupViewModelHash() =>
    r'53a4dc74df50d4b1a4bfd2846671f187dbb2e469';

/// Checks the typed address and saves it. The root then leaves this screen on
/// its own, because it watches the saved address.

abstract class _$ServerSetupViewModel extends $Notifier<ServerSetupState> {
  ServerSetupState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ServerSetupState, ServerSetupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ServerSetupState, ServerSetupState>,
              ServerSetupState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
