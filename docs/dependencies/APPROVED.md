# Approved community libraries

| Library | Version | Approved | Evaluation | Conditions |
|---------|---------|----------|------------|------------|
| FastEndpoints, FastEndpoints.OpenApi | 8.3.x | 2026-11-02, by the owner | [fastendpoints.md](fastendpoints.md) | Endpoints, validation and OpenAPI only; no job queues, messaging or `FastEndpoints.Swagger`. Includes `FluentValidation` as its dependency. |
| OpenAPI Generator (`dart` target, Docker image `openapitools/openapi-generator-cli:v7.26.0`) | 7.26.0 | 2026-11-02, by the owner | [openapi-generator.md](openapi-generator.md) | Build tool only. Server emits OpenAPI 3.0, DTOs stay flat. Generate with `useOptional`, `useFinalProperties`, `enumUnknownDefaultCase`. Stop and report if generated code needs a package outside `dart.dev` or the multipart upload cannot be generated. |
