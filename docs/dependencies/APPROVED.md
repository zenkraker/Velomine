# Approved community libraries

| Library | Version | Approved | Evaluation | Conditions |
|---------|---------|----------|------------|------------|
| FastEndpoints, FastEndpoints.OpenApi | 8.3.x | 2026-11-02, by the owner | [fastendpoints.md](fastendpoints.md) | Endpoints, validation and OpenAPI only; no job queues, messaging or `FastEndpoints.Swagger`. Includes `FluentValidation` as its dependency. |
| OpenAPI Generator (`dart` target, Docker image `openapitools/openapi-generator-cli:v7.26.0`) | 7.26.0 | 2026-11-02, by the owner | [openapi-generator.md](openapi-generator.md) | Build tool only. Server emits OpenAPI 3.0, DTOs stay flat. Generate with `useOptional`, `useFinalProperties`, `enumUnknownDefaultCase`. Stop and report if generated code needs a package outside `dart.dev` or the multipart upload cannot be generated. |
| Npgsql.EntityFrameworkCore.PostgreSQL (brings `Npgsql`) | 10.0.3 | 2026-11-02, by the owner | [npgsql-efcore.md](npgsql-efcore.md) | Pin 10.0.x, not 11.0 until stable. Upgrade together with EF Core. Provider-specific code stays in `Program.cs`, the `Data/` folder and migrations. |
| `postgres` container image (Docker Official Image), used in `docker-compose.yml` | 17 (major version pinned) | 2026-11-02, by the owner | none | Local and self-hosted database. Stay on the 17 line; minor releases are safe in-place upgrades. Moving to a new major version needs a dump and restore plan and a new approval. |
| xunit.v3 | 4.0.x | 2026-11-02, by the owner | [xunit.md](xunit.md) | Test projects only. Run through the Microsoft Testing Platform (`global.json`). |
| Testcontainers.PostgreSql | 4.16.x | 2026-11-02, by the owner | [testcontainers.md](testcontainers.md) | Test projects only; PostgreSQL module only. Keep the `VELOMINE_TEST_POSTGRES` escape hatch. |
| Bogus | 35.6.x | 2026-11-02, by the owner | [bogus.md](bogus.md) | **Approved, not added yet.** Test projects only, fixed seed, no exact-value assertions. |
