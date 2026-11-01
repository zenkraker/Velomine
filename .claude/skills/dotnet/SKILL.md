---
name: dotnet
description: Use when writing, reviewing or testing Velomine's server code - .NET 10, C#, ASP.NET Core, EF Core, server-rendered HTML share pages, FIT file handling, configuration and tests.
---

# .NET in Velomine

Server: .NET 10 (LTS), ASP.NET Core, EF Core on PostgreSQL. Read `CLAUDE.md` first; its dependency rule overrides anything here.

## Rules

- **Dependencies:** BCL, ASP.NET Core and EF Core first; then `Microsoft.*` / `System.*` packages and vendor SDKs for their own formats (`Garmin.FIT.Sdk`). Anything else needs `docs/dependencies/<package>.md` and approval before `dotnet add package`. Use central package management (`Directory.Packages.props`) and commit `packages.lock.json`.
- **Language:** nullable reference types on, `TreatWarningsAsErrors` on, file-scoped namespaces, `record` for DTOs, `async` all the way with `CancellationToken` passed through.
- **APIs:** Minimal APIs grouped with `MapGroup`, `TypedResults`, errors as `ProblemDetails`. Validate every request body at the boundary.
- **Data access:** `DbContext` directly in handlers/services; no generic repository over EF Core. `AsNoTracking()` for reads, project to DTOs with `Select`, no N+1 (check the generated SQL).
- **Share and landing pages:** plain HTML rendered by the server (Razor Pages or Razor components rendered to HTML). No SPA framework, no client-side build step.
- **Config and secrets:** `IOptions<T>` with validation on start; secrets from environment variables or user-secrets, never committed. Self-hosters must be able to run with just env vars.
- **Auth:** ASP.NET Core Identity / built-in authentication. A member can only read and change their own data unless club roles grant more; enforce it server side.
- **Logging:** `ILogger<T>` with structured templates; never log tokens, passwords or raw location tracks.

## Checks before commit

```bash
dotnet format --verify-no-changes
dotnet build -warnaserror
dotnet test
```

Tests: xUnit (or MSTest), `Microsoft.AspNetCore.Mvc.Testing` for HTTP tests, real PostgreSQL for data tests (see the `postgres` skill), not the EF in-memory provider.
