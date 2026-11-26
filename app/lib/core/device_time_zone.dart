import 'device_time_zone_stub.dart'
    if (dart.library.js_interop) 'device_time_zone_web.dart';

/// The device's IANA time zone, or null where the platform does not say one. A server stores it on an account that
/// has none, so midnight and 07:00 are the rider's.
///
/// The browser knows its zone's name. A phone reports only its offset, so it sends that and the server maps it
/// (a `shortcut`: an exact name needs a native channel, which arrives when the 07:00 mail needs it to be exact).
String? deviceTimeZone() => platformTimeZone();
