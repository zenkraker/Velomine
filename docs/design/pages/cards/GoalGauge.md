# GoalGauge

One goal on one card: a half-circle gauge with the percentage, the current value against the target, and one sentence that says what is left.

**Recorded choice (design first):** the percentage in the middle of the gauge is `stat` — **24 px on a 28 px line**, the token whose own usage is "a gauge's centre". The mock-up drew it at 30 px, which is not on the type scale and is not added: the scale has `page-title`/`kpi` 40, `stat` 24, `card-title` 17, `body` 15, `caption` 13 and `axis` 12, and a value shown inside a gauge is a secondary number, not a headline.

**The consumer provides** the goal's name, the current value, the target, the unit and the period's end date, plus the routes for editing and deleting it.

**Use it** on the Goals page, a grid of these cards: three per row from 1200 dp, two from 600 dp, one on a phone. Goals are a main destination of their own, not cards on Progress.

**Do**
- Gauge arc `accent-strong` on `track`, 14 px, round caps; the percentage in the middle at `stat`.
- A reached goal draws the full arc, shows a "Reached" chip on `accent-soft`, and says by how much in the sentence. Over 100 % never draws past the end, and the number in the middle says how far past it the rider is (130 %).
- Edit and Delete live in the card's `⋯` menu; Delete is last, in `danger`, and confirmed.

**Don't**
- Put two goals on one card, or a gauge on a value that is not a share of a target.
- Scale the percentage to fill the arc: it is one size at every card width.

**Flutter:** `fl_chart`'s `GaugeChart` inside `app/lib/core/widgets/goal_gauge.dart`, clamped at 100 %, with every colour and the thickness from the tokens; only that file imports the library, and the percentage is `VelomineText.stat`.
