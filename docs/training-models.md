# Training and physiology models

Every number Velomine shows about training load, zones, power, heart rate or readiness must match this document. It is
normative: **MUST** and **MUST NOT** are requirements, and a deviation is a bug, not a preference.

The code that implements it lives in `Features/Rides/TrainingLoad.cs`, `Features/Rides/Ingestion/{RideMetrics,
PowerBests,EstimatedPower}.cs`, `Features/Analytics/` (`Readiness.cs` for F2), `Features/Accounts/HeartRates.cs` and
`Features/Training/` (`Recipes.cs`, `SessionPlan.cs`, `SessionTargets.cs`, `WeekPlanner.cs` for the planned week,
`SessionMatch.cs` for ticking, `SessionAdaptation.cs` for W6 and `SessionScore.cs` for L7).

## Rules for changing a model

1. A formula, constant or reference changes in this document, in the code and in its test in the same change.
2. Every formula has a test named `Subject_ShouldDoSomething_WhenCondition` against a hand-worked or published value.
   A test that repeats the implementation is not evidence; the expected number comes from the source.
3. Changing a number in the **stored** list of *Stored or computed* also raises `RideParserVersion.Current`, so older
   rides are read again (`AGENTS.md`).
4. A number Velomine defines itself (see *Where Velomine defines its own score*) MUST be named after Velomine in the
   UI and in code comments, and MUST NOT be attributed to a published method.
5. Constants that represent a published model are written with their source in a comment on the constant.
6. Custom zone bounds are the rider's fractions of the reference. They follow the FTP or the heart rate; only the
   stored TRIMP keeps the standard bounds (H6).

## Stored or computed

Decided once per number, so a chart that sums a range never recomputes it on every request:

- **Stored when a ride is read:** intensity factor, TSS, TRIMP, hrTSS, the power bests, estimated power, and L6's
  efficiency factor and decoupling — from the FTP, the maximum and threshold heart rates and the bike at the ride's
  first read, because the dashboard sums and compares them over a range.
