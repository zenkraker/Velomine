---
title: Training and bikes
description: Fitness and fatigue, the power numbers, auto training and bike wear.
---

## Progress

**Progress** opens with one rider card: FTP and W/kg, critical power, W′ and peak power, your best 5 seconds to 20 minutes (each opens its ride), maximum and threshold heart rate, the efficiency trend of the last eight weeks, the last 90 days, today's fitness and form, and the next event. Each number says where it came from: typed by you, measured on a ride, or estimated.

Below it are weekly and monthly totals, training load, fitness and fatigue, the power curve, and a daily readiness score. The FTP history shows where each value came from, reminds you when it is out of date, and suggests a higher one when a ride shows it. The formulas are in [the training models](https://github.com/zenkraker/Velomine/blob/main/docs/training-models.md).

Without a power meter, a heart-rate strap alone builds the fitness chart. Heart-rate zones come from your threshold, and both zone sets can be adjusted by hand. Velomine cautions you when every day was about as hard, or the week was much heavier than usual.

**Events** are a date, a distance and climbing: the days to go, and the ride that turned out to be it.

## Auto training (experimental)

Switch it on in *Profile, Riding*. Velomine plans your week from your own rides, after three questions:

1. **Your goal.** Ride more regularly, get fitter, get faster, get ready for an event on a date, or stay fit with less time. One is suggested, with its reason.
2. **When you ride.** Your free days, hours per week (1 to 30), and a day for the long ride.
3. **Your heart rate.** A maximum you type, or "I don't know": it is estimated from age and learned from rides.

Then **Training** shows today's session with its targets in watts, heart rate and feel, and the week's sessions with their state: planned, done with a score, easy instead, moved, skipped or missed. Two hard days a week are kept apart from a long ride on your day, a lighter week comes every few, and load grows only after a week you finished. A ride ticks the session it was and scores it against the plan. You can **make today easy**, move a session, or skip it with a reason.

It is new and still changing: tell us what feels wrong. If you have a heart condition or have not exercised for a long time, check with a doctor first.

Turning it off removes your plan for this week and later; your past sessions stay. A server's operator can disable the feature entirely with `VELOMINE__TRAINING__AUTOENABLED`.

## Bikes and parts

*Profile, My bikes* lists your bikes. A bike holds parts grouped by drivetrain, wheels, brakes and so on, each with a wear bar that goes to a warning when it is getting worn and to danger when it is worn out, always with words. Add service reminders, mark them done, and keep a service log. A bike can be the default for new rides, and archived when you no longer ride it.
