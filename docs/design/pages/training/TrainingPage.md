# TrainingPage

Training: the rider's auto-training week. It answers "What do I ride today, and how is my week going?". Route `/training`, `features/training/training_screen.dart`. A main destination, shown only to a rider who turned auto training on (see `navigation/`).

**The consumer provides** the plan: today's session (or a rest day, or the day the plan starts), the current week's sessions with their state, the goal with its reason, and the rider's numbers for the targets.

**Layout**
- Title row: `page-title` "Training" and the `⋯` menu (Change setup, then Turn off auto training after the divider, in `danger`, confirmed: "Your plan for this week and later goes. Your past sessions stay."). No main action: today's session carries its own.
- One sentence under the title: the goal and the week, e.g. "Get fitter · 6 h a week".
- **Today** card, full width: the day as a `caption` ("Today · Thursday"), the session name in `stat` (from `TrainingNames.md`, never the technical term) with its length beside it in `ink-muted`, one sentence of purpose, the main set's targets on one line ("220–235 W · 152–160 bpm · feel 5–6"), the session's shape as a small bar strip, and two actions: "Make today easy" (`quiet` button) and "Open session →" (link). The number the rider can follow leads the target line; estimated numbers carry "estimated". When today changed, one line says why, above the targets: "Easy today: you slept poorly. The intervals move to Saturday." A rest day reads "Rest day" with one kind sentence; before the plan starts, "Your plan starts Monday".
- **This week** card: one row per day of the rider's week, first day first. Each row: the date block, the session name and length (or "Rest"), and its state as a badge: Planned (no badge), Done with its score ("Done · 92"), Easy instead, Moved (to/from a day), Skipped, Missed. Today's row is `card-raised`. Under the rows one line: "2 of 4 done. Nicely on track." Never red, no streaks.
- **Your goal** card: the goal's name, its one-line reason, and when it was set. "Change setup" is in the `⋯` menu, not here.
- From 1200 dp: Today full width, then This week and Your goal side by side (2 : 1). On a phone: one column, the five-item nav pill floating over the bottom.

**States**
- Loading: the shared loading state. Failed: the error state with Try again.
- The night's planning has not run yet for a new week: the rows of last week stay until it does; no empty state.
- On the last day of the week, a second card "Next week (preview)" with the same rows, plain, no actions.

**Do**
- Kind words only. A missed or skipped session is stated plainly, never in `danger`.
- Every number formatted for the language; durations as "1 h 15".

**Don't**
- Show a streak, a total score or a comparison with other riders.
- Say "polarised", "pyramidal", "proven", "fat-burning" or "faster recovery".
