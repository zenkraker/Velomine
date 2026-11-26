# RidesPage

Rides: the rider's list of rides, newest first. Route `/rides`, `features/rides/rides_screen.dart`.

- Upload ride is the page's one action; Import from Strava and Zwift are in the `⋯` menu.
- From 600 dp the filters (search, dates, ride type) sit on the page and, on the web, so does [the drop area](BulkUploadCard.html); on a phone the filters open from the menu.
- A rider in no club sees [the solo line](SoloClubBanner.html) above the list, until they put it away.
- Each ride is a card: its title, date and type chips, then only the facts the ride has, each with its name. A ride still being read shows "Reading the file…"; a failed one shows why.
