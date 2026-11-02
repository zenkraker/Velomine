# Npgsql.EntityFrameworkCore.PostgreSQL 10.0.3

Checked on 2026-11-02 from [NuGet](https://www.nuget.org/packages/Npgsql.EntityFrameworkCore.PostgreSQL), the [GitHub repo](https://github.com/npgsql/efcore.pg), the [10.0 release notes](https://www.npgsql.org/efcore/release-notes/10.0.html) and [Microsoft's provider list](https://learn.microsoft.com/en-us/ef/core/providers/). Items marked *unverified* were not confirmed.

## Need
EF Core needs a database provider to talk to PostgreSQL. Microsoft publishes providers for SQL Server, SQLite, Cosmos and in-memory only; there is no Microsoft PostgreSQL provider. Without it, PostgreSQL would mean writing all data access by hand and giving up EF Core migrations, which the architecture relies on.

This package also pulls in the `Npgsql` ADO.NET driver (same owners), which would be needed even for hand-written SQL.

## Alternatives considered
- **Hand-written SQL with `Npgsql` only:** still a community library (the driver), and loses EF Core, migrations and LINQ. Large effort.
- **Another database with an official provider (SQLite, SQL Server):** contradicts the decision to use PostgreSQL.
- **Another PostgreSQL provider:** none comparable; `Npgsql` is the standard and the one Microsoft lists.

## Licence
PostgreSQL licence (NuGet and GitHub). It is a permissive licence (MIT/BSD style), compatible with AGPL-3.0 or MIT. OSI status of the licence not checked here.

## Maintenance
- Last release: 10.0.3. NuGet says 2026-07-10, the GitHub release list says "14 Sep" (no year); re-check on NuGet before relying on the date. Line 10.0.x targets EF Core 10 and .NET 10; 11.0 is at release candidate 3 (2026-10-28).
- Commit activity: 2,072 commits on main; a release roughly every 2 to 4 months. Last commit date *unverified*.
- Maintainers: Shay Rojansky (`roji`) does essentially every release; NuGet owners are `roji` and the `Npgsql` organisation. Contributor count *unverified*; release notes list about 5 to 8 contributors per release.
- Issues: 208 open issues and 16 open pull requests; response time not measured.
- Adoption: 544.5M total downloads (Npgsql driver 1.1B), 1.8k stars.
- Listed on Microsoft's EF Core provider page, maintained by the Npgsql Development Team (not by Microsoft). That page is out of date and shows EF Core 8 and 9 only.

## Security
- Known advisories or CVEs: none. `dotnet list package --vulnerable --include-transitive` reported no vulnerable packages on 2026-11-02 (the GitHub advisories page was not opened). The 9.0.2 release notes mention a fix around SSL validation in the driver.
- Transitive dependencies (net10.0): `Microsoft.EntityFrameworkCore` >= 10.0.4 < 11, `Microsoft.EntityFrameworkCore.Relational` >= 10.0.4 < 11 (both Microsoft), `Npgsql` >= 10.0.3, which needs `Microsoft.Extensions.Logging.Abstractions` >= 10.0.0 (Microsoft).

## Platform support
- .NET: net10.0 (the 10.0.x line); `Npgsql` targets net8.0, net9.0 and net10.0.
- Flutter: not applicable.
- Feature support, checked by the spike in `tests/Velomine.Server.Tests/Spikes/NpgsqlProviderSpikeTests.cs` against PostgreSQL 16.15 (all passing):
  - `Guid` → `uuid`, `DateTimeOffset` → `timestamptz`, `float[]` → `real[]`, `byte[]` → `bytea`.
  - **Only UTC is accepted for `timestamptz`:** writing a `DateTimeOffset` with a non-zero offset throws (`DbUpdateException` with an inner `ArgumentException`). Code must store UTC and keep the ride's local offset in its own column, as the architecture says.
  - A table in a non-default schema (one schema per feature area) works.
  - `IsRowVersion()` maps to PostgreSQL's `xmin`; a second concurrent save throws `DbUpdateConcurrencyException`.
  - `migrationBuilder.Sql(..., suppressTransaction: true)` runs `CREATE INDEX CONCURRENTLY`, and the index is valid.
- Not yet checked: PostgreSQL 17 (compose uses 17; the spike ran on 16), and `jsonb`.

## Size and performance
No Velomine measurements. Widely used in production; the driver is the performance-focused part (prepared statements, binary protocol).

## Risk and exit plan
- Risk: one main maintainer (bus factor), and a new major version each year that must follow EF Core's release (EF Core 11 will need Npgsql 11).
- Mitigation: pin 10.0.x with the lock file; upgrade together with EF Core; only use provider features through standard EF Core APIs, with raw SQL kept in the `Data/` folder.
- Exit: slices use the `DbContext`, so only `Program.cs` and the migrations reference the provider. A replacement would be a different provider package plus regenerated migrations; the data stays in PostgreSQL. There is no realistic alternative provider today.

## Recommendation
Approved by the owner on 2026-11-02 with these conditions (advisory check and spike done, see above):
- Pin 10.0.x (not 11.0 until stable), commit the lock file.
- Check the security advisories before the first commit.
- First spike: map a ride with `timestamptz`, a `real[]` stream, `bytea`, a schema per feature area, and a migration with `CREATE INDEX CONCURRENTLY`, and report anything unsupported.
