# StrapPairingSheet

Pair a heart-rate strap: find the straps around the phone and let the member pick one. A `SheetFrame` behind the start card's strap row on [RecordPhone](RecordPhone.html) (`features/recording/recording_screen.dart`, `_SensorSheet`), reached by that row's "Pair". Phone only, and only where the recorder has sensors.

**Recorded choice (design first):** picking a strap is the only action. There is no Pair button, no empty page and no second step: a row is tapped, the sheet closes, and the start card keeps the pairing.

- Title "Pair a heart-rate strap", then "Wear the strap so it wakes up, then pick it below. It is remembered for your next rides."
- The sheet scans by itself as it opens, after asking for Bluetooth permission.
- While it scans: a progress bar and "Searching for straps…". This is the sheet's only loading state, and it is a scan, not a page load.
- Found straps, one row each: a heart icon, the strap's own name, its address as the detail, and the signal strength where the phone reports one. Tapping a row closes the sheet and hands the strap back to the start card, which connects it.
- Nothing found: "No straps found. Make sure the strap is worn and Bluetooth is on." — the sentence says what to do, and Search again is right under it.
- Bluetooth refused, off, or a scan that failed: `InlineError` in the sheet's body carrying the recorder's own message, above Search again. The sheet never closes on its own and never shows an empty list instead of the reason.
- Search again is a text button at the foot, and is gone while a scan runs.
- Dismissing the sheet pairs nothing and leaves the start card as it was; the row still says "None paired. Optional: heart rate is saved with the ride."
- Forget is the strap row's action on the start card, not a row in this sheet: a paired strap is unpaired where it is shown.

**Don't**
- Show straps that are not heart-rate straps, or rows for services the app does not read.
- Put a main action in the sheet: the sheet's submit is the tap on a row.

**Flutter:** `_SensorSheet` in `features/recording/recording_screen.dart`; scanning and pairing are `RecordingViewModel.scanSensors` / `pairSensor`, and the pairing is stored by `RecorderSettingsStore`.
