# FastEndpoints 8.3.0 (with FastEndpoints.OpenApi 8.3.0)

## Need
Endpoint framework for the server's vertical slices: one class per use case with its request, response and validator. The owner chose it explicitly.

ASP.NET Core minimal APIs could do the same job; FastEndpoints gives a fixed structure per slice and built-in validation with less boilerplate.

## Alternatives considered
- ASP.NET Core minimal APIs (official): no extra dependency, but each slice's structure and validation wiring is up to us.
- ASP.NET Core MVC controllers (official): grouped by controller, not by use case.
- Writing a small slice convention ourselves on top of minimal APIs: possible, but that is what FastEndpoints already is.

## Licence
MIT (core and `FastEndpoints.OpenApi`). Compatible with either licence Velomine is considering (AGPL-3.0 or MIT).

## Maintenance
- Last release date: 8.3.0, 2026-08-20. Prereleases of 9.0 up to 9.0.0-beta.6 (2026-10-25).
- Commit activity in the last 12 months: active (8.0 to 8.3 released in 2026; about 3,600 commits on main).
- Number of active maintainers: not verified; the project is led by one main author.
- Open issues and pull requests: 2 open issues at the time of checking.
- 19.8M downloads on NuGet, about 6,000 GitHub stars.
- **Warning:** the 8.x release notes say sponsorship is below target and that the project "will soon be going into 'Bugfix Only' mode".

## Security
- Known advisories or CVEs: none found on NuGet or in the release notes. The GitHub Advisory Database was not checked.
- Transitive dependencies it brings in:
  - `FastEndpoints.Attributes`, `FastEndpoints.JobQueues`, `FastEndpoints.Messaging` (same author; Velomine does not use job queues or messaging)
  - `FluentValidation` >= 12.1.1 (community, Apache-2.0, widely used)
  - `FastEndpoints.OpenApi` adds `Microsoft.AspNetCore.OpenApi` >= 10.0.11 (official)

## Platform support
- .NET: 8.3.0 targets net8.0, net9.0 and net10.0. `FastEndpoints.OpenApi` is net10.0 only.
- Flutter: not applicable.

## Size and performance
Built for low overhead; its benchmarks put it close to minimal APIs. Not measured for Velomine.

## Risk and exit plan
- Risk: one main maintainer and the announced move to bug-fix only.
- Exit: endpoints are thin classes over `VelomineDbContext`, so each one can be rewritten as a minimal API endpoint without touching the logic. FluentValidation validators can be kept, or swapped for minimal API validation. The OpenAPI document already comes from Microsoft's library, so the Dart client generation is unaffected.

## Recommendation
Approve with conditions:
- Pin 8.3.x; do not adopt 9.0 until it is stable.
- Use only endpoints, validation and `FastEndpoints.OpenApi`. Do not use its job queues, messaging or command bus (background work stays in plain hosted services).
- Do not use `FastEndpoints.Swagger` (NSwag); OpenAPI comes from `FastEndpoints.OpenApi`.
