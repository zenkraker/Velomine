# TrainingSetupPage

Set up auto training: three short questions, then Velomine plans the week. Route `/training/setup`, `features/training/training_setup_screen.dart`. Opened by turning on "Auto training (experimental)" in Profile, and by Change setup on the Training page (then pre-filled with the last answers).

**The consumer provides** the suggested goal and its reason, the rider's free days and hours from last time, and their maximum heart rate and year of birth when known.

**Layout** (a full-page form, `narrow`)
- Title row: the `caption` "Training" above the `page-title` "Set up auto training", and one sentence: "Velomine plans your week from your rides. It is new: tell us what feels wrong." with a link to the feedback form.
- **1 · Your goal**: one row per goal (Ride more regularly · Get fitter · Get faster, with the line "On climbs and on the flat" · Get ready for a ride or race · Stay fit with less time; names and Italian in `TrainingNames.md`) as a single choice. The suggested one is selected and carries the badge "Suggested" and its one-line reason under it. "An event on a date" shows the rider's events to pick from, or "Add an event" when there are none.
- **2 · When you ride**: the days of the week as chips (several can be on), hours per week as a number field, and "Long ride on" as a choice of the free days with "Velomine picks" first (the last free weekend day).
- **3 · Your heart rate**: the switch "I don't know" (on by default when Velomine has no typed or measured maximum; then estimated from age and learned from rides). Turning it off shows the maximum heart rate field. When the year of birth is missing, its field appears here too.
- One `caption` line at the end: "If you have a heart condition or have not exercised for a long time, check with a doctor first."
- Start is the form's submit on the bottom bar; the back arrow cancels and turns nothing on.

**Validation**
- At least one free day; hours between 1 and 30; maximum heart rate 120–220 when typed.

**Don't**
- Ask about other sports, weight goals or anything the plan does not use.
