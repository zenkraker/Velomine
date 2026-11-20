# GoalGauge

One goal on one card: a half-circle gauge with the percentage, the current value against the target, and one sentence that says what is left.

**The consumer provides** the goal's name, the current value, the target, the unit and the period's end date, plus the routes for editing and deleting it.

**Use it** on the Goals page, a grid of these cards: three per row from 1200 dp, two from 600 dp, one on a phone. Goals are a main destination of their own, not cards on Progress.

**Do**
- Gauge arc `accent-strong` on `track`, 14 px, round caps; the percentage in the middle.
- A reached goal draws the full arc, shows a "Reached" chip on `accent-soft`, and says by how much in the sentence. Over 100 % never draws past the end.
- Edit and Delete live in the card's `⋯` menu; Delete is last, in `danger`, and confirmed.

**Don't**
- Put two goals on one card, or a gauge on a value that is not a share of a target.

**Flutter:** `CustomPainter` with `drawArc`, `StrokeCap.round`.
