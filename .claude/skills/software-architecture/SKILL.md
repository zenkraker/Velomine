---
name: software-architecture
description: Use when making structural decisions in Velomine - where code lives, module boundaries, API contracts between server and Flutter apps, sync/offline, background processing, self-hosting and recording decisions.
---

# Software architecture in Velomine

Velomine is one application image and one PostgreSQL database, for the cloud (many clubs) and for a self-hosted club (one club). Judge every decision by two questions: does it stay simple to run, and does the member keep ownership of their data?

The system shape and its decisions are in `docs/architecture.md`; the code rules in `AGENTS.md` win over this skill.

## Before a structural change

- Does it fit the existing shape: a vertical slice in `Features/<Area>/`, a hosted service for background work, one schema per area? If not, the change needs a decision first.
- Does it add a service, a broker, a cache or a second database? The answer is no unless `docs/architecture.md` changes first.
- Does it hold club data? Then it carries `club_id`, filters by the caller's club and gets a second-club test.
- Does it hold member data? Then export and deletion cover it, and non-owners see it only through a grant and the privacy function.
- Does it change the API? Released versions never break; the Dart client is regenerated.
- Does it work offline on the phone? Uploads are idempotent by a client-generated id, so retries never duplicate a ride.
- Does it call an outside service? It is optional, configured by the operator, and off or replaceable for a self-hosted club.

## Recording a decision

A decision that changes the system's shape goes into the *Decisions* table of `docs/architecture.md` with its reason, in the same change. A rule that code must follow goes into `AGENTS.md`. Prefer reversible, boring choices.

To understand an unfamiliar subsystem first, use `codegraph_explore`.
