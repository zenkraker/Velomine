# LocationPickerPage

Pick a point: a club's place, or the rider's saved location for finding clubs. `features/club/location_picker.dart` (`LocationPickerScreen`). Pushed as a full page over the shell — no URL of its own — from [ClubPage](../club/ClubPage.html) (the location card's "Change location"), [StartClubPage](../club/StartClubPage.html), [NearbyClubsPage](../club/NearbyClubsPage.html) (the saved location), [PrivacyPage](../profile/PrivacyPage.html) (the centre of a new privacy zone) and [PlanRidePage](../club/PlanRidePage.html) (the meeting point).

**Recorded choice (design first):** the pin never moves and the map moves under it. There is no "drag the pin" gesture, no search field and no address: one point, chosen by looking at the map, and that is the whole page.

- The header is on every width, the phone included: "Pick a point", with "Drag the map until the pin is on the place." as the subtitle. The back arrow cancels and returns no point.
- One map, nothing else. It is `narrow` (720 px) wide and a fixed 420 px tall, its corners `radius-md`, and it sits in the page's scroll view. The map is always there: no loading page and no empty map.
- The pin is a `signal` dot with a `card` ring in the middle of the map, as `bundle.css` draws `.pin`; the map's own centre is the chosen point.
- Dragging moves the map, and so does pinch; the wheel zooms. Zoom is held between 3 and 18.
- "Use my current location" is an icon button in the map's top-right corner, filled tonal, with its label as the tooltip: it asks the device for one position and puts the map there, zoomed in to 15. While it asks, a `LoadingState` covers the map and the button is disabled.
- A device that shares nothing is not an error page: the map stays as it was and a line says "Your device did not share its position." The page opens by asking for a position once, silently, when it was given no starting point.
- The chosen numbers sit in a small `card` at the map's bottom-left, to five decimals, formatted for the language; the tiles' attribution sits at the bottom-right.
- Use this point is the page's one main action, pinned on the bottom action bar at the narrow measure. With no point yet it changes nothing and says what to do ("Drag the map to the place first.").
- The point goes back to the page that opened this one; nothing is saved here, and there is no error state, because there is no request to fail.

**Don't**
- Add a search field, an address, a radius or more than one map on the page: the radius is NearbyClubs' own control, and a saved location is one point.
- Make the map shorter than 420 px or give the page a second action: the map is the page.

**Open question for the owner:** the code draws the pin in the theme's error colour, and the design's map pin is `signal`; one of the two changes.

**Flutter:** `features/club/location_picker.dart`; the map is `AppMap` (`lib/core/widgets/app_map.dart`, `flutter_map` over raster tiles), the same widget as [RouteMap](../maps/RouteMap.html).
