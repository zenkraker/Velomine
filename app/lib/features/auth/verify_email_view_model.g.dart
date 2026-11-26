// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_email_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VerifyEmailViewModel)
final verifyEmailViewModelProvider = VerifyEmailViewModelProvider._();

final class VerifyEmailViewModelProvider
    extends $NotifierProvider<VerifyEmailViewModel, VerifyEmailState> {
  VerifyEmailViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifyEmailViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifyEmailViewModelHash();

  @$internal
  @override
  VerifyEmailViewModel create() => VerifyEmailViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerifyEmailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerifyEmailState>(value),
    );
  }
}

String _$verifyEmailViewModelHash() =>
    r'eb1b1233d1a1ccb1c8794f4fd1ed300e40803d37';

abstract class _$VerifyEmailViewModel extends $Notifier<VerifyEmailState> {
  VerifyEmailState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VerifyEmailState, VerifyEmailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<VerifyEmailState, VerifyEmailState>,
              VerifyEmailState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
