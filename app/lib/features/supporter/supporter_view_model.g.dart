// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supporter_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The member's supporter licence. Kept alive for the session; a sign-out
/// rebuilds it empty, so the next account never sees the last one's badge.

@ProviderFor(SupporterViewModel)
final supporterViewModelProvider = SupporterViewModelProvider._();

/// The member's supporter licence. Kept alive for the session; a sign-out
/// rebuilds it empty, so the next account never sees the last one's badge.
final class SupporterViewModelProvider
    extends $NotifierProvider<SupporterViewModel, SupporterState> {
  /// The member's supporter licence. Kept alive for the session; a sign-out
  /// rebuilds it empty, so the next account never sees the last one's badge.
  SupporterViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supporterViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supporterViewModelHash();

  @$internal
  @override
  SupporterViewModel create() => SupporterViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupporterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupporterState>(value),
    );
  }
}

String _$supporterViewModelHash() =>
    r'ed3737751c49385f562608281594ed5d93d558ee';

/// The member's supporter licence. Kept alive for the session; a sign-out
/// rebuilds it empty, so the next account never sees the last one's badge.

abstract class _$SupporterViewModel extends $Notifier<SupporterState> {
  SupporterState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SupporterState, SupporterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SupporterState, SupporterState>,
              SupporterState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
