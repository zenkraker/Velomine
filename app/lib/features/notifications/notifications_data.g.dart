// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationsData)
final notificationsDataProvider = NotificationsDataProvider._();

final class NotificationsDataProvider
    extends
        $FunctionalProvider<
          NotificationsData,
          NotificationsData,
          NotificationsData
        >
    with $Provider<NotificationsData> {
  NotificationsDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationsDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationsDataHash();

  @$internal
  @override
  $ProviderElement<NotificationsData> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationsData create(Ref ref) {
    return notificationsData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationsData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationsData>(value),
    );
  }
}

String _$notificationsDataHash() => r'496e4b2739a234ca7638d617e7025043ef93231f';
