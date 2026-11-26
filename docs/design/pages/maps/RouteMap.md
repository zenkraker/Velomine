# RouteMap

A ride's route on a dimmed map, drawn as a glowing line, with the ride's facts on a glass card over the bottom of the map.

**The consumer provides** the route points (already passed through the privacy function for anyone but the owner), the ride's name and date, and up to three facts (distance, moving time, climbing).

**Do**
- Dim and desaturate the tiles toward `map-ground` in both themes, so the route is the brightest thing.
- Draw a 14 px `route-glow` stroke blurred by 6 px, then the 4 px `accent-strong` line on top.
- Start: `accent` dot. Finish: `signal` dot. Both with a 3 px `card` ring.
- The info card is `glass`, `radius-xl`, inset by `space-lg`.

**Don't**
- Colour the route by speed or heart rate on overview cards; that belongs to the ride page.
- Put buttons on the map card; the whole card opens the ride.

**Flutter:** the tiles are drawn with a `ColorFilter.matrix` that lowers saturation and brightness; the glow is a `Paint` with `MaskFilter.blur(BlurStyle.normal, 6)` under the line (`features/rides/detail/route_painter.dart`).
