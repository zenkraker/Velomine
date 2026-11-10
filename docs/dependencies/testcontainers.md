# Testcontainers for .NET (Testcontainers.PostgreSql 4.16.0)

Checked 2026-11-02 from [NuGet](https://www.nuget.org/packages/Testcontainers.PostgreSql), the [GitHub repo](https://github.com/testcontainers/testcontainers-dotnet) and the [PostgreSQL module docs](https://dotnet.testcontainers.org/modules/postgres/). *Unverified* items were not confirmed.

## Need
Data tests must run against a real PostgreSQL (not the EF in-memory provider). Testcontainers starts a throwaway `postgres:17` container per test run, the same image `docker-compose.yml` uses, so developers need no database installed.

## Alternatives considered
- **A PostgreSQL service in CI plus a connection string:** official and simple; still supported through `VELOMINE_TEST_POSTGRES` (the fixture uses it when set).
- **Own code driving the Docker CLI:** more code to maintain, no automatic cleanup.

## Licence
MIT. Test-only; not in the server image.

## Maintenance
- Latest 4.16.0 (2026-10-09); roughly monthly releases.
- Main maintainer: Andre Hofmeister (`HofmeisterAn`), who releases almost every version. 4.4k stars, 31 open issues, 15 open PRs. 55.7M downloads.
- Release 4.14.0 (2026-08-14) was published after developers asked for a fix to an SSH.NET vulnerability. 4.16.0 uses signed attestations and NuGet Trusted Publishing.

## Security
- Known advisories: none shown on NuGet (the GitHub tab was not checked). `dotnet list package --vulnerable --include-transitive` should be run after adding it.
- Dependencies: `Testcontainers` (same project). It brings Docker.DotNet, SSH.NET and BouncyCastle for its own use.
- It needs access to the Docker socket and starts a "Ryuk" helper container (`testcontainers/ryuk:0.14.0`) that removes test containers afterwards. Anyone who can run the tests can start containers on the machine.

## Platform support
- .NET: net10.0 listed as compatible; verified here on .NET 10.0.403 with `postgres:17`.
- Needs Docker (or a compatible engine) on the machine running the tests. Without Docker, set `VELOMINE_TEST_POSTGRES`.

## Size and performance
First run pulls `postgres:17` (about 650 MB) and `testcontainers/ryuk`. After that a database starts in a few seconds. The fixture starts one container per test class; each test creates its own database.

## Risk and exit plan
- Risk: one main maintainer; tied to Docker availability and Docker Hub rate limits in CI (pull the image through a mirror or cache it).
- Exit: only `PostgresFixture` uses it. Replace its body with a connection string to any PostgreSQL.

## Recommendation
Approved by the owner on 2026-11-02. Pin 4.16.x; the PostgreSQL module, plus the core generic `ContainerBuilder` to run Dex with the same configuration as `docker-compose.yml`. The binding terms are in `AGENTS.md`. Keep the `VELOMINE_TEST_POSTGRES` escape hatch.
