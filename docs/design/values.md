# Velomine values and product principles

These are the rules that decide what we build, how we price it, and what we refuse to do.
They outrank feature requests, competitors and growth targets.

`AGENTS.md` holds the code rules; `docs/architecture.md` holds the architecture. This
document holds the product and ethical rules and the product scope. When they conflict, a change to this document
is a deliberate decision, not a side effect of a feature.

## Why this exists

Cycling data is personal. A ride file reveals where someone lives, when they are away, how
their health is, and who they ride with. Most platforms treat that data as fuel for
subscriptions, ads and growth. Velomine exists so a club and its members can own the record
of their riding: the club pays for the platform, the member owns the data, and nobody pays
again to see their own history.

## The values

### 1. The member owns the data

- Every member can export everything, in open formats, including the original ride files.
- Delete means delete: account, rides, files and derived data. Backups expire within 90 days.
- Member data is never used for advertising, profiling, resale or AI training.
- Changing platform must never mean losing history.

### 2. No feature paywall

- Every feature is included for every member of a club.
- No paid tier for analysis, routes, history, exports, safety or coaching.
- The club pays. Members never do.
- Plans differ only in who operates the server, not in features.
- We do not remove a feature from the free experience to sell it back later.

### 3. The club controls its data and its administration

- Managed cloud or self-hosted/on-premise, chosen by the club.
- In cloud, clubs share one database and each club's records are kept apart by the
  application and row-level security; self-host runs the whole instance for one club.
- The club decides where the data lives and who administers it.
- No vendor lock-in: documented backups, migrations and a supported export path.

### 4. Privacy by default

- Nothing a member records is visible to anyone else until the member shares it.
- Sharing is per data type, per audience, revocable, and logged for the member.
- Health and wellbeing data needs explicit consent and never appears in share links.
- Telemetry from the member's app is opt-in: crash reports and performance/usage data are contributed only when the member chooses, never include rides, health data, names or emails, and can be withdrawn at any time.
- The server keeps anonymised operational logs, following GDPR, only to fix bugs and performance problems. A self-hosted server sends them nowhere unless its operator chooses to.
- Minors are protected by default: no public profiles, no public individual results.

### 5. No engagement traps

- No ads, no infinite feed, no streak guilt, no public leaderboards by default.
- Success is a healthy, well-run club, not time spent in the app.
- We do not optimise for notifications sent, sessions started or daily active users.

### 6. Interoperability over lock-in

- Import from other platforms: Strava export, FIT, GPX and TCX.
- Export everything, always, without a support ticket.
- A documented API for clubs that want to integrate their own tools.
- Open standards where they exist: FIT, GPX, ICS, OIDC.

### 7. Fair, transparent pricing

- One club price: a one-time activation fee, then a yearly fee per club. No per-seat
  pricing, no feature tiers, no paid add-ons.
- A self-hosted club pays for a licence that never limits seats and never blocks member data.
- Pricing is published before a club commits, and the same for comparable clubs.
- Self-hosting is a first-class option, not a punishment.

### 8. Cycling-only and club-first

- We build for cycling clubs and teams, not a generic multi-sport social network.
- Club and coach needs come before individual engagement metrics.
- A feature that only makes the app stickier, without making the club better, is suspect.

### 9. Health data is special

- Collect the minimum, explain why, and encrypt what matters.
- Wellbeing and cycle data are never shared without separate, explicit consent.
- The member can see, export and delete it like everything else.

### 10. Openness and accountability

- Public changelog and documented product decisions.
- A security disclosure path.
- Licensed AGPL-3.0 with a trademark policy: clubs can inspect, self-host and fork; anyone
  running it as a service publishes their source, and nobody else may use the Velomine name.

## Decision tests

Before building or shipping something, ask:

1. Would we be comfortable showing this data flow to the member in plain language?
2. If the member exported everything and left tomorrow, would the product still be honest?
3. Does this gate something that used to be free, or that the member already paid for?
4. Does this make the club more independent, or more dependent on us?
5. Does this serve the club and the coach, or only engagement?
6. Can a self-hosted club use it without a service we control?
7. Would we be happy if a member's parent, club president and data-protection officer read
   this decision?

## Product scope

| Topic | Decision |
|-------|----------|
| Sports | Cycling only: road, gravel, MTB, e-bike, indoor, commute. Every screen and metric is bike-specific. |
| Users | Clubs and teams, and riders on their own. One club per account, club admin and coach roles, sign-up with admin approval, single sign-on alongside local accounts. A club is an opt-in step, never a requirement. |
| Social | Private rides and coach sharing instead of a feed or followers. Privacy zones hide home and other saved places. |
| Clubs and coaches | The member decides what to share (rides, training, routes, wellbeing) and with whom (the club's coaches today). Every share is revocable and every view is logged. |
| Health | A daily 1–5 check-in (fatigue, soreness, mood, stress, motivation), RPE and notes after each ride. Cycle tracking is planned as optional, highly protected context. |
| Body data | Weight is a single profile field, not a tracked series: W/kg, the VO2max estimate and calories need it. |
| Brand | Velomine, direction D: Contour × Night Ride. Cloud Dancer, deep teal and iron oxide by day; asphalt and Volt while riding. |
| Languages | English and Italian first, as an account setting that follows the member to every device. |

### What makes Velomine different

| Feature | Why |
|---------|-----|
| Wheel-sensor speed and distance | Accurate distance in the woods with single-band GPS; GPS is only the fallback. |
| Cycling analytics (NP, IF, TSS, TRIMP, power curve, FTP and VO2max estimates, fitness/fatigue/form) | Turns recorded streams into training guidance. |
| Readiness view from load, check-in and recent RPE | The point of collecting wellbeing data. |
| Clubs and coaches, private by default | Coaching without making anything public. |
| Privacy zones and per-stream switches | Keeps home and saved places out of every shared view; the owner always sees the full track. |
| Component wear by km, hours or months | Warns before a part fails, not after. |
| Native phone recorder with standard Bluetooth sensors | No vendor app or account needed for any sensor. |

### Out of scope

- Gym and running concepts.
- A social feed with followers: clubs and coaches replace it.
- Health logging (steps, sleep, water, fasting, bowel log): the wellness check-in replaces it.
- Health import from the phone: rides come from the phone recorder, a bike computer or connectors.
- Passkeys: Flutter has no official passkey plugin, and iOS passkey sign-in needs a per-domain app association that self-hosted clubs cannot provide.

## Explicit non-goals

- Advertising, data sale, lead generation or "anonymised" audience products.
- Feature paywalls, per-seat pricing, paid exports or paid API access.
- A public follower graph or a global activity feed.
- Public individual segment leaderboards by default.
- Dark patterns: forced sharing, hidden defaults, cancellation mazes.
- Collecting health data without consent.
- Building a generic multi-sport platform.

## Inter-club social principles

The social layer must not turn Velomine into Strava with a club logo. It follows the same
values:

- **Clubs are the nodes, not people.** The social graph connects clubs; members appear as
  aggregates unless they explicitly opt in.
- **Opt-in at both ends.** One club publishes or invites; the other club accepts. Either can
  revoke.
- **Aggregate by default.** Totals, averages and participation rates, not individual names.
- **The club admin is the moderator** of its club's participation and visibility.
- **No global feed and no follower graph.** Shared events, challenges, routes and results,
  not a stream of everyone's rides.
- **Fair competition.** Normalise by club size or active members, or use divisions, so a
  small club can compete with a large one.
- **No cheating economy.** Verified rides, e-bike/indoor filters, minimums and club
  self-policing; no public KOM hunting.
- **Everything published is also exportable and deletable.**
