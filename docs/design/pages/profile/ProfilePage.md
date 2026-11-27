# ProfilePage

Profile: the rider's numbers, preferences and account. Route `/profile`, `features/profile/profile_screen.dart`.

- Delete my account is in the `⋯` menu, last and red, confirmed with the password.
- The athlete numbers say where each came from (typed, measured on a ride, estimated). Each athlete field saves itself when the rider leaves it or presses done, and sends only that field; the Preferences card and the notification switches save each choice the moment it is made (time zone, first day of the week, notifications, language, units), with no Save of their own. Sections in cards: athlete, zones (the custom zone limits, with Back to automatic), preferences, riding (bikes, privacy, "How I ride" — the rider mode, which opens its sheet — and the switch "Auto training (experimental)" with its sentence and the feedback link: turning it on opens the training setup; turning it off is confirmed: "Your plan for this week and later goes. Your past sessions stay."), notifications, telemetry opt-in, supporter, account (password, two-factor, devices), your data.
- The supporter card shows the licence ("Supporter no. 128 · 3 Oct 2026"), a switch to hide the badge, and Play the celebration again. A solo trial shows as a badge in the same card.
