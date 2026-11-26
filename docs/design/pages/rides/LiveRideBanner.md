# LiveRideBanner

A ride in progress, one tap away from every screen but the recorder. `features/recording/live_ride_banner.dart` (`LiveRideBanner`), placed by the shell in `app/lib/home_shell.dart`. Phone only: the web has no recorder, so the banner never appears there.

**Recorded choice (design first):** it is a floating element, so it is `glass` with `shadow-float` — the same material as the nav pill it sits above. One line, a stadium, over the content. Today's code fills it with a container colour and a raised elevation instead; this page is the decision, and the code follows it.

- Shown while a ride is recording or paused, on every route except `/record` itself: the recorder is where the ride lives, so it needs no signpost.
- Its parts, left to right: the state's icon — a filled record dot in `danger` while recording, a pause mark in `ink` while paused; the state word, "Recording" or "Paused", on one line; the elapsed time; the distance. Time and distance are tabular figures, so nothing jitters as they count.
- The whole banner is one button: tapping it opens [RecordPhone](RecordPhone.html) (`/record`), which is where Pause and Stop are.
- Its screen-reader label is one sentence, "Recording, 1:12:48, 31.4 km", so a member does not hear the four parts separately.
- It floats above the nav pill on a phone. When a page scrolls down and the pill hides, the banner drops into the pill's slot instead of moving twice; the page always leaves room for both, so a list never jumps under a finger.
- From 600 dp, where there is no pill, it sits at the foot of the content column, the same size and the same one line.
- It fades and grows in and out with the design's motion, and simply appears and disappears when the system asks for reduced motion.
- States: recording, and paused — the word and the icon are the only difference. No loading, empty or error state: the banner reads the recorder's own snapshot.

**Don't**
- Give it a second line, a chart, a Pause button or a Stop button: the actions belong to the recorder, and a stop in a floating banner is a tap away from losing a ride.
- Show it over the recorder, or keep it after the ride has been saved.

**Flutter:** `features/recording/live_ride_banner.dart`; the shell decides when it shows (`_PhoneFrame`, `_WithBanner` in `home_shell.dart`), and `RecorderSnapshot` carries the state, the elapsed seconds and the distance.
