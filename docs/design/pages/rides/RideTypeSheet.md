# RideTypeSheet

Ride details: the four facts that say what kind of ride it was. A `FormSheet` from `showRideTypeSheet` (`app/lib/features/rides/ride_type_sheet.dart`), opened from the ride page's `⋯` menu — "Edit ride details", or "Set ride details" while none is set ([RideDetailPage](RideDetailPage.html)).

**Recorded choice (design first):** the four are separate pickers, not one category. Surface, E-bike, Where and Commute answer different questions and can be true together (a gravel ride, no assist, outdoor, a commute), so the sheet offers four optional choices in a fixed order and never derives one from another.

- Title "Ride details", then "What kind of ride was it? Everything here is optional."
- Four rows, in this order, each starting on what the ride already says or on "Not set": **Surface** (Road, Gravel, Mountain, Track), **E-bike** (No e-bike, E-bike), **Where** (Outdoor, Indoor, Virtual), **Commute** (Yes, No).
- "Not set" is always one of the choices: picking it clears the fact, and Save writes that. Nothing here is required.
- Each row is the platform's dropdown, not a segmented control: four rows of segmented controls would not fit one sheet, and the values are four or fewer. The mock-up draws the same dropdowns.
- Save is the sheet's pinned submit, the width of the sheet; dismissing the sheet is cancel and keeps what the ride had.
- While saving, the four rows are disabled and Save shows its busy state. A save the server refuses leaves the sheet open with the choices as they were, and the reason appears as the page's own message; the sheet never closes on a failure.
- The entry appears only for a ride the server has finished reading: a ride still being read has no `⋯` entry for its details.
- The surface, the e-bike switch, the place and the commute are what name a ride that has no title of its own ([RideTextSheet](RideTextSheet.html)): the word that says most about it comes from these four.
- States: no loading, empty or error state. The sheet edits four fields of a ride the page already has.

**Don't**
- Make a fact required, or make one sheet for each of the four: one sheet, one Save.
- Add free text, notes or a route here: the member's own words are the title and description sheet, and the route is the map.
- Save on every change: the sheet's changes go together, on Save.

**Open question for the owner:** the four rows are dropdowns while the visual language says a short segmented choice is a `SegmentedControl`; this page records the sheet's taller form as the exception.

**Flutter:** `_RideTypeSheet` in `features/rides/ride_type_sheet.dart` on `FormSheet`, four `DropdownButton`s inside an `InputDecorator`; the save is the page's `RideTypeSaver`, `RideDetailViewModel.setType`.
