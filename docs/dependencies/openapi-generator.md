# OpenAPI Generator 7.26.0 (`dart` target)

Checked against the official docs and source on 2026-11-02: [dart generator docs](https://openapi-generator.tech/docs/generators/dart/) (updated 2026-07-14), [installation](https://openapi-generator.tech/docs/installation/) (updated 2026-10-06), [`dart2/pubspec.mustache`](https://github.com/OpenAPITools/openapi-generator/blob/master/modules/openapi-generator/src/main/resources/dart2/pubspec.mustache), [README](https://github.com/OpenAPITools/openapi-generator), [v7.27.0 release](https://github.com/OpenAPITools/openapi-generator/releases/tag/v7.27.0).

## Need
Generate the Dart API client from the server's OpenAPI document, so the Flutter app never has hand-written models or calls that drift from the server. Neither the Dart SDK nor `flutter.dev`/`dart.dev` publish a generator.

The owner accepts a community generator if it is free, well documented and actively supported.

## Alternatives considered
- **swagger_parser 1.45.1** (pub.dev, MIT, verified publisher carapacik.dev): supports OpenAPI 3.1, `allOf`/`oneOf`, and is very active. But the generated code needs `dio`, `retrofit` and `json_annotation` at runtime and `build_runner`, `retrofit_generator` and `json_serializable` at build time: three more community runtime packages, each needing its own evaluation.
- **OpenAPI Generator `dart-dio` target**: needs `dio` and `built_value` at runtime (community).
- **Writing the client by hand**: no dependency, but models drift from the server; the owner ruled this out.

## Licence
Apache-2.0 (LICENSE file). It is a build tool; its output is not under its licence, so it is compatible with AGPL-3.0 or MIT.

## Maintenance
- Last release: 7.27.0 on 2026-11-02 (today; the README still lists it as an upcoming snapshot). Latest stable in the docs and the documented JAR download: **7.26.0** (2026-10-06).
- Commit activity in the last 12 months: very active; about one release a month, the latest with "170+ enhancements and bug fixes". No Dart-specific changes are named in the 7.27.0 notes.
- Maintainers: the OpenAPITools organisation with many contributors (exact number not verified).
- Open issues: many, as it covers 50+ languages; Dart response time not measured.
- Documentation: one page per generator with every option. The `dart` generator is marked **STABLE**.

## What the `dart` generator supports (from its docs)
- Supported: simple schemas; int, double, string, byte, binary, boolean, date, date-time, array, object, enum; path, query, header and cookie parameters; JSON; basic, API key and bearer auth.
- **Not supported:** `allOf`, `anyOf`, `oneOf`, `not`, polymorphism; the `Null` type (OAS3); `uuid` as its own type (generated as plain `String`); `AnyType`; XML; OAuth2 flows other than implicit; OpenID Connect; multiple servers.
- **Multipart form bodies** are marked as supported for OAS2 only. Velomine's ride upload is a multipart request, so this must be tested first.
- Useful options: `useOptional` (distinguishes absent, null and present, Dart 3+), `useFinalProperties`, `enumUnknownDefaultCase` (keeps old apps working when the server adds an enum value), `pubName`, `pubLibrary`.

## Security
- Known advisories or CVEs: none found. The tool runs only in CI and on developer machines, never in production.
- Runtime packages of the generated code (`pubspec.mustache`): `http >=0.13.0 <2.0.0`, `collection >=1.17.0 <2.0.0`, `meta >=1.1.8 <2.0.0`, `intl: any`. All are Dart team packages; confirm each is under `dart.dev` on pub.dev before the first commit. `intl` is unconstrained, so pin it in the app's `pubspec.yaml`.
- Dev packages: `test` (pinned to the old range `>=1.21.6 <1.22.0`); the generated package's own tests are not used.

## Platform support
- .NET: not applicable (it reads the OpenAPI JSON the server produces).
- Flutter: `package:http` works on Android, iOS and web. No native code.
- **OpenAPI 3.1:** the README says "3.1 (beta support)". The `dart` docs only cover OAS2/OAS3. ASP.NET Core 10 emits 3.1 by default and expresses nullable as `"type": ["string", "null"]`, which hits the unsupported `Null` type. **The server must emit OpenAPI 3.0 for the generator** (`OpenApiVersion` set to 3.0 in the OpenAPI options).
- Installation: official Docker image `openapitools/openapi-generator-cli`, or the JAR (Java 11+), npm wrapper `@openapitools/openapi-generator-cli`, Homebrew `openapi-generator`.

## Size and performance
No runtime cost beyond `package:http`. Generation takes seconds.

## Risk and exit plan
- Risks: Dart support is basic (no composition or polymorphism, OAS 3.1 in beta); multipart upload may need a hand-written call; the generated pubspec templates use old version ranges.
- Mitigation: keep API types flat (no `allOf`/`oneOf`, no inheritance in DTOs), emit OpenAPI 3.0, and allow one hand-written method for the file upload if the generator cannot do it.
- Exit: generated code is committed, so the app keeps building if the tool is dropped. Switch to swagger_parser (after evaluating `dio`, `retrofit` and `json_annotation`); only `core/api/` changes.

## Recommendation
Approve with conditions:
- Use the `dart` target with the Docker image pinned to **v7.26.0** (documented stable); move to 7.27.x after it has been out for a few weeks.
- Server emits OpenAPI 3.0; DTOs stay flat.
- Generate with `useOptional=true`, `useFinalProperties=true`, `enumUnknownDefaultCase=true`.
- First task: generate against a sample endpoint including the multipart upload. If any runtime package is not under `dart.dev`, or the upload cannot be generated, stop and report back.
