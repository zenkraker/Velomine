---
name: postgres
description: Use when designing Velomine's PostgreSQL schema, writing EF Core migrations, raw SQL, indexes or queries, or handling ride stream data, backups and data export.
---

# PostgreSQL in Velomine

Practical guidance for the database. The rules are in `AGENTS.md` (*Server*, *Clubs and isolation*, *Data*); where this skill and `AGENTS.md` disagree, `AGENTS.md` wins. Access goes through EF Core with the approved Npgsql provider.

## Migrations

- Add a migration with `just migration Name`, and read the generated SQL (`dotnet ef migrations script`) before committing.
- Self-hosters upgrade in place: add a nullable column, backfill, then constrain, across releases. Avoid long locks on big tables (`CREATE INDEX CONCURRENTLY` through `migrationBuilder.Sql`).
- A new club table gets a non-null `club_id`, an index on it, and its place in the club deletion.
- A new member table gets its place in the export and the account deletion cascade.

## Types and shape

- `timestamptz` for instants, `uuid` keys, `text` over `varchar(n)`, `numeric` only for money, `jsonb` only for truly schemaless data.
- Ride streams are arrays per signal on one row per ride; best efforts are rows in `rides.ride_power_bests`. Don't add per-sample rows without a measured query that needs them.

## Queries

- Index for the queries you actually run; check with `EXPLAIN (ANALYZE, BUFFERS)`.
- Paginate with keyset (`WHERE (t, id) < (@t, @id)`), not large `OFFSET`.
- Raw SQL only through parameterised `FromSql`/`ExecuteSql` interpolation, never string concatenation.

## Tests and operations

- Integration tests run against `postgres:17` through `PostgresFixture`, with migrations applied to an empty database.
- Backups for self-hosters are `pg_dump -Fc` and `pg_restore`, together with the file volume and the Data Protection keys.
