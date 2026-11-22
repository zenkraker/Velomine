# RideDetailPage

Ride: one ride with everything read from its file. Route `/rides/:id`, `features/rides/detail/ride_detail_screen.dart`.

- The `⋯` menu holds editing the title and description, the ride details, the bike, Download original file, Download as FIT (only when the original is not a FIT file) and Delete (last, after a divider, in danger red). The owner only: a coach's view of the ride has no menu entries for the file.
- When a ride looks like an open training session from the day before or after, a card above the map asks "Was this your Thursday sweet spot?" with Yes (ticks it) and No (never asked again for this ride). The same question is in the inbox. With auto training off it never appears.
- The route map leads, then the numbers: four headline numbers, then every other number the ride has as tiles on one card, never loose on the page.
- The charts share one cursor; the zones card switches between heart rate and power. Laps, how the ride felt (RPE), the bike, and who looked follow.
