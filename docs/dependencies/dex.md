# Dex v2.46.1 (container image `ghcr.io/dexidp/dex`)

Checked 2026-11-02 from the [GitHub repo](https://github.com/dexidp/dex), its [releases](https://github.com/dexidp/dex/releases), the [docs](https://dexidp.io/docs/) and the security advisories page. Run locally to confirm the config below. *Unverified* items were not confirmed.

## Need
A small OpenID Connect provider for **development and automated tests only**, so the SSO flow (redirect, login, code exchange, account creation) can be tested end to end without an outside service. It is not part of what Velomine ships: in production an admin points Velomine at their own provider (Keycloak, Authentik, Entra, Google, ...).

The official alternative would be Microsoft Entra ID, which is a cloud service with an account and cannot be started in `docker compose` or in a test.

## Alternatives considered
- **Keycloak** (Apache-2.0, CNCF incubating): the most realistic and widely deployed, but about 500 MB, slow to start (JVM), and needs a realm export to configure.
- **mock-oauth2-server** (navikt, MIT): simplest, but its login page is a debugger form, not a real login; image 381 MB.
- **Authentik, Zitadel:** full products with a database; far more than a test needs.
- **A fake OIDC provider written for the tests:** more code to maintain and would not catch real-provider behaviour.

## Licence
Apache-2.0. Not distributed with Velomine, so it does not affect Velomine's licence.

## Maintenance
- Latest v2.46.1 (2026-10-21); v2.46.0 (2026-10-07); releases every few months. 11.2k stars, 4,151 commits.
- Open: 357 issues and 206 pull requests (large backlog). Releases are cut mostly by two maintainers. CNCF Sandbox project (accepted 2020). Last commit date *unverified*.

## Security
- Advisories listed: 4. The latest, GHSA-7qjx-gp9h-65qj (High, May 2026, token-exchange endpoint ignored the allowed-connectors setting), is fixed in v2.46.0. Older ones date from 2020 to 2024. **Use v2.46.1 or later; never v2.41.1 or older.**
- v2.45.0 notes mention two known CVEs in the image's bundled `gomplate` tool (not fixed upstream at that time). Dex is only run locally for tests and bound to `127.0.0.1`, never exposed.
- Runs as a non-root user (uid 1001) — verified.
- The sample password hash in Dex's own docs is the bcrypt of `password`; it is used only in test fixtures.

## Platform support
- Image 218 MB (alpine variant). Tested here: starts in under 3 seconds with `storage: type: memory`, serves discovery at `{issuer}/.well-known/openid-configuration` with `authorization_endpoint {issuer}/auth`, `token_endpoint {issuer}/token`, `jwks_uri {issuer}/keys`, `userinfo_endpoint {issuer}/userinfo`.
- Static users carry `email`, `name` and `email_verified` in the ID token (`emailVerified` in the config).
- The issuer URL must be the same for the browser and for the server calling the token endpoint (see `docker-compose.yml` for how that is solved).

## Size and performance
Starts in seconds; memory use is small. Not measured further.

## Risk and exit plan
- Risk: only used for tests and local runs, so a Dex problem cannot affect production or member data. The backlog of open issues could make a future bug slow to fix.
- Exit: any OIDC provider works with Velomine's SSO setting; swap the compose service and the test fixture for another (Keycloak, mock-oauth2-server).

## Recommendation
Approve for dev and tests only:
- Pin `ghcr.io/dexidp/dex:v2.46.1`, upgrade to later 2.x patches.
- Never run it in a shared or production environment; bind its port to `127.0.0.1`.
