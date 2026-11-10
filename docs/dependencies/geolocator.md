# geolocator 14.1.2

> **Scope widened on 2026-11-10:** the same single on-demand position also sorts nearby clubs on the same server. The binding terms are in `AGENTS.md`.

Checked 2026-11-09 from [pub.dev](https://pub.dev/packages/geolocator), the [GitHub repository](https://github.com/Baseflow/flutter-geolocator) and the pub.dev API. *Unverified* items were not confirmed.

## Need
The opt-in club directory page (inter-club layer, v2) asks the device for one position so the directory can sort clubs by distance. The Flutter SDK has no geolocation API of its own, and neither does the web app outside the browser's `Geolocation` API. On Android and iOS this needs the platform permission flow, which a Dart-only package cannot provide. `geolocator` is the de facto community plugin for exactly this.

The feature does not depend on the plugin being present: a rider can save a home point instead, and that fallback stays in the app whether or not the device allows location.

## Alternatives considered
- **Browser Geolocation API only, via `dart:js_interop`:** no package, but web-only. Android and iOS still need native permission plumbing, so the phone apps would lose the feature.
- **`location` (community):** comparable, smaller community. No advantage over `geolocator` for this need.
- **Saved home location only:** the zero-dependency fallback we keep. It works over plain HTTP and asks no permission, but it is a manual step and is not really "near me".
- **Infer the position from the rider's last ride:** no permission, but implicit and surprising; rejected.

## Licence
MIT, the repository's declared licence. Compatible with this project.

## Maintenance
- Latest 14.1.2, published 2026-10-19 on pub.dev.
- Repository: `Baseflow/flutter-geolocator`, 1.3k stars, 824 forks, 162 open issues, pushed 2026-11-05.
- Maintained by Baseflow as an organisation, not a single developer; it has shipped releases since 2018.
- The issue count is high, but the package is the one most Flutter projects use for this.

## Security
- Known advisories: none found for `geolocator` or its platform packages in a web search on 2026-11-09. This is not a substitute for `flutter pub outdated` / advisory scanning after adding it.
- Transitive dependencies: `geolocator_platform_interface`, `geolocator_android`, `geolocator_apple`, `geolocator_web`, `geolocator_windows`, `geolocator_linux`. The desktop implementations are pulled in by the umbrella package even though Velomine ships Android, iOS and web; they are not used.
- It requests the platform location permission and reads the device position. Velomine uses the result only for the club-directory request and does not store it; the app copy says so.

## Platform support
- Flutter: Android, iOS, web, macOS, Windows and Linux. Native code in the platform packages.
- Web needs a secure context (HTTPS, or `localhost`). On a plain-HTTP LAN address the browser refuses, which is why the saved home location exists.
- Android needs `ACCESS_COARSE_LOCATION` (and optionally `ACCESS_FINE_LOCATION`) in the manifest; iOS needs `NSLocationWhenInUseUsageDescription` in `Info.plist`.
- Dart SDK `^3.5.0`, Flutter `>=2.8.0`; this project is well above both.

## Size and performance
The umbrella package is small; the platform packages add native code to the mobile builds. No background location, no continuous stream: one `getCurrentPosition` call when the club-directory page asks for it, with a timeout. No measurable startup impact.

## Risk and exit plan
- Risk: a community plugin outside the `flutter.dev` publisher; a breaking major update or abandonment would force a migration.
- Exit: the app talks to a single `LocationService` interface. Replacing the plugin means rewriting only its production implementation (or dropping device location and keeping the saved home point). The server and the rest of the app are unaffected.

## Recommendation
Approve. Pin the 14.1.x line, use the umbrella `geolocator` package only (Android, iOS and web), request a single position on demand, and keep the saved-home-location fallback so the feature works when permission or HTTPS is missing.
