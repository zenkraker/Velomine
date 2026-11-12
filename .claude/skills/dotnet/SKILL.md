---
name: dotnet
description: Use when writing, reviewing or testing Velomine's server code - .NET 10, C#, ASP.NET Core, EF Core, FastEndpoints, FIT file handling, configuration and tests.
---

# .NET in Velomine

Practical guidance for the server. The rules are in `AGENTS.md` (*Server*, *Clubs and isolation*, *Data*, *Ride processing*, *API*, *Security and privacy in code*, *Tests*); where this skill and `AGENTS.md` disagree, `AGENTS.md` wins.

## Writing code

- **Language:** nullable reference types and `TreatWarningsAsErrors` are on. File-scoped namespaces, `record` for DTOs, `async` all the way with the `CancellationToken` passed through.
- **Packages:** central package management in `Directory.Packages.props`; `packages.lock.json` is committed. Check the approved list in `AGENTS.md` before reaching for a package.
- **Queries:** `AsNoTracking()` for reads, project to DTOs with `Select`, no N+1 (check the generated SQL). A query on a club table always carries the caller's club.
- **Time:** inject `TimeProvider`; never read `DateTime.UtcNow` in code you want to test.
- **Logging:** `ILogger<T>` with message templates, route templates instead of paths, and nothing from the forbidden list in `AGENTS.md`.
- **Configuration:** a new setting is an `IOptions<T>` with validation on start, documented in the README settings table when an operator may change it.

## Tests

- xUnit v3 with `Microsoft.AspNetCore.Mvc.Testing` for HTTP and `PostgresFixture` (Testcontainers) for a real database; single sign-on tests use Dex with the same configuration as `compose.development.yaml`.
- Bogus is approved for fake data when needed: a fixed seed, and no assertions on exact generated values.
- A slice that touches club data gets a second-club test.

## Before committing

Run `just check`.
