# EditRoutePage

Edit a club route: its name, its description and its surface. Route `/club/routes/:id/edit`, `features/routes/route_forms.dart` (`EditRouteScreen`). Opened from the route's `⋯` menu on [RouteDetailPage](../club/RouteDetailPage.html), and only for the member who added it: only that member can change a route, so nobody else is drawn an entry to this page.

**Recorded choice (design first):** this page is the add page's second half, not a second form. It is the "Name and details" card of [AddRoutePage](../club/AddRoutePage.html) on a page of its own, with Save pinned. The line is not editable here, and nothing about where the route came from is shown: a route keeps the line and the privacy trimming it was added with.

- The header carries "Club routes" as its `caption` above "Edit the route". There is no sentence under the title: the add page's sentence is about choosing a line, and here there is nothing to choose. Cancel is the back arrow.
- The page is `narrow` (720 px), as the add page is.
- One card, titled "Name and details", in this order: Name, Description (optional), Surface as a [segmented control](../controls/Controls.html) of Road, Gravel, Mountain and Mixed. The fields come filled with what the route has now. Name is required and at most 120 characters, the description at most 1000, and Surface is one of the four.
- Save is the page's one main action, on the bottom action bar (`BottomActionBar`), not in the card: the sheet's or the form's submit is never a filled button inside a card.
- Save shows its busy state while the server takes the change, then closes the page back to the route, which shows the new values.
- A save the server refuses keeps the page open, under the card, as an `InlineError` with the reason: the member's text is still in the fields to retry.
- States: while the route loads, a `LoadingState` under the title. A route that is gone — deleted, or another club's — is not a form with empty fields: it is an empty state that says "It no longer exists." and offers nothing to save.
- Saving is not destructive: no confirmation, and no `⋯` menu on this page — the destructive action is Delete, and it lives on the route's own page.

**Don't**
- Add a map, a source control or the privacy note: those belong to adding a route, and showing them here would say the line can change.
- Put Save inside the card, or a second action beside it.

**Open question for the owner:** the surface is a free choice here, so a route can be switched from Road to Mountain without its line changing; if the surface is meant to describe the line, the picker belongs on the add page only.

**Flutter:** `features/routes/route_forms.dart` (`EditRouteScreen`), `PageScaffold` + `SectionCard` + `AppTextField` + `SegmentedControl` + `BottomActionBar`; the view model is `routeEditViewModelProvider(id)` in `routes_view_model.dart`.
