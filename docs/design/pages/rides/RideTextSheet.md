# RideTextSheet

Name this ride: the member's title and description for one ride. A `FormSheet` from `showRideTextSheet` (`app/lib/features/rides/ride_text_sheet.dart`), opened from the ride page's `⋯` menu, "Edit title and description" ([RideDetailPage](RideDetailPage.html)). `app/lib/features/rides/ride_title.dart` holds the name a ride shows when this sheet is left empty.

**Recorded choice (design first):** both fields are optional and both are the member's own words. Emptying a field removes it, and an empty title is not a problem to fix — the ride then shows a name made from when and what it was.

- Title "Name this ride", then "Your own words. Coaches you share rides with can read them." — the one place a member is told their text is shared.
- **Title**, with "Leave empty for a name made from the time and type of ride." under it, at most 120 characters.
- **Description**, multiline and five lines tall, at most 2000 characters.
- Save is the sheet's pinned submit, the width of the sheet; dismissing the sheet is cancel and keeps what the ride had.
- While saving, both fields are disabled and Save shows its busy state. A save the server refuses leaves the sheet open with the text as it was, and the reason appears as the page's own message.
- A title left empty falls back to a made-up one, worked out when it is shown and never stored: the ride's period on the member's own clock and the one word that says most about it — "Morning gravel ride", "Evening commute". It therefore follows the language the app is showing.
- States: no loading and no empty state. This sheet edits two fields of a ride the page already has; if the ride is not ready, the menu does not offer the entry at all.

**Don't**
- Make the name required, or add a character counter that blocks Save.
- Write the made-up name into the ride's title: nothing is stored until the member types one.

**Flutter:** `_RideTextSheet` in `features/rides/ride_text_sheet.dart` on `FormSheet` and `AppTextField`; the limits are `rideTitleLimit` and `rideDescriptionLimit`; `rideTitle` / `ridePeriod` / `rideKind` in `features/rides/ride_title.dart` build the fallback name.