- **Computed on read, never stored:** part wear, goals, weekly, monthly and yearly totals (from each ride's local date
  and the member's first day of the week), zone seconds (from the current profile), the feel score from the rider's own
  rating, the effort score and its source (TSS, else hrTSS, else the feel score, else the estimated TSS), a session's
  planned effort score (L7) and its session score (L8).
- Fitness and fatigue follow L1's effort score for each day.
- A number that moves between those two lists raises `RideParserVersion.Current` (rule 3).

## Inputs that every load depends on

A wrong moving time makes TSS, NP and every average wrong, so these are part of the contract:

- **Pause.** A gap between samples longer than `max(30 s, 5 × median gap)` is a pause, and so is a FIT timer event.
  Pauses are left out of moving time, averages, distance and normalized power.
- **Stopped.** Speed below `0.5 m/s` is stopped.
- **1 Hz resampling.** Signals are held at one value per second of riding; a sample's value lasts until the next
  sample. A second in a pause or in a gap is not emitted.
- **Speed.** The file's speed when most samples have it, otherwise from positions (or cumulative distance). A speed
  that needs more than `10 m/s²` from the last plausible one is a gap.
- **Elevation gain.** 5-sample median filter, moving average, then the sum of changes above `2 m`.
- **Max speed.** The maximum of 5-sample sliding medians over the plausible speeds.

## Power

### P1 — Normalized power (NP)

Resample power to 1 Hz over the ride's stretches. Take a 30-second rolling average, raise each average to the fourth
power, take the mean, then the fourth root. Include coasting zeros; leave pauses out. Null under 30 seconds of power.
The device's own NP wins when the file has one.

Source: Allen & Coggan, *Training and Racing with a Power Meter*; TrainingPeaks, "Normalized Power".

### P2 — Intensity factor (IF)

`IF = NP / FTP`, rounded to two decimals.

Source: Allen & Coggan.

### P3 — Training Stress Score (TSS)

```
TSS = movingS × NP × IF / (FTP × 3600) × 100
```

Null without NP, FTP or moving time. One hour at FTP is 100. Rounded to one decimal.

Source: Allen & Coggan; TrainingPeaks, "What is TSS?".

### P4 — Power zones

Seven zones by upper bound as a fraction of FTP; zone 7 is open-ended. 0 W is not training time and is not counted.

| Zone | Range |
|------|-------|
| Z1 active recovery | < 55 % |
| Z2 endurance | 55 – 75 % |
| Z3 tempo | 75 – 90 % |
| Z4 threshold | 90 – 105 % |
| Z5 VO2max | 105 – 120 % |
| Z6 anaerobic | 120 – 150 % |
| Z7 neuromuscular | > 150 % |

Source: Coggan/Allen (the seven-zone model). Not Friel's six-zone power table.

### P5 — Best mean maximal power

The best mean power over 1, 5, 15, 30 s, 1, 2, 5, 8, 10, 20, 30 and 60 minutes. A window MUST stay inside one
uninterrupted stretch; a pause or a gap ends the stretch, so a stop never creates an effort across it.

Source: Allen & Coggan.

### P6 — FTP from a test

| Test | FTP |
|------|-----|
| 20 minutes | 95 % of the best 20 min |
| 8 minutes | 90 % of the best 8 min |
| 60 minutes | the best 60 min (the definition of FTP) |

A 30-minute effort is not used: its factor has no authoritative source. Suggestions made before this rule keep the
`30min` method; no new one is made.

The power curve uses the 20-minute best, else the 8-minute one. The FTP a finished ride suggests uses the 20 or 60
minute best, whichever gives the higher result (a tie goes to the longer effort), and only when it is at least 3 %
above the FTP in use.

A suggestion comes only from a ride of the last **42 days** on the member's calendar, and never from an e-bike. Both
are Velomine's own rules, not Allen & Coggan's: `Features/Analytics/FtpSuggestion.cs` (`MaxAgeDays`, and the
`Assists.EBike` test).

Source: Allen & Coggan (20 min × 0.95, 8 min × 0.90, FTP ≈ 60 min); the window is Velomine's own.

### P7 — Critical power and W′

Fit `P(t) = CP + W′ / t` by ordinary least squares on `y = P`, `x = 1/t`, using the 2, 5, 10 and 20 minute bests; at
least three of the four. Reject the fit when `R² < 0.90`, `CP` is outside 50–600 W or `W′` is outside 3–50 kJ.

Source: Monod & Scherrer (1965); Poole et al., *Critical Power: An Important Fatigue Threshold in Exercise Physiology*,
Med Sci Sports Exerc 2016 (PMID 27031742).

### P8 — W′ balance

Above CP the balance falls by `(P − CP)` per second. Below CP it recovers exponentially toward W′:

```
τ = 546 × e^(−0.01 × (CP − P)) + 316   seconds   (Skiba et al. 2012)
balance += (W′ − balance) × (1 − e^(−dt/τ))
```

The balance is capped at W′ and MAY go below 0 when the rider beat the model. Pauses carry it over unchanged.

Source: Skiba PF, Chidnok W, Vanhatalo A, Jones AM. *Modeling the expenditure and reconstitution of work capacity above
critical power.* Med Sci Sports Exerc 2012;44(8):1526-32 (PMID 22382171).

### P9 — VO2max estimate

```
VO2max (ml/kg/min) = 10.8 × (W / kg) + 7
```

Source: Hawley & Noakes, *Peak power output predicts maximal oxygen uptake and performance time in trained cyclists*,
Eur J Appl Physiol 1992 (PMID 1505544). The equation was fitted on laboratory peak power from a maximal ramp test. Using
the best 5-minute power is an approximation and MUST be labelled as one.

## Heart rate

### H1 — Maximum heart rate when the rider has not set one

```
maxHR = 208 − 0.7 × age          age clamped to 10–100
```

Source: Tanaka H, Monahan KD, Seals DR. *Age-predicted maximal heart rate revisited.* J Am Coll Cardiol 2001 (PMID
11153730).

### H2 — Threshold heart rate when the rider has not set one

`threshold = 89 % of the maximum in use`, rounded. Never stored.

### H3 — Which zone model applies

The **threshold model** applies only when the threshold's source is `manual` or `measured`. Otherwise the **maximum
model** applies. The choice MUST be made from the source, never from the size of the numbers.

```
HeartRateZoneFor(max, threshold, maxBounds, thresholdBounds)
```

### H4 — Maximum model

Five zones by upper bound as a fraction of the maximum; zone 5 is open-ended.

| Zone | Range |
|------|-------|
| Z1 | < 60 % |
| Z2 | 60 – 70 % |
| Z3 | 70 – 80 % |
| Z4 | 80 – 90 % |
| Z5 | > 90 % |

The zone chart and the easy/moderate/hard split count from 0 %: a beat below the first bound is zone 1. Only the stored
TRIMP applies the 50 % floor.

Source: the conventional five-zone maximum-heart-rate model (ACSM; Polar).

### H5 — Threshold model

Five zones by upper bound as a fraction of the threshold; zone 5 is open-ended.

| Zone | Range |
|------|-------|
| Z1 | < 81 % |
| Z2 | 81 – 90 % |
| Z3 | 90 – 94 % |
| Z4 | 94 – 100 % |
| Z5 | > 100 % |

This is Friel's bike table with 5a/5b/5c merged into zone 5.

Source: Friel, *The Cyclist's Training Bible*; "Joe Friel's Quick Guide to Setting Zones" (bike zones by LTHR).

### H6 — Custom bounds

`accounts.users.heart_rate_max_zone_bounds` and `heart_rate_threshold_zone_bounds` hold four fractions each. They
replace the standard bounds in the zone charts and the three-zone split, and move with the FTP or the heart rate because
they are fractions of the reference. Only the stored TRIMP keeps the standard bounds.

### H7 — TRIMP

```
TRIMP = Σ(seconds in zone i × i) / 60      i = 1..5
```

Maximum model, 50 % floor, stored at the ride's first read. This is **Edwards' zone-weighted TRIMP**, not Banister's
exponential HR-reserve TRIMP. Code, API and UI MUST NOT call it Banister's. The short UI label `TRIMP` is allowed; the
help text under the number names Edwards.

Source: Edwards S, *The Heart Rate Monitor Book* (1993); reviewed in Halson, *Monitoring training load to understand
fatigue in athletes*, Sports Med 2014 (PMID 25200666).

### H8 — Heart-rate effort score (hrTSS)

```
hrTSS = Σ (HR / thresholdHR)² × dt / 3600 × 100
```

One hour at the threshold is 100, so it sits on the TSS scale. Leave out pauses, gaps over 30 s and a heart rate outside
40–230 bpm. Stored at the ride's first read from the threshold in use then.

**Where Velomine defines its own score.** TrainingPeaks' hrTSS is derived from TRIMP and its exact formula is not
published. Velomine's squared-intensity form is a design choice, not the published one. It MUST be presented as
Velomine's own value and MUST NOT be compared with hrTSS from another platform. The field keeps the name `hrTss`; every
comment and any help text says it is ours.

### H9 — Heart-rate values a ride suggests

- **Maximum** from the highest 5-second median, within 120–220 bpm, and only when no rise exceeds 10 bpm/s in the
  preceding 10 s. Rides older than 365 days are ignored.
- **Threshold** from Friel's 30-minute test: the 30-minute window with the highest mean, of which the last 20 minutes
  are averaged. A window with a pause, or under 90 % heart-rate coverage, is skipped. Rides older than 42 days are
  ignored. The threshold MUST stay below the maximum in use.
- A value the rider typed is only **suggested**. An estimated or previously measured value is replaced directly, and
  only by a higher number.

Source: Friel (30-minute threshold test).

## Load and form

### L1 — One effort score per ride

The first that exists: TSS, else hrTSS, else the feel score, else the estimated TSS. The score and its source are chosen
on read from the stored inputs and the rider's rating, so a later rating can change the source.

### L2 — Fitness, fatigue and form

One-pole exponential moving averages, seeded 42 days before the requested range:

```
fitness += (load − fitness) × (1 − e^(−1/42))
fatigue += (load − fatigue) × (1 − e^(−1/7))
form     = fitness − fatigue
```

Source: Coggan/TrainingPeaks Performance Management Chart (CTL, ATL, TSB).

TrainingPeaks' form for today is yesterday's CTL minus yesterday's ATL. Velomine uses the same day; code and UI call
it form and MUST NOT call it TSB.

### L3 — Monotony and strain

Over the seven days ending today (or yesterday when today has no ride yet):

```
monotony = mean(daily load) / SD(daily load)
strain   = Σ(daily load) × monotony
```

A week with no load has neither. SD is the **population** standard deviation of the seven daily loads, not the sample
one. Monotony is capped at 7 when every day is equal. Monotony ≥ 2 is the warning. "Heavy week" is strain above 1.5 ×
the mean of the previous eight seven-day blocks that had load, needing at least four such blocks; that threshold is
Velomine's own.

Source: Foster C. *Monitoring training in athletes with reference to overtraining syndrome.* Med Sci Sports Exerc 1998
(PMID 9662690).

### L4 — Easy, moderate and hard

Seiler's three zones, from power when the ride has power and the rider an FTP, otherwise from the rider's heart-rate
model:

| Signal | Easy | Moderate | Hard |
|--------|------|----------|------|
| Power | < 75 % FTP | 75 – 105 % FTP | > 105 % FTP |
| HR from maximum | < 80 % | 80 – 90 % | > 90 % |
| HR from threshold | < 90 % | 90 – 94 % | > 94 % |

The power boundaries are a proxy for LT1 and LT2, not a measured threshold. A ride with neither signal adds nothing.

Source: Seiler & Kjerland, *Quantifying training intensity distribution in elite endurance athletes*, Scand J Med Sci
Sports 2006 (PMID 16430681); Seiler, *What is best practice for training intensity and duration distribution in
endurance athletes?*, IJSPP 2010 (PMID 20861519).

### L5 — Polarisation index and label

```
PI = log10(easy% × hard% / moderate%)
```

with the three shares as percentages of zone time. Null when moderate is under 0.1 % or hard is 0. The cut-off for a
polarised distribution is `PI > 2.00`.

Source: Treff G et al. *The Polarization-Index.* Front Physiol 2019 (PMID 31249533).

The labels (`polarised`, `pyramidal`, `threshold`, `hiit`, `base`, `mixed`) add thresholds on the shares beyond Treff's
cut-off. They are Velomine's own and MUST be documented as such.

### L6 — Efficiency factor and decoupling

After a 15-minute warm-up, on the seconds that have both power and heart rate (HR 60–220 bpm, power 50–2500 W):

```
EF = NP / mean(HR)
decoupling% = (EF_first_half − EF_second_half) / EF_first_half × 100
```

A ride needs at least 40 minutes after the warm-up. A ride is steady when `NP / mean(power) ≤ 1.05`; only steady rides
get a decoupling number. Positive decoupling means heart rate drifted up for the same power.

Source: Friel, *The Cyclist's Training Bible* (aerobic decoupling, Pw:HR).

### L7 — A planned session's effort score

P3's form over the blocks of a planned session, with each block's intensity factor instead of the ride's:

```
plannedScore = Σ(hours_block × IF_block² × 100)
```

`IF_block` is the middle of the block's % FTP band over 100. A block with no % FTP — the gentle base recipes, which are
ridden by feel — takes the middle of its feel band over 7, the same form as F1. A week's planned load is the sum of its
sessions' scores.

The published number is one intensity for one effort; a recipe gives a range, so using the middle of the band is
Velomine's own choice, and a session ridden at the top of the band scores a few points more than the middle.

Source: Allen & Coggan's TSS form (P3) applied to a plan; the band's middle is Velomine's own. Code:
`Features/Training/SessionPlan.cs` (`PlannedScore`), test `SessionPlanTests`.

### L8 — Session score

Velomine's own score for one planned session against the ride that was it, 0–100, computed on read from the session and
the ride's stored numbers and never stored (see *Stored or computed*):

```
time   = clamp(moving time / planned minutes, 0, 1)
effort = clamp(ride effort score (L1) / the session's planned effort score (L7), 0, 1)
target = clamp(seconds inside the main set's target / the main set's planned seconds, 0, 1)

score = round(100 × (40 % × time + 40 % × effort + 20 % × target))   with the leading signal
score = round(100 × (50 % × time + 50 % × effort))                   without it
```

- The **leading signal** is what the rider could follow: power when the ride has power and every main-set block has a
  % FTP band (P4), else heart rate when the ride has heart rate and every main-set block has a % threshold-heart-rate
  band (H5), else nothing. The gentle base recipes ride by feel, and a ride without a sensor carries neither signal.
- **Time in target** counts the seconds whose sampled value is inside any of the main set's own bands, over the main
  set's planned minutes and capped at the whole set. A pause or a gap over 30 s is not time ridden.
- **A part the ride has no number for is left out, and its weight is shared among the others.** Without the leading
  signal the time in target cannot be measured, so time and effort are 50 % each. A ride with no effort score at all —
  no power, no heart rate, no estimated TSS and no rating — is scored on its time alone, so a rider without sensors who
  rode the plan still reaches 100; that ride is null in `doneEffort`, and it is the only case where the score has one
  part.
- A part of the plan is never worth more than the whole: a longer or harder ride does not pay for a block left out, and
  the score is never negative or above 100.
- **The bands and the planned effort are the ones in use when the session is read**, not the ones in force when the
  ride was: watts from today's FTP (P6), heart rate from today's threshold (H3), and L7's planned effort from those same
  bands. A rider who raises their FTP therefore sees a finished session score differently against the same ride, which
  is deliberate: a session is scored against the plan as the rider would read it now. It is also why the score is never
  stored.

**Where Velomine defines its own score.** The three weights, how a missing part shares its weight with the others, and
the cap at the whole plan are Velomine's own (owner, 24 Nov 2026). No other platform's execution or compliance score is this number and it MUST NOT be
presented as one. It is the rider's private number: it MUST NOT be shown to anyone but the rider, or compared between
riders. Code: `Features/Training/SessionScore.cs`, tests `SessionScoreTests` and `TrainingTickTests`.

## Feel and readiness

### F1 — Feel score

The stored ride feel is the rider's RPE on a 1–10 scale. Foster's session RPE is **linear**: `duration × RPE`. Velomine
scales it to the TSS scale and squares the RPE:

```
feelScore = hours × (RPE / 7)² × 100
```

That squared form is Velomine's own, anchored so one hour at RPE 7 is 100. Code and UI call it the feel score, and it
MUST NOT be described as Foster's sRPE.

Source: Foster C et al. *A new approach to monitoring exercise training.* J Strength Cond Res 2001 (PMID 11708692).

### F2 — Readiness

A transparent sum, never machine learning:

```
score = clamp(50 + form + ramp + recent load + wellbeing + RPE, 0, 100)
```

| Factor | Effect |
|--------|--------|
| form | `−25 + 45 × clamp((form + 30) / 50, 0, 1)` |
| 7-day ramp | `ramp ≥ 0 ? −min(ramp, 10) : +min(−ramp, 5)` |
| today + yesterday load | `−5` when above 200 |
| wellbeing | `(mean − 3) × 10`, mean of mood, motivation, sleep, and `6 −` fatigue, soreness, stress |
| last RPE within 48 h | `−8` at RPE ≥ 8, `+4` at RPE ≤ 4 |

Bands: ≥ 75 hard, ≥ 55 normal, ≥ 35 easy, otherwise rest; `unknown` without history. The wellbeing items are adapted
from Hooper & Mackinnon's index, with the signs flipped so a higher number is better. The score is Velomine's own and
MUST be labelled a guide, not a medical measure.

Source: Hooper SL, Mackinnon LT. *Monitoring overtraining in athletes.* Sports Med 1995 (PMID 8571005).

## Goals

### G1 — Goal pre-selection

The setup opens with one of the five goals pre-selected and one line saying why. These rules decide which goal and which
reason; the rider always wins, so this only pre-selects. **The first rule that matches wins.**

| # | Condition, from the rider's own rides and events | Goal | Reason code | Support |
|---|---|---|---|---|
| 1 | Fewer than 4 calendar weeks of rides (the week of the first ride counts as one) | `aerobic` | `not_enough_riding` | Velomine's own; BC-BEG, WHO, Friel (a chart needs ~6 weeks of data) |
| 2 | Over the last 4 weeks: under 2 rides a week, or under 150 minutes a week, or 2 or more weeks with no ride | `aerobic` | `regular_riding` | WHO/ACSM's 150 minutes a week; the two-ride and empty-week thresholds are Velomine's own |
| 3 | An event in the next 20 weeks (140 days) | `event` | `event_soon` | Velomine's own; the goal is planned as `fitter` (the taper is a later story) |
| 4 | The last ride was 10 or more days ago | `fitter` | `after_break` | Velomine's own; TrainingPeaks on a 10–14 day break |
| 5 | 26 or more weeks of rides, and over the last 8 weeks 3 rides and 4 hours a week and a ride in 6 of the 8 weeks, and the rider set an FTP, and half their rides carry power | `faster` | `power_rides` | Velomine's own; Friel (advanced riders gain most from intensity), Laursen & Jenkins |
| 6 | Everything else | `fitter` | `regular_rider` | Velomine's own; pyramidal-leaning practice (BC-WIN, CTS-WEEK, Friel) |

Weeks are the member's own: a week starts on their first day of the week and a ride counts on its local date, as
everywhere else. "A rides a week" is the count in the window divided by the window's weeks; hours are moving time.
Rule 4's "stay fit with less time" (`keep`) needs the hours the rider is about to give, which the setup asks for after
the goal: it is not pre-selected until a later story reads those hours.

**Every rule and every threshold above is Velomine's own.** No published algorithm picks a plan goal from ride history;
what exists is coaching practice, named in *Support*. The goal pick MUST NOT be presented as a published method, a
coaching guarantee or a medical assessment, and the rider's own choice always replaces it. Code:
`Features/Training/TrainingGoalSuggestion.cs`; the reason codes become the app's one-line sentences.

Tests: `TrainingGoalSuggestion_ShouldPickAerobicExercise_WhenThereAreFewerThanFourWeeksOfRides`,
`…_WhenTheLastFourWeeksAreUnderOneHundredAndFiftyMinutes`, `…_WhenTwoOfTheLastFourWeeksAreEmpty`,
`…_ShouldPickTheEvent_WhenAnEventIsWithinTwentyWeeks`, `…_ShouldPickGetFitter_WhenTheLastRideWasTenDaysAgo`,
`…_ShouldPickGetFaster_WhenAnEstablishedRiderHasPowerInHalfTheRecentRides`,
`…_ShouldPickGetFitter_WhenAnEstablishedRiderHasNotSetAnFtp`,
`…_ShouldPickGetFitter_WhenThreeHoursAWeeksIsAllTheRiderHas`.

## Session recipes

Every planned session is one of these fifteen recipes, scaled to the day. Each block has a length, a % FTP band (P4), a
% threshold heart-rate band (H5) and a feel band (F1); a `–` is a block that has no target in that signal. The code is
`Features/Training/Recipes.cs`, the rider-facing names are `docs/design/pages/training/TrainingNames.md`, and the tests
are `RecipesTests`, `SessionPlanTests` and `SessionTargetsTests`.

| Code | Coaches call it | Rider sees (English · Italian) | Least | Quality | Blocks: minutes @ % FTP · % threshold HR · feel | Goals |
|------|-----------------|-------------------------------|-------|---------|--------------------------------------------------|-------|
| R01 | Easy spin (recovery) | Easy spin · Giro defaticante | 30 | no | 30 @ 40–55 · 60–80 · 1–2 | all five |
| R02 | Endurance | Easy ride · Giro tranquillo | 45 | no | 10 @ 45–60 · 70–80 · 2–3; 50 @ 56–75 · 81–89 · 3–4 | all five |
| R03 | Long ride | Long ride · Uscita lunga | 60 | no | 10 @ 45–60 · 70–80 · 2–3; 90 @ 56–75 · 81–89 · 3–4; 20 @ 70–80 · 88–93 · 4 | all five |
| R04 | Tempo | Steady pace · Ritmo costante | 60 | no | 15 @ 45–65 · 75–85 · 2–3; 40 @ 76–90 · 90–93 · 4–5; 5 @ 40–55 · 70–80 · 2; 10 @ 40–55 · 70–80 · 2 | fitter, event |
| R05 | Sweet spot | Strong and steady · Forte e costante | 60 | yes | 15 @ 55–70 · 80–88 · 3; 40 @ 88–94 · 91–97 · 5–6; 5 @ 40–55 · 70–80 · 2; 10 @ 40–55 · 70–80 · 2 | fitter, faster, event |
| R06 | Threshold | At your limit · Al limite | 50 | yes | 15 @ 65–80 · 85–92 · 4; 30 @ 95–105 · 94–102 · 6–7; 10 @ 40–55 · 70–80 · 2; 10 @ 40–55 · 70–80 · 2 | faster, event |
| R07 | Climbing repeats | Hill repeats · Ripetute in salita | 70 | yes | 15 @ 65–80 · 85–92 · 4; 25 @ 95–105 · 94–102 · 6–7; 20 @ 40–55 · 70–80 · 2; 10 @ 40–55 · 70–80 · 2 | faster |
| R08 | VO2max 4–5 min | Hard efforts · Sforzi duri | 55 | yes | 20 @ 60–80 · 80–90 · 3–4; 20 @ 106–120 · 94–100 · 8–9 (5-minute efforts); 20 @ 40–55 · 70–80 · 2; 10 @ 40–55 · 70–80 · 2 | fitter, faster |
| R09 | 30/15 | On and off · Acceso e spento | 50 | yes | 20 @ 60–80 · 80–90 · 3–4; 10 @ 115–125 · 94–100 · 8–9 (30-second efforts); 10 @ 40–55 · 70–80 · 2 (15-second recoveries); 10 @ 40–55 · 70–80 · 2 | fitter, faster |
| R10 | Anaerobic capacity | All-out bursts · Scatti al massimo | 45 | yes | 20 @ 60–80 · 80–90 · 3–4; 4 @ 120–130 · – · 9 (60-second efforts); 12 @ 40–55 · 70–80 · 2; 10 @ 40–55 · 70–80 · 2 | faster, event |
| R12 | Cadence | Quick legs · Gambe agili | 45 | no | 60 @ 56–75 · 81–89 · 3–4 | all five |
| R14 | Easy start | First rides · Primi giri | 30 | no | 30 @ – · – · 3–4 | aerobic |
| R15 | Steady build | A little faster · Un po' più veloce | 45 | no | 10 @ – · – · 2–3; 20 @ – · – · 4–5; 5 @ – · – · 2; 10 @ – · – · 2–3 | aerobic |
| R16 | Long and easy (base) | Longer, still easy · Più lungo, sempre facile | 60 | no | 75 @ – · – · 3–4 | aerobic |
| R17 | Keep-it | Keep it going · Mantieni il ritmo | 45 | yes | 10 @ 60–75 · 80–88 · 3; 20 @ 88–94 · 91–97 · 5–6; 5 @ 40–55 · 70–80 · 2; 10 @ 40–55 · 70–80 · 2 | keep |

**Scaling.** A recipe fills the day's minutes: its warm-up and cool-down keep their length, and its work, recovery and
steady blocks grow or shrink in proportion, the longest of them taking the minute that rounding leaves over. A day
too short for those fixed blocks — under about twelve minutes of a recipe with a warm-up — scales the whole session, so
a day is never run over. A day shorter than the recipe's least length gets **R02** instead, scaled to that day — the
three gentle base recipes (R14–R16) excepted: they are ridden by feel and scale to whatever the day holds, because the
easy fallback would give a short day the watt and heart-rate targets they deliberately have none of.

**Targets.** A block's watts are its % FTP band against the FTP in use (P6), its heart rate its % threshold band against
the threshold in use (H3) — the number `HeartRates.For` gives: the one the rider set or a ride measured, else H2's 89 %
of the maximum — and its feel is F1's band. A session stores its recipe and its percentages, never watts. Without an FTP
there is no watt target: without a power meter the session says "Add a power meter for watt targets", and with one it
asks for the FTP instead; the 2.5 W/kg stand-in is never a target. Heart rate is no target on an effort of 2 minutes or
less, where it lags, and the session says so once. Every heart-rate number is marked estimated when the threshold in
use is H2's estimate rather than a number the rider set or a ride measured.

**A quality session** is one whose main set **starts** at 88 % FTP or more, the sweet-spot floor (P4's Z4 floor is 90 %):
R05–R10, and R17's short strong block, which is what the keep goal is for. A recipe whose band merely runs into 88 %
(R04's tempo to 90 %) is not a quality session. The long ride is load, not intensity, and is never a quality session. It
is every goal's ride, because the planner gives it to every week: R03 outside the gentle base block, and R16 in it.

**The numbers' sources.** The zone bands are the drafts' rows in `.dev/pack-3-research.md` §3: Coggan's power levels
(TrainingPeaks, "Cycling Power Zones Explained"), Friel's threshold-heart-rate zones ("Joe Friel's Quick Guide to
Setting Zones"), sweet spot 88–94 % FTP (TrainingPeaks, "How to Train at Your Sweet Spot"; British Cycling,
"Understanding intensity 3"), the hard-effort structures of the interval trials (Seiler 2013, PMID 21812820;
Rønnestad 2020, PMID 31977120), the maintenance finding behind R17 (Spiering et al. 2021, PMID 33629972) and the talk
test for the easy bands. Velomine's own, and never attributed to a published session: the warm-up, recovery and
cool-down bands; R01's 40 % floor; **R08 and R09's ceiling of 100 % of the threshold**, where the drafts say only
"> 103 %" and any figure above the threshold would exceed a rider's maximum on the maximum model; **R10's 130 % FTP**
where the drafts say only "> 120 %"; **R03's closing block as a scaled main block** rather than the draft's optional
finish; the gentle base recipes' feel-only targets; and the fifteen recipes themselves in place of a workout library.

## The planned week

Auto training fills the rider's own riding days with the recipes above, one week at a time, and the rules of this section
are what keeps a week safe. They are pure functions: the setup, the last weeks and today go in, the sessions come out
(`Features/Training/WeekPlanner.cs`). The weeks the decisions owe this document are numbered as they are there: owed
number 2 is W1, 3 is W2, 4 is W3, 5 is W4, 6 is W5 and 9 is W6.

**What a week is.** The week runs from the member's first day of the week (`MemberClock`, as everywhere). A session is
written for each of the rider's riding days from today to the end of that week, and a week already met mid-way is
written only for the days it has left. The week's minutes are the rider's hours per week, less what the week already
carries; a week planned for the first time mid-week is scaled to the days left, because the days gone were never planned.
The **long ride** takes two shares of the week's minutes and every other riding day one, so it is `2 / (days + 1)` of
the week. A day is never shorter than its recipe's least length: the day grows into the recipe and the easy days give the
minutes up, down to a floor of 20 minutes. The rider's hours are the ceiling and a day holds 1440 minutes: hours that
cannot give every day its 20-minute floor keep fewer days, hours that cannot hold even one day's floor leave the week
with what it already spent, a hard day's least length never pushes the week past the hours, and no session is longer
than a day. The long-ride day is the rider's own, else the last free weekend day (Sunday, else
Saturday), else the last free day; a week whose long ride is already ridden has no second one, and neither has one whose
every remaining day sits next to a hard day the rider already has — two loaded days in a row are worse than no long ride.
A week too long for its hours or its cap drops its easy days, then its hard days, and never the long ride.

A session stores its recipe, its block percentages and **the day's minutes**; its planned score is L7's, computed from
those on read and never stored. A week's planned load is the sum of its sessions' scores, plus what the week has already
spent: a day ridden without a planned session — today included — is load the week carries and is not planned again.

The order of a goal's hard-day recipes — the gentlest that fits the day first — is `R05 → R08 → R09` for get fitter,
`R05 → R06 → R07 → R08` for get faster and for get ready for a ride or race, `R17` for stay fit with less time, and none
for ride more regularly (research §3, *Which goal uses which recipe*).

### W1 — Two hard days and three loaded days

Owed number 2. A **hard day** is a quality session (see *Session recipes*). A week has **two** of them, **one** under 4
hours a week, **never on consecutive days**, **never the day before or after the long ride**, and never next to a hard day
the week already has. When the rider's days cannot keep that apart, the second hard day goes, and then the first: a week
with no hard day is a correct week. The rider never reads the word quality: it is a **hard day** in every line that says
why.

A **loaded day** is a hard day, or the long ride when it carries **more than 35 %** of the week's planned load. A week has
**three loaded days at most, never on consecutive days**. The long ride is load, not intensity, so it never spends one of
the two hard-day slots. The two counts measure different things on purpose: intensity and load.

The share is one rule and one function, `WeekPlanner.IsLongRideLoaded`: the planner writes a week with it and a move
judges a week with it, over the same load — the week's sessions plus what the week already spent — so a week never has two
answers about its own long ride. The days either side of the week belong to the weeks next to it, whatever window a move
is checked against.

Source: the placement is research §4.2's algorithm and CTS's "two hard days a week, never back to back" (C, coaching
practice); the 88 % sweet-spot boundary and the 35 % share are Velomine's own. Code: `WeekPlanner.HardDays`,
`HardIndexes`, `QualityPreferences`, `LoadedLongRideShare`, `IsLongRideLoaded`, `SessionAdaptation.LongRideLoaded`. Tests:
`WeekPlannerTests` (`ShouldPlanTwoHardDays…`, `ShouldKeepHardDaysApart…`, `ShouldNeverPlanLoadedDaysInARow…`,
`LongRide_ShouldCountAsLoaded…`, `ShouldGiveUpTheLongRide…`, `ShouldKeepTheLongRideAndDropTheHardDay…`,
`ShouldDrawTheGoalsHardDaysFromTheDocumentedRecipes…`), and
`SessionAdaptation_ShouldReadTheLongRideAsThePlannerDid_WhenTheWeekIsJudged`.

### W2 — The build cycle

Owed number 3. Three weeks are built and the fourth is lighter; from the year of birth 50 the cycle is two and one. The
count is the weeks that carry sessions since the **last lighter week**, which the plan records, so a rider who is away
for a month does not come back to a lighter week by arithmetic alone. A week once recorded as lighter **stays lighter**,
so a rewrite in the middle of it cannot turn it back into a build week.

An **early lighter week** follows **three completed days in a row in F2's rest band** (below 35), whether or not the cycle
has reached its lighter week. Today's own readiness is not part of it: the week is planned in the morning, and the three
days it reads are the ones already ridden.

Source: 3:1 is research §4.3 (C: the recovery week of the British Cycling beginner plan, Rutberg's week 4 of 8, TrainingPeaks
and CTS); 2:1 from 50 is Friel's "older athletes need longer recovery" with the 50 cut as Velomine's own; the three
rest-band days are Velomine's own and read F2's band, not a new number. Code: `WeekPlanner.IsLighterWeek`,
`OlderRiderAge`, `RestDaysInARow`. Tests: `ShouldPlanALighterWeek…`, `ShouldPlanALighterWeekAfterTwo…`,
`ShouldPlanALighterWeekEarly…`, `ShouldKeepALighterWeekLighter…`.

### W3 — The lighter week

Owed number 4. A lighter week carries **65 % of the last normal week's load at most**, on the same riding days, and it
keeps **one short hard day, at most 60 minutes**. It is not growth, so it never counts towards W4's mean. The hard day is
kept only while the cap can hold it: the shortest hard session alone can carry more than 65 % of a small last normal
week, and the week is then planned without it, because a lighter week is never made harder to keep a hard day.

Source: research §4.3 — no source gives a verified figure for how much lighter; the drafts' 70 % of the previous build
week (D) becomes 65 % here, and the short hard day is Friel's "two or three days of short, higher-intensity sessions"
(C). Code: `WeekPlanner.LighterWeekShare`, `ShortHardSessionMinutes`. Tests:
`LighterWeek_ShouldCarrySixtyFivePercentOfTheLastNormalWeek…`, `LighterWeek_ShouldKeepOneShortHardDay…`.

### W4 — The ramp

Owed number 5. A week grows by **10 %** past the **mean of the last four normal weeks**, and **only after a week where
everything planned was done** (every session `done`, or `easy` and ridden); otherwise it is held to that mean. It is
never above the rider's hours, which is the week's ceiling whatever the mean says.

A **normal week** is a completed week that has a ride and was not made lighter. Empty weeks (a break) and lighter weeks
are left out of the mean, so neither drags down the week the rider grows from. Without a normal week there is no ramp at
all — a new rider is in the gentle base block below.

When the cap binds, the days shrink together: the planner finds the longest week still under the cap, so a capped week is
a **shorter** week and never a harder one. If even the 20-minute floor is over it, the last easy day goes, then a hard day;
the long ride's day is never the one that goes, because W1 gives up the hard days and keeps the long ride.

Source: research §1.1 and §4.4 — the 10 % cap is a conservative default with no trial behind it (the one randomised trial
of a 10 % rule found no benefit, PMID 17940147), and measuring it against the **normal** weeks only is the research's own
recommendation (D) without which a 2:1 cycle shrinks the load. Velomine MUST NOT present the 10 % as a safety fact.
Code: `WeekPlanner.LoadCap`, `NormalWeeks`, `RampShare`. Tests: `ShouldGrowTenPercent…`, `ShouldNotGrow…`,
`NormalWeeks_ShouldLeaveOutLighterAndEmptyWeeks…`, `ShouldNeverGoOverTheRidersHours…`,
`ShouldStayInsideTheHours…`, `ShouldKeepASessionInsideADay…`, `ShouldPlanNothing_WhenTheWeeksHoursAreAlreadySpent`.

### W5 — The gentle base block

Owed number 6. Fewer than **4 weeks of rides** (G1's first rule) or **back from a break** — G1's 10 days without a ride —
the week is the gentle base block: **R14, R15 and R16 only**, feel targets only, **no intervals**, **no feel number above
6**, and **no ramp** at all. The block is never named to the rider; the one line it shows is "It gets more personal as
your rides come in". Back from a break the plan restarts from the real recent load: the week is no longer than the hours
the recent normal weeks really took, however far back the last of them was, whatever the setup now says, so a rider who
rode three hours a week comes back to about three and not to the twelve they used to. A rider whose first weeks these are
has no recent weeks to restart from, so their own hours are the week, and a base day rides by feel at whatever length it
gets (see *Scaling*).

Source: Velomine's own (G1; research §3, *Gentle base block*, D for the exact dose, C/D for the direction). Code:
`WeekPlanner.IsBaseBlock`, `FromBreak`, `BaseBlockWeeks`, `BreakDays`, `NormalWeeks`. Tests:
`ShouldPlanOnlyTheGentleBaseBlock…`, `BaseBlock_ShouldHaveNoRamp…`, `BaseBlock_ShouldStartAgain…`,
`BaseBlock_ShouldKeepTheRecentWeeksHours…`, `ShouldRestartFromTheHoursLastRode…`, `BaseBlock_ShouldKeepAShortDayGentle…`,
`GetTrainingWeek_ShouldSayItGetsMorePersonal…`.

**What the rider reads.** The planner's terms never reach the rider: a hard session is a **hard day** in every line that
says why (the why lines arrive with the week on screen), the lighter week is an "Easy week" ("Easy week: your body gets
stronger while it rests"), and the gentle base block is never named at all — only that it gets more personal as the rides
come in. The lines are `TrainingNotes`; the names themselves are
`docs/design/pages/training/TrainingNames.md`.

### W6 — Making today easy

Owed number 9. Today adapts to the morning, and the rider can change the day by hand.

**The triggers.** A check-in that answers F2's worst on one of its items — **sleep 1**, **fatigue 5** or **soreness 5**
(F2 keeps higher-is-better, so these are the bottom of the scale) — or a **readiness below 35**, which is F2's rest band,
makes **today's hard session** an endurance one at once, when the check-in is saved. Without a check-in, or without the
wellbeing terms accepted, **L2's form below −30** makes the next hard day easy in the night's own run. A triggering
answer is taken as sleep first, then fatigue, then soreness, so one line is always the reason.

**The replacement.** The hard session becomes **R02** — P4's zone 2 (56–75 % FTP in its main set) at **feel 3–4** — at
**the same minutes**: the same length or shorter, never longer, so a long ride stays long and only gets easier.

**Where the hard work goes.** The replaced hard session moves to the first **later free day** of the week where W1 still
holds — it is not the day before or after another hard day, and not the day before or after the long ride — and where
the week keeps **three loaded days at most**. A free day is one of the rider's own riding days. When no free day fits,
the hard session is **dropped**: it is never piled onto another day, and a week is never made harder to keep it.

**By hand.** "Make today easy" applies to today's session only — nothing else in the week moves — and "Back to the plan"
undoes it the same day, unless a ride has ticked the session; it also takes back the copy a check-in had moved. **Move**
takes a session to any day left this week, a day the rider rides or not; a hard day is refused the day before or after
another hard day or the long ride, and the refusal names the nearest day that works. A session the rider moved is never
rewritten at night. **Skip** takes an optional reason (tired, ill or injured, no time, other) and leaves the session on
its own day; nothing is moved to a later day, and from the second skip of a week the app offers to skip the rest of it.

**What the rider reads.** One line on the today card and the same words in an in-app notification ("Easy today: you
slept poorly. The hard day moves to Thursday."). The reason is one of five: you slept poorly, you feel tired, you are
sore, your form is low, or you asked for it. **A check-in's answers themselves are never returned to anyone but the
owner through the plan** — the owner-only week endpoint carries the reason code and nothing else, so a coach with a
wellbeing grant still reads check-in scores and RPE only.

**Where Velomine defines its own score.** The trigger set, the endurance replacement and the rule that the hard work
moves rather than piles up are Velomine's own. F2's rest band and L2's form floor are this document's numbers, and W1's
spacing and loaded days are the planned week's.

**A ticked session is never undone.** "Back to the plan" refuses once a ride has answered the session, and the night's
planning never removes a session a ride has ticked, whatever its state says: a page left open cannot put a day the rider
rode back to planned, and the week cannot plan a blank day over it.

**A change that loses its row answers 409.** The night removes and re-adds every planned session of today and later, with
new ids, so an easy, a move or a skip issued at that moment updates no row. Each endpoint catches the concurrency failure
and answers 409 with the sentence its own refusal carries, as a ride's own edit does.

Code: `Features/Training/SessionAdaptation.cs` (the triggers, the replacement, the spacing and the night rule),
`MakeSessionEasy.cs`, `MoveTrainingSession.cs`, `SkipTrainingSession.cs`, `TrainingPlanSweeper.cs`, and the check-in's own
`Features/Wellbeing/SaveCheckIn.cs`. Tests: `SessionAdaptationTests`,
`SaveCheckIn_ShouldMakeTodaysHardSessionEndurance_WhenSleepIsTheWorstAnswer`,
`SaveCheckIn_ShouldMakeTodayEasy_WhenTheReadinessIsInTheRestBand`,
`SaveCheckIn_ShouldKeepTheLongRideLong_WhenItIsMadeEasy`,
`TrainingPlanSweeper_ShouldMakeTheNextHardDayEasy_WhenTheFormIsBelowTheFloorAndThereIsNoCheckIn`,
`TrainingPlanSweeper_ShouldNeverRewriteATickedSession_WhenTheNightWritesTheWeekAgain`,
`MoveTrainingSession_ShouldRefuseTheDayBesideAnotherHardDay_WhenTheSessionIsHard`,
`MoveTrainingSession_ShouldRefuseTheDayBesideTheLongRide_WhenTheSessionIsHard`,
`MoveTrainingSession_ShouldLeaveAMovedSessionAlone_WhenTheNightWritesTheWeekAgain`,
`SkipTrainingSession_ShouldKeepItOnItsOwnDay_WhenTheRiderSkipsIt`,
`SkipTrainingSession_ShouldSkipTheRestOfTheWeek_WhenTheSecondSkipAsksForIt`,
`BackToTrainingPlan_ShouldBringTheMovedHardSessionBack_WhenACheckInMovedIt`,
`BackToTrainingPlan_ShouldRefuse_WhenARideHasTickedTheEasySession`,
`MakeSessionEasy_ShouldAnswerAConflict_WhenTheNightReplacedTheSession`,
`MoveTrainingSession_ShouldAnswerAConflict_WhenTheNightReplacedTheSession`,
`SkipTrainingSession_ShouldAnswerAConflict_WhenTheNightReplacedTheSession`,
`GetTrainingWeek_ShouldNotReturnTheCheckInAnswers_WhenTheDayWasMadeEasy`.

## Estimated power

For a ride with no power at all, outdoors or unknown, not an e-bike, with a rider weight:

```
F = m·g·(Crr·cos θ + sin θ) + ½·ρ·CdA·v² + m·a
P = clamp(F·v, 0, 2000 W)
```

| Constant | Value |
|----------|-------|
| `g` | 9.81 m/s² |
| `ρ` | 1.225 kg/m³ (15 °C, still air, no altitude correction) |
| `v` | 5-sample median speed; below 0.5 m/s the sample is 0 W |
| `a` | `(v − v_prev)/dt`, clamped to ±1.5 m/s² |
| grade | altitude change over ±5 s ÷ distance, at least 5 m, clamped to ±25 % |
| `m` | rider weight + bike weight (the bike's own, else the kind's default) |

| Kind | Crr | CdA (m²) | Bike kg |
|------|-----|----------|---------|
| road | 0.004 | 0.32 | 8.5 |
| timetrial, track | 0.004 | 0.25 | 9 |
| gravel | 0.008 | 0.36 | 9.5 |
| mountain | 0.012 | 0.45 | 13 |
| city | 0.008 | 0.55 | 15 |
| other | 0.006 | 0.40 | 11 |

No drivetrain loss is applied. The estimated TSS uses the FTP at read, or `2.5 W/kg` when the rider has none; the
stand-in is never stored. Estimated watts MUST NOT feed power bests, the power curve, FTP suggestions, records, critical
power, W′ balance, decoupling or power zones. They MAY feed the effort score only through L1's last fallback.

Source: Martin JC et al. *Validation of a mathematical model for road cycling power.* J Appl Biomech 1998 (PMID
28121252); Strava's published description of its estimate.

## Where Velomine defines its own score

These are legitimate, but they are Velomine's and must never be presented as a published method or compared with
another platform's number:

- hrTSS (H8) — squared heart-rate intensity.
- feel score (F1) — squared RPE.
- readiness (F2) — the weighted sum above.
- the intensity labels (L5) — thresholds added to Treff's PI.
- "heavy week" (L3) — 1.5 × the usual strain.
- the planned effort score (L7) — P3's form with the middle of a recipe's band as the block's intensity.
- the session score (L8) — time 40 %, effort 40 % and time in target 20 %, or time and effort 50/50 without the leading
  signal.
- the planned week (W1–W5) — the hard-day and loaded-day limits, the cycle, the 65 % lighter week, the 10 % ramp and the
  gentle base block. The coaching practice behind their shape is cited, but no published algorithm plans a week this way,
  so none of it is presented as one.
- making today easy (W6) — the trigger set, the endurance replacement and the rule that the hard work moves to another
  day or goes. Its pieces are F2's band, L2's form floor and W1's spacing, but the adaptation itself is Velomine's own.

## Known non-compliance

None. Every rule above matches the code, and each formula has a test against a hand-worked or published value.
