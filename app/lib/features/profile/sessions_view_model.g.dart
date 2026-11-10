// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sessions_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where the member is signed in. Route-scoped: a fresh list each visit.

@ProviderFor(SessionsViewModel)
final sessionsViewModelProvider = SessionsViewModelProvider._();

/// Where the member is signed in. Route-scoped: a fresh list each visit.
final class SessionsViewModelProvider
    extends $NotifierProvider<SessionsViewModel, SessionsState> {
  /// Where the member is signed in. Route-scoped: a fresh list each visit.
  SessionsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionsViewModelHash();

  @$internal
  @override
  SessionsViewModel create() => SessionsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionsState>(value),
    );
  }
}

String _$sessionsViewModelHash() => r'b5be23b2497413ee3aafdb57c3a503fed362bf47';

/// Where the member is signed in. Route-scoped: a fresh list each visit.

abstract class _$SessionsViewModel extends $Notifier<SessionsState> {
  SessionsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SessionsState, SessionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionsState, SessionsState>,
              SessionsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
