// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where this phone's Velomine server is, kept on the device so it is asked for
/// once. The web app is served by the server itself, so it always uses its own
/// origin and never shows a setup screen.

@ProviderFor(ServerConfigViewModel)
final serverConfigViewModelProvider = ServerConfigViewModelProvider._();

/// Where this phone's Velomine server is, kept on the device so it is asked for
/// once. The web app is served by the server itself, so it always uses its own
/// origin and never shows a setup screen.
final class ServerConfigViewModelProvider
    extends $AsyncNotifierProvider<ServerConfigViewModel, ServerConfigState> {
  /// Where this phone's Velomine server is, kept on the device so it is asked for
  /// once. The web app is served by the server itself, so it always uses its own
  /// origin and never shows a setup screen.
  ServerConfigViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverConfigViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverConfigViewModelHash();

  @$internal
  @override
  ServerConfigViewModel create() => ServerConfigViewModel();
}

String _$serverConfigViewModelHash() =>
    r'a5172327b550b55407850a5a7af4a26f17f69701';

/// Where this phone's Velomine server is, kept on the device so it is asked for
/// once. The web app is served by the server itself, so it always uses its own
/// origin and never shows a setup screen.

abstract class _$ServerConfigViewModel
    extends $AsyncNotifier<ServerConfigState> {
  FutureOr<ServerConfigState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ServerConfigState>, ServerConfigState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ServerConfigState>, ServerConfigState>,
              AsyncValue<ServerConfigState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
