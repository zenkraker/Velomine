# ClubPage

Club: the rider's club. Route `/club`, `features/club/club_screen.dart` and `features/club/widgets/`.

**Recorded choice (design first):** the club's name is written **once**. The page's `h1` is "Club" — the destination's own name, at every width and on both branches, with no `caption` above it, because Club is a destination and not a section's sub-page — and the club's name is the title of the first card, with the member's role badge and the member count beside it. The mock-up drew the name twice (as the `h1` and again on the card); the card keeps it. For a rider in no club the same `h1` opens [NoClubPage](NoClubPage.html), so the destination reads the same whether or not there is a club. Today's code titles the page with the club's name, with "Club" in a `caption` above it; this page is the change, and the code follows it.

- The header's `⋯` menu holds one entry, last and in `danger`, and it is confirmed: **Leave club** for a member, **New code** for the owner (the owner cannot leave).
- Owner and coaches see the plan, the join code, join requests, members (with role changes in each row's menu), the location and the athletes; riders see the rides, the routes and what they share.
- Each card links to its full page: club rides, routes, athletes.
- Every count appears once: the member count on the hero card, the plan's "24 of 50" on the plan card. They are two different facts and neither repeats the other.
- States: a first load is a loading state; a failed load is an error state with a retry; a club with no upcoming rides, no routes or no members says so in that card rather than drawing an empty list.
