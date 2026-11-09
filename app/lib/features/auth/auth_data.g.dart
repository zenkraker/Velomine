// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authData)
final authDataProvider = AuthDataProvider._();

final class AuthDataProvider
    extends $FunctionalProvider<AuthData, AuthData, AuthData>
    with $Provider<AuthData> {
  AuthDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authDataHash();

  @$internal
  @override
  $ProviderElement<AuthData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthData create(Ref ref) {
    return authData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthData>(value),
    );
  }
}

String _$authDataHash() => r'586eb2d160c150d723db735af062b5d63ff1987c';
