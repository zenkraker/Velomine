# SoloClubBanner

Ride at your own pace: one quiet line at the top of the Rides list for a member who is in no club. `_SoloBanner` in `app/lib/features/rides/rides_screen.dart`, on [RidesPage](RidesPage.html); the dismissal is kept by `SoloHintViewModel` (`app/lib/core/solo_hint.dart`).

**Recorded choice (design first):** it is a line, not a card. It sits above the list in the page flow with `card` behind it, one row tall, and it never takes the place of a fact card, a chart or a ride — a member with no club is not being sold anything, so it says one thing and then gets out of the way.

- Shown when the club has loaded and is empty, and the member has not dismissed it. It is not shown while the club is still loading, so it never flashes for a member who does have one.
- Its parts, in order: a compass icon in `ink-muted`; the title "Ride at your own pace" and the sentence "There are clubs near you when you want one."; a text button **See clubs**, which opens [NearbyClubsPage](../club/NearbyClubsPage.html); and a close icon button whose label is "Not now".
- Not now puts it away for good: the choice is kept on the device, so it does not come back on the next visit. There is no "undo" and no setting to bring it back.
- The banner has no loading, empty or error state of its own: whether it shows is decided before it is drawn, and its two buttons only navigate and dismiss.
- Only the two actions are interactive; the words are not a link.

**Don't**
- Give it a filled button, a second sentence or an illustration: See clubs is a text button, because the page's main action belongs to the rides.
- Show it to a member who is in a club, or in place of the page's empty state when there are no rides yet.

**Open question for the owner:** the banner is not offered again once dismissed, and no page lists it again; if a member changes their mind, the only way back to it is NearbyClubs from elsewhere.

**Flutter:** `_SoloBanner` in `features/rides/rides_screen.dart`, shown from the router (`app.dart`) with `showSoloCard`; `soloHintViewModelProvider` keeps the dismissal.
