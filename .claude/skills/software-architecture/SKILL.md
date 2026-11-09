---
name: software-architecture
description: Use when making structural decisions in Velomine - where code lives, module boundaries, API contracts between server and Flutter apps, sync/offline, background processing, self-hosting and recording architecture decisions.
---

# Software architecture in Velomine

Velomine runs as a managed cloud service (one shared app, one database per club) and as a self-hosted single-tenant instance. Every decision is judged by: does it stay simple to run, and does the member keep ownership of their data?

## Shape

Follow `docs/architecture.md`; `AGENTS.md` holds only code invariants. In short:

- **One application service and one database per club.** Cloud runs a shared deployment with one database and role per club; self-host runs the same image single-tenant. No microservices, brokers, Redis or extra services. Each club serves up to about 1,000 members; don't design for more.
- **Tenant resolution is a request boundary.** Resolve the club from the host before authentication and select its database. No `club_id` column.
- **Vertical slices** in `Features/<Area>/`: one FastEndpoints endpoint per use case, using the `DbContext` directly. No layers, repositories or mediators.
- **One PostgreSQL schema per feature area**, inside each club's database.
- **Background work** runs in the server: a `Channel<T>` + `BackgroundService` for ingestion, `PeriodicTimer` for scheduled tasks. Queued work carries its tenant; PostgreSQL is storage only: no jobs table, events or outbox.

## Contracts

- The server's HTTP API is the only contract between server and Flutter apps. Version it (`/api/v1`), describe it with `FastEndpoints.OpenApi`, generate the Dart client from that document, and never break a released version: mobile apps update late.
- The server is the source of truth. Mobile may record offline and upload later; uploads must be idempotent (client-generated id) so retries never duplicate an activity.
- Share pages are public, server-rendered HTML with only the data the member chose to share.

## Data ownership and privacy

- Members can export all their data in open formats (original FIT/GPX + JSON) and delete their account completely.
- Privacy zones around home locations are applied before any track is shared.
- No telemetry or third-party calls by default; anything that leaves the server is opt-in and documented.

## Decisions

- Record significant decisions as short ADRs in `docs/adr/NNNN-title.md` (context, decision, consequences).
- Prefer reversible, boring choices. Dependency choices follow the rule in `AGENTS.md`.
- To understand an unfamiliar subsystem before changing it, use CodeGraph (`codegraph_explore`, `codegraph_impact`).
