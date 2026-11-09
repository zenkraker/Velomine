// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sso_callback_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Trades the one-time code for a session. True means it failed and the screen
/// must go back to sign-in with the reason showing there.

@ProviderFor(SsoCallbackViewModel)
final ssoCallbackViewModelProvider = SsoCallbackViewModelFamily._();

/// Trades the one-time code for a session. True means it failed and the screen
/// must go back to sign-in with the reason showing there.
final class SsoCallbackViewModelProvider
    extends $NotifierProvider<SsoCallbackViewModel, bool> {
  /// Trades the one-time code for a session. True means it failed and the screen
  /// must go back to sign-in with the reason showing there.
  SsoCallbackViewModelProvider._({
    required SsoCallbackViewModelFamily super.from,
    required SsoCallbackArgs super.argument,
  }) : super(
         retry: null,
         name: r'ssoCallbackViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ssoCallbackViewModelHash();

  @override
  String toString() {
    return r'ssoCallbackViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SsoCallbackViewModel create() => SsoCallbackViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SsoCallbackViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ssoCallbackViewModelHash() =>
    r'200f06e8b862c689d1f99ca915036c24030b3b53';

/// Trades the one-time code for a session. True means it failed and the screen
/// must go back to sign-in with the reason showing there.

final class SsoCallbackViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          SsoCallbackViewModel,
          bool,
          bool,
          bool,
          SsoCallbackArgs
        > {
  SsoCallbackViewModelFamily._()
    : super(
        retry: null,
        name: r'ssoCallbackViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Trades the one-time code for a session. True means it failed and the screen
  /// must go back to sign-in with the reason showing there.

  SsoCallbackViewModelProvider call(SsoCallbackArgs args) =>
      SsoCallbackViewModelProvider._(argument: args, from: this);

  @override
  String toString() => r'ssoCallbackViewModelProvider';
}

/// Trades the one-time code for a session. True means it failed and the screen
/// must go back to sign-in with the reason showing there.

abstract class _$SsoCallbackViewModel extends $Notifier<bool> {
  late final _$args = ref.$arg as SsoCallbackArgs;
  SsoCallbackArgs get args => _$args;

  bool build(SsoCallbackArgs args);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
