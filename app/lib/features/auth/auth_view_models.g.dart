// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_view_models.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The sign-in form. Route-scoped: it holds one attempt, not the session.

@ProviderFor(SignInViewModel)
final signInViewModelProvider = SignInViewModelProvider._();

/// The sign-in form. Route-scoped: it holds one attempt, not the session.
final class SignInViewModelProvider
    extends $NotifierProvider<SignInViewModel, SignInState> {
  /// The sign-in form. Route-scoped: it holds one attempt, not the session.
  SignInViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInViewModelHash();

  @$internal
  @override
  SignInViewModel create() => SignInViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInState>(value),
    );
  }
}

String _$signInViewModelHash() => r'907ba2eec896bec46c5ccfed7c8f91484b344c50';

/// The sign-in form. Route-scoped: it holds one attempt, not the session.

abstract class _$SignInViewModel extends $Notifier<SignInState> {
  SignInState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SignInState, SignInState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SignInState, SignInState>,
              SignInState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The sign-up form.

@ProviderFor(RegisterViewModel)
final registerViewModelProvider = RegisterViewModelProvider._();

/// The sign-up form.
final class RegisterViewModelProvider
    extends $NotifierProvider<RegisterViewModel, RegisterState> {
  /// The sign-up form.
  RegisterViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registerViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registerViewModelHash();

  @$internal
  @override
  RegisterViewModel create() => RegisterViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegisterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegisterState>(value),
    );
  }
}

String _$registerViewModelHash() => r'0daf8f8db467f0ed0c99a3b6de088c87ca04cb93';

/// The sign-up form.

abstract class _$RegisterViewModel extends $Notifier<RegisterState> {
  RegisterState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RegisterState, RegisterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RegisterState, RegisterState>,
              RegisterState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Asking for a password-reset link.

@ProviderFor(ForgotPasswordViewModel)
final forgotPasswordViewModelProvider = ForgotPasswordViewModelProvider._();

/// Asking for a password-reset link.
final class ForgotPasswordViewModelProvider
    extends $NotifierProvider<ForgotPasswordViewModel, ForgotState> {
  /// Asking for a password-reset link.
  ForgotPasswordViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'forgotPasswordViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$forgotPasswordViewModelHash();

  @$internal
  @override
  ForgotPasswordViewModel create() => ForgotPasswordViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ForgotState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ForgotState>(value),
    );
  }
}

String _$forgotPasswordViewModelHash() =>
    r'0059fd1427a6abd860833c8500eccf126401de30';

/// Asking for a password-reset link.

abstract class _$ForgotPasswordViewModel extends $Notifier<ForgotState> {
  ForgotState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ForgotState, ForgotState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ForgotState, ForgotState>,
              ForgotState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Choosing a new password from the one-time link.

@ProviderFor(ResetPasswordViewModel)
final resetPasswordViewModelProvider = ResetPasswordViewModelProvider._();

/// Choosing a new password from the one-time link.
final class ResetPasswordViewModelProvider
    extends $NotifierProvider<ResetPasswordViewModel, ResetState> {
  /// Choosing a new password from the one-time link.
  ResetPasswordViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resetPasswordViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resetPasswordViewModelHash();

  @$internal
  @override
  ResetPasswordViewModel create() => ResetPasswordViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResetState>(value),
    );
  }
}

String _$resetPasswordViewModelHash() =>
    r'3ed515f94a7e2550d96b1876d437e9b623662686';

/// Choosing a new password from the one-time link.

abstract class _$ResetPasswordViewModel extends $Notifier<ResetState> {
  ResetState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ResetState, ResetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ResetState, ResetState>,
              ResetState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
