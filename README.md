# Velomine

Self-hosted, cycling-only training platform for clubs and teams. No paywall; every member owns their data.

## Status

Early development. Done so far: the server skeleton, the PostgreSQL data layer with migrations, and accounts (sign up with admin approval, password login with cookie or bearer token, refresh, roles admin/member/coach). Next: single sign-on (OpenID Connect), then ride ingestion. The v1 scope, release plan and open questions are in [docs/design/v1-scope-and-architecture.md](docs/design/v1-scope-and-architecture.md).

## Run it

```
docker compose up --build
```

Then open http://localhost:8080/health and http://localhost:8080/api/v1/server. The first admin is created on start: `admin@velomine.local` / `Velomine-dev-1` (set `VELOMINE_ADMIN_EMAIL` and `VELOMINE_ADMIN_PASSWORD` to change them; they only apply while no admin exists). New sign-ups wait for an admin to approve them (`POST /api/v1/accounts/users/{id}/approve`); switch that off with `Velomine__Accounts__RequireAdminApproval=false`. Change the port with `VELOMINE_PORT` and the database password with `POSTGRES_PASSWORD` (a `.env` file works). Without Docker: `dotnet run --project src/Velomine.Server`; Tests: `dotnet test --solution Velomine.slnx` (needs Docker: the database tests start a `postgres:17` container with Testcontainers; set `VELOMINE_TEST_POSTGRES` to a server connection string to use an existing PostgreSQL instead).

## Documents

- [Architecture](docs/architecture.md)
- [v1 scope and architecture](docs/design/v1-scope-and-architecture.md)
- [Endurain feature analysis (v0.20.2)](docs/research/endurain-feature-analysis-v0.20.2.md)
- [Endurain porting comparison](docs/research/endurain-porting-comparison.md)
- [Brand directions](docs/design/brand-directions.html)

## Contributing

Read [CLAUDE.md](CLAUDE.md) first: it holds the rules for code, architecture and dependencies, including the mandatory ponytail plugin for Claude Code.
