# Controls

The four controls every page draws from: the main action, the period selector, the sport filter and the page menu.

**The consumer provides** the labels, the current choice and what each choice does.

**Do**
- **Main action:** one filled pill per screen, `accent` with `on-accent`, `button-label`, at least 48 px tall, in the page header.
- **Period:** a segmented control on `track`; the chosen segment is `card` with `ink`. It sits in the title row of the chart it changes.
- **Sport filter:** chips; the chosen chip is `accent-soft` with `on-accent-soft`. It sits under the page title and applies to the whole page. On a phone the row scrolls sideways.
- **Page menu:** a `⋯` icon button that opens rare actions; destructive entries come last after a divider, in `danger`, and are always confirmed.

**Don't**
- Put the period selector and the sport filter in one row.
- Show a destructive action as a visible button.

**Flutter:** `FilledButton`, `SegmentedButton`, `FilterChip` and `PageMenu` themed from the tokens.
