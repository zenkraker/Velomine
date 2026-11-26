// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events_data.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventsData)
final eventsDataProvider = EventsDataProvider._();

final class EventsDataProvider
    extends $FunctionalProvider<EventsData, EventsData, EventsData>
    with $Provider<EventsData> {
  EventsDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventsDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventsDataHash();

  @$internal
  @override
  $ProviderElement<EventsData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventsData create(Ref ref) {
    return eventsData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventsData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventsData>(value),
    );
  }
}

String _$eventsDataHash() => r'e19dc2f7afb277857be2eff967d0e58da05ac64e';
