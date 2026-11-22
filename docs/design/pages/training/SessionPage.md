# SessionPage

One planned session: what to ride and why, and, once ridden, how it went. Route `/training/sessions/:id`, `features/training/session_screen.dart`. Pushed over the shell from the Training page.

**The consumer provides** the session (recipe, day, length, blocks with their percentages, state), the rider's current numbers for the targets, and, when done, the ride and its score.

**Layout**
- Title row: the `caption` "Training" above the `page-title` (the session's name), a sub-line with the day, the length and the state ("Thursday 27 Nov · 1 h 15 · planned"), and the `⋯` menu: Make today easy (today only; "Back to the plan" when it was made easy), Move, Skip. None is destructive. No main action.
- **Why this session**: one or two sentences of purpose, in plain words.
- **The session**: one row per block (warm-up, each main-set block or repeat group, recoveries, cool-down) with its length and the three targets: watts, heart rate and feel. The leading number is bold. Estimated numbers say "estimated". On efforts of 2 minutes or less the heart-rate part reads "heart rate lags here: go by watts and feel". Without a power meter (and no climb estimate), the watts part reads "Add a power meter for watt targets". In the gentle base block, feel leads and watts and heart rate are shown after it, marked estimated.
- The session's shape as a bar strip above the rows (block heights by intensity, hard blocks in `accent-strong`).
- One `caption` line under the rows explains feel once: "Feel 7: hard, you could hold it about an hour."
- **How it went** (when done), above "The session": the score in `kpi` with a kind line in `body` ("Spot on. Textbook session."), then planned beside done as facts: time, effort score, the main target against the ride's average ("228 W planned, 224 W ridden"), and "Open the ride →". The score is the rider's own.
- Move opens a sheet with the days left this week; a hard session cannot land next to another hard one: the day is disabled with the reason, and the nearest allowed day is offered.
- Skip opens a sheet with an optional reason (Tired · Ill or injured · No time · Other) and Skip. On the second skip in a week the sheet adds "Skip the rest of this week?".

**Don't**
- Show a score to anyone but the rider, or in red.
- Put Skip after a divider or in `danger`: skipping is not destructive.
