# AthletePage

Athlete: what one athlete shares with their coach. Route `/club/athletes/:id`, `features/coach/coach_athlete_screen.dart`.

- Read-only. Chips say what is shared; each shared part has its card. Wellbeing shows scores and RPE, never notes.
- With the Rides choice shared and auto training on, a **Plan** card: the goal and this week's sessions, one row per day with its state and, when done, planned beside done in time. The effort score stays with the rider, like the session score. Skip reasons show; the session score does not. Read-only, no actions. Opening it is logged as "Plan" in the rider's "who looked".
