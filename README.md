# Velomine

Self-hosted, cycling-only training platform for clubs and teams. No paywall; every member owns their data.

## Status

Early development. The server skeleton runs (ASP.NET Core + FastEndpoints, health check, one endpoint) and the whole stack starts with Docker Compose. Database access is waiting for the Npgsql provider to be approved ([evaluation](docs/dependencies/npgsql-efcore.md)). The v1 scope, release plan and open questions are in [docs/design/v1-scope-and-architecture.md](docs/design/v1-scope-and-architecture.md).

## Run it

```
docker compose up --build
```

Then open http://localhost:8080/health and http://localhost:8080/api/v1/server. Change the port with `VELOMINE_PORT` and the database password with `POSTGRES_PASSWORD` (a `.env` file works). Without Docker: `dotnet run --project src/Velomine.Server`; run the tests with `dotnet test`.

## Documents

- [Architecture](docs/architecture.md)
- [v1 scope and architecture](docs/design/v1-scope-and-architecture.md)
- [Endurain feature analysis (v0.20.2)](docs/research/endurain-feature-analysis-v0.20.2.md)
- [Endurain porting comparison](docs/research/endurain-porting-comparison.md)
- [Brand directions](docs/design/brand-directions.html)

## Contributing

Read [CLAUDE.md](CLAUDE.md) first: it holds the rules for code, architecture and dependencies, including the mandatory ponytail plugin for Claude Code.
