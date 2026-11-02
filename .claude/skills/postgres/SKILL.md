---
name: postgres
description: Use when designing Velomine's PostgreSQL schema, writing EF Core migrations, raw SQL, indexes or queries, or handling time-series activity data, backups and data export.
---

# PostgreSQL in Velomine

PostgreSQL is the only database. Access goes through EF Core with the Npgsql provider. Read `CLAUDE.md` first: `Npgsql.EntityFrameworkCore.PostgreSQL` is published by the Npgsql project, not Microsoft, so it needs an evaluation in `docs/dependencies/` like any community library.

## Schema

- Every schema change is an EF Core migration committed to the repo. Never edit an applied migration; add a new one. Review the generated SQL (`dotnet ef migrations script`) before committing.
- Migrations must be safe for self-hosters upgrading in place: additive first (add nullable column, backfill, then constrain), no data loss, no long table locks on big tables (`CREATE INDEX CONCURRENTLY` via `migrationBuilder.Sql` where needed).
- Types: `timestamptz` for all instants (store UTC), `bigint`/`uuid` keys, `numeric` only for money, `text` over `varchar(n)`, `jsonb` only for truly schemaless data.
- Constraints in the database: `NOT NULL`, foreign keys, unique and check constraints. Don't rely on app code alone.
- Snake_case table and column names.

## Activity data

- Activity samples (power, heart rate, cadence, speed, position) are large time series: one row per sample with a composite index on `(activity_id, t)`, or a compact per-activity blob if queries never touch single samples. Decide with a measured query, not a guess.
- Keep the original uploaded file (FIT/GPX/TCX) so data can be re-processed and exported. Members own their data: export and delete must cover every table that holds it.

## Queries

- Index for the queries you actually run; check with `EXPLAIN (ANALYZE, BUFFERS)`.
- Paginate with keyset (`WHERE (t, id) < (@t, @id)`), not large `OFFSET`.
- Raw SQL only through parameterised `FromSql`/`ExecuteSql` interpolation, never string concatenation.

## Tests and ops

- Integration tests run against a real PostgreSQL through `PostgresFixture` (Testcontainers, `postgres:17`), with migrations applied from scratch and one database per test.
- Document backup/restore for self-hosters with `pg_dump` / `pg_restore`.
