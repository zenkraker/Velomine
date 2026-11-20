# RidesPage

Rides: the rider's list of rides, newest first. Route `/rides`, `features/rides/rides_screen.dart`.

- Upload ride is the page's one action; Import from Strava and Zwift are in the `⋯` menu.
- From 600 dp the drop area and the filters (search, dates, ride type) sit on the page; on a phone they open from the menu.
- Each ride is a card: its title, date and type chips, then only the facts the ride has, each with its name. A ride still being read shows "Reading the file…"; a failed one shows why.
