// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One session's page. The session is one of the week's, so the page reads the week the Training page already
/// loaded; the address works on its own too, because the week is loaded as soon as the plan is on.

@ProviderFor(SessionViewModel)
final sessionViewModelProvider = SessionViewModelFamily._();

/// One session's page. The session is one of the week's, so the page reads the week the Training page already
/// loaded; the address works on its own too, because the week is loaded as soon as the plan is on.
final class SessionViewModelProvider
    extends $NotifierProvider<SessionViewModel, SessionState> {
  /// One session's page. The session is one of the week's, so the page reads the week the Training page already
  /// loaded; the address works on its own too, because the week is loaded as soon as the plan is on.
  SessionViewModelProvider._({
    required SessionViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionViewModelHash();

  @override
  String toString() {
    return r'sessionViewModelProvider'
        ''
        '($argument)';
  }

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

  @override
  bool operator ==(Object other) {
    return other is SessionViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionViewModelHash() => r'5a58c72b24df4d5e6ca50eb87335300f36714364';

/// One session's page. The session is one of the week's, so the page reads the week the Training page already
/// loaded; the address works on its own too, because the week is loaded as soon as the plan is on.

final class SessionViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionViewModel,
          SessionState,
          SessionState,
          SessionState,
          String
        > {
  SessionViewModelFamily._()
    : super(
        retry: null,
        name: r'sessionViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One session's page. The session is one of the week's, so the page reads the week the Training page already
  /// loaded; the address works on its own too, because the week is loaded as soon as the plan is on.

  SessionViewModelProvider call(String id) =>
      SessionViewModelProvider._(argument: id, from: this);

  @override
  String toString() => r'sessionViewModelProvider';
}

/// One session's page. The session is one of the week's, so the page reads the week the Training page already
/// loaded; the address works on its own too, because the week is loaded as soon as the plan is on.

abstract class _$SessionViewModel extends $Notifier<SessionState> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  SessionState build(String id);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
