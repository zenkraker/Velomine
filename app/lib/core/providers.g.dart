// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The session for the chosen server. A new address rebuilds it, and with it
/// every ViewModel that holds member data.

@ProviderFor(session)
final sessionProvider = SessionProvider._();

/// The session for the chosen server. A new address rebuilds it, and with it
/// every ViewModel that holds member data.

final class SessionProvider
    extends $FunctionalProvider<Session, Session, Session>
    with $Provider<Session> {
  /// The session for the chosen server. A new address rebuilds it, and with it
  /// every ViewModel that holds member data.
  SessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionHash();

  @$internal
  @override
  $ProviderElement<Session> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Session create(Ref ref) {
    return session(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Session value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Session>(value),
    );
  }
}

String _$sessionHash() => r'55b1b63cd2e3c890554eb08135b9a8b058e7af5e';

/// The session's reactive state: status, member, server details and the reason
/// a sign-in did not work. It mirrors [Session.states] into Riverpod.

@ProviderFor(SessionViewModel)
final sessionViewModelProvider = SessionViewModelProvider._();

/// The session's reactive state: status, member, server details and the reason
/// a sign-in did not work. It mirrors [Session.states] into Riverpod.
final class SessionViewModelProvider
    extends $NotifierProvider<SessionViewModel, SessionState> {
  /// The session's reactive state: status, member, server details and the reason
  /// a sign-in did not work. It mirrors [Session.states] into Riverpod.
  SessionViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionViewModelHash();

  @$internal
  @override
  SessionViewModel create() => SessionViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionState>(value),
    );
  }
}

String _$sessionViewModelHash() => r'91fb061f1b7163fe3a7639103447bc68216094d4';

/// The session's reactive state: status, member, server details and the reason
/// a sign-in did not work. It mirrors [Session.states] into Riverpod.

abstract class _$SessionViewModel extends $Notifier<SessionState> {
  SessionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SessionState, SessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SessionState, SessionState>,
              SessionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
