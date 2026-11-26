# BulkUploadCard

Adding rides from files: three pieces of the same job, on the web only. `features/rides/bulk/` — `RideDropZone` (the drop area on the page), `_DropTarget` (what a drag over any page shows), `BulkUploadCard` (the run's progress and its summary). The first two sit on [RidesPage](RidesPage.html); the third appears under them.

**Recorded choice (design first):** a folder is one job, reported once. The page's drop area and the drag overlay are the way in; the progress card is the only report, and every file's outcome is a count, with the names of the ones that could not be read — never a row per file and never a notification per file.

## The drop area, on the page

- A card at the top of the Rides list, from 600 dp, wherever the browser can take a drop. It is not drawn on a phone or in a browser without drop support.
- A file icon in `ink-muted`; the title "Drop to add your rides"; the sentence "Files or a whole folder: .fit, .gpx and .tcx files are read, also zipped (.gz)."
- Two text buttons on the right: **Choose files** and **Choose a folder**. Both are disabled while a run is in progress, and both are the same action a drop is.
- Under 720 px the card stacks: the words first, the two buttons under them, so neither runs over the edge.

## The drag overlay

- While files are dragged over the app, any page shows one target over everything: the same title and sentence, centred, larger, and the drop is taken there.
- The target takes no taps: a member who changes their mind drops nothing and the overlay goes when the drag does.
- A drop that cannot be used says so in one line, not a card: "Sign in first, then add your rides again." when nobody is signed in, and "No ride files found. Velomine reads .fit, .gpx and .tcx files, also zipped (.gz)." when the drop held no ride files.
- When a drop starts, the app brings the progress card into view.

## The progress card

It is drawn only while there is a run: not before the first file and not after Close. Its title is **Adding rides from files**, and its sentence changes with the phase.

- **Looking through the files…** while a folder is being walked, with a progress bar under it.
- **Running:** "Reading 12 of 40", spoken as it changes; a determinate bar; **Cancel**, which becomes "Stopping…" — the files already in flight finish first. When the server asks the app to slow down, one more line says "Waiting a moment, the server is busy…"
- **Done:** the sentence is "All files read", or "Stopped before the end" when the member cancelled, and then the counts, in this order: "12 new rides", "3 rides were already here", "2 files could not be read" with their names and reasons (the first 20, then "and 4 more"), "1 file skipped: not a ride file", "1 file was not read". **Close** is the card's one filled button and puts the card away.
- Every file of a drop is sent as a bulk import, so the server makes no notification for any of them: this card is the whole report, and the list behind it refreshes as the rides arrive.

**Don't**
- Show an empty progress card, a row per file, or a failure card of its own: the summary is one card and every outcome is a count in it.
- Leave Cancel enabled once stopping has begun, or leave the bar indeterminate when the total is known.

**Open question for the owner:** the code fills the drag overlay flat and frames it with a 3 px accent border, while the visual language says a floating element is `glass` with `shadow-float`; the mock-up here draws it as glass, so one of the two changes.

**Flutter:** `features/rides/bulk/ride_drop_area.dart` (`RideDropZone`, `RideDropArea`, `_DropTarget`), `bulk_upload_card.dart` (`BulkUploadCard`), `bulk_upload_view_model.dart` (phases) and `drop_source_web.dart` (the browser's drop).
