# AdminClubsPage

Admin → Clubs. `features/admin/clubs_tab.dart`.

**Recorded choice (design first):** a club's row carries three entries, and the middle one is conditional. The `⋯` menu holds **Edit plan** (room for, paid until), **Change owner** — only when the club has a member who is not the owner, because a club with only its owner has nobody to hand it to — and last **Deactivate club**, or **Activate club** when it is off. Activating and deactivating are confirmed, and the confirmation says what it means for the members (an inactive club keeps its members and rides; nobody can join it until it is turned back on).

- Create club is the main action (owner's email, name).
- Each row names the club with a state badge beside it: **Active** (accent-soft), **Inactive**, or **Plan ended** (signal) when the paid date has passed. The facts are one caption line under the name, not a subtitle: owner, members against the plan, paid until, and the join code.
- States: the first load is a loading state, not "no clubs yet"; a failed load is an `InlineError` with a retry, above whatever is on screen; an empty server is an empty state.
