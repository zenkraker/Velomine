# Velomine

Self-hosted, cycling-only training platform for clubs and teams. No paywall; every member owns their data.

## Status

Early development. Done so far: the server skeleton, the PostgreSQL data layer with migrations, and accounts (sign up with admin approval, password login with cookie or bearer token, refresh, roles admin/member/coach). Single sign-on with any OpenID Connect provider works and is tested end to end. Next: ride ingestion. The v1 scope, release plan and open questions are in [docs/design/v1-scope-and-architecture.md](docs/design/v1-scope-and-architecture.md).

## Run it

```
docker compose up --build
```

Then open http://localhost:8080/health and http://localhost:8080/api/v1/server. The first admin is created on start: `admin@velomine.local` / `Velomine-dev-1` (set `VELOMINE_ADMIN_EMAIL` and `VELOMINE_ADMIN_PASSWORD` to change them; they only apply while no admin exists). New sign-ups wait for an admin to approve them (`POST /api/v1/accounts/users/{id}/approve`); switch that off with `Velomine__Accounts__RequireAdminApproval=false`. Change the port with `VELOMINE_PORT` and the database password with `POSTGRES_PASSWORD` (a `.env` file works). Without Docker: `dotnet run --project src/Velomine.Server`; Tests: `dotnet test --solution Velomine.slnx` (needs Docker: the database tests start a `postgres:17` container with Testcontainers; set `VELOMINE_TEST_POSTGRES` to a server connection string to use an existing PostgreSQL instead).

## Single sign-on

Velomine signs people in through any OpenID Connect provider (Keycloak, Authentik, Entra ID, Google, ...). It is on when `Velomine__Sso__Authority` is set, together with `Velomine__Sso__ClientId` and `Velomine__Sso__ClientSecret`; `Velomine__Sso__DisplayName` is the button text, and `Velomine__Sso__AutoCreateUsers=false` limits sign-in to people who already have an account. In the provider, allow the redirect address `https://your-server/signin-oidc`. Behind a reverse proxy that ends TLS, set `ASPNETCORE_FORWARDEDHEADERS_ENABLED=true` so Velomine builds `https` addresses.

How it behaves: the first sign-in creates an account (waiting for admin approval unless `Velomine__Accounts__RequireAdminApproval=false`), or links to an existing account with the same email when the provider says the email is verified. The client starts at `GET /api/v1/accounts/sso/login?returnUrl=/path` and comes back to `returnUrl`, with `?sso_error=<reason>` when it did not work (`not_approved`, `email_not_verified`, `no_account`, `locked_out`, `no_email`, `failed`). `GET /api/v1/accounts/sso` says whether to show the button.

To try it locally, `docker compose up --build` also starts [Dex](docs/dependencies/dex.md), a small provider for development only. Open http://localhost:8080/api/v1/accounts/sso/login and sign in with `rider@sso.test` / `password`. The new account waits for approval, so approve it as the admin first (see above), then sign in again. Use Chrome or Firefox: they send `dex.localhost` to your own machine.

## Documents

- [Architecture](docs/architecture.md)
- [v1 scope and architecture](docs/design/v1-scope-and-architecture.md)
- [Endurain feature analysis (v0.20.2)](docs/research/endurain-feature-analysis-v0.20.2.md)
- [Endurain porting comparison](docs/research/endurain-porting-comparison.md)
- [Brand directions](docs/design/brand-directions.html)

## Contributing

Read [CLAUDE.md](CLAUDE.md) first: it holds the rules for code, architecture and dependencies, including the mandatory ponytail plugin for Claude Code.
