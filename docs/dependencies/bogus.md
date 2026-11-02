# Bogus 35.6.5

Checked 2026-11-02 from [NuGet](https://www.nuget.org/packages/Bogus) and the [GitHub repo](https://github.com/bchavez/Bogus). *Unverified* items were not confirmed.

## Need
Realistic fake data (names, e-mails, dates, GPS-like numbers) for tests and seed data. **Approved but not added to the project yet:** add it when a test needs generated data.

## Alternatives considered
- **Hand-written test data / `Random`:** no dependency; fine for small cases and for deterministic ride files.
- **AutoFixture, other fakers:** also community libraries.

## Licence
MIT (per the repository). The author also sells "Bogus Premium" extensions; the core library is not affected. Premium terms not read.

## Maintenance
- Latest stable 35.6.5, 2025-10-25. **No release in the last 12 months**; there was also a 20-month gap before 2023 (34.0.2 → 35.0.1).
- One owner and maintainer (Brian Chavez), with occasional contributors. 9.8k stars, 70 open issues, 26 open PRs. 290M downloads.
- Received an AWS .NET FOSS Fund award in October 2024.

## Security
- Known advisories: none shown on NuGet.
- Dependencies: none for net6.0 and netstandard2.0; the library does not pull other packages on .NET 10.

## Platform support
- .NET: net6.0 and netstandard2.0 builds; works on .NET 10 through those. Not verified here (not installed).

## Size and performance
Test-only. Seeded generators give repeatable data (use a fixed seed in tests).

## Risk and exit plan
- Risk: slow release cadence and a single maintainer. Output for a given seed can change between versions, so tests must not depend on exact generated values.
- Exit: generated data is only used inside tests; removing it means replacing a few helper methods.

## Recommendation
Approved by the owner on 2026-11-02, with conditions: test projects only, never in `src/`; pin 35.6.x; use a fixed seed and assert on properties, not exact values. Add it when first needed.
