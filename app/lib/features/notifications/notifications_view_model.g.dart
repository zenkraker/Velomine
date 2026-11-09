// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The member's notifications and unread count. Kept alive while signed in so the
/// bell has news without opening the screen; a sign-out rebuilds it empty.

@ProviderFor(NotificationsViewModel)
final notificationsViewModelProvider = NotificationsViewModelProvider._();

/// The member's notifications and unread count. Kept alive while signed in so the
/// bell has news without opening the screen; a sign-out rebuilds it empty.
final class NotificationsViewModelProvider
    extends $NotifierProvider<NotificationsViewModel, NotificationsState> {
  /// The member's notifications and unread count. Kept alive while signed in so the
  /// bell has news without opening the screen; a sign-out rebuilds it empty.
  NotificationsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsViewModelHash();

  @$internal
  @override
  NotificationsViewModel create() => NotificationsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationsState>(value),
    );
  }
}

String _$notificationsViewModelHash() =>
    r'10a250530e863eec6339d97600b81143c215f5ef';

/// The member's notifications and unread count. Kept alive while signed in so the
/// bell has news without opening the screen; a sign-out rebuilds it empty.

abstract class _$NotificationsViewModel extends $Notifier<NotificationsState> {
  NotificationsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NotificationsState, NotificationsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NotificationsState, NotificationsState>,
              NotificationsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
