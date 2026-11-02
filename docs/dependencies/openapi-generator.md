# OpenAPI Generator 7.27.0 (`dart` target)

## Need
Generate the Dart API client from the server's OpenAPI document, so the Flutter app never has hand-written models or calls that drift from the server. Neither the Dart SDK nor `flutter.dev`/`dart.dev` publish a generator.

The owner accepts a community generator if it is free, well documented and actively supported.

## Alternatives considered
- **swagger_parser 1.45.1** (pub.dev, MIT, verified publisher carapacik.dev): supports OpenAPI 3.1 and is very active. But the generated code needs `dio`, `retrofit` and `json_annotation` at runtime and `build_runner`, `retrofit_generator` and `json_serializable` at build time. That is three more community runtime packages, each needing its own evaluation.
- **OpenAPI Generator `dart-dio` target**: needs `dio` and `built_value` at runtime (community).
- **Writing the client by hand**: no dependency, but models drift from the server; the owner ruled this out.

The `dart` target of OpenAPI Generator is preferred because its generated code needs only `dart.dev` packages (`http`, `intl`, `meta`, `collection`). That still has to be confirmed on the first generated client.

## Licence
Apache-2.0. It is a build tool only and its output is not under its licence, so it is compatible with AGPL-3.0 or MIT.

## Maintenance
- Last release date: 7.27.0, 2026-11-02.
- Commit activity in the last 12 months: very active; releases about every month, each with 100+ fixes.
- Number of active maintainers: a large maintainer team under the OpenAPITools organisation (exact number not verified).
- Open issues and pull requests: many open issues because it covers 50+ languages; Dart-specific response time not measured.
- Documentation: a page per generator with all options at openapi-generator.tech. The `dart` generator is marked **STABLE**.

## Security
- Known advisories or CVEs: none known for generated Dart code. The tool itself runs only in CI and on developer machines, never in production.
- Transitive dependencies it brings in: none into the app beyond the `dart.dev` packages above. The tool runs from the official `openapitools/openapi-generator-cli` Docker image (or a JAR, which needs Java), so no Java is needed on developer machines that use Docker.

## Platform support
- .NET: not applicable (it reads the OpenAPI JSON the server produces).
- Flutter: `package:http` works on Android, iOS and web. No native code.
- **OpenAPI 3.1:** support was not verified, and the docs mark `oneOf`/`anyOf`/`allOf` as unsupported for `dart`. ASP.NET Core 10 emits 3.1 by default; configure the server to emit 3.0 for the generator if 3.1 causes problems, and keep request/response types simple (no polymorphism).

## Size and performance
No runtime cost beyond `package:http`. Generation takes seconds in CI.

## Risk and exit plan
- Risk: weaker Dart support than the more popular languages; polymorphic schemas not supported.
- Exit: generated code is committed, so the app keeps building if the tool is dropped. Switch to swagger_parser (after evaluating its runtime packages) or another generator; only `core/api/` changes.

## Recommendation
Approve. Use the `dart` target via the official Docker image, pinned to 7.27.0, with the version recorded in the generate script. If the first generated client needs any non-`dart.dev` package, stop and evaluate it.
