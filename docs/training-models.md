# Training and physiology models

Every number Velomine shows about training load, zones, power, heart rate or readiness must match this document. It is
normative: **MUST** and **MUST NOT** are requirements, and a deviation is a bug, not a preference.

The code that implements it lives in `Features/Rides/TrainingLoad.cs`, `Features/Rides/Ingestion/{RideMetrics,
PowerBests,EstimatedPower}.cs`, `Features/Analytics/` and `Features/Accounts/HeartRates.cs`.

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
  rating, and the effort score and its source (TSS, else hrTSS, else the feel score, else the estimated TSS).
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

Source: Allen & Coggan (20 min × 0.95, 8 min × 0.90, FTP ≈ 60 min).

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

## Known non-compliance

None. Every rule above matches the code, and each formula has a test against a hand-worked or published value.
