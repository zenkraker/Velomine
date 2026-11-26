# NavPill

The phone's main navigation: a floating glass pill with Rides, Progress, Goals and Club (and Training after Rides when the rider turned auto training on), above the content and the safe area.

**The consumer provides** the destinations (four, or five with auto training) and the current one. A ride in progress shows as a banner above the pill.

**Do**
- `glass` with `blur-glass` and `shadow-float`, `radius-pill`, 64 px tall, at most 420 px wide, inset `space-md` from the edges.
- The selected item sits on `accent-soft` in `on-accent-soft`; icons filled when selected, outlined otherwise.
- The pill slides away while the page scrolls down and returns on scroll up; with reduced motion it stays.
- Pages leave room under their content so the last card clears the pill.

**Don't**
- Add any item beyond these (Training is the only fifth, and only with auto training on), or a floating action button beside it.
- Squeeze labels: with five items the labels stay, at `nav-label` size; the pill keeps its 420 px maximum.

**Flutter:** `FloatingNavPill` in `home_shell.dart`; sizes in `AppNav`.
