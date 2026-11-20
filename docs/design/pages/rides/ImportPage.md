# ImportPage

Import from Strava: the progress of reading a Strava export ZIP on the server. Route `/rides/import/:id`, `features/rides/import/import_screen.dart`.

- One card: activities read of the total, then what came of them (imported, already here, could not be read, skipped). When it ends: "Import finished" and Back to rides.
