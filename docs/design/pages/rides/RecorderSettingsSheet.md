# RecorderSettingsSheet

Recording settings: the recorder options the start card has no room for. A `SheetFrame` opened by `showRecorderSettings` from the Record page's `⋯` menu (`features/recording/recording_screen.dart`), phone only — the web has no recorder.

**Recorded choice (design first):** starting a ride needs no sheet. Every choice a ride needs *before* Start stays on the start card ([RecordPhone](RecordPhone.html)) — the ride type and auto-pause — and this sheet holds only what can change without affecting the ride about to start.

- Title "Recording settings", no sentence under it.
- One switch row: **E-bike**, with "Counts as assisted and prefers your e-bike." as its detail. The switch writes at once; the sheet watches the recorder itself, so the row shows the new value without a reload.
- "Done" is the sheet's action at its foot, a filled pill the width of the sheet. It only closes the sheet: there is nothing to save, and dismissing the sheet is the same as Done.
- The choice is kept on this phone for the next ride. A phone that cannot store it still applies the choice until the app closes.
- States: none. The sheet holds one local switch, so there is no loading, empty or error state, and no request is made.

**Don't**
- Move the ride type or auto-pause into this sheet: they change the ride being recorded, so they sit where Start does.
- Add a second action beside Done, or a Save that can fail.

**Flutter:** `_SettingsSheet` in `features/recording/recording_screen.dart`; the value is stored by `RecorderSettingsStore` in `features/recording/recorder_settings.dart`.
