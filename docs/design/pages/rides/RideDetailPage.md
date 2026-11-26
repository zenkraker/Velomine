# RideDetailPage

Ride: one ride with everything read from its file. Route `/rides/:id`, `features/rides/detail/ride_detail_screen.dart`.

**Recorded choice (design first):** the bike is a **card**, not a menu entry. The page draws a Bike card with the bike's name, "Default" and its distance, and one **Change** action that opens a sheet of the rider's active bikes (plus "No bike"); the `⋯` menu does not mention the bike. The mock-up below already drew it this way, and the code agrees.

- The `⋯` menu holds editing the title and description (the [RideTextSheet](RideTextSheet.html)), the ride details (the [RideTypeSheet](RideTypeSheet.html)), Download original file, Download as FIT (only when the original is not a FIT file) and Delete (last, after a divider, in danger red). The owner only: a coach's view of the ride has no menu entries for the file.
- When a ride looks like an open training session from the day before or after, a card above the map asks "Was this your Thursday strong and steady?" with Yes (ticks it) and No (never asked again for this ride). The same question is in the inbox. With auto training off it never appears.
- The route map leads, then the numbers: four headline numbers, then every other number the ride has as tiles on one card, never loose on the page.
- The charts share one cursor; the zones card switches between heart rate and power. Laps, how the ride felt (RPE), the Bike card, and who looked follow. A ride with no bike and none on the account has no Bike card at all; a bike that has been archived is still offered on the ride that used it.
