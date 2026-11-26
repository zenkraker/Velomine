---
title: Getting rides in
description: Upload files, import a Strava export or record with the Android app.
---

## From files

On the **Rides** page, *Upload ride* takes FIT, GPX and TCX files, gzipped or not. On the web you can also drop files, or a whole folder, on the page: a bike computer's folder, or Zwift's Activities folder, goes in as one job with one report, not a message per file. A FIT file that holds several activities becomes one ride per activity.

When the job ends you see counts: new rides, rides that were already here, files that could not be read (with their names and reasons) and files skipped because they are not ride files.

## From Strava

Request your export from Strava, then choose *Import from Strava* in the `⋯` menu on **Rides** and pick the ZIP. The server reads it, one ride per activity. Importing a newer export later skips what is already here. Activities that are not cycling are skipped and counted, photos and the other files are ignored, and the archive is deleted when the import finishes.

## From the Android app

The app records with the screen off and connects to a heart-rate strap over standard Bluetooth LE, with no vendor app and no ANT+. A missing sensor never blocks a ride. The APK is attached to every [release](https://github.com/zenkraker/Velomine/releases/latest). On an iPhone, use the web app in the browser; the iOS recorder is not built yet.

## What Velomine does with a ride

- **Duplicates.** The same ride from another app or device is recognised (same file, or nearly the same start, time and distance) and kept hidden. A single upload tells you; an import counts it. If you delete the ride that was kept, its hidden copy is read again.
- **Speed** comes from the file's own speed when most samples carry it, otherwise from the GPS positions. Every ride records which.
- **The original file** is kept as received, forever. When Velomine's reading improves, your older rides are read again from their own files.
- **No power meter?** The effort score on each ride comes from power, otherwise from heart rate, otherwise from how hard it felt, otherwise from watts estimated from speed and slope. Estimated numbers are always marked as estimated.

The formulas are in [the training models](https://github.com/zenkraker/Velomine/blob/main/docs/training-models.md).
