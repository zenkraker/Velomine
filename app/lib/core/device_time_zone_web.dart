import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// The browser's own zone, from `Intl.DateTimeFormat().resolvedOptions().timeZone`, which is an IANA name such as
/// `Europe/Rome` and follows the browser's daylight saving.
String? platformTimeZone() {
  try {
    final intl = globalContext['Intl'] as JSObject?;
    final constructor = intl?['DateTimeFormat'] as JSFunction?;
    if (constructor == null) return null;
    final formatter = constructor.callAsConstructor<JSObject>();
    final resolve = formatter['resolvedOptions'] as JSFunction?;
    final resolved = resolve?.callAsFunction(formatter) as JSObject?;
    final zone = (resolved?['timeZone'] as JSString?)?.toDart;
    return zone == null || zone.isEmpty ? null : zone;
  } catch (_) {
    // A browser too old for Intl: the server maps the offset the caller also sends.
    return null;
  }
}
